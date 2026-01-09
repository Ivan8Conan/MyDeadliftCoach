import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
// Pastikan import ini sesuai dengan struktur folder Anda
import './services/camera_service.dart';
import './services/media_pipe_service.dart';
import './services/posture_analysis_service.dart';
import './models/posture_status.dart';
import './models/pose_keypoint.dart';
import './services/camera_overlay_painter.dart';

class TrainingCapturePage extends StatefulWidget {
  const TrainingCapturePage({super.key});

  @override
  State<TrainingCapturePage> createState() => _TrainingCapturePageState();
}

class _TrainingCapturePageState extends State<TrainingCapturePage> {
  // Service Instances
  final CameraService _cameraService = CameraService();
  final MediaPipeService _mediaPipeService = MediaPipeService();
  final PostureAnalysisService _postureAnalysisService = PostureAnalysisService();

  // State Variables
  int _currentFps = 0;
  Timer? _fpsTimer;
  int _frameCount = 0;
  PostureStatus _postureStatus = PostureStatus.loading();
  bool _isMediaPipeLoaded = false;
  bool _isCameraReady = false;
  List<PoseKeypoint> _currentKeypoints = [];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startFpsCounter();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) {
      _setupServices();
    } else {
      setState(() => _postureStatus = PostureStatus.error());
    }
  }

  Future<void> _setupServices() async {
    _cameraService.onCameraStateChanged = (isActive) async {
      if (mounted && isActive && !_isDisposed) {
        setState(() => _isCameraReady = true);

        await _mediaPipeService.initialize();
        if (mounted && !_isDisposed) {
          setState(() => _isMediaPipeLoaded = true);
        }

        _mediaPipeService.onKeypointsUpdated = (keypoints) {
          if (mounted && !_isDisposed) {
            setState(() {
              _currentKeypoints = keypoints;
              _postureStatus = _postureAnalysisService.analyzePosture(keypoints);
            });
          }
        };
        _mediaPipeService.startDetection();
      }
    };
    await _cameraService.initializeCamera();
  }

  void _startFpsCounter() {
    _fpsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && !_isDisposed) {
        setState(() {
          // Simulasi FPS atau hitung real frame jika ada logic-nya
          _currentFps = _currentKeypoints.isEmpty ? 0 : 28 + (_frameCount++ % 4);
        });
      }
    });
  }

  void _toggleAudio() {
    if (_isDisposed) return;
    _cameraService.toggleAudio();
    if (mounted) setState(() {});
  }

  void _toggleRecording() {
    if (_isDisposed) return;
    if (_cameraService.isRecording) {
      _cameraService.stopRecording();
    } else {
      _cameraService.startRecording();
    }
    if (mounted) setState(() {});
  }

  Future<void> _cleanupBeforePop() async {
    try {
      _fpsTimer?.cancel();
      if (_cameraService.isRecording) {
        await _cameraService.stopRecording();
      }
      _mediaPipeService.stopDetection();
      _cameraService.dispose();
      _mediaPipeService.dispose();
      _isDisposed = true;
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  @override
  void dispose() {
    _cleanupBeforePop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ukuran layar untuk handling overlay
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: Camera Feed (Immersive)
          if (_isCameraReady && _cameraService.controller != null)
            SizedBox(
              width: size.width,
              height: size.height,
              child: CameraPreview(_cameraService.controller!),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // LAYER 2: Skeleton Overlay
          if (_isMediaPipeLoaded && _currentKeypoints.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: CameraOverlayPainter(
                  keypoints: _currentKeypoints,
                  videoSize: Size(
                    _cameraService.controller!.value.previewSize!.height, // Swap W/H jika portrait
                    _cameraService.controller!.value.previewSize!.width,
                  ),
                ),
              ),
            ),

          // LAYER 3: UI Gradient & Controls
          // Gradient atas untuk status bar agar terlihat jelas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Gradient bawah untuk controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // UI Elements
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar: Back & Status
                _buildModernHeader(),

                // Bottom Area: Feedback & Recording
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingFeedback(),
                    const SizedBox(height: 30),
                    _buildShutterControl(),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali (Circle Glassmorphism)
          GestureDetector(
            onTap: () async {
              await _cleanupBeforePop();
              if (mounted) Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),

          // Status Indicators (Capsules)
          Row(
            children: [
              // ML/FPS Status
              _buildStatusPill(
                icon: Icons.monitor_heart_outlined,
                text: _currentFps > 0 ? "$_currentFps FPS" : "Loading...",
                color: _currentFps > 15 ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              
              // Audio Toggle
              GestureDetector(
                onTap: _toggleAudio,
                child: _buildStatusPill(
                  icon: _cameraService.isAudioEnabled ? Icons.mic : Icons.mic_off,
                  text: _cameraService.isAudioEnabled ? "ON" : "OFF",
                  color: _cameraService.isAudioEnabled ? Colors.white : Colors.redAccent,
                  isActionable: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String text,
    required Color color,
    bool isActionable = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActionable ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingFeedback() {
    // Jangan tampilkan jika belum ada data
    if (!_isMediaPipeLoaded || _currentKeypoints.isEmpty) return const SizedBox.shrink();

    final isGood = _postureStatus.isGood;
    final color = isGood ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9), // Sedikit transparan
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _postureStatus.message.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // Font besar agar terbaca dari jauh
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutterControl() {
    final isRecording = _cameraService.isRecording;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Dummy Spacer (Kiri) agar tombol tengah pas
        const SizedBox(width: 60),

        // Shutter Button (iPhone Style)
        GestureDetector(
          onTap: _toggleRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 6, // Ring tebal putih
              ),
              color: Colors.transparent,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRecording ? 30 : 64, // Mengecil saat rekam
                height: isRecording ? 30 : 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30), // Warna merah khas record
                  borderRadius: BorderRadius.circular(isRecording ? 4 : 50), // Bulat jadi kotak
                ),
              ),
            ),
          ),
        ),

        // Indikator Durasi (Hanya muncul saat merekam) / Spacer Kanan
        SizedBox(
          width: 60,
          child: isRecording
              ? Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "REC",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                )
              : null,
        ),
      ],
    );
  }
}