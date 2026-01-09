import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // Warna Palet Khas iOS
  final Color _iosBgColor = const Color(0xFFF2F2F7);
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosGreen = const Color(0xFF34C759);
  final Color _iosGrey = const Color(0xFF8E8E93);
  final Color _iosRed = const Color(0xFFFF3B30);

  // Dummy Data untuk List (Descending)
  final List<Map<String, dynamic>> _sessions = const [
    {
      "date": "07 Jan 2026",
      "time": "16:30",
      "duration": "45s",
      "reps": 8,
      "score": 4.0,
      "status": "Baik",
      "color": Colors.orange, // Representasi visual status
    },
    {
      "date": "05 Jan 2026",
      "time": "08:00",
      "duration": "60s",
      "reps": 10,
      "score": 5.0,
      "status": "Sempurna",
      "color": Color(0xFF34C759), // Hijau iOS
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
      "color": Color(0xFFFF3B30), // Merah iOS
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _iosBgColor,
      // SafeArea hanya atas, bawah false agar list bisa discroll di balik navbar
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding bawah besar untuk navbar
          physics: const BouncingScrollPhysics(), // Efek scroll iOS
          children: [
            // [A] Header Halaman
            const Text(
              'Riwayat Latihan',
              style: TextStyle(
                fontSize: 34, // Large Title iOS standard
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 24),

            // [B] Ringkasan Mingguan
            _buildSectionLabel("Ringkasan Mingguan"),
            const SizedBox(height: 10),
            _buildSummaryCard(),

            const SizedBox(height: 30),

            // [C] Daftar Sesi
            _buildSectionLabel("Daftar Sesi (Terbaru)"),
            const SizedBox(height: 10),
            
            // Loop data sessions
            ..._sessions.map((session) => _buildSessionCard(session)),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Label Section
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

  // [B] Widget Kartu Ringkasan (Summary)
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
          // Kolom 1: Total Reps
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
          
          // Garis Pemisah Vertikal
          Container(height: 40, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 20),

          // Kolom 2: Rata-rata Skor
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

  // [C] Widget Kartu Sesi (List Item)
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
          // Baris Atas: Tanggal & Panah Detail
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
              // Tombol Detail (Chevron)
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _iosGrey),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // Baris Bawah: Metrik & Skor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Info Durasi & Reps
              Row(
                children: [
                  _buildMetricChip(Icons.timer_outlined, session['duration']),
                  const SizedBox(width: 12),
                  _buildMetricChip(Icons.repeat, "${session['reps']} Reps"),
                ],
              ),
              
              // Badge Skor
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

  // Helper Kecil untuk Chip (Durasi/Reps)
  Widget _buildMetricChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _iosGrey),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}