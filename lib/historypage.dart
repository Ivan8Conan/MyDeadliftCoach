import 'package:flutter/material.dart';
import 'package:mydeadliftcouch/training/database/sqlite_helper.dart';
import 'history_details.dart';

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

  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SQLiteHelper.instance.getAllSessions();
      setState(() {
        _sessions = data;
        _isLoading = false;
      });
      _entranceController.forward(from: 0.0);
    } catch (e) {
      setState(() => _isLoading = false);
      print("Gagal load history: $e");
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  // Fungsi helper untuk format durasi dan tanggal
  String _formatDuration(String start, String? end) {
    if (end == null) return "Belum selesai";
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final diff = e.difference(s);
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ${diff.inSeconds % 60}s";
      return "${diff.inSeconds}s";
    } catch (_) {
      return "-";
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "-";
    }
  }

  int _calculateTotalReps() {
    int total = 0;
    for (var s in _sessions) {
      total += (s['jumlah_repetisi'] as int?) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _iosBgColor,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _iosBlue))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
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

                  _buildAnimatedItem(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel("Ringkasan Total"),
                        const SizedBox(height: 10),
                        _BouncyCard(child: _buildSummaryCard()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildAnimatedItem(
                    index: 2,
                    child: _buildSectionLabel("Daftar Sesi (Terbaru)"),
                  ),
                  const SizedBox(height: 10),

                  if (_sessions.isEmpty)
                    _buildAnimatedItem(
                      index: 3,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        alignment: Alignment.center,
                        child: Text("Belum ada riwayat latihan.", style: TextStyle(color: _iosGrey)),
                      ),
                    ),

                  ..._sessions.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> session = entry.value;

                    // Kalkulasi tampilan untuk list
                    final durationStr = _formatDuration(session['waktu_mulai'], session['waktu_selesai']);
                    final timeStr = _formatTime(session['waktu_mulai']);
                    final reps = session['jumlah_repetisi'] ?? 0;
                    final score = session['rating_efektivitas'] ?? 0;

                    return _buildAnimatedItem(
                      index: 3 + index,
                      child: _BouncyCard(
                        onTap: () {
                          // Navigasi ke HistoryDetailsPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HistoryDetailsPage(sessionData: session),
                            ),
                          ).then((_) => _loadData()); // Refresh saat kembali (jika ada data baru)
                        },
                        child: _buildSessionCard(
                          date: session['tanggal'],
                          time: timeStr,
                          duration: durationStr,
                          reps: reps.toString(),
                          score: score.toString(),
                        ),
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
          CurvedAnimation(parent: _entranceController, curve: Interval(start, end, curve: Curves.easeOut)),
        );

        final Animation<Offset> slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceController, curve: Interval(start, end, curve: Curves.easeOutQuart)),
        );

        return FadeTransition(opacity: fadeAnimation, child: SlideTransition(position: slideAnimation, child: child));
      },
      child: child,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _iosGrey, letterSpacing: 0.5),
    );
  }

  Widget _buildSummaryCard() {
    int totalReps = _calculateTotalReps();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
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
                Text("$totalReps", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
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
                    const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text("Total Sesi", style: TextStyle(color: _iosGrey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("${_sessions.length}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard({required String date, required String time, required String duration, required String reps, required String score}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text(time, style: TextStyle(fontSize: 14, color: _iosGrey)),
                ],
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _iosGrey),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildMetricChip(Icons.timer_outlined, duration),
                  const SizedBox(width: 12),
                  _buildMetricChip(Icons.repeat, "$reps Reps"),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _iosBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text("Skor: $score", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _iosBlue)),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), reverseDuration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
        child: widget.child,
      ),
    );
  }
}