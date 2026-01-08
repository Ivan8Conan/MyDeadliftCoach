import 'package:flutter/material.dart';
import '../../../training/models/pose_keypoint.dart';

class CameraOverlayPainter extends CustomPainter {
  final List<PoseKeypoint> keypoints;
  final Size videoSize;

  CameraOverlayPainter({required this.keypoints, required this.videoSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final greenPointPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Konversi koordinat
    double scaleX = size.width / videoSize.width;
    double scaleY = size.height / videoSize.height;

    // Connections untuk skeleton
    final connections = [
      [0, 1], [1, 2], [2, 3], [3, 7], [0, 4], [4, 5], [5, 6], [6, 8],
      [9, 10], [11, 12], [11, 13], [13, 15], [15, 17], [15, 19], [15, 21],
      [12, 14], [14, 16], [16, 18], [16, 20], [16, 22],
      [11, 23], [12, 24], [23, 24],
      [23, 25], [25, 27], [27, 29], [27, 31],
      [24, 26], [26, 28], [28, 30], [28, 32],
    ];

    // Gambar garis skeleton
    for (var conn in connections) {
      if (conn[0] < keypoints.length && conn[1] < keypoints.length) {
        final start = keypoints[conn[0]];
        final end = keypoints[conn[1]];
        
        if (start.visibility > 0.5 && end.visibility > 0.5) {
          final startX = start.x * scaleX;
          final startY = start.y * scaleY;
          final endX = end.x * scaleX;
          final endY = end.y * scaleY;
          
          canvas.drawLine(
            Offset(startX, startY),
            Offset(endX, endY),
            paint,
          );
        }
      }
    }

    // Gambar titik keypoints
    for (var kp in keypoints) {
      if (kp.visibility > 0.5) {
        final x = kp.x * scaleX;
        final y = kp.y * scaleY;
        
        // Lingkaran putih luar
        canvas.drawCircle(Offset(x, y), 6, pointPaint);
        // Lingkaran hijau dalam
        canvas.drawCircle(Offset(x, y), 4, greenPointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CameraOverlayPainter oldDelegate) {
    return oldDelegate.keypoints != keypoints;
  }
}