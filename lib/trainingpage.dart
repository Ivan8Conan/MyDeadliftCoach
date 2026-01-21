import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '/training/trainingcapture.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> with SingleTickerProviderStateMixin {
  bool _cameraPermissionGranted = false;
  bool _checkingPermissions = true;
  
  late AnimationController _pageController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosGreen = const Color(0xFF34C759);
  final Color _iosOrange = const Color(0xFFFF9500);

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    
    // Setup Page Animation
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );

    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    setState(() => _checkingPermissions = true);
    
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TrainingCapturePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    
    if (mounted) _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: _iosBgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  
                  // Animated Icon
                  const BreathingWidget(
                    child: HeroIconWidget(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Judul & Deskripsi
                  const Text(
                    'Mulai Latihan',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aplikasi akan menganalisis postur tubuh Anda secara real-time menggunakan kamera depan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                  ),

                  const Spacer(flex: 2),

                  // Status Card
                  _buildStatusCard(),

                  const Spacer(flex: 3),

                  // Interactive Action Button
                  BouncingButton(
                    onTap: _cameraPermissionGranted ? _navigateToCapture : _requestPermissions,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _iosBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: _iosBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _cameraPermissionGranted ? 'Buka Kamera' : 'Izinkan Akses',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _iosBgColor,
      body: Center(child: CircularProgressIndicator(color: _iosBlue)),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _cameraPermissionGranted ? _iosGreen.withOpacity(0.15) : _iosOrange.withOpacity(0.15),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  _cameraPermissionGranted ? "Siap untuk memulai sesi latihan." : "Izinkan akses kamera & mikrofon.",
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroIconWidget extends StatelessWidget {
  const HeroIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.camera_front_rounded, size: 56, color: Color(0xFF007AFF)),
    );
  }
}

class BreathingWidget extends StatefulWidget {
  final Widget child;
  const BreathingWidget({super.key, required this.child});

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncingButton({super.key, required this.child, required this.onTap});

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.0, upperBound: 0.1);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final scale = 1 - _controller.value;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(scale: scale, child: widget.child),
    );
  }
}