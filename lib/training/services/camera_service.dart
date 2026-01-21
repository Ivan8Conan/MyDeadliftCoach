import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;
  bool isCameraActive = false;
  bool isAudioEnabled = true;
  bool isRecording = false;
  bool _isDisposed = false;
  
  CameraLensDirection lensDirection = CameraLensDirection.front;

  Function(bool)? onCameraStateChanged;
  Function(bool)? onRecordingStateChanged;

  Future<void> initializeCamera({bool audioEnabled = true}) async {
    if (_isDisposed) return;
    
    isAudioEnabled = audioEnabled;
    
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }
    
    CameraDescription? selectedCamera;
    try {
      selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      selectedCamera = cameras.first;
    }

    lensDirection = selectedCamera.lensDirection;
    
    controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: isAudioEnabled,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller!.initialize();
      if (!_isDisposed) {
        isCameraActive = true;
        onCameraStateChanged?.call(true);
        print('✅ Kamera aktif (${lensDirection == CameraLensDirection.front ? "Depan" : "Belakang"})');
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
      if (!controller!.value.isInitialized) return;
      if (controller!.value.isRecordingVideo) return;
      await controller!.startVideoRecording();
      isRecording = true;
      onRecordingStateChanged?.call(true);
    } catch (e) {
      isRecording = false;
    }
  }

  Future<void> stopRecording() async {
    if (controller == null || !isRecording || _isDisposed) return;
    try {
      if (!controller!.value.isRecordingVideo) {
        isRecording = false;
        return;
      }
      final file = await controller!.stopVideoRecording();
      isRecording = false;
      onRecordingStateChanged?.call(false);
    } catch (e) {
      isRecording = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    try {
      if (controller != null) {
        if (controller!.value.isRecordingVideo) {
          controller!.stopVideoRecording();
        }
        controller!.dispose();
      }
    } catch (e) {}
    controller = null;
  }
}