import 'package:flutter/material.dart';
import '/training/trainingcapture.dart';
import 'package:permission_handler/permission_handler.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  bool _cameraPermissionGranted = false;
  bool _checkingPermissions = true;
  bool _isNavigating = false; // Prevent multiple navigation

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final audioStatus = await Permission.microphone.status;
    
    if (mounted) {
      setState(() {
        _checkingPermissions = false;
        _cameraPermissionGranted = cameraStatus.isGranted && audioStatus.isGranted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (mounted) {
      final granted = statuses[Permission.camera]!.isGranted && 
                      statuses[Permission.microphone]!.isGranted;
      setState(() {
        _cameraPermissionGranted = granted;
      });
      
      if (granted) {
        _navigateToCapture();
      }
    }
  }

  void _navigateToCapture() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    // Use pushReplacement to avoid stacking
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TrainingCapturePage()),
    );
    
    // Reset state when returning
    if (mounted) {
      _isNavigating = false;
      _checkPermissions(); // Re-check permissions when coming back
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return _buildLoadingScreen();
    }

    // Jika sudah punya izin & tidak sedang navigate, langsung ke capture
    if (_cameraPermissionGranted && !_isNavigating) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _navigateToCapture();
      });
      return _buildLoadingScreen();
    }

    return _buildPermissionRequest();
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menyiapkan kamera...'),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Color(0xFF0084FF),
                  ),
                  const SizedBox(height: 32),
                  
                  // Teks utama dengan styling rapi
                  const Text(
                    'Izin Kamera & Mikrofon Diperlukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                      letterSpacing: -0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Teks deskripsi dengan styling rapi
                  Text(
                    'Aplikasi ini membutuhkan akses kamera untuk menganalisis gerakan Anda.',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0084FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      child: const Text('Izinkan Akses'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}