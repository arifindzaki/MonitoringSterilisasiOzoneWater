import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
const Color bgCream = Color(0xFFF5EFE6);


/// =======================================================
/// GLOBAL KHUSUS GRAFIK (CACHE 10 DATA TERAKHIR)
/// =======================================================
// class SensorChartStore {
//   static final List<double> suhuAir = [];
//   static final List<double> suhuUdara = [];
//   static final List<double> kelembaban = [];
//
//   static void add({
//     required double air,
//     required double udara,
//     required double lembab,
//   }) {
//     suhuAir.add(air);
//     suhuUdara.add(udara);
//     kelembaban.add(lembab);
//
//     // Membatasi hanya 10 data terbaru agar grafik tetap rapi
//     if (suhuAir.length > 10) suhuAir.removeAt(0);
//     if (suhuUdara.length > 10) suhuUdara.removeAt(0);
//     if (kelembaban.length > 10) kelembaban.removeAt(0);
//   }
// }
class SensorChartStore {
  static final List<double> suhuAir = [];
  static final List<double> suhuUdara = [];
  static final List<double> kelembaban = [];

  static DateTime? _lastInsertedTime;

  /// interval minimal antar data (misal 3 detik)
  static const Duration minInterval = Duration(seconds: 3);

  static void add({
    required double air,
    required double udara,
    required double lembab,
  }) {
    final now = DateTime.now();

    // ⛔ CEGAH SNAPSHOT DUPLIKAT SAAT HALAMAN DIBUKA ULANG
    if (_lastInsertedTime != null &&
        now.difference(_lastInsertedTime!) < minInterval) {
      return;
    }

    _lastInsertedTime = now;

    suhuAir.add(air);
    suhuUdara.add(udara);
    kelembaban.add(lembab);

    if (suhuAir.length > 10) suhuAir.removeAt(0);
    if (suhuUdara.length > 10) suhuUdara.removeAt(0);
    if (kelembaban.length > 10) kelembaban.removeAt(0);
  }

  static void clear() {
    suhuAir.clear();
    suhuUdara.clear();
    kelembaban.clear();
    _lastInsertedTime = null;
  }
}

/// =======================================================
/// HALAMAN GRAFIK (STATEFUL UNTUK REALTIME)
/// =======================================================
class GrafikPage extends StatefulWidget {
  const GrafikPage({super.key});

  @override
  State<GrafikPage> createState() => _GrafikPageState();
}

class _GrafikPageState extends State<GrafikPage> {
  // DISESUAIKAN: Berdasarkan gambar, path-nya adalah 'iot/sensor'
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('iot/sensor');
  StreamSubscription<DatabaseEvent>? _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _listenToSensors();
  }

  void _listenToSensors() {
    // Mendengarkan perubahan data secara realtime pada node 'iot/sensor'
    _sensorSubscription = _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          // Mengambil nilai berdasarkan key di Firebase (suhu_air, suhu_udara, kelembaban)
          double air = double.tryParse(data['suhu_air']?.toString() ?? '0') ?? 0.0;
          double ph = double.tryParse(data['ph']?.toString() ?? '0') ?? 0.0;
          double tds = double.tryParse(data['tds']?.toString() ?? '0') ?? 0.0;

          // Tambahkan ke store global
          SensorChartStore.add(air: air, udara: ph, lembab: tds);
        });
      }
    }, onError: (error) {
      debugPrint("Firebase Error: $error");
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: bgCream,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildChartSection(
            title: 'Suhu Air',
            data: SensorChartStore.suhuAir,
            color: Colors.teal,
            unit: '°C',
          ),
          const SizedBox(height: 24),
          _buildChartSection(
            title: 'pH',
            data: SensorChartStore.suhuUdara,
            color: Colors.deepOrange,
            unit: '',
          ),
          const SizedBox(height: 24),
          _buildChartSection(
            title: 'TDS',
            data: SensorChartStore.kelembaban,
            color: Colors.indigo,
            unit: ' PPM',
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required List<double> data,
    required Color color,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Judul & Nilai Terbaru
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (data.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Aktual: ${data.last.toStringAsFixed(1)}$unit',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // LIST 10 DATA TERAKHIR (Horizontal Chips)
          const Text(
            "Riwayat 10 Data Terakhir:",
            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 35,
            child: data.isEmpty
                ? const Text("Menghubungkan ke Firebase...", style: TextStyle(fontSize: 12, color: Colors.grey))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (context, index) {
                // Tampilkan data dari yang terbaru di paling kiri (opsional)
                // Jika ingin urutan input, gunakan data[index]
                final val = data[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${val.toStringAsFixed(1)}$unit",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // GRAFIK LINE CHART
          if (data.isNotEmpty)
            AspectRatio(
              aspectRatio: 2,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: color.withOpacity(0.8),
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)}$unit',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )).toList(),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}