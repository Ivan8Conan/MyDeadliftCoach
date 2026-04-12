// SUDAH DIOPTIMASI - Versi Final
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import './models/pose_keypoint.dart';
import './models/posture_status.dart';
import './services/camera_service.dart';
import './services/camera_overlay_painter.dart';
import './services/media_pipe_service.dart';
import './services/posture_analysis_service.dart';
import 'package:permission_handler/permission_handler.dart';

class TrainingCapturePage extends StatefulWidget {
  const TrainingCapturePage({super.key});

  @override
  State<TrainingCapturePage> createState() => _TrainingCapturePageState();
}

class _TrainingCapturePageState extends State<TrainingCapturePage> {
  final CameraService _cameraService = CameraService();
  final MediaPipeService _mediaPipeService = MediaPipeService();
  final PostureAnalysisService _postureService = PostureAnalysisService();

  bool _isCameraReady = false;
  bool _isMediaPipeLoaded = false;
  bool _isRecording = false;
  bool _isDisposed = false;

  List<PoseKeypoint> _keypoints = [];
  PostureStatus _status = PostureStatus.loading();

  // Tampilkan hasil ML selama 3 detik setelah update terakhir, lalu reset ke status terbaru
  PostureStatus? _pinnedResult;
  DateTime? _pinnedAt;
  static const _pinDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _setup();
  }

