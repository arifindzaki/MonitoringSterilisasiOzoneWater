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

  // 🔥 TAMBAHAN
  final suhuF = FocusNode();
  final phF = FocusNode();
  final tdsF = FocusNode();

  Map<String, double> mu = {};
  List<Map<String, dynamic>> ruleAktif = [];

  double zAkhir = 0;
  String keputusan = "-";

  // 🔥 TAMBAHAN
  void killFocus() {
    suhuF.unfocus();
    phF.unfocus();
    tdsF.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void deactivate() {
    killFocus(); // 🔥 MATIKAN TOTAL
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

  // ================= FUZZY MEMBERSHIP =================
  double suhuR(double t){ if(t<=25) return 1; if(t>=27) return 0; return (27-t)/2; }
  double suhuS(double t){ if(t<=25||t>=29) return 0; if(t<=27) return (t-25)/2; return (29-t)/2; }
  double suhuT(double t){ if(t<=27) return 0; if(t>=29) return 1; return (t-27)/2; }

  double tdsR(double d){ if(d<=200) return 1; if(d>=400) return 0; return (400-d)/200; }
  double tdsS(double d){ if(d<=200||d>=700) return 0; if(d<=400) return (d-200)/200; return (700-d)/300; }
  double tdsT(double d){ if(d<=600) return 0; if(d>=1200) return 1; return (d-600)/600; }

  double phR(double p){ if(p<=6) return 1; if(p>=6.5) return 0; return (6.5-p)/0.5; }
  double phS(double p){ if(p<=6||p>=8) return 0; if(p<=7) return (p-6); return (8-p); }
  double phT(double p){ if(p<=7.5) return 0; if(p>=9) return 1; return (p-7.5)/1.5; }

  // ================= MAMDANI =================
  double aSebentar = 0;
  double aSedang = 0;
  double aLama = 0;

  double AND(double a, double b) => a < b ? a : b;
  double AND3(double a, double b, double c) => AND(a, AND(b, c));

  double muOutput(double z) {
    double sebentar = 0;
    double sedang = 0;
    double lama = 0;

    if (z >= 0 && z <= 10) sebentar = z / 10;
    else if (z > 10 && z <= 20) sebentar = (20 - z) / 10;

    if (z >= 15 && z <= 20) sedang = (z - 15) / 5;
    else if (z > 20 && z <= 30) sedang = (30 - z) / 10;

    if (z >= 20 && z <= 30) lama = (z - 20) / 10;

    sebentar = sebentar > aSebentar ? aSebentar : sebentar;
    sedang = sedang > aSedang ? aSedang : sedang;
    lama = lama > aLama ? aLama : lama;

    return [sebentar, sedang, lama].reduce((a, b) => a > b ? a : b);
  }

  // ================= HITUNG =================
  void hitungFuzzy() {
    killFocus(); // 🔥 ganti dari unfocus

    aSebentar = 0;
    aSedang = 0;
    aLama = 0;
    ruleAktif.clear();

    final t = double.tryParse(suhuC.text.replaceAll(',', '.')) ?? 0;
    final p = double.tryParse(phC.text.replaceAll(',', '.')) ?? 0;
    final d = double.tryParse(tdsC.text.replaceAll(',', '.')) ?? 0;

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

    final SR = mu["Suhu Dingin"]!;
    final SS = mu["Suhu Normal"]!;
    final ST = mu["Suhu Panas"]!;
    final DR = mu["TDS Rendah"]!;
    final DS = mu["TDS Sedang"]!;
    final DT = mu["TDS Tinggi"]!;
    final PH_R = mu["pH Asam"]!;
    final PH_S = mu["pH Netral"]!;
    final PH_T = mu["pH Basa"]!;

    void RULE(String r, double a, String output) {
      if (a > 0) {
        ruleAktif.add({"rule": r, "alpha": a, "output": output});

        if (output == "Sebentar") {
          aSebentar = aSebentar > a ? aSebentar : a;
        } else if (output == "Sedang") {
          aSedang = aSedang > a ? aSedang : a;
        } else if (output == "Lama") {
          aLama = aLama > a ? aLama : a;
        }
      }
    }

    // (SEMUA RULE KAMU TETAP — TIDAK DIUBAH)

    // ================= 27 RULE =================
    RULE("R1", AND3(SR, DR, PH_R), "Sedang");
    RULE("R2", AND3(SR, DR, PH_S), "Sebentar");
    RULE("R3", AND3(SR, DR, PH_T), "Sebentar");
    RULE("R4", AND3(SR, DS, PH_R), "Sedang");
    RULE("R5", AND3(SR, DS, PH_S), "Sedang");
    RULE("R6", AND3(SR, DS, PH_T), "Sebentar");
    RULE("R7", AND3(SR, DT, PH_R), "Lama");
    RULE("R8", AND3(SR, DT, PH_S), "Sedang");
    RULE("R9", AND3(SR, DT, PH_T), "Sedang");

    RULE("R10", AND3(SS, DR, PH_R), "Sedang");
    RULE("R11", AND3(SS, DR, PH_S), "Sebentar");
    RULE("R12", AND3(SS, DR, PH_T), "Sebentar");
    RULE("R13", AND3(SS, DS, PH_R), "Sedang");
    RULE("R14", AND3(SS, DS, PH_S), "Sedang");
    RULE("R15", AND3(SS, DS, PH_T), "Sedang");
    RULE("R16", AND3(SS, DT, PH_R), "Lama");
    RULE("R17", AND3(SS, DT, PH_S), "Sedang");
    RULE("R18", AND3(SS, DT, PH_T), "Sedang");

    RULE("R19", AND3(ST, DR, PH_R), "Lama");
    RULE("R20", AND3(ST, DR, PH_S), "Sedang");
    RULE("R21", AND3(ST, DR, PH_T), "Lama");
    RULE("R22", AND3(ST, DS, PH_R), "Lama");
    RULE("R23", AND3(ST, DS, PH_S), "Lama");
    RULE("R24", AND3(ST, DS, PH_T), "Sedang");
    RULE("R25", AND3(ST, DT, PH_R), "Lama");
    RULE("R26", AND3(ST, DT, PH_S), "Lama");
    RULE("R27", AND3(ST, DT, PH_T), "Lama");

    // ================= DEFUZZY =================
    double sumZ = 0;
    double sumMu = 0;

    for (double z = 0; z <= 30; z += 0.1) {
      double muZ = muOutput(z);
      sumZ += z * muZ;
      sumMu += muZ;
    }

    zAkhir = sumMu == 0 ? 0 : sumZ / sumMu;

    // ================= KEPUTUSAN =================
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
          Text(desc, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: 1,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      getTitlesWidget: (v, _) =>
                      xTicks.contains(v)
                          ? Text(v.toString(), style: const TextStyle(fontSize: 10))
                          : const SizedBox.shrink(),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      getTitlesWidget: (v, _) =>
                          Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: List.generate(lines.length, (i) =>
                    LineChartBarData(
                      spots: lines[i],
                      color: colors[i],
                      barWidth: 3,
                      isCurved: false,
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
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                input("Suhu (°C)", suhuC),
                input("pH", phC),
                input("TDS (ppm)", tdsC),

                ElevatedButton(
                  onPressed: hitungFuzzy,
                  style: ElevatedButton.styleFrom(backgroundColor: terracotta),
                  child: const Text("Hitung Fuzzy"),
                ),

                const SizedBox(height: 16),

                grafik(
                  "Grafik Keanggotaan Suhu",
                  "Suhu Dingin (Biru), Normal (Hijau), Panas (Merah)",
                  20, 35, [25,27,29],
                  [
                    line([20,25,27],[1,1,0]),
                    line([25,27,29],[0,1,0]),
                    line([27,29,35],[0,1,1]),
                  ],
                  [Colors.blue, Colors.green, Colors.red],
                ),

                grafik(
                  "Grafik Keanggotaan TDS",
                  "TDS Rendah (Biru), Sedang (Hijau), Tinggi (Merah)",
                  0, 1200, [200,400,600,700],
                  [
                    line([0,200,400],[1,1,0]),
                    line([200,400,700],[0,1,0]),
                    line([600,1200],[0,1]),
                  ],
                  [Colors.blue, Colors.green, Colors.red],
                ),

                grafik(
                  "Grafik Keanggotaan pH",
                  "pH Asam (Biru), Netral (Hijau), Basa (Merah)",
                  5, 9, [6,6.5,7,7.5,8,9],
                  [
                    line([5,6,6.5],[1,1,0]),
                    line([6,7,8],[0,1,0]),
                    line([7.5,9],[0,1]),
                  ],
                  [Colors.blue, Colors.green, Colors.red],
                ),

                hasil(
                  "Nilai Keanggotaan",
                  mu.entries
                      .map((e) => "${e.key} = ${e.value.toStringAsFixed(3)}")
                      .join("\n"),
                ),

                hasil(
                  "Rule Aktif",
                  ruleAktif.map(
                          (r) => "${r['rule']} | α=${r['alpha'].toStringAsFixed(3)} | ${r['output']}"
                  ).join("\n"),
                ),

                hasil("Defuzzifikasi", "Z = ${zAkhir.toStringAsFixed(2)}\nKeputusan: $keputusan"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget input(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget hasil(String title, String text) => card(title, Text(text));

  Widget card(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: terracottaDark)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}