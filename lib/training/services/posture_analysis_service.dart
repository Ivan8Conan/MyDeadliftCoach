import '../models/pose_keypoint.dart';
import '../models/posture_status.dart';

class PostureAnalysisService {
  PostureStatus analyzePosture(List<PoseKeypoint> keypoints) {
    if (keypoints.length < 25) {
      return PostureStatus.notDetected();
    }

    try {
      final leftShoulder = keypoints.firstWhere((kp) => kp.name == 'leftShoulder');
      final rightShoulder = keypoints.firstWhere((kp) => kp.name == 'rightShoulder');
      final leftHip = keypoints.firstWhere((kp) => kp.name == 'leftHip');
      final rightHip = keypoints.firstWhere((kp) => kp.name == 'rightHip');
      final nose = keypoints.firstWhere((kp) => kp.name == 'nose');
      
      if (leftShoulder.visibility < 0.5 || rightShoulder.visibility < 0.5 ||
          leftHip.visibility < 0.5 || rightHip.visibility < 0.5) {
        return PostureStatus.notClear();
      }

      final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final hipY = (leftHip.y + rightHip.y) / 2;
      final noseY = nose.y;
      final shoulderSlope = (rightShoulder.y - leftShoulder.y).abs();
      
      bool isHunched = (shoulderY - hipY).abs() > 0.15 || noseY < shoulderY - 0.1;
      bool isAsymmetric = shoulderSlope > 0.08;
      
      if (isHunched) {
        return PostureStatus.hunched();
      } else if (isAsymmetric) {
        return PostureStatus.asymmetric();
      } else {
        return PostureStatus.good();
      }
    } catch (e) {
      print('Error analyzing posture: $e');
      return PostureStatus.error();
    }
  }
}