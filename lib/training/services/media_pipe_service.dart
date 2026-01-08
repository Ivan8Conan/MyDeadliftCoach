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
  
  List<PoseKeypoint> currentKeypoints = [];
  Function(List<PoseKeypoint>)? onKeypointsUpdated;
  Function(bool)? onModelLoaded;

  Future<void> initialize() async {
    isMediaPipeLoaded = true;
    onModelLoaded?.call(true);
    print('ML Kit Pose Detector ready');
  }

  Future<void> processImage(InputImage image) async {
    if (!isPoseDetectionActive || image.bytes == null) {
      onKeypointsUpdated?.call([]);
      return;
    }

    try {
      final poses = await _poseDetector.processImage(image);
      if (poses.isNotEmpty && poses.first.landmarks.isNotEmpty) {
        currentKeypoints = _convertPosesToKeypoints(poses);
        onKeypointsUpdated?.call(currentKeypoints);
      } else {
        onKeypointsUpdated?.call([]);
      }
    } catch (e) {
      print('Error processing image: $e');
      onKeypointsUpdated?.call([]);
    }
  }

  List<PoseKeypoint> _convertPosesToKeypoints(List<Pose> poses) {
    if (poses.isEmpty || poses.first.landmarks.isEmpty) return [];
    
    final pose = poses.first;
    final landmarks = pose.landmarks;
    
    final keypointNames = [
      'nose', 'leftEyeInner', 'leftEye', 'leftEyeOuter', 'rightEyeInner',
      'rightEye', 'rightEyeOuter', 'leftEar', 'rightEar', 'mouthLeft',
      'mouthRight', 'leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow',
      'leftWrist', 'rightWrist', 'leftPinky', 'rightPinky', 'leftIndex',
      'rightIndex', 'leftThumb', 'rightThumb', 'leftHip', 'rightHip',
      'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle', 'leftHeel',
      'rightHeel', 'leftFootIndex', 'rightFootIndex'
    ];

    List<PoseKeypoint> keypoints = [];
    
    for (int i = 0; i < landmarks.length && i < keypointNames.length; i++) {
      final landmark = landmarks[i];
      // FIX: Null check
      if (landmark != null) {
        keypoints.add(PoseKeypoint(
          name: keypointNames[i],
          x: landmark.x,
          y: landmark.y,
          z: landmark.z ?? 0.0,
          visibility: landmark.likelihood,
        ));
      }
    }

    return keypoints;
  }

  void startDetection() {
    isPoseDetectionActive = true;
    print('Pose detection started');
  }

  void stopDetection() {
    isPoseDetectionActive = false;
    print('Pose detection stopped');
  }

  void dispose() {
    stopDetection();
    _poseDetector.close();
    print('MediaPipeService disposed');
  }
}