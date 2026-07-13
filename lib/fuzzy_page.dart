import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

const Color bgCream = Color(0xFFF5EFE6);
const Color terracotta = Color(0xFFB85C38);
const Color terracottaDark = Color(0xFF9C4A2E);

class FuzzyPage extends StatefulWidget {
  const FuzzyPage({super.key});

  @override
  State<FuzzyPage> createState() => _FuzzyPageState();
}

class _FuzzyPageState extends State<FuzzyPage> {
  final suhuC = TextEditingController();
  final phC = TextEditingController();
  final tdsC = TextEditingController();

  final suhuF = FocusNode();
  final phF = FocusNode();
  final tdsF = FocusNode();

  Map<String, double> mu = {};
  List<Map<String, dynamic>> ruleAktif = [];
  List<Map<String, dynamic>> defuzzyDetails = [];

  double zAkhir = 0;
  String keputusan = "-";
  double sumZTotal = 0;
  double sumMuTotal = 0;

  void killFocus() {
    suhuF.unfocus();
    phF.unfocus();
    tdsF.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void deactivate() {
    killFocus();
    super.deactivate();
  }

  @override
  void dispose() {
    suhuF.dispose();
    phF.dispose();
    tdsF.dispose();
    suhuC.dispose();
    phC.dispose();
    tdsC.dispose();
    super.dispose();
  }

  // ================= MEMBERSHIP FUNCTIONS (INPUT) =================
  double suhuR(double t) { if (t <= 25) return 1; if (t >= 27) return 0; return (27 - t) / 2; }
  double suhuS(double t) { if (t <= 25 || t >= 29) return 0; if (t <= 27) return (t - 25) / 2; return (29 - t) / 2; }
  double suhuT(double t) { if (t <= 27) return 0; if (t >= 29) return 1; return (t - 27) / 2; }

  double tdsR(double d) { if (d <= 200) return 1; if (d >= 400) return 0; return (400 - d) / 200; }
  double tdsS(double d) { if (d <= 200 || d >= 700) return 0; if (d <= 400) return (d - 200) / 200; return (700 - d) / 300; }
  double tdsT(double d) { if (d <= 600) return 0; if (d >= 1200) return 1; return (d - 600) / 600; }

  double phR(double p) { if (p <= 6) return 1; if (p >= 6.5) return 0; return (6.5 - p) / 0.5; }
  double phS(double p) { if (p <= 6 || p >= 8) return 0; if (p <= 7) return (p - 6); return (8 - p); }
  double phT(double p) { if (p <= 7.5) return 0; if (p >= 9) return 1; return (p - 7.5) / 1.5; }

  // ================= MEMBERSHIP FUNCTIONS (OUTPUT) =================
  // Disesuaikan sepenuhnya dengan logika firmware IoT C++ Anda
  double muSebentar(double z) {
    if (z <= 10) return 1.0;
    if (z >= 20) return 0.0;
    return (20.0 - z) / 10.0;
  }

  double muSedang(double z) {
    if (z <= 15 || z >= 25) return 0.0;
    if (z <= 20) return (z - 15.0) / 5.0;
    return (25.0 - z) / 5.0;
  }

  double muLama(double z) {
    if (z <= 20) return 0.0;
    if (z >= 30) return 1.0;
    return (z - 20.0) / 10.0;
  }

  // ================= INFERENSI & DEFUZZIFIKASI =================
  double aSebentar = 0;
  double aSedang = 0;
  double aLama = 0;

  double min3(double a, double b, double c) {
    double m = a < b ? a : b;
    return m < c ? m : c;
  }

  void hitungFuzzy() {
    killFocus();

    aSebentar = 0;
    aSedang = 0;
    aLama = 0;
    ruleAktif.clear();
    defuzzyDetails.clear();

    final t = double.tryParse(suhuC.text.replaceAll(',', '.')) ?? 0.0;
    final p = double.tryParse(phC.text.replaceAll(',', '.')) ?? 0.0;
    final d = double.tryParse(tdsC.text.replaceAll(',', '.')) ?? 0.0;

    mu = {
      "Suhu Dingin": suhuR(t),
      "Suhu Normal": suhuS(t),
      "Suhu Panas": suhuT(t),
      "TDS Rendah": tdsR(d),
      "TDS Sedang": tdsS(d),
      "TDS Tinggi": tdsT(d),
      "pH Asam": phR(p),
      "pH Netral": phS(p),
      "pH Basa": phT(p),
    };

    final sR = mu["Suhu Dingin"]!;
    final sS = mu["Suhu Normal"]!;
    final sT = mu["Suhu Panas"]!;
    final tR = mu["TDS Rendah"]!;
    final tS = mu["TDS Sedang"]!;
    final tT = mu["TDS Tinggi"]!;
    final pR = mu["pH Asam"]!;
    final pS = mu["pH Netral"]!;
    final pT = mu["pH Basa"]!;

    // Pendefinisian 27 Rule persis dengan array RuleDef r[27] pada IoT C++
    // target: 0 = Sebentar, 1 = Sedang, 2 = Lama
    final List<Map<String, dynamic>> rulesConfig = [
      {"name": "R1", "s": sR, "t": tR, "p": pR, "sN": "suhuR", "tN": "tdsR", "pN": "phR", "target": 1},
      {"name": "R2", "s": sR, "t": tR, "p": pS, "sN": "suhuR", "tN": "tdsR", "pN": "phS", "target": 0},
      {"name": "R3", "s": sR, "t": tR, "p": pT, "sN": "suhuR", "tN": "tdsR", "pN": "phT", "target": 0},

      {"name": "R4", "s": sR, "t": tS, "p": pR, "sN": "suhuR", "tN": "tdsS", "pN": "phR", "target": 1},
      {"name": "R5", "s": sR, "t": tS, "p": pS, "sN": "suhuR", "tN": "tdsS", "pN": "phS", "target": 1},
      {"name": "R6", "s": sR, "t": tS, "p": pT, "sN": "suhuR", "tN": "tdsS", "pN": "phT", "target": 0},

      {"name": "R7", "s": sR, "t": tT, "p": pR, "sN": "suhuR", "tN": "tdsT", "pN": "phR", "target": 2},
      {"name": "R8", "s": sR, "t": tT, "p": pS, "sN": "suhuR", "tN": "tdsT", "pN": "phS", "target": 1},
      {"name": "R9", "s": sR, "t": tT, "p": pT, "sN": "suhuR", "tN": "tdsT", "pN": "phT", "target": 1},

      {"name": "R10", "s": sS, "t": tR, "p": pR, "sN": "suhuS", "tN": "tdsR", "pN": "phR", "target": 1},
      {"name": "R11", "s": sS, "t": tR, "p": pS, "sN": "suhuS", "tN": "tdsR", "pN": "phS", "target": 0},
      {"name": "R12", "s": sS, "t": tR, "p": pT, "sN": "suhuS", "tN": "tdsR", "pN": "phT", "target": 0},

      {"name": "R13", "s": sS, "t": tS, "p": pR, "sN": "suhuS", "tN": "tdsS", "pN": "phR", "target": 1},
      {"name": "R14", "s": sS, "t": tS, "p": pS, "sN": "suhuS", "tN": "tdsS", "pN": "phS", "target": 1},
      {"name": "R15", "s": sS, "t": tS, "p": pT, "sN": "suhuS", "tN": "tdsS", "pN": "phT", "target": 1},

      {"name": "R16", "s": sS, "t": tT, "p": pR, "sN": "suhuS", "tN": "tdsT", "pN": "phR", "target": 2},
      {"name": "R17", "s": sS, "t": tT, "p": pS, "sN": "suhuS", "tN": "tdsT", "pN": "phS", "target": 1},
      {"name": "R18", "s": sS, "t": tT, "p": pT, "sN": "suhuS", "tN": "tdsT", "pN": "phT", "target": 1},

      {"name": "R19", "s": sT, "t": tR, "p": pR, "sN": "suhuT", "tN": "tdsR", "pN": "phR", "target": 2},
      {"name": "R20", "s": sT, "t": tR, "p": pS, "sN": "suhuT", "tN": "tdsR", "pN": "phS", "target": 1},
      {"name": "R21", "s": sT, "t": tR, "p": pT, "sN": "suhuT", "tN": "tdsR", "pN": "phT", "target": 2},

      {"name": "R22", "s": sT, "t": tS, "p": pR, "sN": "suhuT", "tN": "tdsS", "pN": "phR", "target": 2},
      {"name": "R23", "s": sT, "t": tS, "p": pS, "sN": "suhuT", "tN": "tdsS", "pN": "phS", "target": 2},
      {"name": "R24", "s": sT, "t": tS, "p": pT, "sN": "suhuT", "tN": "tdsS", "pN": "phT", "target": 1},

      {"name": "R25", "s": sT, "t": tT, "p": pR, "sN": "suhuT", "tN": "tdsT", "pN": "phR", "target": 2},
      {"name": "R26", "s": sT, "t": tT, "p": pS, "sN": "suhuT", "tN": "tdsT", "pN": "phS", "target": 2},
      {"name": "R27", "s": sT, "t": tT, "p": pT, "sN": "suhuT", "tN": "tdsT", "pN": "phT", "target": 2},
    ];

    for (var r in rulesConfig) {
      double alpha = min3(r["s"], r["t"], r["p"]);

      if (alpha > 0) {
        String outputLabel = r["target"] == 0
            ? "Sebentar"
            : r["target"] == 1
            ? "Sedang"
            : "Lama";

        ruleAktif.add({
          "rule": r["name"],
          "alpha": alpha,
          "output": outputLabel,
          "detail": "μ_${r['sN']}=${r['s'].toStringAsFixed(3)}, μ_${r['tN']}=${r['t'].toStringAsFixed(3)}, μ_${r['pN']}=${r['p'].toStringAsFixed(3)} → α=min(...) = ${alpha.toStringAsFixed(3)}"
        });

        if (r["target"] == 0) {
          aSebentar = aSebentar > alpha ? aSebentar : alpha;
        } else if (r["target"] == 1) {
          aSedang = aSedang > alpha ? aSedang : alpha;
        } else {
          aLama = aLama > alpha ? aLama : alpha;
        }
      }
    }

    // ================= DEFUZZIFIKASI DISKRIT (z++ Step = 1) =================
    // Mencerminkan loop "for(int z = 0; z <= 30; z++)" pada source code C++ IoT Anda secara presisi
    double sumZ = 0;
    double sumMu = 0;

    for (int z = 0; z <= 30; z++) {
      double limitSebentar = aSebentar < muSebentar(z.toDouble()) ? aSebentar : muSebentar(z.toDouble());
      double limitSedang = aSedang < muSedang(z.toDouble()) ? aSedang : muSedang(z.toDouble());
      double limitLama = aLama < muLama(z.toDouble()) ? aLama : muLama(z.toDouble());

      // Operator OR (MAX)
      double muResult = limitSebentar;
      if (limitSedang > muResult) muResult = limitSedang;
      if (limitLama > muResult) muResult = limitLama;

      if (muResult > 0) {
        double zMu = z * muResult;
        sumZ += zMu;
        sumMu += muResult;

        defuzzyDetails.add({
          "z": z,
          "mu": muResult,
          "zMu": zMu,
        });
      }
    }

    sumZTotal = sumZ;
    sumMuTotal = sumMu;
    zAkhir = sumMu == 0 ? 0 : sumZ / sumMu;

    // Klasifikasi Keputusan
    if (zAkhir < 15) {
      keputusan = "Sebentar";
    } else if (zAkhir < 25) {
      keputusan = "Sedang";
    } else {
      keputusan = "Lama";
    }

    setState(() {});
  }

  List<FlSpot> line(List<double> x, List<double> y) =>
      List.generate(x.length, (i) => FlSpot(x[i], y[i]));

  Widget grafik(
      String title,
      String desc,
      double minX,
      double maxX,
      List<double> xTicks,
      List<List<FlSpot>> lines,
      List<Color> colors,
      ) {
    return card(
      title,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: 1.1,
                gridData: const FlGridData(show: true, drawVerticalLine: true),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => xTicks.contains(v)
                          ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          v.toStringAsFixed(v % 1 == 0 ? 0 : 1),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 0.5,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: List.generate(
                  lines.length,
                      (i) => LineChartBarData(
                    spots: lines[i],
                    color: colors[i],
                    barWidth: 3,
                    isCurved: false,
                    dotData: const FlDotData(show: true),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        return true;
      },
      child: Scaffold(
        backgroundColor: bgCream,
        appBar: AppBar(
          title: const Text("Fuzzy Ozonisasi Air", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: terracottaDark,
          elevation: 0,
        ),
        body: GestureDetector(
          onTap: killFocus,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // INPUT CARD
                card(
                  "Input Parameter Sensor",
                  Column(
                    children: [
                      input("Suhu Air (°C)", suhuC, suhuF, "Contoh: 26.5"),
                      input("pH Air", phC, phF, "Contoh: 7.2"),
                      input("TDS (ppm)", tdsC, tdsF, "Contoh: 350"),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: hitungFuzzy,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: terracotta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                          ),
                          child: const Text("PROSES HITUNG FUZZY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),

                // GRAFIK MEMBERSHIP INPUT
                grafik(
                  "Kurva Keanggotaan: Suhu Air",
                  "Dingin (Biru), Normal (Hijau), Panas (Merah)",
                  20, 35, [25, 27, 29],
                  [
                    line([20, 25, 27], [1, 1, 0]),
                    line([20, 25, 27, 29, 35], [0, 0, 1, 0, 0]),
                    line([20, 27, 29, 35], [0, 0, 1, 1]),
                  ],
                  [Colors.blue, Colors.green, Colors.red],
                ),

                grafik(
                  "Kurva Keanggotaan: TDS",
                  "Rendah (Biru), Sedang (Hijau), Tinggi (Merah)",
                  0, 1200, [200, 400, 600, 700, 1200],
                  [
                    line([0, 200, 400, 1200], [1, 1, 0, 0]),
                    line([0, 200, 400, 700, 1200], [0, 0, 1, 0, 0]),
                    line([0, 600, 1200], [0, 0, 1]),
                  ],
                  [Colors.blue, Colors.green, Colors.red],
                ),

                grafik(
                  "Kurva Keanggotaan: pH",
                  "Asam (Biru), Netral (Hijau), Basa (Merah)",
                  5, 10, [6, 6.5, 7, 7.5, 8, 9],
                  [
                    line([5, 6, 6.5, 10], [1, 1, 0, 0]),
                    line([5, 6, 7, 8, 10], [0, 0, 1, 0, 0]),
                    line([5, 7.5, 9, 10], [0, 0, 1, 1]),
                  ],
                  [Colors.blue, Colors.green, Colors.red],
                ),

                // GRAFIK MEMBERSHIP OUTPUT
                grafik(
                  "Kurva Keanggotaan: Durasi Ozonisasi (Output)",
                  "Sebentar (Biru), Sedang (Hijau), Lama (Merah)",
                  0, 30, [10, 15, 20, 25, 30],
                  [
                    line([0, 10, 20, 30], [1, 1, 0, 0]),
                    line([0, 15, 20, 25, 30], [0, 0, 1, 0, 0]),
                    line([0, 20, 30], [0, 0, 1]),
                  ],
                  [Colors.blue, Colors.green, Colors.red],
                ),

                // NILAI KEANGGOTAAN
                if (mu.isNotEmpty)
                  hasil(
                    "Nilai Fuzzifikasi (μ)",
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                      },
                      children: mu.entries.map((e) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                e.value.toStringAsFixed(3),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: terracottaDark),
                                textAlign: TextAlign.right,
                              ),
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                // ATURAN AKTIF
                if (ruleAktif.isNotEmpty)
                  hasil(
                    "Aturan / Rule yang Aktif",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ruleAktif.map((r) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bgCream.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: terracotta.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${r['rule']} [${r['output']}]", style: const TextStyle(fontWeight: FontWeight.bold, color: terracottaDark)),
                                  Text("α = ${r['alpha'].toStringAsFixed(3)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(r['detail'], style: const TextStyle(fontSize: 11, color: Colors.black87, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // DETAIL PERHITUNGAN DISKRIT DEFUZZY
                if (defuzzyDetails.isNotEmpty)
                  hasil(
                    "Defuzzifikasi Diskrit (Laporan)",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Detail nilai titik sampel z yang bernilai μ(z) > 0:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          child: SingleChildScrollView(
                            child: Table(
                              border: TableBorder.all(color: Colors.grey[300]!, width: 0.5),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: bgCream),
                                  children: [
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4), child: Text("z", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4), child: Text("mu(z)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4), child: Text("z * mu(z)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))))),
                                  ],
                                ),
                                ...defuzzyDetails.map((det) {
                                  return TableRow(
                                    children: [
                                      TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(4), child: Text("${det['z']}", style: const TextStyle(fontSize: 11))))),
                                      TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(4), child: Text(det['mu'].toStringAsFixed(3), style: const TextStyle(fontSize: 11))))),
                                      TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(4), child: Text(det['zMu'].toStringAsFixed(3), style: const TextStyle(fontSize: 11))))),
                                    ],
                                  );
                                }).toList()
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text("Σ (z * μ(z)) = ${sumZTotal.toStringAsFixed(3)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text("Σ (μ(z)) = ${sumMuTotal.toStringAsFixed(3)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                // HASIL DEFUZZY KEPUTUSAN
                hasil(
                  "Hasil Akhir",
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Durasi Terhitung (Z*)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            "${zAkhir.toStringAsFixed(3)} menit",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: terracottaDark),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Keputusan Kategori", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: keputusan == "Sebentar"
                                  ? Colors.blue[100]
                                  : keputusan == "Sedang"
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              keputusan,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: keputusan == "Sebentar"
                                    ? Colors.blue[800]
                                    : keputusan == "Sedang"
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget input(String label, TextEditingController c, FocusNode f, String placeholder) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      focusNode: f,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        labelStyle: const TextStyle(color: terracottaDark, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: bgCream.withOpacity(0.3),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: terracotta, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: terracotta.withOpacity(0.4)),
        ),
      ),
    ),
  );

  Widget hasil(String title, Widget child) => card(title, child);

  Widget card(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: terracottaDark, fontSize: 14),
        ),
        const Divider(height: 16, thickness: 1),
        child,
      ],
    ),
  );
}