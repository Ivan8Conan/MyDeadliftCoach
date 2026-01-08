import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;
  bool isCameraActive = false;
  bool isAudioEnabled = true;
  bool isRecording = false;
  bool _isDisposed = false;
  
  Function(bool)? onCameraStateChanged;
  Function(bool)? onRecordingStateChanged;

  Future<void> initializeCamera({bool audioEnabled = true}) async {
    if (_isDisposed) return;
    
    isAudioEnabled = audioEnabled;
    
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }
    
    controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: isAudioEnabled,
    );

    try {
      await controller!.initialize();
      if (!_isDisposed) {
        isCameraActive = true;
        onCameraStateChanged?.call(true);
        print('✅ Kamera aktif');
      }
    } catch (e) {
      if (!_isDisposed) {
        print("❌ Error accessing camera: $e");
        isCameraActive = false;
        onCameraStateChanged?.call(false);
        rethrow;
      }
    }
  }

  void toggleAudio() {
    if (controller == null || _isDisposed) return;
    isAudioEnabled = !isAudioEnabled;
  }

  Future<void> startRecording() async {
    if (controller == null || isRecording || _isDisposed) return;
    
    try {
      // Validasi state kamera
      if (!controller!.value.isInitialized) {
        print('❌ Camera not initialized');
        return;
      }
      
      if (controller!.value.isRecordingVideo) {
        print('❌ Already recording');
        return;
      }
      
      await controller!.startVideoRecording();
      isRecording = true;
      onRecordingStateChanged?.call(true);
      print('▶️ Mulai merekam');
    } catch (e) {
      print('❌ Error starting recording: $e');
      isRecording = false;
    }
  }

  Future<void> stopRecording() async {
    if (controller == null || !isRecording || _isDisposed) return;
    
    try {
      // Validasi state recording
      if (!controller!.value.isRecordingVideo) {
        print('❌ Not currently recording');
        isRecording = false;
        return;
      }
      
      // Tunggu sebentar agar recording stabil
      await Future.delayed(const Duration(milliseconds: 100));
      
      final file = await controller!.stopVideoRecording();
      isRecording = false;
      onRecordingStateChanged?.call(false);
      print('⏹️ Rekaman selesai: ${file.path}');
    } catch (e) {
      print('❌ Error stopping recording: $e');
      isRecording = false;
      // Recovery: reset kamera jika error
      if (!_isDisposed) {
        await controller?.dispose();
        controller = null;
        isCameraActive = false;
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    controller?.dispose();
    controller = null;
    print('🗑️ Camera service disposed');
  }
}