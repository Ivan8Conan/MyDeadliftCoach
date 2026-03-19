import 'dart:math';
import '../models/pose_keypoint.dart';
import '../models/posture_status.dart';
import 'deadlift_classifier_modelv2.dart';

class PostureAnalysisService {
  final DeadliftClassifier _classifier = DeadliftClassifier();

  // Rule-based gatekeeper state
  String _state = 'IDLE';
  List<Map<String, double>> _activeFrames = [];
  int _idleCount = 0;

  static const int _minFrames = 15;
  static const int _idleThreshold = 8;

  // Hasil terakhir dari ML
  String _lastLabel = '';
  double _lastConfidence = 0.0;
  bool _hasNewResult = false;

  // Frame skipping untuk efisiensi
  int _frameCount = 0;
  static const int _frameSkip = 2; // proses 1 dari setiap 2 frame

  // Getter untuk UI
  String get state => _state;
  String get lastLabel => _lastLabel;
  double get lastConfidence => _lastConfidence;

  PostureStatus analyzePosture(List<PoseKeypoint> keypoints) {
    if (keypoints.length < 25) return PostureStatus.notDetected();

    // Frame skipping
    _frameCount++;
    if (_frameCount % _frameSkip != 0) {
      return _buildCurrentStatus();
    }

    try {
      // Hitung sudut sendi
      final angles = _calculateAngles(keypoints);
      if (angles == null) return PostureStatus.notClear();

      // Jalankan gatekeeper
      _processGatekeeper(angles);

      // Return status
      return _buildCurrentStatus();
    } catch (e) {
      return PostureStatus.error();
    }
  }

  /// Rule-based gatekeeper untuk deteksi start/end satu rep
  void _processGatekeeper(Map<String, double> angles) {
    final lutut = angles['lutut']!;
    final pinggul = angles['pinggul']!;

    if (_state == 'IDLE') {
      // Mulai gerakan: lutut mulai menekuk, pinggul turun
      if (lutut < 155 && pinggul < 145) {
        _state = 'ACTIVE';
        _activeFrames = [angles];
        _idleCount = 0;
      }
    } else if (_state == 'ACTIVE') {
      _activeFrames.add(angles);

      // Deteksi akhir rep: kembali ke posisi tegak
      if (lutut > 155 && pinggul > 145) {
        _idleCount++;
        if (_idleCount >= _idleThreshold && _activeFrames.length >= _minFrames) {
          // Rep selesai — jalankan ML
          _runClassification();
          _state = 'IDLE';
          _activeFrames = [];
          _idleCount = 0;
        }
      } else {
        _idleCount = 0;
      }
    }
  }

  /// Jalankan GB classifier pada frames yang terkumpul
  void _runClassification() {
    try {
      final features = _extractFeatures(_activeFrames);
      final result = _classifier.predict(features);
      _lastLabel = result['label'] as String;
      _lastConfidence = result['confidence'] as double;
      _hasNewResult = true;
    } catch (e) {
    }
  }

