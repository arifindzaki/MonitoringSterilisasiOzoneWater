import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

const Color bgCream = Color(0xFFF5EFE6);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  // ================= TAMBAHAN EMERGENCY =================
  final DatabaseReference emergencyRef =
  FirebaseDatabase.instance.ref('iot/status/emergency');

  @override
  void initState() {
    super.initState();
    _listenEmergency();
  }

  void _listenEmergency() {
    emergencyRef.onValue.listen((event) async {
      final value = event.snapshot.value?.toString();

      if (value == '2') {
        try {

          final query = await FirebaseFirestore.instance
              .collection('logs')
              .get();

          final docs = query.docs;

          docs.sort((a, b) {
            final dataA = a.data();
            final dataB = b.data();

            try {
              final dateA = DateFormat('dd-MM-yyyy HH:mm:ss')
                  .parse(dataA['timestamp']);
              final dateB = DateFormat('dd-MM-yyyy HH:mm:ss')
                  .parse(dataB['timestamp']);

              return dateB.compareTo(dateA); // terbaru di atas
            } catch (_) {
              return 0;
            }
          });

          if (docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('logs')
                .doc(docs.first.id)
                .update({
              'status_ozonisasi': 'emergency cut off',
            });
          }

          await emergencyRef.set(0);
        } catch (e) {
          debugPrint('Emergency error: $e');
        }
      }
    });
  }

  // void _listenEmergency() {
  //   emergencyRef.onValue.listen((event) async {
  //     final value = event.snapshot.value?.toString();
  //
  //     if (value == '2') {
  //       try {
  //         final query = await FirebaseFirestore.instance
  //             .collection('logs')
  //             .orderBy('timestamp', descending: true)
  //             .limit(1)
  //             .get();
  //
  //         if (query.docs.isNotEmpty) {
  //           await FirebaseFirestore.instance
  //               .collection('logs')
  //               .doc(query.docs.first.id)
  //               .update({
  //             'status_ozonisasi': 'emergency cut off',
  //           });
  //         }
  //
  //         await emergencyRef.set(0);
  //       } catch (e) {
  //         debugPrint('Emergency error: $e');
  //       }
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> historyStream = FirebaseFirestore.instance
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: bgCream,
      body: StreamBuilder<QuerySnapshot>(
        stream: historyStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data riwayat'));
          }

          /// ================= TAMBAHAN SORTING TANGGAL =================
          final docs = snapshot.data!.docs;
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final tsA = dataA['timestamp'] ?? '';
            final tsB = dataB['timestamp'] ?? '';

            try {
              final dateA = DateFormat('dd-MM-yyyy HH:mm:ss').parse(tsA);
              final dateB = DateFormat('dd-MM-yyyy HH:mm:ss').parse(tsB);

              return dateB.compareTo(dateA); // terbaru paling atas
            } catch (e) {
              return 0;
            }
          });
          // docs.sort((a, b) {
          //   final dataA = a.data() as Map<String, dynamic>;
          //   final dataB = b.data() as Map<String, dynamic>;
          //
          //   try {
          //     final dateA = DateFormat('dd-MM-yyyy HH:mm:ss')
          //         .parse(dataA['timestamp']);
          //     final dateB = DateFormat('dd-MM-yyyy HH:mm:ss')
          //         .parse(dataB['timestamp']);
          //
          //     return dateB.compareTo(dateA); // terbaru di atas
          //   } catch (_) {
          //     return 0;
          //   }
          // });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// ================= HEADER TABEL =================
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: Text(
                              'Tanggal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: Text(
                              'Durasi ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: Text(
                              'Aksi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                /// ================= ISI DATA =================
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  String tanggal = '-';
                  final rawTimestamp = data['timestamp']?.toString();

                  if (rawTimestamp != null) {
                    try {
                      tanggal = DateFormat('dd MMM yyyy').format(
                        DateFormat('dd-MM-yyyy HH:mm:ss')
                            .parse(rawTimestamp),
                      );
                    } catch (_) {}
                  }

                  return Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: Text(
                                tanggal,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: Text(
                                '${data['durasi'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showDetailDialog(context, data),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Detail',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= POPUP DETAIL (UTUH) =================
  void _showDetailDialog(
      BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Detail Ozonisasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _popupRow('pH Air', (data['ph'] ?? '-').toString()),
              _popupRow(
                'Suhu Air',
                data['suhu'] != null ? '${data['suhu']} °C' : '-',
              ),
              _popupRow('TDS', (data['tds'] ?? '-').toString()),

              const Divider(),

              _popupRow('Rule 1 Nama', (data['rule1_nama'] ?? '-').toString()),
              _popupRow('Rule 1 Alpha', (data['rule1_alpha'] ?? '-').toString()),
              _popupRow('Rule 1 Z', (data['rule1_z'] ?? '-').toString()),

              const Divider(),

              _popupRow('Rule 2 Nama', (data['rule2_nama'] ?? '-').toString()),
              _popupRow('Rule 2 Alpha', (data['rule2_alpha'] ?? '-').toString()),
              _popupRow('Rule 2 Z', (data['rule2_z'] ?? '-').toString()),

              const Divider(),

              _popupRow(
                'Jumlah Rule',
                (data['rule_count'] ?? '-').toString(),
              ),

              const Divider(),

              _popupRow(
                'Status Ozonisasi',
                (data['status_ozonisasi'] ?? 'normal').toString(),
              ),

              const Divider(),

              _popupRow(
                'Durasi',
                data['durasi'] != null ? '${data['durasi']}' : '-',
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);

                // 🔥 paksa reset focus SETELAH dialog benar-benar tertutup
                Future.delayed(const Duration(milliseconds: 100), () {
                  FocusManager.instance.primaryFocus?.unfocus();
                });
              },              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}