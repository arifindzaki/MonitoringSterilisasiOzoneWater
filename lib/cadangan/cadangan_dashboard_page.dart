import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ================= WARNA TEMA =================
const Color bgCream = Color(0xFFF5EFE6);
const Color terracotta = Color(0xFFB85C38);
const Color terracottaDark = Color(0xFF9C4A2E);
const Color softBlue = Color(0xFF5FA8D3);
const Color softGreen = Color(0xFF6AA84F);
const Color softRed = Color(0xFFC0392B);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// ================= FIREBASE =================
  ///

  final DatabaseReference _emergencyRef =
  FirebaseDatabase.instance.ref('iot/status/emergency');


  final DatabaseReference _sensorRef =
  FirebaseDatabase.instance.ref('iot/sensor');

  final DatabaseReference _relayRef =
  FirebaseDatabase.instance.ref('iot/status/relay');

  final DatabaseReference _fuzzyRef =
  FirebaseDatabase.instance.ref('iot/fuzzy/perhitungan');

  final DatabaseReference _triggerRef =
  FirebaseDatabase.instance.ref('iot/control/trigger');

  /// 🔑 TAMBAHAN TIMER (REALTIME DB)
  final DatabaseReference _durasiRef =
  FirebaseDatabase.instance.ref('iot/fuzzy/detail/durasi');

  /// 🔴 TAMBAHAN STATUS PH (ADD ONLY)
  final DatabaseReference _statusPhRef =
  FirebaseDatabase.instance.ref('iot/status/statusph');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================= SENSOR =================
  double suhuUdara = 0;
  double kelembaban = 0;
  double suhuAir = 0;

  /// ================= STATUS =================
  String relayStatus = 'OFF';
  int perhitungan = 0;

  /// 🔴 STATUS PH
  String statusPh = 'normal';

  /// ================= STATE =================
  bool trigger = false;
  bool isLoading = false;

  /// ================= TIMER =================
  Timer? _timer;
  int sisaDetik = 0;
  int durasiFirestore = 0;

  /// ================= POPUP =================
  bool _popupShown = false;

  @override
  void initState() {

    _relayRef.onValue.listen((event) async {
      if (event.snapshot.value == 'ON') {
        await Future.delayed(const Duration(milliseconds: 300));
        _tryStartTimer();
      }
    });

    super.initState();

    /// ===== SENSOR =====
    _sensorRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        suhuUdara = double.tryParse(data['ph'].toString()) ?? 0;
        kelembaban = double.tryParse(data['tds'].toString()) ?? 0;
        suhuAir = double.tryParse(data['suhu_air'].toString()) ?? 0;
      });
    });

    /// ===== RELAY =====
    _relayRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      setState(() {
        relayStatus = event.snapshot.value.toString();
        _updateLoading();
      });

      _tryStartTimer(); // ASLI

      // 🔒 TAMBAHAN (ADD ONLY)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryStartTimer();
      });
    });

    /// ===== FUZZY =====
    _fuzzyRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      setState(() {
        perhitungan =
            int.tryParse(event.snapshot.value.toString()) ?? 0;
      });
    });

    /// ===== TRIGGER =====
    _triggerRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      setState(() {
        trigger = event.snapshot.value == true;
        _updateLoading();
      });
    });

    /// ===== FIRESTORE DURASI TERBARU (TETAP ADA) =====
    _firestore
        .collection('ozone')
        .orderBy('tanggal', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      final data = snapshot.docs.first.data();
      durasiFirestore =
          int.tryParse(data['durasi'].toString()) ?? 0;
    });

    /// ===== DURASI REALTIME =====
    _durasiRef.onValue.listen((event) {
      _tryStartTimer(); // ASLI

      // 🔒 TAMBAHAN (ADD ONLY)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryStartTimer();
      });
    });

    /// 🔴 LISTENER STATUS PH (ADD ONLY)
    _statusPhRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      setState(() {
        statusPh = event.snapshot.value.toString();
      });
    });

    // 🔒 FALLBACK SEKALI SAAT INIT (ADD ONLY)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryStartTimer();
    });
  }

  /// ================= COBA MULAI TIMER =================
  Future<void> _tryStartTimer() async {
    if (_timer != null) return;
    if (relayStatus != 'ON') return;

    final snapshot = await _durasiRef.get();
    if (!snapshot.exists) return;

    final int durasi =
        double.tryParse(snapshot.value.toString())?.floor() ?? 0;


    if (durasi == 0) return;

    _popupShown = false;

    setState(() {
      sisaDetik = durasi;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (sisaDetik <= 0) {
        timer.cancel();
        _timer = null;

        await _durasiRef.set(0);

        if (!_popupShown && mounted) {
          _popupShown = true;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('✅ Sterilisasi Selesai'),
              content: const Text(
                'Nikmati buah yang lebih segar 🍎🍊',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          sisaDetik--;
        });
      }
    });
  }

  /// ================= UPDATE LOADING =================
  void _updateLoading() {
    isLoading = trigger == true && relayStatus == 'OFF';
  }

  /// ================= START OZONISASI =================
  Future<void> startOzonisasi() async {
    if (statusPh == 'phtinggi') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            '⚠️ PERINGATAN PH TINGGI',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'PH AIR TERLALU TINGGI.\n\n'
                'PROSES STERILISASI TIDAK DAPAT DIJALANKAN.\n\n'
                'SILAKAN GANTI AIR TERLEBIH DAHULU.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('MENGERTI'),
            ),
          ],
        ),
      );
      return;
    }

    if (trigger || relayStatus == 'ON') return;
    await _triggerRef.set(true);
  }

  /// ================= FORMAT TIMER =================
  String formatTimer(int detik) {
    final menit = (detik ~/ 60).toString().padLeft(2, '0');
    final s = (detik % 60).toString().padLeft(2, '0');
    return '$menit:$s';
  }

  /// ================= EMERGENCY =================
  // Future<void> emergencyCutOff() async {
  //   _timer?.cancel();
  //   _timer = null;
  //   await _relayRef.set('OFF');
  //   await _triggerRef.set(false);
  //   await _durasiRef.set(0);
  // }
  Future<void> emergencyCutOff() async {
    _timer?.cancel();
    _timer = null;

    setState(() {
      sisaDetik = 0; // ⬅️ TIMER LANGSUNG NOL DI UI
    });

    await _relayRef.set('OFF');
    await _triggerRef.set(false);
    await _durasiRef.set(0);
    await _emergencyRef.set(1); // ⬅️ STATUS EMERGENCY = 1
  }

  @override
  Widget build(BuildContext context) {
    final bool isOzoneOn = relayStatus == 'ON';

    return Scaffold(
      backgroundColor: bgCream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              'assets/images/3diotai.png',
              height: 150,
              fit: BoxFit.contain,
            ),

            if (statusPh == 'phtinggi')
              const RunningWarningText(
                text:
                '⚠️ PH AIR TERLALU TINGGI! PROSES STERILISASI TIDAK DAPAT DIJALANKAN. SILAKAN GANTI AIR TERLEBIH DAHULU!',
              ),

            SizedBox(
              height: 32,
              child: isLoading
                  ? const Text(
                '⏳ Menunggu alat memulai ozonisasi...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: terracottaDark,
                ),
              )
                  : (sisaDetik != 0
                  ? Text(
                'Sisa waktu: ${formatTimer(sisaDetik)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: terracottaDark,
                ),
              )
                  : const SizedBox.shrink()),
            ),

            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                SensorCard(
                  title: 'PH',
                  value: 'pH $suhuUdara',
                  icon: Icons.thermostat,
                  color: terracotta,
                ),
                SensorCard(
                  title: 'TDS',
                  value: '$kelembaban PPM',
                  icon: Icons.water_drop,
                  color: softBlue,
                ),
                SensorCard(
                  title: 'Suhu Air',
                  value: '$suhuAir °C',
                  icon: Icons.waves,
                  color: softGreen,
                ),
              ],
            ),

            const SizedBox(height: 20),

            StatusOzoneCard(isOn: isOzoneOn),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                (!trigger && relayStatus == 'OFF')
                    ? startOzonisasi
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Start Ozonisasi',
                  style: TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: terracottaDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            EmergencyCutOffCard(
              isEnabled: isOzoneOn || isLoading,
              onPressed: emergencyCutOff,
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= STATUS OZONE =================
class StatusOzoneCard extends StatelessWidget {
  final bool isOn;
  const StatusOzoneCard({super.key, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud,
            size: 36,
            color: isOn ? softGreen : softRed,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ozone Generator',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isOn ? softGreen : softRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ================= EMERGENCY =================
class EmergencyCutOffCard extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const EmergencyCutOffCard({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Cut Off',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: softRed,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isEnabled ? onPressed : null,
              icon: const Icon(Icons.warning),
              label: const Text('Matikan Ozone Generator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: softRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= SENSOR CARD =================
class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= RUNNING WARNING TEXT =================
class RunningWarningText extends StatefulWidget {
  final String text;
  const RunningWarningText({super.key, required this.text});

  @override
  State<RunningWarningText> createState() => _RunningWarningTextState();
}

class _RunningWarningTextState extends State<RunningWarningText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _animation = Tween<double>(
      begin: 1.0,
      end: -2.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        height: 40,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return FractionalTranslation(
              translation: Offset(_animation.value, 0),
              child: child,
            );
          },
          child: Text(
            widget.text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: softRed,
            ),
          ),
        ),
      ),
    );
  }
}
