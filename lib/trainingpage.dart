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
      // **HAPUS logika auto-navigasi dari sini**
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
    }
  }

  void _navigateToCapture() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrainingCapturePage()),
    );
    
    // Setelah kembali, refresh status izin (tapi tidak auto-navigasi)
    if (mounted) {
      _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return _buildLoadingScreen();
    }

    // **Selalu tampilkan UI permission request**
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
                  const Icon(Icons.camera_alt_outlined, size: 80, color: Color(0xFF0084FF)),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Izin Kamera & Mikrofon Diperlukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // **Tampilkan status izin dan tombol yang sesuai**
                  if (_cameraPermissionGranted) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Izin sudah diberikan',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _navigateToCapture,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0084FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text('Mulai Training', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Aplikasi ini membutuhkan akses kamera untuk menganalisis gerakan Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _requestPermissions,
                        child: const Text('Izinkan Akses'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}