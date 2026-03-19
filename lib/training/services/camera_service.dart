import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class CameraService {
  CameraController? controller;
  bool isCameraActive = false;
  bool isAudioEnabled = true;
  bool isRecording = false;
  bool _isDisposed = false;
  bool _isStreamActive = false;

  CameraLensDirection lensDirection = CameraLensDirection.front;

  Function(bool)? onCameraStateChanged;
  Function(bool)? onRecordingStateChanged;
  Function(InputImage)? onImageAvailable;

  Future<void> initializeCamera({bool audioEnabled = true}) async {
    if (_isDisposed) return;
    isAudioEnabled = audioEnabled;

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    CameraDescription? selectedCamera;
    try {
      selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      selectedCamera = cameras.first;
    }
    lensDirection = selectedCamera.lensDirection;

    controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: isAudioEnabled,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();
    if (_isDisposed) return;

    isCameraActive = true;
    onCameraStateChanged?.call(true);

    // Mulai image stream ke ML Kit
    await _startImageStream(selectedCamera);
  }

  Future<void> _startImageStream(CameraDescription camera) async {
    if (_isDisposed || controller == null || _isStreamActive) return;
    _isStreamActive = true;

    // Semua frame masuk tanpa filter
    await controller!.startImageStream((CameraImage cameraImage) {
    if (_isDisposed || onImageAvailable == null) return;
      final inputImage = _toInputImage(cameraImage, camera);
    if (inputImage != null) {
    onImageAvailable!.call(inputImage); // langsung kirim
    }
  });
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final rotation = _getRotation(camera.sensorOrientation);

      // Gabungkan semua plane bytes
      final WriteBuffer buffer = WriteBuffer();
      for (final Plane plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      final bytes = buffer.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:   return InputImageRotation.rotation0deg;
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation270deg;
    }
  }

  Future<void> startRecording() async {
    if (controller == null || isRecording || _isDisposed) return;
    if (!controller!.value.isInitialized) return;
    if (controller!.value.isRecordingVideo) return;

    // Stop image stream dulu sebelum recording (Android requirement)
    if (_isStreamActive) {
      await controller!.stopImageStream();
      _isStreamActive = false;
    }

    await controller!.startVideoRecording();
    isRecording = true;
    onRecordingStateChanged?.call(true);
  }

  Future<String?> stopRecording() async {
    if (controller == null || !isRecording || _isDisposed) return null;
    if (!controller!.value.isRecordingVideo) {
      isRecording = false;
      return null;
    }

    final file = await controller!.stopVideoRecording();
    isRecording = false;
    onRecordingStateChanged?.call(false);

    // Resume image stream setelah recording selesai
    if (controller != null && !_isDisposed) {
      final cameras = await availableCameras();
      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == lensDirection,
        orElse: () => cameras.first,
      );
      await _startImageStream(selectedCamera);
    }

    return file.path;
  }

  void dispose() {
    _isDisposed = true;
    try {
      if (controller != null) {
        if (_isStreamActive) controller!.stopImageStream();
        if (controller!.value.isRecordingVideo) controller!.stopVideoRecording();
        controller!.dispose();
      }
    } catch (_) {}
    controller = null;
  }
}