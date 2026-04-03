// SUDAH DIOPTIMASI - Versi Final
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:async';
import '../models/pose_keypoint.dart';

class MediaPipeService {
  // Pose Detectors
  PoseDetector _detectorBase = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );
  PoseDetector _detectorAccurate = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  // Detektor aktif saat ini
  PoseDetector get _activeDetetor =>
      _useAccurateModel ? _detectorAccurate : _detectorBase;

  bool _useAccurateModel = false;
  bool isPoseDetectionActive = false;
  bool isMediaPipeLoaded = false;
  bool _isProcessing = false;

  /// Counter: bertambah saat visibility rendah, berkurang saat bagus
  int _lowQualityCount = 0;

  /// jika > nilai ini, skip 1 frame berikutnya sebelum coba lagi
  static const _lowQualityThreshold = 5;

  /// Jumlah penalti per frame buruk
  static const _badFramePenalty = 2;

  /// Penalti jika pose tidak terdeteksi sama sekali
  static const _noDetectionPenalty = 3;

  // Consecutive Failure Protection
  int _consecutiveFailures = 0;
  static const _maxConsecutiveFailures = 15;

  // Keypoints
  List<PoseKeypoint> currentKeypoints = [];
  Function(List<PoseKeypoint>)? onKeypointsUpdated;
  Function(bool)? onModelLoaded;

  // Landmark Order
  static const _landmarkOrder = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftEyeInner,
    PoseLandmarkType.leftEye,
    PoseLandmarkType.leftEyeOuter,
    PoseLandmarkType.rightEyeInner,
    PoseLandmarkType.rightEye,
    PoseLandmarkType.rightEyeOuter,
    PoseLandmarkType.leftEar,
    PoseLandmarkType.rightEar,
    PoseLandmarkType.leftMouth,
    PoseLandmarkType.rightMouth,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftPinky,
    PoseLandmarkType.rightPinky,
    PoseLandmarkType.leftIndex,
    PoseLandmarkType.rightIndex,
    PoseLandmarkType.leftThumb,
    PoseLandmarkType.rightThumb,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
    PoseLandmarkType.leftHeel,
    PoseLandmarkType.rightHeel,
    PoseLandmarkType.leftFootIndex,
    PoseLandmarkType.rightFootIndex,
  ];

  static const _keypointNames = [
    'nose', 'leftEyeInner', 'leftEye', 'leftEyeOuter', 'rightEyeInner',
    'rightEye', 'rightEyeOuter', 'leftEar', 'rightEar', 'mouthLeft',
    'mouthRight', 'leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow',
    'leftWrist', 'rightWrist', 'leftPinky', 'rightPinky', 'leftIndex',
    'rightIndex', 'leftThumb', 'rightThumb', 'leftHip', 'rightHip',
    'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle', 'leftHeel',
    'rightHeel', 'leftFootIndex', 'rightFootIndex',
  ];

  Future<void> initialize() async {
    isMediaPipeLoaded = true;
    onModelLoaded?.call(true);
  }

  // Switch Model
  /// Dipanggil dari PostureAnalysisService saat state berubah
  void switchModel({required bool useAccurate}) {
    if (_useAccurateModel == useAccurate) return;
    _useAccurateModel = useAccurate;
    // Reset quality counter saat ganti model
    _lowQualityCount = 0;
    _consecutiveFailures = 0;
  }

  // Main Process
  Future<void> processImage(InputImage image) async {
    if (!isPoseDetectionActive || _isProcessing) return;
    // Jika terlalu banyak frame berkualitas buruk, skip frame ini
    if (_lowQualityCount > _lowQualityThreshold) {
      _lowQualityCount = (_lowQualityCount - 1).clamp(0, 20);
      return;
    }

    _isProcessing = true;

    try {
      final poses = await _activeDetetor.processImage(image);

      if (poses.isNotEmpty) {
        final keypoints = _convertToKeypoints(poses.first);

        // Hitung rata-rata visibility
        final avgVisibility = keypoints.isEmpty
            ? 0.0
            : keypoints
                    .map((k) => k.visibility)
                    .reduce((a, b) => a + b) /
                keypoints.length;

        // Update quality counter
        if (avgVisibility < 0.4) {
          // Frame ada tapi kualitas buruk
          _lowQualityCount =
              (_lowQualityCount + _badFramePenalty).clamp(0, 20);
        } else {
          // Frame bagus — kurangi counter secara gradual
          _lowQualityCount = (_lowQualityCount - 1).clamp(0, 20);
        }

        _consecutiveFailures = 0;
        currentKeypoints = keypoints;
        onKeypointsUpdated?.call(keypoints);
      } else {
        // Tidak ada pose terdeteksi
        _lowQualityCount =
            (_lowQualityCount + _noDetectionPenalty).clamp(0, 20);
        _consecutiveFailures++;

        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          // Terlalu banyak gagal berturut-turut — kirim list kosong & reset
          _consecutiveFailures = 0;
          onKeypointsUpdated?.call([]);
        }
      }
    } catch (e) {
      _consecutiveFailures++;
      onKeypointsUpdated?.call([]);
    } finally {
      _isProcessing = false;
    }
  }

  // Keypoints Converter
  List<PoseKeypoint> _convertToKeypoints(Pose pose) {
    final List<PoseKeypoint> keypoints = [];
    for (int i = 0; i < _landmarkOrder.length; i++) {
      final landmark = pose.landmarks[_landmarkOrder[i]];
      if (landmark != null) {
        keypoints.add(PoseKeypoint(
          name: _keypointNames[i],
          x: landmark.x,
          y: landmark.y,
          z: landmark.z,
          visibility: landmark.likelihood,
        ));
      }
    }
    return keypoints;
  }

  void startDetection() {
    isPoseDetectionActive = true;
    _lowQualityCount = 0;
    _consecutiveFailures = 0;
  }

  void stopDetection() => isPoseDetectionActive = false;

  void dispose() {
    stopDetection();
    _detectorBase.close();
    _detectorAccurate.close();
  }
}






