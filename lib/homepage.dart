import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'trainingpage.dart';
import 'historypage.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, RouteAware {
  int _selectedIndex = 0;
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;
  late PageController _carouselController;

  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosCardColor = Colors.white;

  late final List<Widget> _pages;

  // Animation controllers
  late AnimationController _profileController;
  late AnimationController _cardController;
  late AnimationController _tipsController;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(initialPage: 0);

    // Animations
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _tipsController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pages = [
      _buildHomeContent(),
      const TrainingPage(),
      const HistoryPage(),
    ];
    _startAnimations();

    // Mulai timer
    _startTimer();
  }

  void _startTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_carouselController.hasClients) {
        final next = (_currentCarouselIndex + 1) % 3;
        _carouselController.animateToPage(next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic);
      }
    });
  }

  void _stopTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = null;
  }

  void _startAnimations() {
    _profileController.reset();
    _cardController.reset();
    _tipsController.reset();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _profileController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _tipsController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of<dynamic>(context) as PageRoute<dynamic>?; // <-- cast
    if (modalRoute != null) routeObserver.subscribe(this, modalRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _stopTimer();
    _carouselController.dispose();
    _profileController.dispose();
    _cardController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() => _stopTimer();

  @override
  void didPopNext() {
    if (_selectedIndex == 0) {
      _startTimer();
    }
  }

  Widget _buildHomeContent() {
    return Scaffold(
      backgroundColor: _iosBgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selamat Datang,',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MyDeadliftCoach',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      AnimatedBuilder(
                        animation: _profileController,
                        builder: (context, child) => Transform.scale(
                          scale: Tween<double>(begin: 0.8, end: 1.0)
                              .animate(CurvedAnimation(parent: _profileController, curve: Curves.easeOutBack))
                              .value,
                          child: child,
                        ),
                        child: GestureDetector(
                          onTap: () => Feedback.forTap(context),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                            child: const CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildModernCarousel(),
                  const SizedBox(height: 24),
                  _buildAnimatedSectionHeader("Statistik Terakhir"),
                  const SizedBox(height: 12),
                  _buildAnimatedIOSWidget(controller: _cardController, child: _buildInfoContent()),
                  const SizedBox(height: 24),
                  _buildAnimatedSectionHeader("Tips Hari Ini"),
                  const SizedBox(height: 12),
                  _buildAnimatedIOSWidget(controller: _tipsController, child: _buildTipsContent()),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSectionHeader(String title) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) => Transform.translate(
        offset: Offset(Tween<double>(begin: -20, end: 0).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic)).value, 0),
        child: Opacity(
          opacity: Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(parent: _cardController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)))
              .value,
          child: child,
        ),
      ),
      child: _buildSectionHeader(title),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(children: [
      Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: -0.5)),
    ]);
  }

  Widget _buildAnimatedIOSWidget({required AnimationController controller, required Widget child}) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.scale(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)).value,
        child: Opacity(
          opacity: Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(parent: controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)))
              .value,
          child: child,
        ),
      ),
      child: _buildIOSWidget(child: child),
    );
  }

  Widget _buildIOSWidget({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _iosCardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildModernCarousel() {
    final List<String> carouselImages = [
      'assets/images/deadlifttips1.webp',
      'assets/images/deadlifttips2.jfif',
      'assets/images/deadlifttips3.webp',
    ];

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            PageView.builder(
              controller: _carouselController,
              onPageChanged: (index) => setState(() => _currentCarouselIndex = index),
              itemCount: carouselImages.length,
              itemBuilder: (context, index) => Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(carouselImages[index]),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _buildSmoothIOSDots(carouselImages.length),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmoothIOSDots(int count) {
    return AnimatedBuilder(
      animation: _carouselController,
      builder: (context, child) {
        double currentPage = 0;
        if (_carouselController.hasClients && _carouselController.position.haveDimensions) {
          currentPage = _carouselController.page ?? _carouselController.initialPage.toDouble();
        } else {
          currentPage = _currentCarouselIndex.toDouble();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            double distance = (currentPage - index).abs();
            double t = (1.0 - distance).clamp(0.0, 1.0);
            t = Curves.easeOutQuart.transform(t);
            double width = 8.0 + (16.0 * t);
            double opacity = 0.4 + (0.6 * t);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: width,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInfoContent() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Sesi Kemarin", style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 6),
        const Text("Skor: 4/5", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _iosBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(Icons.repeat, size: 14, color: _iosBlue),
            const SizedBox(width: 4),
            Text("8 Reps", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _iosBlue)),
          ]),
        ),
      ]),
      GestureDetector(
        onTap: () => Feedback.forTap(context),
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 65,
            height: 65,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => CircularProgressIndicator(
                value: value * 0.8,
                backgroundColor: Colors.grey.shade100,
                color: const Color(0xFF34C759),
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          const Text("80%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    ]);
  }

  Widget _buildTipsContent() {
    return GestureDetector(
      onTap: () => Feedback.forTap(context),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFF9500).withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFFF9500), size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Jaga Punggung Lurus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text("Mencegah cedera tulang belakang saat mengangkat beban.",
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: _iosBgColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGlassIcon(0, Icons.home_rounded, 'Home'),
                  _buildGlassIcon(1, Icons.fitness_center_rounded, 'Training'),
                  _buildGlassIcon(2, Icons.history_rounded, 'Riwayat'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIcon(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? _iosBlue : Colors.grey[400], size: 26),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: _iosBlue, fontSize: 10, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
    );
  }
}