import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'trainingpage.dart';
import 'historypage.dart';
import 'package:mydeadliftcouch/training/database/sqlite_helper.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, RouteAware {
  int _selectedIndex = 0;

  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosCardColor = Colors.white;

  late AnimationController _profileController;
  late AnimationController _cardController;
  late AnimationController _tipsController;

  // Variabel untuk Data Dinamis
  int _totalSessions = 0;
  String _averageAccuracy = "0%";
  Map<String, dynamic>? _lastSession;

  @override
  void initState() {
    super.initState();

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

    _loadData();
    _startAnimations();
  }

  // Menarik Data dari SQLite
  Future<void> _loadData() async {
    try {
      final sessions = await SQLiteHelper.instance.getAllSessions();
      if (sessions.isNotEmpty) {
        int total = sessions.length;
        double totalScore = 0.0;
        int validScoreCount = 0;

        for (var s in sessions) {
          if (s['rating_efektivitas'] != null) {
            totalScore += (s['rating_efektivitas'] as num).toDouble();
            validScoreCount++;
          }
        }

        // Hitung akurasi persentase dari skor (skala 5)
        double avgScore = validScoreCount > 0 ? totalScore / validScoreCount : 0.0;
        int avgPercentage = ((avgScore / 5.0) * 100).round();

        setState(() {
          _totalSessions = total;
          _averageAccuracy = "$avgPercentage%";
          _lastSession = sessions.first;
        });
      } else {
        setState(() {
          _totalSessions = 0;
          _averageAccuracy = "0%";
          _lastSession = null;
        });
      }
    } catch (e) {
      print("Gagal memuat data homepage: $e");
    }
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
    final modalRoute = ModalRoute.of<dynamic>(context) as PageRoute<dynamic>?;
    if (modalRoute != null) routeObserver.subscribe(this, modalRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _profileController.dispose();
    _cardController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {}

  @override
  void didPopNext() {
    _loadData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) _loadData();
  }

  Widget _buildHomeContent() {
    return Scaffold(
      backgroundColor: _iosBgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Bagian Header (Welcome)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                            child: const CircleAvatar(
                                radius: 20, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Bagian Tombol Aksi Persuasif
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PulsingCTA(
                onTap: () {
                  Feedback.forTap(context);
                  _onItemTapped(1);
                },
              ),
            ),
          ),

          // Konten Dinamis Halaman Home
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  _buildAnimatedSectionHeader("Ringkasan Performa"),
                  const SizedBox(height: 12),
                  _buildAnimatedIOSWidget(controller: _cardController, child: _buildPerformanceGrid()),
                      
                  const SizedBox(height: 24),
                  
                  _buildAnimatedSectionHeader("Latihan Terakhir"),
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
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut))).value,
          child: child,
        ),
      ),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: -0.5)),
      ]),
    );
  }

  Widget _buildAnimatedIOSWidget({required AnimationController controller, required Widget child}) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.scale(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)).value,
        child: Opacity(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut))).value,
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _buildPerformanceGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            title: "Total Sesi",
            value: "$_totalSessions",
            subtitle: "Keseluruhan",
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF007AFF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMiniStatCard(
            title: "Akurasi Form",
            value: _averageAccuracy,
            subtitle: "Rata-rata",
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF34C759),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({required String title, required String value, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoContent() {
    // Variabel Dinamis Sesi Terakhir
    String dateStr = _lastSession != null ? _lastSession!['tanggal'] : "Belum ada sesi";
    String repsStr = _lastSession != null ? "${_lastSession!['jumlah_repetisi'] ?? 0} Reps" : "-";
    String scoreStr = _lastSession != null ? "${_lastSession!['rating_efektivitas'] ?? 0}/5" : "-";

    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        _onItemTapped(2);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _iosCardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Sesi Terakhir", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(dateStr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)), // DATA DINAMIS
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _iosBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.repeat, size: 14, color: _iosBlue),
                  const SizedBox(width: 4),
                  Text(repsStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _iosBlue)), // DATA DINAMIS
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF34C759).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFF34C759)),
                  const SizedBox(width: 4),
                  Text(scoreStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF34C759))), // DATA DINAMIS
                ]),
              ),
            ]),
          ]),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded, 
              size: 32, 
              color: Colors.grey.shade400,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTipsContent() {
    return GestureDetector(
      onTap: () => Feedback.forTap(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _iosCardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFF9500).withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFFF9500), size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Jaga Punggung Lurus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Mencegah cedera tulang belakang saat mengangkat beban berat.", style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage;
    if (_selectedIndex == 0) {
      activePage = _buildHomeContent();
    } else if (_selectedIndex == 1) {
      activePage = const TrainingPage();
    } else {
      activePage = const HistoryPage();
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: _iosBgColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: activePage,
        ),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
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
                  _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                  _buildNavItem(1, Icons.fitness_center_rounded, 'Latihan'),
                  _buildNavItem(2, Icons.history_rounded, 'Riwayat'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    const activeColor = Color(0xFF007AFF);
    final inactiveColor = Colors.grey[400]!;

    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        _onItemTapped(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()..translate(0.0, isSelected ? -2.0 : 0.0),
              child: Icon(icon, size: 24, color: isSelected ? activeColor : inactiveColor),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: isSelected ? 0.2 : 0.0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingCTA extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingCTA({required this.onTap});

  @override
  State<_PulsingCTA> createState() => _PulsingCTAState();
}

class _PulsingCTAState extends State<_PulsingCTA> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00C6FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ayo Mulai Latihan!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}