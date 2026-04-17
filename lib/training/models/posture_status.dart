import 'package:flutter/material.dart';

class PostureStatus {
  final String message;
  final String explanation;
  final String errorId;
  final bool isGood;
  final IconData icon;
  final Color color;

  PostureStatus({
    required this.message,
    required this.explanation,
    required this.errorId,
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
          explanation: 'Postur deadlift Anda sudah benar. Pertahankan form ini!',
          errorId: 'GB000',
          isGood: true,
          icon: Icons.check_circle,
          color: const Color(0xFF34C759),
        );
      case 'lutut_lebih_jari_kaki':
        return PostureStatus(
          message: '  LUTUT TERLALU MAJU',
          explanation: 'Tarik pinggul lebih ke belakang dan pastikan lutut tidak melewati jari kaki!',
          errorId: 'LK002',
          isGood: false,
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
        );
      case 'punggung_bungkuk':
        return PostureStatus(
          message: ' PUNGGUNG BUNGKUK',
          explanation: 'Busungkan dada ke depan, tarik bahu ke belakang, dan jaga punggung tetap lurus!',
          errorId: 'PB001',
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
        explanation: '',
        errorId: '',
        isGood: true,
        icon: Icons.radio_button_on,
        color: Colors.blueAccent,
      );

  factory PostureStatus.standby() => PostureStatus(
        message: 'SIAP — MULAI DEADLIFT',
        explanation: '',
        errorId: '',
        isGood: true,
        icon: Icons.accessibility_new,
        color: Colors.white70,
      );

  /// Tampilkan progress kalibrasi adaptif
  factory PostureStatus.calibrating(int current, int total) => PostureStatus(
        message: 'KALIBRASI... $current/$total — Berdiri tegak sebentar',
        explanation: '',
        errorId: '',
        isGood: true,
        icon: Icons.tune,
        color: const Color(0xFFFF9F0A),
      );

  // Error & UI
  factory PostureStatus.notDetected() => PostureStatus(
        message: "SUBJEK TIDAK TERDETEKSI",
        explanation: '',
        errorId: '',
        isGood: false,
        icon: Icons.person_off,
        color: Colors.grey,
      );

  factory PostureStatus.notClear() => PostureStatus(
        message: "POSISI KAMERA KURANG PAS",
        explanation: '',
        errorId: '',
        isGood: false,
        icon: Icons.visibility_off,
        color: Colors.orange,
      );

  factory PostureStatus.loading() => PostureStatus(
        message: "MENYIAPKAN MODEL AI...",
        explanation: '',
        errorId: '',
        isGood: true,
        icon: Icons.hourglass_empty,
        color: Colors.blue,
      );

  factory PostureStatus.error() => PostureStatus(
        message: "ERROR ANALISIS SISTEM",
        explanation: '',
        errorId: '',
        isGood: false,
        icon: Icons.error_outline,
        color: Colors.redAccent,
      );
}