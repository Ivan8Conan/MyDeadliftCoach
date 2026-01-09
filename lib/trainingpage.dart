import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '/training/trainingcapture.dart'; // Pastikan path ini sesuai dengan struktur folder Anda

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  bool _cameraPermissionGranted = false;
  bool _checkingPermissions = true;

  // Palet Warna Khas iOS
  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosGreen = const Color(0xFF34C759);
  final Color _iosOrange = const Color(0xFFFF9500);

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
    setState(() => _checkingPermissions = true); // Tampilkan loading sebentar
    
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (mounted) {
      final granted = statuses[Permission.camera]!.isGranted && 
                      statuses[Permission.microphone]!.isGranted;
      setState(() {
        _checkingPermissions = false;
        _cameraPermissionGranted = granted;
      });
    }
  }

  void _navigateToCapture() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrainingCapturePage()),
    );
    
    // Cek ulang izin saat kembali (siapa tahu user mematikan izin di settings)
    if (mounted) {
      _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: _iosBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1), // Spacer atas agar konten agak ke tengah
              
              // 1. Hero Icon (Ikon Besar)
              _buildHeroIcon(),
              
              const SizedBox(height: 32),
              
              // 2. Judul & Deskripsi
              const Text(
                'Mulai Latihan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aplikasi akan menganalisis postur tubuh Anda secara real-time menggunakan kamera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // 3. Status Card
              _buildStatusCard(),

              const Spacer(flex: 3), // Dorong tombol ke bawah

              // 4. Tombol Aksi
              _buildActionButton(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _iosBgColor,
      body: Center(
        child: CircularProgressIndicator(
          color: _iosBlue,
        ),
      ),
    );
  }

  // Ikon Kamera Besar dengan Background Lingkaran
  Widget _buildHeroIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _iosBlue.withOpacity(0.1), // Biru transparan lembut
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.camera_alt_rounded,
        size: 56,
        color: _iosBlue,
      ),
    );
  }

  // Kartu Status Izin (Style iOS Settings)
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _cameraPermissionGranted 
                  ? _iosGreen.withOpacity(0.15) 
                  : _iosOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _cameraPermissionGranted ? Icons.check_rounded : Icons.lock_outline_rounded,
              color: _cameraPermissionGranted ? _iosGreen : _iosOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cameraPermissionGranted ? "Izin Diberikan" : "Izin Diperlukan",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cameraPermissionGranted 
                      ? "Siap untuk memulai sesi latihan." 
                      : "Izinkan akses kamera & mikrofon.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tombol Full Width iOS Style
  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56, // Tinggi standar tombol mobile modern
      child: ElevatedButton(
        onPressed: _cameraPermissionGranted ? _navigateToCapture : _requestPermissions,
        style: ElevatedButton.styleFrom(
          backgroundColor: _iosBlue,
          foregroundColor: Colors.white,
          elevation: 0, // Flat design (tanpa bayangan tinggi)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Sudut membulat
          ),
          // Efek sentuhan
          splashFactory: NoSplash.splashFactory, 
        ),
        child: Text(
          _cameraPermissionGranted ? 'Buka Kamera' : 'Izinkan Akses',
          style: const TextStyle(
            fontSize: 17, // Ukuran font standar iOS Button
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}