// // SEBELUM OPTIMASI
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
// import 'dart:async';
// import '../models/pose_keypoint.dart';

// class MediaPipeService {
//   // UNOPTIMIZED: Selalu menggunakan model Accurate yang sangat berat
//   final PoseDetector _detector = PoseDetector(
//     options: PoseDetectorOptions(
//       mode: PoseDetectionMode.stream,
//       model: PoseDetectionModel.accurate, 
//     ),
//   );

//   bool isPoseDetectionActive = false;
//   bool isMediaPipeLoaded = false;
//   bool _isProcessing = false;

//   List<PoseKeypoint> currentKeypoints = [];
//   Function(List<PoseKeypoint>)? onKeypointsUpdated;
//   Function(bool)? onModelLoaded;

//   static const _landmarkOrder = [
//     PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye,
//     PoseLandmarkType.leftEyeOuter, PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye,
//     PoseLandmarkType.rightEyeOuter, PoseLandmarkType.leftEar, PoseLandmarkType.rightEar,
//     PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth, PoseLandmarkType.leftShoulder,
//     PoseLandmarkType.rightShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
//     PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist, PoseLandmarkType.leftPinky,
//     PoseLandmarkType.rightPinky, PoseLandmarkType.leftIndex, PoseLandmarkType.rightIndex,
//     PoseLandmarkType.leftThumb, PoseLandmarkType.rightThumb, PoseLandmarkType.leftHip,
//     PoseLandmarkType.rightHip, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
//     PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle, PoseLandmarkType.leftHeel,
//     PoseLandmarkType.rightHeel, PoseLandmarkType.leftFootIndex, PoseLandmarkType.rightFootIndex,
//   ];

//   static const _keypointNames = [
//     'nose', 'leftEyeInner', 'leftEye', 'leftEyeOuter', 'rightEyeInner', 'rightEye',
//     'rightEyeOuter', 'leftEar', 'rightEar', 'mouthLeft', 'mouthRight', 'leftShoulder',
//     'rightShoulder', 'leftElbow', 'rightElbow', 'leftWrist', 'rightWrist', 'leftPinky',
//     'rightPinky', 'leftIndex', 'rightIndex', 'leftThumb', 'rightThumb', 'leftHip',
//     'rightHip', 'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle', 'leftHeel',
//     'rightHeel', 'leftFootIndex', 'rightFootIndex',
//   ];

//   Future<void> initialize() async {
//     isMediaPipeLoaded = true;
//     onModelLoaded?.call(true);
//   }

//   // Dummy method agar tidak error di trainingcapture
//   void switchModel({required bool useAccurate}) {}

//   Future<void> processImage(InputImage image) async {
//     if (!isPoseDetectionActive || _isProcessing) return;
//     _isProcessing = true;

//     // UNOPTIMIZED: Tidak ada filter kualitas frame, proses semua mentah-mentah
//     try {
//       final poses = await _detector.processImage(image);
//       if (poses.isNotEmpty) {
//         currentKeypoints = _convertToKeypoints(poses.first);
//         onKeypointsUpdated?.call(currentKeypoints);
//       } else {
//         onKeypointsUpdated?.call([]);
//       }
//     } catch (e) {
//       onKeypointsUpdated?.call([]);
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   List<PoseKeypoint> _convertToKeypoints(Pose pose) {
//     final List<PoseKeypoint> keypoints = [];
//     for (int i = 0; i < _landmarkOrder.length; i++) {
//       final landmark = pose.landmarks[_landmarkOrder[i]];
//       if (landmark != null) {
//         keypoints.add(PoseKeypoint(
//           name: _keypointNames[i],
//           x: landmark.x, y: landmark.y, z: landmark.z, visibility: landmark.likelihood,
//         ));
//       }
//     }
//     return keypoints;
//   }

//   void startDetection() => isPoseDetectionActive = true;
//   void stopDetection() => isPoseDetectionActive = false;

//   void dispose() {
//     stopDetection();
//     _detector.close();  
//   } 
// }