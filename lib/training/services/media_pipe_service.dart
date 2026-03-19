import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:async';
import '../models/pose_keypoint.dart';

class MediaPipeService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  bool isPoseDetectionActive = false;
  bool isMediaPipeLoaded = false;
  bool _isProcessing = false;
  double _lastAvgVisibility = 0.0;
  int _lowQualityCount = 0;

  List<PoseKeypoint> currentKeypoints = [];
  Function(List<PoseKeypoint>)? onKeypointsUpdated;
  Function(bool)? onModelLoaded;

  // Urutan landmark sesuai PoseLandmarkType enum
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

  Future<void> processImage(InputImage image) async {
    if (!isPoseDetectionActive || _isProcessing) return;
    _isProcessing = true;

    try {
      final poses = await _poseDetector.processImage(image);
      if (poses.isNotEmpty) {
        currentKeypoints = _convertToKeypoints(poses.first);
        onKeypointsUpdated?.call(currentKeypoints);
      } else {
        onKeypointsUpdated?.call([]);
      }
    } catch (e) {
      onKeypointsUpdated?.call([]);
    } finally {
      _isProcessing = false;
    }
  }

  List<PoseKeypoint> _convertToKeypoints(Pose pose) {
    final List<PoseKeypoint> keypoints = [];
    // landmarks adalah Map<PoseLandmarkType, PoseLandmark>
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

  void startDetection() => isPoseDetectionActive = true;
  void stopDetection() => isPoseDetectionActive = false;

  void dispose() {
    stopDetection();
    _poseDetector.close();
  }
}