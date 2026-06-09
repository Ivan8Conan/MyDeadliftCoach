// SUDAH DIOPTIMASI - Versi Final
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import './models/pose_keypoint.dart';
import './models/posture_status.dart';
import './services/camera_service.dart';
import './services/camera_overlay_painter.dart';
import './services/media_pipe_service.dart';
import './services/posture_analysis_service.dart';
import './database/sqlite_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'info_training.dart';

class TrainingCapturePage extends StatefulWidget {
  const TrainingCapturePage({super.key});

  @override
  State<TrainingCapturePage> createState() => _TrainingCapturePageState();
}

class _TrainingCapturePageState extends State<TrainingCapturePage> {
  // Arsitektur menggunakan 'Separation of Concerns' (Pemisahan Tugas).
  // Kamera, MediaPipe (Ekstraksi), dan Machine Learning (Analisis) dipisah ke service independen.
  // Ini membuat kode modular dan sangat mudah di-maintain.
  final CameraService _cameraService = CameraService();
  final MediaPipeService _mediaPipeService = MediaPipeService();
  final PostureAnalysisService _postureService = PostureAnalysisService();

  bool _isCameraReady = false;
  bool _isMediaPipeLoaded = false;
  bool _isDisposed = false;

  int? _currentSessionId;
  int _totalRepetisi = 0;
  int _errorCount = 0;

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

// Menghubungkan Kamera -> MediaPipe -> Classifier
Future<void> _setup() async {
  await _initDatabaseSession();
  await _postureService.initIsolate(); // Inisiasi background thread untuk ML

  // Sambungkan referensi kamera agar adaptive fps bisa bekerja
  _postureService.cameraServiceRef = _cameraService; //v2
  _postureService.currentSessionId = _currentSessionId;

  // EVENT LISTENER 1: Hasil Klasifikasi ML Selesai
  _postureService.onClassificationResult = (result) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _pinnedResult = result;
      _pinnedAt = DateTime.now(); // Memicu penahanan teks feedback selama 3 detik di layar
      _status = result;
      _totalRepetisi++;

      // Kalkulasi rasio error secara real-time untuk penentuan skor akhir nanti
      if (!result.isGood) {
        _errorCount++;
      }
    });
  };

  // EVENT LISTENER 2: Status FSM Berubah (IDLE / ACTIVE)
  _postureService.onStateChanged = (newState) {
    if (_isDisposed) return;
    // Mengubah akurasi ML Kit secara dinamis. 'Accurate' saat mengangkat, 'Base' saat diam.
    _mediaPipeService.switchModel(useAccurate: newState == 'ACTIVE');
  };

  _mediaPipeService.onModelLoaded = (loaded) {
    if (mounted && !_isDisposed) {
      setState(() => _isMediaPipeLoaded = loaded);
    }
  };

  // EVENT LISTENER 3: Aliran Data Keypoint dari MediaPipe
  _mediaPipeService.onKeypointsUpdated = (keypoints) {
    if (mounted && !_isDisposed) {
      // Melempar keypoints ke algoritma Welford dan Gatekeeper
      final newStatus = _postureService.analyzePosture(keypoints);
      setState(() {
        _keypoints = keypoints;
        _status = _getDisplayStatus(newStatus);
      });
    }
  };

  // EVENT LISTENER 4: Kamera Siap
  _cameraService.onCameraStateChanged = (isActive) async {
    if (!mounted || !isActive || _isDisposed) return;
    setState(() => _isCameraReady = true);
    await _mediaPipeService.initialize();

    // Meneruskan buffer byte dari kamera ke ML Kit
    _cameraService.onImageAvailable = (inputImage) {
      _mediaPipeService.processImage(inputImage);
    };

    _mediaPipeService.startDetection();
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

// Fungsi ini dijalankan saat halaman dibuka. 
// Berfungsi merekam awalan sesi ke database SQLite.
Future<void> _initDatabaseSession() async {
    // Buat User Dummy jika kosong
    final db = await SQLiteHelper.instance.database;
    final users = await db.query('users');
    if (users.isEmpty) {
      await SQLiteHelper.instance.insertUser({
        'nama': 'Pengguna',
        'level': 'Pemula',
      });
    }

    // Membuat Sesi Baru
    final sessionId = await SQLiteHelper.instance.insertSession({
      'user_id': 1,
      'tanggal': DateTime.now().toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      'waktu_mulai': DateTime.now().toIso8601String(),
    });

    setState(() {
      _currentSessionId = sessionId;
    });
    print("ID User: $_currentSessionId");
  }

  // Fungsi ini berjalan saat user keluar halaman (Kamera ditutup).
  // Mengkalkulasi SKOR EFEKTIVITAS (Bintang 1-5) berdasarkan rasio gerakan benar vs salah.
  Future<void> _closeDatabaseSession() async {
    if (_currentSessionId != null) {
      double finalScore = 0.0;
      if (_totalRepetisi > 0) {
        int validErrors = _errorCount > _totalRepetisi ? _totalRepetisi : _errorCount;
        int correctReps = _totalRepetisi - validErrors;
        
        finalScore = (correctReps / _totalRepetisi) * 5.0;
      }

      // Mengupdate baris sesi di database
      await SQLiteHelper.instance.updateSession(_currentSessionId!, {
        'waktu_selesai': DateTime.now().toIso8601String(),
        'jumlah_repetisi': _totalRepetisi,
        'rating_efektivitas': double.parse(finalScore.toStringAsFixed(1)) 
      });
      print("Sesi Latihan Ditutup. Total Reps: $_totalRepetisi, Salah: $_errorCount, Skor: $finalScore");
    }
  }

  // UX Mechanism (Terminal Feedback).
  // Teks hasil (misal: "Punggung Bungkuk") di-pin di layar selama 3 detik (_pinDuration)
  PostureStatus _getDisplayStatus(PostureStatus latest) {
    if (_pinnedResult != null && _pinnedAt != null) {
      if (DateTime.now().difference(_pinnedAt!) < _pinDuration) {
        return _pinnedResult!;
      }
      _pinnedResult = null;
    }
    return latest;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _closeDatabaseSession(); // Menutup dan menyimpan sesi DB
    _postureService.dispose(); // Mematikan Isolate Thread ML
    _mediaPipeService.dispose(); // Mematikan model ML Kit
    _cameraService.dispose(); // Melepas sensor kamera
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
          Align(
            alignment: Alignment.bottomCenter,
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
        key: ValueKey(_status.message + _status.explanation),
        width: double.infinity, 
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _status.color.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _status.color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_status.icon, color: _status.color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _status.message.trim(),
                    style: TextStyle(
                      color: _status.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  if (_status.explanation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _status.explanation,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
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

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tombol Reset
                    _buildModernButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      onTap: () {
                        _postureService.reset();
                        setState(() => _status = PostureStatus.standby());
                      },
                    ),
                    
                    // Garis Pemisah (Divider)
                    Container(
                      height: 40,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    
                    // Tombol Panduan (Info Training Page)
                    _buildModernButton(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Panduan',
                      onTap: _showInfoDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
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
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, 
        pageBuilder: (context, animation, secondaryAnimation) => const InfoTrainingPage(isFromTrainingPage: false),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); 
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
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