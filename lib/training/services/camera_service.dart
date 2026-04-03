// SUDAH DIOPTIMASI — Versi Final
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
  CameraDescription? _currentCamera;

  Function(bool)? onCameraStateChanged;
  Function(bool)? onRecordingStateChanged;
  Function(InputImage)? onImageAvailable;

  // Adaptive Frame Throttling
  static const _intervalFrameIdle   = Duration(milliseconds: 150); // ±6 FPS
  static const _intervalFrameActive = Duration(milliseconds: 50); // ±20 FPS

  DateTime? _lastFrameTime;
  bool _isGatekeeperActive = false;

  Duration get _currentInterval =>
      _isGatekeeperActive ? _intervalFrameActive : _intervalFrameIdle;

  // Dynamic Resolution
  ResolutionPreset _currentPreset = ResolutionPreset.medium;
  bool _isReinitializing = false;

  // Consecutive Drop Tracking
  int _droppedFrameCount = 0;
  static const _maxDropLog = 50;

  /// Dipanggil dari PostureAnalysisService saat gatekeeper ACTIVE/IDLE
  void setGatekeeperState(bool isActive) {
    _isGatekeeperActive = isActive;
    // Reset last frame time agar interval baru langsung berlaku
    _lastFrameTime = null;
  }

  Future<void> initializeCamera({bool audioEnabled = true}) async {
    if (_isDisposed) return;
    isAudioEnabled = audioEnabled;

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    CameraDescription? selected;
    try {
      selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      selected = cameras.first;
    }
    lensDirection = selected.lensDirection;
    _currentCamera = selected;

    await _buildController(selected, _currentPreset);
  }

  Future<void> _buildController(
    CameraDescription camera,
    ResolutionPreset preset,
  ) async {
    if (_isDisposed) return;

    controller = CameraController(
      camera,
      preset,
      enableAudio: isAudioEnabled,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();
    if (_isDisposed) return;

    isCameraActive = true;
    onCameraStateChanged?.call(true);

    await _startImageStream(camera);
  }

  Future<void> _startImageStream(CameraDescription camera) async {
    if (_isDisposed || controller == null || _isStreamActive) return;
    _isStreamActive = true;
    _droppedFrameCount = 0;

    await controller!.startImageStream((CameraImage cameraImage) {
      if (_isDisposed || onImageAvailable == null) return;

      // Adaptive frame throttling — interval berubah sesuai state gatekeeper
      final now = DateTime.now();
      if (_lastFrameTime != null &&
          now.difference(_lastFrameTime!) < _currentInterval) {
        _droppedFrameCount++;
        if (_droppedFrameCount > _maxDropLog) {
          _droppedFrameCount = 0;
        }
        return;
      }
      _lastFrameTime = now;
      _droppedFrameCount = 0;

      final inputImage = _toInputImage(cameraImage, camera);
      if (inputImage != null) {
        onImageAvailable!.call(inputImage);
      }
    });
  }

  Future<void> adjustResolutionForState(String state) async {
    if (_isDisposed || _isReinitializing || _currentCamera == null) return;
    if (isRecording) return;

    final target =
        state == 'ACTIVE' ? ResolutionPreset.medium : ResolutionPreset.low;

    if (target == _currentPreset) return;
    _currentPreset = target;
    _isReinitializing = true;

    try {
      if (_isStreamActive) {
        await controller?.stopImageStream();
        _isStreamActive = false;
      }
      await controller?.dispose();
      controller = null;
      await _buildController(_currentCamera!, target);
    } catch (e) {
      if (!_isDisposed) {
        _currentPreset = ResolutionPreset.medium;
        await _buildController(_currentCamera!, ResolutionPreset.medium);
      }
    } finally {
      _isReinitializing = false;
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final rotation = _getRotation(camera.sensorOrientation);

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

    if (_currentCamera != null && !_isDisposed) {
      await _startImageStream(_currentCamera!);
    }

    return file.path;
  }

  void dispose() {
    _isDisposed = true;
    try {
      if (controller != null) {
        if (_isStreamActive) controller!.stopImageStream();
        if (controller!.value.isRecordingVideo) {
          controller!.stopVideoRecording();
        }
        controller!.dispose();
      }
    } catch (_) {}
    controller = null;
  }
}









// // SUDAH DIOPTIMASI - V1
// import 'dart:ui';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// class CameraService {
//   CameraController? controller;
//   bool isCameraActive = false;
//   bool isAudioEnabled = true;
//   bool isRecording = false;
//   bool _isDisposed = false;
//   bool _isStreamActive = false;

//   CameraLensDirection lensDirection = CameraLensDirection.front;
//   CameraDescription? _currentCamera;

//   Function(bool)? onCameraStateChanged;
//   Function(bool)? onRecordingStateChanged;
//   Function(InputImage)? onImageAvailable;

//   // FRAME THROTTLING STATIS (V1)
//   DateTime? _lastFrameTime;
//   static const _minFrameInterval = Duration(milliseconds: 80); // Konstan ~12 FPS

//   Future<void> initializeCamera({bool audioEnabled = true}) async {
//     if (_isDisposed) return;
//     isAudioEnabled = audioEnabled;

//     final cameras = await availableCameras();
//     if (cameras.isEmpty) throw Exception('No cameras available');

//     CameraDescription? selected;
//     try {
//       selected = cameras.firstWhere(
//         (c) => c.lensDirection == CameraLensDirection.front,
//       );
//     } catch (_) {
//       selected = cameras.first;
//     }
//     lensDirection = selected.lensDirection;
//     _currentCamera = selected;

//     // Di V1, Resolusi langsung dikunci di Medium (Tidak Dinamis)
//     await _buildController(selected, ResolutionPreset.medium);
//   }

//   Future<void> _buildController(
//     CameraDescription camera,
//     ResolutionPreset preset,
//   ) async {
//     if (_isDisposed) return;

//     controller = CameraController(
//       camera,
//       preset,
//       enableAudio: isAudioEnabled,
//       imageFormatGroup: ImageFormatGroup.yuv420,
//     );

//     await controller!.initialize();
//     if (_isDisposed) return;

//     isCameraActive = true;
//     onCameraStateChanged?.call(true);

//     await _startImageStream(camera);
//   }

//   Future<void> _startImageStream(CameraDescription camera) async {
//     if (_isDisposed || controller == null || _isStreamActive) return;
//     _isStreamActive = true;

//     await controller!.startImageStream((CameraImage cameraImage) {
//       if (_isDisposed || onImageAvailable == null) return;
//       final now = DateTime.now();
//       if (_lastFrameTime != null &&
//           now.difference(_lastFrameTime!) < _minFrameInterval) {
//         return; // Frame diskip / dibuang
//       }
//       _lastFrameTime = now;

//       final inputImage = _toInputImage(cameraImage, camera);
//       if (inputImage != null) {
//         onImageAvailable!.call(inputImage);
//       }
//     });
//   }

//   InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
//     try {
//       final format = InputImageFormatValue.fromRawValue(image.format.raw);
//       if (format == null) return null;

//       final rotation = _getRotation(camera.sensorOrientation);

//       final WriteBuffer buffer = WriteBuffer();
//       for (final Plane plane in image.planes) {
//         buffer.putUint8List(plane.bytes);
//       }
//       final bytes = buffer.done().buffer.asUint8List();

//       return InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           rotation: rotation,
//           format: format,
//           bytesPerRow: image.planes[0].bytesPerRow,
//         ),
//       );
//     } catch (_) {
//       return null;
//     }
//   }

//   InputImageRotation _getRotation(int sensorOrientation) {
//     switch (sensorOrientation) {
//       case 0:   return InputImageRotation.rotation0deg;
//       case 90:  return InputImageRotation.rotation90deg;
//       case 180: return InputImageRotation.rotation180deg;
//       case 270: return InputImageRotation.rotation270deg;
//       default:  return InputImageRotation.rotation270deg;
//     }
//   }

//   Future<void> startRecording() async {
//     if (controller == null || isRecording || _isDisposed) return;
//     if (!controller!.value.isInitialized) return;
//     if (controller!.value.isRecordingVideo) return;

//     if (_isStreamActive) {
//       await controller!.stopImageStream();
//       _isStreamActive = false;
//     }

//     await controller!.startVideoRecording();
//     isRecording = true;
//     onRecordingStateChanged?.call(true);
//   }

//   Future<String?> stopRecording() async {
//     if (controller == null || !isRecording || _isDisposed) return null;
//     if (!controller!.value.isRecordingVideo) {
//       isRecording = false;
//       return null;
//     }

//     final file = await controller!.stopVideoRecording();
//     isRecording = false;
//     onRecordingStateChanged?.call(false);

//     if (_currentCamera != null && !_isDisposed) {
//       await _startImageStream(_currentCamera!);
//     }

//     return file.path;
//   }

//   void dispose() {
//     _isDisposed = true;
//     try {
//       if (controller != null) {
//         if (_isStreamActive) controller!.stopImageStream();
//         if (controller!.value.isRecordingVideo) {
//           controller!.stopVideoRecording();
//         }
//         controller!.dispose();
//       }
//     } catch (_) {}
//     controller = null;
//   }
// }











// // SEBELUM OPTIMASI
// import 'dart:ui';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// class CameraService {
//   CameraController? controller;
//   bool isCameraActive = false;
//   bool isAudioEnabled = true;
//   bool isRecording = false;
//   bool _isDisposed = false;
//   bool _isStreamActive = false;

//   CameraLensDirection lensDirection = CameraLensDirection.front;

//   Function(bool)? onCameraStateChanged;
//   Function(bool)? onRecordingStateChanged;
//   Function(InputImage)? onImageAvailable;

//   Future<void> initializeCamera({bool audioEnabled = true}) async {
//     if (_isDisposed) return;
//     isAudioEnabled = audioEnabled;

//     final cameras = await availableCameras();
//     if (cameras.isEmpty) throw Exception('No cameras available');

//     CameraDescription? selectedCamera;
//     try {
//       selectedCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
//     } catch (_) {
//       selectedCamera = cameras.first;
//     }
//     lensDirection = selectedCamera.lensDirection;

//     controller = CameraController(
//       selectedCamera,
//       ResolutionPreset.high, // UNOPTIMIZED: Paksa resolusi tinggi secara konstan
//       enableAudio: isAudioEnabled,
//       imageFormatGroup: ImageFormatGroup.yuv420,
//     );

//     await controller!.initialize();
//     if (_isDisposed) return;

//     isCameraActive = true;
//     onCameraStateChanged?.call(true);

//     await _startImageStream(selectedCamera);
//   }

//   // Dummy method agar tidak error saat dipanggil dari capture
//   Future<void> adjustResolutionForState(String state) async {}

//   Future<void> _startImageStream(CameraDescription camera) async {
//     if (_isDisposed || controller == null || _isStreamActive) return;
//     _isStreamActive = true;

//     await controller!.startImageStream((CameraImage cameraImage) {
//       if (_isDisposed || onImageAvailable == null) return;
      
//       // UNOPTIMIZED: Kirim semua frame ke ML Kit secepat mungkin tanpa throttle (FPS tidak dibatasi)
//       final inputImage = _toInputImage(cameraImage, camera);
//       if (inputImage != null) {
//         onImageAvailable!.call(inputImage);
//       }
//     });
//   }

//   InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
//     try {
//       final format = InputImageFormatValue.fromRawValue(image.format.raw);
//       if (format == null) return null;
//       final rotation = _getRotation(camera.sensorOrientation);
//       final WriteBuffer buffer = WriteBuffer();
//       for (final Plane plane in image.planes) {
//         buffer.putUint8List(plane.bytes);
//       }
//       final bytes = buffer.done().buffer.asUint8List();
//       return InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           rotation: rotation, format: format, bytesPerRow: image.planes[0].bytesPerRow,
//         ),
//       );
//     } catch (_) {
//       return null;
//     }
//   }

//   InputImageRotation _getRotation(int sensorOrientation) {
//     switch (sensorOrientation) {
//       case 0: return InputImageRotation.rotation0deg;
//       case 90: return InputImageRotation.rotation90deg;
//       case 180: return InputImageRotation.rotation180deg;
//       case 270: return InputImageRotation.rotation270deg;
//       default: return InputImageRotation.rotation270deg;
//     }
//   }

//   Future<void> startRecording() async {
//     if (controller == null || isRecording || _isDisposed) return;
//     if (!controller!.value.isInitialized || controller!.value.isRecordingVideo) return;
//     if (_isStreamActive) {
//       await controller!.stopImageStream();
//       _isStreamActive = false;
//     }
//     await controller!.startVideoRecording();
//     isRecording = true;
//     onRecordingStateChanged?.call(true);
//   }

//   Future<String?> stopRecording() async {
//     if (controller == null || !isRecording || _isDisposed) return null;
//     if (!controller!.value.isRecordingVideo) {
//       isRecording = false;
//       return null;
//     }
//     final file = await controller!.stopVideoRecording();
//     isRecording = false;
//     onRecordingStateChanged?.call(false);
    
//     if (controller != null && !_isDisposed) {
//       final cameras = await availableCameras();
//       final selectedCamera = cameras.firstWhere((c) => c.lensDirection == lensDirection, orElse: () => cameras.first);
//       await _startImageStream(selectedCamera);
//     }
//     return file.path;
//   }

//   void dispose() {
//     _isDisposed = true;
//     try {
//       if (controller != null) {
//         if (_isStreamActive) controller!.stopImageStream();
//         if (controller!.value.isRecordingVideo) controller!.stopVideoRecording();
//         controller!.dispose();
//       }
//     } catch (_) {}
//     controller = null;
//   }
// }