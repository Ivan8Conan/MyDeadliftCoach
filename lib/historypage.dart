import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosGrey = const Color(0xFF8E8E93);
  late AnimationController _entranceController;

  final List<Map<String, dynamic>> _sessions = const [
    {
      "date": "07 Jan 2026",
      "time": "16:30",
      "duration": "45s",
      "reps": 8,
      "score": 4.0,
      "status": "Baik",
      "color": Colors.orange,
    },
    {
      "date": "05 Jan 2026",
      "time": "08:00",
      "duration": "60s",
      "reps": 10,
      "score": 5.0,
      "status": "Sempurna",
      "color": Color(0xFF34C759),
    },
    {
      "date": "02 Jan 2026",
      "time": "17:15",
      "duration": "30s",
      "reps": 5,
      "score": 3.5,
      "status": "Cukup",
      "color": Colors.orangeAccent,
    },
    {
      "date": "30 Des 2025",
      "time": "07:00",
      "duration": "55s",
      "reps": 9,
      "score": 2.0,
      "status": "Buruk",
      "color": Color(0xFFFF3B30),
    },
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _iosBgColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            // Header Halaman
            _buildAnimatedItem(
              index: 0,
              child: const Text(
                'Riwayat Latihan',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ringkasan Mingguan
            _buildAnimatedItem(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("Ringkasan Mingguan"),
                  const SizedBox(height: 10),
                  _BouncyCard(child: _buildSummaryCard()),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Daftar Sesi Label
            _buildAnimatedItem(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("Daftar Sesi (Terbaru)"),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Daftar Sesi
            ..._sessions.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> session = entry.value;
              
              return _buildAnimatedItem(
                index: 3 + index, 
                child: _BouncyCard(
                  onTap: () {
                    print("Tapped session: ${session['date']}");
                  },
                  child: _buildSessionCard(session),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final double delay = (index * 0.1).clamp(0.0, 1.0); 
        final double start = delay;
        final double end = (start + 0.4).clamp(0.0, 1.0);

        final Animation<double> fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );

        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutQuart), // Curve smooth ala iOS
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _iosGrey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center, size: 16, color: _iosBlue),
                    const SizedBox(width: 6),
                    Text("Total Reps", style: TextStyle(color: _iosGrey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "50",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text("Rata-rata Skor", style: TextStyle(color: _iosGrey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "4.2",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['date'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session['time'],
                    style: TextStyle(
                      fontSize: 14,
                      color: _iosGrey,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _iosGrey),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildMetricChip(Icons.timer_outlined, session['duration']),
                  const SizedBox(width: 12),
                  _buildMetricChip(Icons.repeat, "${session['reps']} Reps"),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (session['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      "Skor: ${session['score']}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: session['color'],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _iosGrey),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _BouncyCard({required this.child, this.onTap});

  @override
  State<_BouncyCard> createState() => _IOSBouncyCardState();
}

class _IOSBouncyCardState extends State<_BouncyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        Feedback.forTap(context);
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}