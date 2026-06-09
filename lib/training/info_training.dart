import 'package:flutter/material.dart';
import 'trainingcapture.dart';

class InfoTrainingPage extends StatefulWidget {
  final bool isFromTrainingPage;
  const InfoTrainingPage({super.key, this.isFromTrainingPage = true});

  @override
  State<InfoTrainingPage> createState() => _InfoTrainingPageState();
}

class _InfoTrainingPageState extends State<InfoTrainingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "icon": Icons.phone_android_rounded,
      "title": "Posisi Kamera",
      "description": "Posisikan HP di samping untuk tampak samping tubuh penuh.\n Pastikan seluruh badan Anda terlihat jelas di dalam layar kamera.",
      "color": const Color(0xFF007AFF),
    },
    {
      "icon": Icons.accessibility_new_rounded,
      "title": "Kalibrasi Otomatis",
      "description": "Berdiri tegak dengan rileks selama ~30 detik di depan kamera. Sistem akan melakukan kalibrasi otomatis untuk membentuk threshold postur Anda.",
      "color": const Color(0xFFFF9500),
    },
    {
      "icon": Icons.auto_awesome_rounded,
      "title": "Analisis Pintar",
      "description": "Mulai gerakan deadlift. Sistem akan mendeteksi secara otomatis dan hasil analisis koreksi postur akan muncul tepat setelah satu repetisi selesai.",
      "color": const Color(0xFF34C759),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex == _onboardingData.length - 1) {
      if (widget.isFromTrainingPage) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const TrainingCapturePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _iosBgColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 20),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            
            // Carousel Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildSlideContent(_onboardingData[index]);
                },
              ),
            ),

            // Indikator Titik (Dots)
            _buildDotsIndicator(),
            
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "DISCLAIMER: Aplikasi ini adalah purwarupa (prototype) dan tidak menggantikan peran pelatih profesional maupun saran medis. Risiko cedera ditanggung pengguna.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Tombol Aksi Bawah
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _BouncingButton(
                onTap: _onNext,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _iosBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _iosBlue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentIndex == _onboardingData.length - 1 ? 'Saya Paham, Mulai Latihan' : 'Lanjut',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desain Konten Per Slide ala iOS What's New
  Widget _buildSlideContent(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: (data['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data['icon'],
              size: 64,
              color: data['color'],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data['title'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data['description'],
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Indikator Titik bergaya iOS Smooth
  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _onboardingData.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentIndex == index ? _iosBlue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BouncingButton({required this.child, required this.onTap});

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1 - _controller.value;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: Transform.scale(scale: scale, child: widget.child),
    );
  }
}