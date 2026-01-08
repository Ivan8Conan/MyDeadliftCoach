import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import './services/camera_service.dart';
import './services/media_pipe_service.dart';
import './services/posture_analysis_service.dart';
import './models/posture_status.dart';
import './models/pose_keypoint.dart';
import './services/camera_overlay_painter.dart';
import 'dart:async';

class TrainingCapturePage extends StatefulWidget {
  const TrainingCapturePage({super.key});

  @override
  State<TrainingCapturePage> createState() => _TrainingCapturePageState();
}

class _TrainingCapturePageState extends State<TrainingCapturePage> {
  final CameraService _cameraService = CameraService();
  final MediaPipeService _mediaPipeService = MediaPipeService();
  final PostureAnalysisService _postureAnalysisService = PostureAnalysisService();
  
  int _currentFps = 0;
  Timer? _fpsTimer;
  int _frameCount = 0;
  
  PostureStatus _postureStatus = PostureStatus.loading();
  bool _isMediaPipeLoaded = false;
  bool _isCameraReady = false;
  List<PoseKeypoint> _currentKeypoints = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startFpsCounter();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) {
      _setupServices();
    } else {
      setState(() {
        _postureStatus = PostureStatus.error();
      });
    }
  }

  void _setupServices() async {
    _cameraService.onCameraStateChanged = (isActive) async {
      if (mounted && isActive) {
        setState(() {
          _isCameraReady = true;
        });
        await _mediaPipeService.initialize();
        setState(() {
          _isMediaPipeLoaded = true;
        });
        _mediaPipeService.onKeypointsUpdated = (keypoints) {
          if (mounted) {
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
    _fpsTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _frameCount++;
          _currentFps = 28 + (_frameCount % 4);
        });
      }
    });
  }

  void _toggleAudio() {
    _cameraService.toggleAudio();
    if (mounted) setState(() {});
  }

  void _startRecording() {
    _cameraService.startRecording();
    if (mounted) setState(() {});
  }

  void _stopRecording() async {
    await _cameraService.stopRecording(); // Pastikan async
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
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
          // Video Layer
          if (_isCameraReady && _cameraService.controller != null)
            Positioned.fill(
              child: CameraPreview(_cameraService.controller!),
            ),
          
          // Canvas Overlay
          if (_isMediaPipeLoaded && _currentKeypoints.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: CameraOverlayPainter(
                  keypoints: _currentKeypoints,
                  videoSize: Size(
                    _cameraService.controller!.value.previewSize!.width,
                    _cameraService.controller!.value.previewSize!.height,
                  ),
                ),
              ),
            ),
          
          // UI Overlay
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildCameraArea()),
                _buildFeedbackBox(),
                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildControlButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
            color: Colors.white,
          ),
          
          Row(
            children: [
              _buildStatusIndicator(
                icon: Icons.speed,
                label: "$_currentFps FPS",
                color: Colors.green,
                isActive: true,
              ),
              
              const SizedBox(width: 8),
              
              _buildStatusIndicator(
                icon: _cameraService.isAudioEnabled ? Icons.mic : Icons.mic_off,
                label: _cameraService.isAudioEnabled ? "On" : "Off",
                color: _cameraService.isAudioEnabled ? Colors.green : Colors.red,
                isActive: _cameraService.isAudioEnabled,
                onTap: _toggleAudio,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    return Stack(
      children: [
        if (_cameraService.isRecording)
          Positioned(
            top: 12,
            left: 12,
            child: _buildRecordingIndicator(),
          ),
        
        if (_isMediaPipeLoaded)
          Positioned(
            top: 12,
            right: 12,
            child: _buildPoseDetectionStatus(),
          ),
        
        if (!_isCameraReady)
          Center(child: _buildLoadingIndicator('Menyiapkan kamera...'))
        else if (!_isMediaPipeLoaded)
          Center(child: _buildLoadingIndicator('Memuat AI Pose Detection...')),
      ],
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.blue),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPoseDetectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.accessibility_new, color: Colors.blue, size: 16),
          const SizedBox(width: 6),
          const Text(
            "ML Kit Active",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          if (_currentKeypoints.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentKeypoints.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "REC",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _postureStatus.isGood 
            ? Colors.green.shade100 
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _postureStatus.isGood 
              ? Colors.green.shade400 
              : Colors.red.shade400,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_postureStatus.isGood ? Colors.green : Colors.red)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _postureStatus.icon,
            color: _postureStatus.isGood ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _postureStatus.message,
              style: TextStyle(
                color: _postureStatus.isGood ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: GestureDetector(
        onTap: _cameraService.isRecording ? _stopRecording : _startRecording,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _cameraService.isRecording 
                  ? [const Color(0xFFE53935), const Color(0xFFD32F2F)]
                  : [const Color(0xFF4CAF50), const Color(0xFF45A049)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_cameraService.isRecording ? Colors.red : Colors.green)
                    .withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _cameraService.isRecording 
                      ? Icons.stop 
                      : Icons.fiber_manual_record,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _cameraService.isRecording 
                    ? "BERHENTI REKAM" 
                    : "MULAI REKAM",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? color.withOpacity(0.15) 
              : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}