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

  factory PostureStatus.good() => PostureStatus(
        message: "✓ POSTUR BAIK",
        isGood: true,
        icon: Icons.check_circle,
        color: Colors.green,
      );

  factory PostureStatus.hunched() => PostureStatus(
        message: "⚠️ PUNGGUNG BUNGKUK",
        isGood: false,
        icon: Icons.warning_amber_rounded,
        color: Colors.red,
      );

  factory PostureStatus.asymmetric() => PostureStatus(
        message: "⚠️ BAHU MIRING",
        isGood: false,
        icon: Icons.warning_amber_rounded,
        color: Colors.red,
      );

  factory PostureStatus.notClear() => PostureStatus(
        message: "POSISI TIDAK JELAS",
        isGood: false,
        icon: Icons.visibility_off,
        color: Colors.orange,
      );

  factory PostureStatus.notDetected() => PostureStatus(
        message: "TIDAK TERDETEKSI",
        isGood: false,
        icon: Icons.person_off,
        color: Colors.grey,
      );

  factory PostureStatus.loading() => PostureStatus(
        message: "MEMUAT...",
        isGood: false,
        icon: Icons.hourglass_empty,
        color: Colors.blue,
      );

  factory PostureStatus.error() => PostureStatus(
        message: "ERROR ANALISIS",
        isGood: false,
        icon: Icons.error,
        color: Colors.purple,
      );
}