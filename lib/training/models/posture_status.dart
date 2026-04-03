import 'package:flutter/material.dart';

class PostureStatus {
  final String message;
  final bool isGood;
  final IconData icon;
  final Color color;

  PostureStatus({
    required this.message,
    required this.isGood,
    required this.icon,
    required this.color,
  });

  // Hasil ML Classifier
  factory PostureStatus.fromLabel(String label, double confidence) {
    final pct = '${(confidence * 100).toStringAsFixed(0)}%';
    switch (label) {
      case 'gerakan_benar':
        return PostureStatus(
          message: '  GERAKAN BENAR  $pct',
          isGood: true,
          icon: Icons.check_circle,
          color: const Color(0xFF34C759),
        );
      case 'lutut_lebih_jari_kaki':
        return PostureStatus(
          message: '  LUTUT TERLALU MAJU',
          isGood: false,
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
        );
      case 'punggung_bungkuk':
        return PostureStatus(
          message: ' PUNGGUNG BUNGKUK',
          isGood: false,
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
        );
      default:
        return PostureStatus.standby();
    }
  }

  // Rule-Based (Gatekeeper)
  factory PostureStatus.recording(int frameCount) => PostureStatus(
        message: ' MEREKAM...  ($frameCount frames)',
        isGood: true,
        icon: Icons.radio_button_on,
        color: Colors.blueAccent,
      );

  factory PostureStatus.standby() => PostureStatus(
        message: 'SIAP — MULAI DEADLIFT',
        isGood: true,
        icon: Icons.accessibility_new,
        color: Colors.white70,
      );

  /// [NEWFactory] — Tampilkan progress kalibrasi adaptif
  factory PostureStatus.calibrating(int current, int total) => PostureStatus(
        message: 'KALIBRASI... $current/$total — Berdiri tegak sebentar',
        isGood: true,
        icon: Icons.tune,
        color: const Color(0xFFFF9F0A),
      );

  // Error & UI
  factory PostureStatus.notDetected() => PostureStatus(
        message: "SUBJEK TIDAK TERDETEKSI",
        isGood: false,
        icon: Icons.person_off,
        color: Colors.grey,
      );

  factory PostureStatus.notClear() => PostureStatus(
        message: "POSISI KAMERA KURANG PAS",
        isGood: false,
        icon: Icons.visibility_off,
        color: Colors.orange,
      );

  factory PostureStatus.loading() => PostureStatus(
        message: "MENYIAPKAN MODEL AI...",
        isGood: true,
        icon: Icons.hourglass_empty,
        color: Colors.blue,
      );

  factory PostureStatus.error() => PostureStatus(
        message: "ERROR ANALISIS SISTEM",
        isGood: false,
        icon: Icons.error_outline,
        color: Colors.redAccent,
      );
}