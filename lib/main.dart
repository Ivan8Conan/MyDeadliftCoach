import 'dart:async';
import 'package:flutter/material.dart';
import 'homepage.dart';

void main() {
  runApp(const MyApp());
}

// Widget Utama untuk Konfigurasi Aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Deadlift Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007BFF)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// Widget SplashScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() {
    // Tampilkan Logo selama 2 detik
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }

      // Tampilkan Loading selama 3 detik, lalu pindah ke HomePage
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            _createRoute(),
          );
        }
      });
    });
  }

  // Fungsi Buat animasi transisi
  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color azureBlue = Color(0xFF0084FF);

    return Scaffold(
      backgroundColor: azureBlue,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _showLoading
              ? Container(
                  key: const ValueKey('loading'), 
                  child: _buildLoadingView()
                )
              : Container(
                  key: const ValueKey('logo'), 
                  child: _buildSplashView()
                ),
        ),
      ),
    );
  }

  // Tampilan 1: Logo Gambar
  Widget _buildSplashView() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Image.asset('assets/images/LogoMyDeadliftCoach.png'),
    );
  }

  // Tampilan 2: Teks & Loading Spinner
  Widget _buildLoadingView() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Text(
          "MyDeadliftCoach™",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 4,
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }
}