Future<void> _setup() async {
  await _postureService.initIsolate();

  // Sambungkan referensi kamera agar adaptive fps bisa bekerja
  _postureService.cameraServiceRef = _cameraService; //v2

  _postureService.onClassificationResult = (result) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _pinnedResult = result;
      _pinnedAt = DateTime.now();
      _status = result;
    });
  };

  _postureService.onStateChanged = (newState) {
    if (_isDisposed) return;
    _mediaPipeService.switchModel(useAccurate: newState == 'ACTIVE');
  };

  _mediaPipeService.onModelLoaded = (loaded) {
    if (mounted && !_isDisposed) {
      setState(() => _isMediaPipeLoaded = loaded);
    }
  };

  _mediaPipeService.onKeypointsUpdated = (keypoints) {
    if (mounted && !_isDisposed && !_isRecording) {
      final newStatus = _postureService.analyzePosture(keypoints);
      setState(() {
        _keypoints = keypoints;
        _status = _getDisplayStatus(newStatus);
      });
    }
  };

  _cameraService.onCameraStateChanged = (isActive) async {
    if (!mounted || !isActive || _isDisposed) return;
    setState(() => _isCameraReady = true);
    await _mediaPipeService.initialize();

    _cameraService.onImageAvailable = (inputImage) {
      _mediaPipeService.processImage(inputImage);
    };

    _mediaPipeService.startDetection();
  };

  _cameraService.onRecordingStateChanged = (isRecording) {
    if (mounted && !_isDisposed) {
      setState(() => _isRecording = isRecording);
    }
  };

  try {
    await _cameraService.initializeCamera();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka kamera: $e')),
      );
    }
  }
}

  PostureStatus _getDisplayStatus(PostureStatus latest) {
    if (_pinnedResult != null && _pinnedAt != null) {
      if (DateTime.now().difference(_pinnedAt!) < _pinDuration) {
        return _pinnedResult!;
      }
      _pinnedResult = null;
    }
    return latest;
  }

  // Recording control: start/stop recording, reset posture status saat stop
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _cameraService.stopRecording();
      _postureService.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(path != null ? 'Video disimpan!' : 'Recording dihentikan'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _cameraService.startRecording();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _postureService.dispose();
    _mediaPipeService.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          _buildCameraPreview(),

          // Skeleton Overlay
          if (_isCameraReady && _keypoints.isNotEmpty) _buildSkeletonOverlay(),

          // Top Bar
          _buildTopBar(),

          // Calibration Banner (saat belum kalibrasi)
          if (_isCameraReady && !_postureService.isCalibrated)
            _buildCalibrationBanner(),

          // Status Feedback
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: _buildStatusCard(),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // Loading Overlay
          if (!_isCameraReady || !_isMediaPipeLoaded) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraService.controller == null) {
      return Container(color: Colors.black);
    }
    return SizedBox.expand(
      child: CameraPreview(_cameraService.controller!),
    );
  }

  Widget _buildSkeletonOverlay() {
    final controller = _cameraService.controller;
    if (controller == null) return const SizedBox();
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox();

    return SizedBox.expand(
      child: CustomPaint(
        painter: CameraOverlayPainter(
          keypoints: _keypoints,
          videoSize: Size(previewSize.height, previewSize.width),
          lensDirection: _cameraService.lensDirection,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            const Spacer(),
            if (_isRecording)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('REC',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            // State indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indikator state
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _postureService.state == 'ACTIVE'
                          ? const Color(0xFF34C759)
                          : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _postureService.state,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  // Indikator model aktif
                  if (_postureService.state == 'ACTIVE') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('HD',
                          style: TextStyle(
                              color: Color(0xFF0A84FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner kalibrasi — muncul di atas saat threshold belum terkalibrasi
  Widget _buildCalibrationBanner() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9F0A).withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.tune, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Berdiri tegak sebentar untuk kalibrasi otomatis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_status.message),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _status.color.withOpacity(0.6), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_status.icon, color: _status.color, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _status.message,
                style: TextStyle(
                  color: _status.color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      height: 110,
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            icon: Icons.refresh,
            label: 'Reset',
            onTap: () {
              _postureService.reset();
              setState(() => _status = PostureStatus.standby());
            },
          ),
          // Tombol record
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: _isRecording ? Colors.red : Colors.transparent,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.videocam,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          _circleButton(
            icon: Icons.info_outline,
            label: 'Info',
            onTap: _showInfoDialog,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Memuat kamera & model AI...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Cara Penggunaan',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '1. Posisikan HP di samping untuk tampak samping tubuh penuh\n'
          '2. Berdiri tegak ~30 detik untuk kalibrasi otomatis threshold\n'
          '3. Pastikan seluruh badan terlihat di kamera\n'
          '4. Mulai gerakan deadlift — sistem otomatis mendeteksi\n'
          '5. Hasil analisis muncul setelah satu rep selesai\n',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}












// // SEBELUM OPTIMASI
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import './models/pose_keypoint.dart';
// import './models/posture_status.dart';
// import './services/camera_service.dart';
// import './services/camera_overlay_painter.dart';
// import './services/media_pipe_service.dart';
// import './services/posture_analysis_service.dart';

// class TrainingCapturePage extends StatefulWidget {
//   const TrainingCapturePage({super.key});

//   @override
//   State<TrainingCapturePage> createState() => _TrainingCapturePageState();
// }

// class _TrainingCapturePageState extends State<TrainingCapturePage> {
//   final CameraService _cameraService = CameraService();
//   final MediaPipeService _mediaPipeService = MediaPipeService();
//   final PostureAnalysisService _postureService = PostureAnalysisService();

//   bool _isCameraReady = false;
//   bool _isMediaPipeLoaded = false;
//   bool _isRecording = false;
//   bool _isDisposed = false;

//   List<PoseKeypoint> _keypoints = [];
//   PostureStatus _status = PostureStatus.loading();

//   @override
//   void initState() {
//     super.initState();
//     _setup();
//   }

//   Future<void> _setup() async {
//     // UNOPTIMIZED: Hapus Isolate, mainkan langsung
//     _postureService.onClassificationResult = (result) {
//       if (mounted && !_isDisposed) {
//         setState(() {
//           _status = result;
//         });
//       }
//     };

//     _mediaPipeService.onModelLoaded = (loaded) {
//       if (mounted && !_isDisposed) setState(() => _isMediaPipeLoaded = loaded);
//     };

//     _mediaPipeService.onKeypointsUpdated = (keypoints) {
//       if (mounted && !_isDisposed && !_isRecording) {
//         // UNOPTIMIZED: Berjalan di UI Thread, menyebabkan frame drop
//         final newStatus = _postureService.analyzePosture(keypoints);
//         setState(() {
//           _keypoints = keypoints;
//           _status = newStatus;
//         });
//       }
//     };

//     _cameraService.onCameraStateChanged = (isActive) async {
//       if (!mounted || !isActive || _isDisposed) return;
//       setState(() => _isCameraReady = true);
//       await _mediaPipeService.initialize();

//       _cameraService.onImageAvailable = (inputImage) {
//         _mediaPipeService.processImage(inputImage);
//       };
//       _mediaPipeService.startDetection();
//     };

//     _cameraService.onRecordingStateChanged = (isRecording) {
//       if (mounted && !_isDisposed) setState(() => _isRecording = isRecording);
//     };

//     await _cameraService.initializeCamera();
//   }

//   Future<void> _toggleRecording() async {
//     if (_isRecording) {
//       await _cameraService.stopRecording();
//       _postureService.reset();
//     } else {
//       await _cameraService.startRecording();
//     }
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     _postureService.dispose();
//     _mediaPipeService.dispose();
//     _cameraService.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           if (_isCameraReady && _cameraService.controller != null)
//             SizedBox.expand(child: CameraPreview(_cameraService.controller!)),
            
//           if (_isCameraReady && _keypoints.isNotEmpty && _cameraService.controller != null)
//             SizedBox.expand(
//               child: CustomPaint(
//                 painter: CameraOverlayPainter(
//                   keypoints: _keypoints,
//                   videoSize: Size(
//                     _cameraService.controller!.value.previewSize!.height,
//                     _cameraService.controller!.value.previewSize!.width,
//                   ),
//                   lensDirection: _cameraService.lensDirection,
//                 ),
//               ),
//             ),
            
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
//                       child: const Icon(Icons.arrow_back, color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           Positioned(
//             bottom: 120, left: 16, right: 16,
//             child: _buildStatusCard(),
//           ),

//           Positioned(
//             bottom: 0, left: 0, right: 0,
//             child: _buildBottomControls(),
//           ),

//           if (!_isCameraReady || !_isMediaPipeLoaded)
//             Container(
//               color: Colors.black87,
//               child: const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.75),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _status.color.withOpacity(0.6), width: 1.5),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(_status.icon, color: _status.color, size: 22),
//           const SizedBox(width: 10),
//           Flexible(
//             child: Text(
//               _status.message,
//               style: TextStyle(color: _status.color, fontSize: 15, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomControls() {
//     return Container(
//       height: 110, color: Colors.black87,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           GestureDetector(
//             onTap: () {
//               _postureService.reset();
//               setState(() => _status = PostureStatus.standby());
//             },
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 48, height: 48,
//                   decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
//                   child: const Icon(Icons.refresh, color: Colors.white, size: 22),
//                 ),
//                 const SizedBox(height: 4),
//                 const Text('Reset', style: TextStyle(color: Colors.white60, fontSize: 11)),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: _toggleRecording,
//             child: Container(
//               width: 72, height: 72,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 3),
//                 color: _isRecording ? Colors.red : Colors.transparent,
//               ),
//               child: Icon(_isRecording ? Icons.stop : Icons.videocam, color: Colors.white, size: 32),
//             ),
//           ),
//           const SizedBox(width: 48), // Spacer
//         ],
//       ),
//     );
//   }
// }