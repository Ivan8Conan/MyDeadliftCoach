import 'package:flutter/material.dart';
import 'package:mydeadliftcouch/training/database/sqlite_helper.dart';

class HistoryDetailsPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const HistoryDetailsPage({super.key, required this.sessionData});

  @override
  State<HistoryDetailsPage> createState() => _HistoryDetailsPageState();
}

class _HistoryDetailsPageState extends State<HistoryDetailsPage> {
  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosGrey = const Color(0xFF8E8E93);

  List<Map<String, dynamic>> _errors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionErrors();
  }

  Future<void> _loadSessionErrors() async {
    try {
      final sessionId = widget.sessionData['session_id'] as int;
      final data = await SQLiteHelper.instance.getSessionErrors(sessionId);
      setState(() {
        _errors = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Gagal mengambil detail: $e");
    }
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return "-";
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    } catch (_) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final reps = widget.sessionData['jumlah_repetisi'] ?? 0;
    final date = widget.sessionData['tanggal'] ?? "-";

    return Scaffold(
      backgroundColor: _iosBgColor,
      appBar: AppBar(
        backgroundColor: _iosBgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _iosBlue),
        centerTitle: true,
        title: const Text(
          "Detail Sesi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _iosBlue))
          : ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Kartu Header Sesi
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _iosBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _iosBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      const Text("Sesi Latihan Deadlift", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStat(Icons.repeat, "$reps", "Repetisi"),
                          _buildHeaderStat(Icons.star_rounded, "${widget.sessionData['rating_efektivitas'] ?? '-'}", "Skor"),
                          _buildHeaderStat(Icons.warning_amber_rounded, "${_errors.where((e) => e['kode_error'] != 'GB000').length}", "Kesalahan"),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Label Timeline
                Text("TIMELINE FEEDBACK (${_errors.length})", 
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _iosGrey, letterSpacing: 0.5)),
                const SizedBox(height: 12),

                // Jika tidak ada error sama sekali
                if (_errors.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: Text("Tidak ada catatan feedback pada sesi ini.", style: TextStyle(color: _iosGrey)),
                  ),

                // Daftar Timeline Kesalahan
                ..._errors.map((err) {
                  bool isGood = err['kode_error'] == 'GB000';
                  Color riskColor = isGood ? const Color(0xFF34C759) : (err['risiko'] == 'Tinggi' ? Colors.red : Colors.orange);
                  IconData riskIcon = isGood ? Icons.check_circle_outline : Icons.error_outline;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: riskColor.withOpacity(0.3), width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: riskColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(riskIcon, color: riskColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(err['nama_error'] ?? 'Feedback', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(_formatTime(err['time_error']), style: TextStyle(color: _iosGrey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(err['pesan_teks'] ?? '-', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}