  /// Ekstrak 17 fitur dari daftar frame (sama persis dengan Python training)
  Map<String, double> _extractFeatures(List<Map<String, double>> frames) {
    final lututs    = frames.map((f) => f['lutut']!).toList();
    final pingguls  = frames.map((f) => f['pinggul']!).toList();
    final punggung  = frames.map((f) => f['punggung']!).toList();

    final frameTime = 1 / 30.0;
    final velocities = <double>[];
    for (int i = 1; i < pingguls.length; i++) {
      velocities.add((pingguls[i] - pingguls[i - 1]) / frameTime);
    }
    if (velocities.isEmpty) velocities.add(0.0);

    final lutut_mean   = _mean(lututs);
    final lutut_std    = _std(lututs);
    final lutut_min    = lututs.reduce(min);
    final lutut_max    = lututs.reduce(max);
    final lutut_range  = lutut_max - lutut_min;

    final pinggul_mean  = _mean(pingguls);
    final pinggul_std   = _std(pingguls);
    final pinggul_min   = pingguls.reduce(min);
    final pinggul_max   = pingguls.reduce(max);
    final pinggul_range = pinggul_max - pinggul_min;

    final punggung_mean = _mean(punggung);
    final punggung_std  = _std(punggung);

    final hip_dominance = pinggul_range / (lutut_range + 1e-6);
    final back_quality  = punggung.where((v) => v < 45).length / punggung.length;
    final hip_quality   = pingguls.where((v) => v > 80 && v < 130).length / pingguls.length;
    final velocity_std  = _std(velocities.map((v) => v.abs()).toList());
    final form_score    = back_quality * 0.6 + hip_quality * 0.4;

    return {
      'lutut_mean':    lutut_mean,
      'lutut_std':     lutut_std,
      'lutut_min':     lutut_min,
      'lutut_max':     lutut_max,
      'lutut_range':   lutut_range,
      'pinggul_mean':  pinggul_mean,
      'pinggul_std':   pinggul_std,
      'pinggul_min':   pinggul_min,
      'pinggul_max':   pinggul_max,
      'pinggul_range': pinggul_range,
      'punggung_mean': punggung_mean,
      'punggung_std':  punggung_std,
      'hip_dominance': hip_dominance,
      'back_quality':  back_quality,
      'hip_quality':   hip_quality,
      'velocity_std':  velocity_std,
      'form_score':    form_score,
    };
  }

  /// Hitung sudut 3 titik dalam derajat
  double _angle3Points(List<double> a, List<double> b, List<double> c) {
    final ba = [a[0] - b[0], a[1] - b[1]];
    final bc = [c[0] - b[0], c[1] - b[1]];
    final dot = ba[0] * bc[0] + ba[1] * bc[1];
    final magBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
    final magBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);
    if (magBA < 1e-6 || magBC < 1e-6) return 0.0;
    return acos((dot / (magBA * magBC)).clamp(-1.0, 1.0)) * 180 / pi;
  }

  /// Sudut punggung terhadap garis vertikal
  double _angleToVertical(List<double> bottom, List<double> top) {
    final dx = (top[0] - bottom[0]).abs();
    final dy = (top[1] - bottom[1]).abs();
    return (atan2(dx, dy + 1e-6) * 180 / pi).clamp(0.0, 90.0);
  }

  Map<String, double>? _calculateAngles(List<PoseKeypoint> keypoints) {
    final kpMap = {for (var kp in keypoints) kp.name: kp};

    final shoulder = kpMap['leftShoulder'];
    final hip      = kpMap['leftHip'];
    final knee     = kpMap['leftKnee'];
    final ankle    = kpMap['leftAnkle'];

    if (shoulder == null || hip == null || knee == null || ankle == null) return null;
    if ([shoulder, hip, knee, ankle].any((kp) => kp.visibility < 0.5)) return null;

    return {
      'lutut':    _angle3Points([ankle.x, ankle.y], [knee.x, knee.y], [hip.x, hip.y]),
      'pinggul':  _angle3Points([shoulder.x, shoulder.y], [hip.x, hip.y], [knee.x, knee.y]),
      'punggung': _angleToVertical([hip.x, hip.y], [shoulder.x, shoulder.y]),
    };
  }

  PostureStatus _buildCurrentStatus() {
    // Tampilkan hasil ML jika ada rep baru selesai
    if (_hasNewResult && _lastLabel.isNotEmpty) {
      _hasNewResult = false;
      return PostureStatus.fromLabel(_lastLabel, _lastConfidence);
    }
    // Tampilkan sedang merekam
    if (_state == 'ACTIVE') {
      return PostureStatus.recording(_activeFrames.length);
    }
    // Standby
    return PostureStatus.standby();
  }

  // Math helpers
  double _mean(List<double> vals) {
    if (vals.isEmpty) return 0.0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double _std(List<double> vals) {
    if (vals.length < 2) return 0.0;
    final m = _mean(vals);
    final variance = vals.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) / vals.length;
    return sqrt(variance);
  }

  void reset() {
    _state = 'IDLE';
    _activeFrames = [];
    _idleCount = 0;
    _hasNewResult = false;
    _lastLabel = '';
    _lastConfidence = 0.0;
  }
}