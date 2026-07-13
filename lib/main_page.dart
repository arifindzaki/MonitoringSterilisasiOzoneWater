import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'grafik_page.dart';
import 'fuzzy_page.dart';
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1; // Home default

  final List<Widget> _pages = const [
    HistoryPage(),
    DashboardPage(),
    GrafikPage(),
    FuzzyPage(), // 🔥 TAMBAH FUZZY PAGE
  ];

  final List<String> _titles = const [
    'Riwayat Ozonisasi',
    'Dashboard Monitoring',
    'Grafik Monitoring',
    'Fuzzy', // 🔥 TAMBAH JUDUL
  ];

  final List<IconData> _icons = const [
    Icons.history,
    Icons.home,
    Icons.show_chart,
    Icons.calculate, // 🔥 ICON CALCULATOR
  ];

  void _onItemTapped(int index) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // 🔥 MATIKAN SEMUA TEXTFIELD GLOBAL
    setState(() {
      _selectedIndex = index;
    });
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// ================= HEADER DINAMIS =================
      appBar: AppBar(
        backgroundColor: const Color(0xFFB85C38),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[_selectedIndex],
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      /// ================= PAGE BODY =================
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      /// ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color(0xFFB85C38),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Grafik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate), // 🔥 FUZZY
            label: 'Fuzzy',
          ),
        ],
      ),
    );
  }
}