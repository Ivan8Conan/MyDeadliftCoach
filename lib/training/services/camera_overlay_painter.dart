import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../training/models/pose_keypoint.dart';

class CameraOverlayPainter extends CustomPainter {
  final List<PoseKeypoint> keypoints;
  final Size videoSize;
  final CameraLensDirection lensDirection;

  CameraOverlayPainter({
    required this.keypoints,
    required this.videoSize,
    this.lensDirection = CameraLensDirection.front,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Scaling factors
    double scaleX = size.width / videoSize.width;
    double scaleY = size.height / videoSize.height;

    // Helper function untuk translate koordinat
    Offset getPoint(double x, double y) {
      double finalX = x;
      // Kamera depan perlu mirroring
      if (lensDirection == CameraLensDirection.front) {
        finalX = videoSize.width - x;
      }
      return Offset(finalX * scaleX, y * scaleY);
    }

    // Connections untuk skeleton
    final connections = [
      [0, 1], [1, 2], [2, 3], [3, 7], [0, 4], [4, 5], [5, 6], [6, 8],
      [9, 10], [11, 12], [11, 13], [13, 15], [15, 17], [15, 19], [15, 21],
      [12, 14], [14, 16], [16, 18], [16, 20], [16, 22],
      [11, 23], [12, 24], [23, 24],
      [23, 25], [25, 27], [27, 29], [27, 31],
      [24, 26], [26, 28], [28, 30], [28, 32],
    ];

    // Gambar garis
    for (var conn in connections) {
      if (conn[0] < keypoints.length && conn[1] < keypoints.length) {
        final startKp = keypoints[conn[0]];
        final endKp = keypoints[conn[1]];
        
        if (startKp.visibility > 0.5 && endKp.visibility > 0.5) {
          canvas.drawLine(
            getPoint(startKp.x, startKp.y),
            getPoint(endKp.x, endKp.y),
            paint,
          );
        }
      }
    }

    // Gambar titik
    for (var kp in keypoints) {
      if (kp.visibility > 0.5) {
        final point = getPoint(kp.x, kp.y);
        canvas.drawCircle(point, 5, pointPaint);
        canvas.drawCircle(point, 3, Paint()..color = Colors.green);
      }
    }
  }

  @override
  bool shouldRepaint(CameraOverlayPainter oldDelegate) {
    return oldDelegate.keypoints != keypoints;
  }
}