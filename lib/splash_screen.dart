import 'dart:async';
import 'package:flutter/material.dart';
import 'main_page.dart';
const Color bgCream = Color(0xFFF5EFE6);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    /// Delay splash 3 detik
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// LOGO
            Image.asset(
              'assets/images/3diotai.png',
              height: 160,
            ),

            const SizedBox(height: 20),

            /// JUDUL
            const Text(
              'Ozone Monitoring System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            /// SUBTITLE
            const Text(
              'IoT • Monitoring • Ozonisasi',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            /// LOADING
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
