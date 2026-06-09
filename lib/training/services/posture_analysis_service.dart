// // SUDAH DIOPTIMASI - V1
// import 'dart:math';
// import 'dart:isolate';
// import 'package:flutter/foundation.dart';
// import '../models/pose_keypoint.dart';
// import '../models/posture_status.dart';
// import 'deadlift_classifier_modelv2.dart';
// import 'package:mydeadliftcouch/running_stats.dart';

// class _IsolateRequest {
//   final Map<String, double> features;
//   _IsolateRequest(this.features);
// }

// class _IsolateResponse {
//   final String label;
//   final double confidence;
//   _IsolateResponse(this.label, this.confidence);
// }

// /// Entry point untuk isolate GB classifier
// void _classifierIsolateEntry(SendPort mainSendPort) {
//   final classifier = DeadliftClassifier();
//   final receivePort = ReceivePort();

//   // Kirim port ke main thread
//   mainSendPort.send(receivePort.sendPort);

//   receivePort.listen((message) {
//     if (message is _IsolateRequest) {
//       try {
//         final result = classifier.predict(message.features);
//         mainSendPort.send(_IsolateResponse(
//           result['label'] as String,
//           result['confidence'] as double,
//         ));
//       } catch (e) {
//         mainSendPort.send(_IsolateResponse('', 0.0));
//       }
//     }
//   });
// }

// class PostureAnalysisService {
//   Isolate? _classifierIsolate;
//   SendPort? _classifierSendPort;
//   ReceivePort? _classifierReceivePort;
//   bool _isolateReady = false;
//   bool _classifierBusy = false;

//   /// Dipanggil saat hasil klasifikasi tersedia dari isolate
//   Function(PostureStatus)? onClassificationResult;

//   /// Dipanggil saat state gatekeeper berubah (untuk CameraService & MediaPipeService)
//   Function(String)? onStateChanged;

//   // Gatekeeper State
//   String _state = 'IDLE';
//   int _idleCount = 0;
//   int _activeFrameCount = 0;

//   // static const int _minFrames = 15; // v1
//   static const int _minFrames = 20; // V2
//   static const int _idleThreshold = 8;

//   // Running Stats (ganti List<Map>)
//   final RunningStats _lututStats = RunningStats();
//   final RunningStats _pinggulStats = RunningStats();
//   final RunningStats _punggungStats = RunningStats();

//   // Frame time untuk velocity (asumsi 30fps)
//   static const double _frameTime = 1 / 30.0;

//   // Adaptive Threshold
//   final List<double> _baselineLutut = [];
//   final List<double> _baselinePinggul = [];
//   static const _baselineWindow = 30;
//   bool _isCalibrated = false;

//   double _lututThreshold = 155.0;
//   double _pinggulThreshold = 145.0;

//   // Hasil ML
//   String _lastLabel = '';
//   double _lastConfidence = 0.0;
//   bool _hasNewResult = false;

//   // Frame Skipping
//   int _frameCount = 0;
//   static const int _frameSkip = 2;

//   // Getters
//   String get state => _state;
//   String get lastLabel => _lastLabel;
//   double get lastConfidence => _lastConfidence;
//   bool get isCalibrated => _isCalibrated;

//   Future<void> initIsolate() async {
//     _classifierReceivePort = ReceivePort();

//     _classifierIsolate = await Isolate.spawn(
//       _classifierIsolateEntry,
//       _classifierReceivePort!.sendPort,
//     );

//     // Terima SendPort dari isolate
//     _classifierReceivePort!.listen((message) {
//       if (message is SendPort) {
//         // Isolate siap, simpan send port-nya
//         _classifierSendPort = message;
//         _isolateReady = true;
//       } else if (message is _IsolateResponse) {
//         // Terima hasil klasifikasi
//         _classifierBusy = false;
//         if (message.label.isNotEmpty) {
//           _lastLabel = message.label;
//           _lastConfidence = message.confidence;
//           _hasNewResult = true;

//           // Langsung emit ke UI via callback
//           final status = PostureStatus.fromLabel(message.label, message.confidence);
//           onClassificationResult?.call(status);
//         }
//       }
//     });
//   }

//   // /// Analisis postur per frame v1
//   // PostureStatus analyzePosture(List<PoseKeypoint> keypoints) {
//   // if (keypoints.length < 25) return PostureStatus.notDetected();

//   // // Frame skipping — kurangi CPU saat IDLE
//   // _frameCount++;
//   // if (_state == 'IDLE' && _frameCount % _frameSkip != 0) {
//   //   return _buildCurrentStatus();
//   // }

//   // try {
//   //   final angles = _calculateAngles(keypoints);
//   //   if (angles == null) return PostureStatus.notClear();
//   //   // Update baseline adaptif
//   //     _updateBaseline(angles);
//   //   // Jalankan gatekeeper
//   //     _processGatekeeper(angles);

//   //     return _buildCurrentStatus();
//   //   } catch (e) {
//   //     return PostureStatus.error();
//   //   }
//   // }

//   // v2
//   PostureStatus analyzePosture(List<PoseKeypoint> keypoints) {
//     if (keypoints.length < 25) return PostureStatus.notDetected();
//     _frameCount++;
//     if (_state == 'IDLE') {
//       if (!_isCalibrated) {
//         // No Frame Skipping saat kalibrasi untuk pengumpulan data
//       } else {
//         // Setelah kalibrasi selesai, baru aktifkan frame skipping
//         if (_frameCount % _frameSkip != 0) {
//           return _buildCurrentStatus();
//         }
//       }
//     }

//     try {
//       final angles = _calculateAngles(keypoints);
//       if (angles == null) return PostureStatus.notClear();

//       // Update baseline adaptif
//       _updateBaseline(angles);

//       // Jalankan gatekeeper
//       _processGatekeeper(angles);

//       return _buildCurrentStatus();
//     } catch (e) {
//       return PostureStatus.error();
//     }
//   }

//   // Kalibrasi threshold dari posisi berdiri pengguna
//   void _updateBaseline(Map<String, double> angles) {
//     // Hanya update saat IDLE (posisi berdiri tegak / standby)
//     if (_state != 'IDLE') return;

//     _baselineLutut.add(angles['lutut']!);
//     _baselinePinggul.add(angles['pinggul']!);

//     // Sliding window — buang data lama
//     if (_baselineLutut.length > _baselineWindow) {
//       _baselineLutut.removeAt(0);
//       _baselinePinggul.removeAt(0);
//     }

//     // Kalibrasi setelah window penuh
//     if (_baselineLutut.length >= _baselineWindow) {
//       final meanLutut =
//           _baselineLutut.reduce((a, b) => a + b) / _baselineLutut.length;
//       final meanPinggul =
//           _baselinePinggul.reduce((a, b) => a + b) / _baselinePinggul.length;

//       // Threshold = 88% dari posisi tegak
//       _lututThreshold = meanLutut * 0.88;
//       _pinggulThreshold = meanPinggul * 0.88;
//       _isCalibrated = true;
//     }
//   }

//   // GATEKEEPER — deteksi start/end satu repetisi
//   void _processGatekeeper(Map<String, double> angles) {
//     final lutut = angles['lutut']!;
//     final pinggul = angles['pinggul']!;

//     // Gunakan adaptive threshold jika sudah kalibrasi
//     final lututThresh = _isCalibrated ? _lututThreshold : 155.0;
//     final pinggulThresh = _isCalibrated ? _pinggulThreshold : 145.0;

//     if (_state == 'IDLE') {
//       // Deteksi mulai gerakan: lutut & pinggul turun dari threshold
//       if (lutut < lututThresh && pinggul < pinggulThresh) {
//         _state = 'ACTIVE';
//         _activeFrameCount = 0;
//         _idleCount = 0;

//         // Reset running stats untuk rep baru
//         _lututStats.reset();
//         _pinggulStats.reset();
//         _punggungStats.reset();

//         // Switch ke accurate model saat ACTIVE
//         onStateChanged?.call('ACTIVE');
//       }
//     } else if (_state == 'ACTIVE') {
//       // Akumulasi data menggunakan running stats — O(1) memory
//       _lututStats.update(lutut);
//       _pinggulStats.updateWithVelocity(pinggul, _frameTime);
//       _punggungStats.update(angles['punggung']!);
//       _activeFrameCount++;

//       // Deteksi akhir rep: kembali ke posisi tegak
//       if (lutut > lututThresh && pinggul > pinggulThresh) {
//         _idleCount++;
//         if (_idleCount >= _idleThreshold && _activeFrameCount >= _minFrames) {
//           // Rep selesai — kirim ke GB classifier via isolate
//           _runClassificationIsolate();
//           _state = 'IDLE';
//           _activeFrameCount = 0;
//           _idleCount = 0;

//           // Switch kembali ke base model
//           onStateChanged?.call('IDLE');
//         }
//       } else {
//         _idleCount = 0;
//       }
//     }
//   }

//   // CLASSIFICATION — kirim fitur ke isolate GB classifier
//   void _runClassificationIsolate() {
//     if (!_isolateReady || _classifierBusy || _classifierSendPort == null) {
//       // Fallback: jalankan di main thread jika isolate belum siap
//       _runClassificationSync();
//       return;
//     }

//     final features = _extractFeaturesFromStats();
//     _classifierBusy = true;
//     _classifierSendPort!.send(_IsolateRequest(features));
//   }

//   /// Fallback synchronous classification (dijalankan jika isolate belum ready)
//   void _runClassificationSync() {
//     try {
//       final features = _extractFeaturesFromStats();
//       final classifier = DeadliftClassifier();
//       final result = classifier.predict(features);
//       _lastLabel = result['label'] as String;
//       _lastConfidence = result['confidence'] as double;
//       _hasNewResult = true;
//     } catch (_) {}
//   }

//   // FITUR EKSTRAKSI dari running stats O(1)
//   Map<String, double> _extractFeaturesFromStats() {
//     // Quality metrics dari running stats
//     // back_quality: fraksi frame di mana sudut punggung < 45 derajat
//     // Tidak bisa dihitung dari RunningStats langsung, perlu approximation
//     // Gunakan: jika punggung_mean < 45 → asumsi back_quality tinggi
//     final backQualityApprox =
//         _punggungStats.mean < 45.0 ? 1.0 : (90.0 - _punggungStats.mean) / 45.0;
//     final backQualityClamped = backQualityApprox.clamp(0.0, 1.0);

//     // hip_quality: fraksi frame di mana 80 < pinggul < 130
//     final hipQualityApprox =
//         (_pinggulStats.mean > 80 && _pinggulStats.mean < 130) ? 0.8 : 0.3;

//     final hipDominance =
//         _pinggulStats.range / (_lututStats.range + 1e-6);

//     final formScore = backQualityClamped * 0.6 + hipQualityApprox * 0.4;

//     return {
//       'lutut_mean':    _lututStats.mean,
//       'lutut_std':     _lututStats.std,
//       'lutut_min':     _lututStats.min,
//       'lutut_max':     _lututStats.max,
//       'lutut_range':   _lututStats.range,
//       'pinggul_mean':  _pinggulStats.mean,
//       'pinggul_std':   _pinggulStats.std,
//       'pinggul_min':   _pinggulStats.min,
//       'pinggul_max':   _pinggulStats.max,
//       'pinggul_range': _pinggulStats.range,
//       'punggung_mean': _punggungStats.mean,
//       'punggung_std':  _punggungStats.std,
//       'hip_dominance': hipDominance,
//       'back_quality':  backQualityClamped,
//       'hip_quality':   hipQualityApprox,
//       'velocity_std':  _pinggulStats.velocityStd,
//       'form_score':    formScore,
//     };
//   }

//   // KALKULASI SUDUT
//   double _angle3Points(List<double> a, List<double> b, List<double> c) {
//     final ba = [a[0] - b[0], a[1] - b[1]];
//     final bc = [c[0] - b[0], c[1] - b[1]];
//     final dot = ba[0] * bc[0] + ba[1] * bc[1];
//     final magBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
//     final magBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);
//     if (magBA < 1e-6 || magBC < 1e-6) return 0.0;
//     return acos((dot / (magBA * magBC)).clamp(-1.0, 1.0)) * 180 / pi;
//   }

//   double _angleToVertical(List<double> bottom, List<double> top) {
//     final dx = (top[0] - bottom[0]).abs();
//     final dy = (top[1] - bottom[1]).abs();
//     return (atan2(dx, dy + 1e-6) * 180 / pi).clamp(0.0, 90.0);
//   }

//   Map<String, double>? _calculateAngles(List<PoseKeypoint> keypoints) {
//     final kpMap = {for (var kp in keypoints) kp.name: kp};

//     final shoulder = kpMap['leftShoulder'];
//     final hip      = kpMap['leftHip'];
//     final knee     = kpMap['leftKnee'];
//     final ankle    = kpMap['leftAnkle'];

//     if (shoulder == null || hip == null || knee == null || ankle == null) {
//       return null;
//     }
//     if ([shoulder, hip, knee, ankle].any((kp) => kp.visibility < 0.5)) {
//       return null;
//     }

//     return {
//       'lutut': _angle3Points(
//         [ankle.x, ankle.y],
//         [knee.x, knee.y],
//         [hip.x, hip.y],
//       ),
//       'pinggul': _angle3Points(
//         [shoulder.x, shoulder.y],
//         [hip.x, hip.y],
//         [knee.x, knee.y],
//       ),
//       'punggung': _angleToVertical(
//         [hip.x, hip.y],
//         [shoulder.x, shoulder.y],
//       ),
//     };
//   }

//   // BUILD STATUS untuk UI
//   PostureStatus _buildCurrentStatus() {
//     // Tampilkan hasil ML jika ada rep baru selesai (dari sync fallback)
//     if (_hasNewResult && _lastLabel.isNotEmpty) {
//       _hasNewResult = false;
//       return PostureStatus.fromLabel(_lastLabel, _lastConfidence);
//     }
//     // Sedang merekam
//     if (_state == 'ACTIVE') {
//       return PostureStatus.recording(_activeFrameCount);
//     }
//     // Standby — tampilkan info kalibrasi jika belum selesai
//     if (!_isCalibrated) {
//       return PostureStatus.calibrating(_baselineLutut.length, _baselineWindow);
//     }
//     return PostureStatus.standby();
//   }

//   // RESET & DISPOSE
//   void reset() {
//     _state = 'IDLE';
//     _activeFrameCount = 0;
//     _idleCount = 0;
//     _hasNewResult = false;
//     _lastLabel = '';
//     _lastConfidence = 0.0;
//     _lututStats.reset();
//     _pinggulStats.reset();
//     _punggungStats.reset();
//     onStateChanged?.call('IDLE');
//   }

//   /// Reset kalibrasi — berguna jika pengguna berganti
//   void resetCalibration() {
//     _baselineLutut.clear();
//     _baselinePinggul.clear();
//     _isCalibrated = false;
//     _lututThreshold = 155.0;
//     _pinggulThreshold = 145.0;
//   }

//   void dispose() {
//     _classifierIsolate?.kill(priority: Isolate.immediate);
//     _classifierReceivePort?.close();
//     _classifierIsolate = null;
//     _classifierSendPort = null;
//     _isolateReady = false;
//   }
// }






// SUDAH DIOPTIMASI - VERSI FINAL
import 'dart:math';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/pose_keypoint.dart';
import '../models/posture_status.dart';
import 'deadlift_classifier_modelv2.dart';
import 'package:MyDeadliftCoach/running_stats.dart';
import 'camera_service.dart';
import '../database/sqlite_helper.dart';

class _IsolateRequest {
  final Map<String, double> features;
  _IsolateRequest(this.features);
}

class _IsolateResponse {
  final String label;
  final double confidence;
  _IsolateResponse(this.label, this.confidence);
}


// Fungsi ini berjalan secara asinkron di BACKGROUND THREAD.
  // Mencegah HP nge-lag/freeze (Main UI Thread tetap mulus di 60 FPS) saat mengeksekusi ratusan if-else klasifikasi ML
void _classifierIsolateEntry(SendPort mainSendPort) {
  final classifier = DeadliftClassifier();
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is _IsolateRequest) {
      // Melakukan prediksi ML, lalu mengirim hasilnya kembali ke UI Utama lewat Port.
      try {
        final result = classifier.predict(message.features);
        mainSendPort.send(_IsolateResponse(
          result['label'] as String,
          result['confidence'] as double,
        ));
      } catch (e) {
        mainSendPort.send(_IsolateResponse('', 0.0));
      }
    }
  });
}

class PostureAnalysisService {
  Isolate? _classifierIsolate;
  SendPort? _classifierSendPort;
  ReceivePort? _classifierReceivePort;
  bool _isolateReady = false;
  bool _classifierBusy = false;
  int? currentSessionId;

  // Referensi ke CameraService untuk adaptive fps
  // Diset dari luar sebelum digunakan
  CameraService? cameraServiceRef;

  Function(PostureStatus)? onClassificationResult;
  Function(String)? onStateChanged;

  // Gatekeeper State
  String _state = 'IDLE';
  int _idleCount = 0;
  int _activeFrameCount = 0;

  String _activeSide = 'left'; // Penambahan terbaru

  static const int _minFrames = 20;
  static const int _idleThreshold = 8;

  // Frame skip — HANYA aktif saat IDLE dan SUDAH kalibrasi
  int _frameCount = 0;
  static const int _frameSkip = 2;

  // Running Stats (Welford O(1))
  final RunningStats _lututStats = RunningStats();
  final RunningStats _pinggulStats = RunningStats();
  final RunningStats _punggungStats = RunningStats();

  static const double _frameTime = 1 / 20.0; // disesuaikan dengan ~20fps ACTIVE

  // Adaptive Threshold
  final List<double> _baselineLutut = [];
  final List<double> _baselinePinggul = [];
  static const _baselineWindow = 30;
  bool _isCalibrated = false;

  double _lututThreshold = 155.0;
  double _pinggulThreshold = 145.0;

  // Inisialisasi Flutter TTS
  final FlutterTts _flutterTts = FlutterTts();

  // Hasil ML
  String _lastLabel = '';
  double _lastConfidence = 0.0;
  bool _hasNewResult = false;

  // Getters
  String get state => _state;
  String get lastLabel => _lastLabel;
  double get lastConfidence => _lastConfidence;
  bool get isCalibrated => _isCalibrated;

  Future<void> initIsolate() async {
    _classifierReceivePort = ReceivePort();
    _classifierIsolate = await Isolate.spawn(
      _classifierIsolateEntry,
      _classifierReceivePort!.sendPort,
    );

    _classifierReceivePort!.listen((message) {
      if (message is SendPort) {
        _classifierSendPort = message;
        _isolateReady = true;
      } else if (message is _IsolateResponse) {
        _classifierBusy = false;
        if (message.label.isNotEmpty) {
          _lastLabel = message.label;
          _lastConfidence = message.confidence;
          _hasNewResult = true;

          final status = PostureStatus.fromLabel(message.label, message.confidence);
          onClassificationResult?.call(status);
          _executeFeedback(_lastLabel);
        }
      }
    });
  }

  PostureStatus analyzePosture(List<PoseKeypoint> keypoints) {
    if (keypoints.length < 25) return PostureStatus.notDetected();
    _frameCount++;
    // Skip HANYA jika: state IDLE AND sudah kalibrasi
    if (_state == 'IDLE' && _isCalibrated && _frameCount % _frameSkip != 0) {
      return _buildCurrentStatus();
    }

    try {
      final angles = _calculateAngles(keypoints);
      if (angles == null) return PostureStatus.notClear();
      _updateBaseline(angles);
      _processGatekeeper(angles);
      return _buildCurrentStatus();
    } catch (e) {
      return PostureStatus.error();
    }
  }

  // FASE KALIBRASI: MENGHITUNG ADAPTIVE THRESHOLD (Bukan Hardcoded)
  void _updateBaseline(Map<String, double> angles) {
    if (_state != 'IDLE') return;
    _baselineLutut.add(angles['lutut']!);
    _baselinePinggul.add(angles['pinggul']!);

    // Menahan memori hanya untuk 30 frame terakhir saat berdiri tegak (Sliding Window)
    if (_baselineLutut.length > _baselineWindow) {
      _baselineLutut.removeAt(0);
      _baselinePinggul.removeAt(0);
    }

    // Jika kalibrasi selesai, hitung RATA-RATA sudut, lalu dikali 0.88 (88%).
    // Ini memastikan threshold disesuaikan dengan postur berdiri pengguna dengan proporsi tubuh berbeda
    if (_baselineLutut.length >= _baselineWindow) {
      final meanLutut =
          _baselineLutut.reduce((a, b) => a + b) / _baselineLutut.length;
      final meanPinggul =
          _baselinePinggul.reduce((a, b) => a + b) / _baselinePinggul.length;
      _lututThreshold  = meanLutut  * 0.88;
      _pinggulThreshold = meanPinggul * 0.88;
      _isCalibrated = true;
    }
  }

  // GATEKEEPER — deteksi start/end satu repetisi
  void _processGatekeeper(Map<String, double> angles) {
    final lutut   = angles['lutut']!;
    final pinggul = angles['pinggul']!;

    final lututThresh  = _isCalibrated ? _lututThreshold  : 155.0;
    final pinggulThresh = _isCalibrated ? _pinggulThreshold : 145.0;

    // Jika posisi tubuh ditekuk melewati batas 88% (Threshold)
    if (_state == 'IDLE') {
      if (lutut < lututThresh && pinggul < pinggulThresh) {
        _state = 'ACTIVE';
        _activeFrameCount = 0;
        _idleCount = 0;
        _lututStats.reset();
        _pinggulStats.reset();
        _punggungStats.reset();

        // Beritahu kamera untuk naik ke ~20fps agar gerakan ditangkap dengan detail
        cameraServiceRef?.setGatekeeperState(true);
        onStateChanged?.call('ACTIVE');
      }
    } else if (_state == 'ACTIVE') {
      // Saat bergerak, terus update nilai Welford (Mean & Std)
      _lututStats.update(lutut);
      _pinggulStats.updateWithVelocity(pinggul, _frameTime);
      _punggungStats.update(angles['punggung']!);
      _activeFrameCount++;

      // Jika user berdiri tegak lagi (melewati ambang batas ke atas)
      if (lutut > lututThresh && pinggul > pinggulThresh) {
        _idleCount++;
        if (_idleCount >= _idleThreshold && _activeFrameCount >= _minFrames) {
          _runClassificationIsolate(); // Panggil Klasifikasi ML
          _state = 'IDLE'; // Reset state ke IDLE untuk tunggu rep berikutnya
          _activeFrameCount = 0;
          _idleCount = 0;

          // Kembalikan kamera ke ~6fps untuk efisiensi
          cameraServiceRef?.setGatekeeperState(false);
          onStateChanged?.call('IDLE');
        }
      } else {
        _idleCount = 0;
      }
    }
  }

  void _runClassificationIsolate() {
    if (!_isolateReady || _classifierBusy || _classifierSendPort == null) {
      _runClassificationSync();
      return;
    }
    final features = _extractFeaturesFromStats();
    _classifierBusy = true;
    _classifierSendPort!.send(_IsolateRequest(features));
  }

  void _runClassificationSync() {
    try {
      final features = _extractFeaturesFromStats();
      final classifier = DeadliftClassifier();
      final result = classifier.predict(features);

      _lastLabel     = result['label'] as String;
      _lastConfidence = result['confidence'] as double;
      _hasNewResult  = true;

      _executeFeedback(_lastLabel);
    } catch (_) {}
  }

  Future<void> _executeFeedback(String label) async {
    final statusObj = PostureStatus.fromLabel(label, _lastConfidence);
    
    if (statusObj.explanation.isNotEmpty) {
      // Eksekusi Suara Indonesia (TTS)
      try {
        await _flutterTts.setLanguage("id-ID");
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setPitch(1.0);
        await _flutterTts.speak(statusObj.explanation);
        
        print("${statusObj.explanation}");
      } catch (e) {
        print("TTS Error: $e");
      }
      
      // Sinkronisasi Database SQLite
      if (currentSessionId != null) {
        try {
          await SQLiteHelper.instance.insertErrorLog({
            'session_id': currentSessionId,
            'kode_error': statusObj.errorId,
            'nama_error': statusObj.message.trim(),
            'risiko': statusObj.isGood ? 'Aman' : 'Tinggi',
            'pesan_teks': statusObj.explanation,
            'is_played': 1,
          });
          print("Berhasil menyimpan log feedback!");
        } catch (e) {
          print("Gagal menyimpan database: $e");
        }
      }
    }
  }

  Map<String, double> _extractFeaturesFromStats() {
    final backQualityApprox = _punggungStats.mean < 45.0
        ? 1.0
        : (90.0 - _punggungStats.mean) / 45.0;
    final backQualityClamped = backQualityApprox.clamp(0.0, 1.0);
    final hipQualityApprox =
        (_pinggulStats.mean > 80 && _pinggulStats.mean < 130) ? 0.8 : 0.3;
    final hipDominance =
        _pinggulStats.range / (_lututStats.range + 1e-6);
    final formScore = backQualityClamped * 0.6 + hipQualityApprox * 0.4;
    return {
      'lutut_mean':    _lututStats.mean,
      'lutut_std':     _lututStats.std,
      'lutut_min':     _lututStats.min,
      'lutut_max':     _lututStats.max,
      'lutut_range':   _lututStats.range,
      'pinggul_mean':  _pinggulStats.mean,
      'pinggul_std':   _pinggulStats.std,
      'pinggul_min':   _pinggulStats.min,
      'pinggul_max':   _pinggulStats.max,
      'pinggul_range': _pinggulStats.range,
      'punggung_mean': _punggungStats.mean,
      'punggung_std':  _punggungStats.std,
      'hip_dominance': hipDominance,
      'back_quality':  backQualityClamped,
      'hip_quality':   hipQualityApprox,
      'velocity_std':  _pinggulStats.velocityStd,
      'form_score':    formScore,
    };
  }

  double _angle3Points(List<double> a, List<double> b, List<double> c) {
    final ba = [a[0] - b[0], a[1] - b[1]];
    final bc = [c[0] - b[0], c[1] - b[1]];
    final dot  = ba[0] * bc[0] + ba[1] * bc[1];
    final magBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
    final magBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);
    if (magBA < 1e-6 || magBC < 1e-6) return 0.0;
    return acos((dot / (magBA * magBC)).clamp(-1.0, 1.0)) * 180 / pi;
  }

  double _angleToVertical(List<double> bottom, List<double> top) {
    final dx = (top[0] - bottom[0]).abs();
    final dy = (top[1] - bottom[1]).abs();
    return (atan2(dx, dy + 1e-6) * 180 / pi).clamp(0.0, 90.0);
  } // Penambahan terbaru

Map<String, double>? _calculateAngles(List<PoseKeypoint> keypoints) {
    final kpMap = {for (var kp in keypoints) kp.name: kp};
    final lShoulder = kpMap['leftShoulder'];
    final lHip      = kpMap['leftHip'];
    final lKnee     = kpMap['leftKnee'];
    final lAnkle    = kpMap['leftAnkle'];

    final rShoulder = kpMap['rightShoulder'];
    final rHip      = kpMap['rightHip'];
    final rKnee     = kpMap['rightKnee'];
    final rAnkle    = kpMap['rightAnkle'];

    final leftVis  = _avgVisibility([lShoulder, lHip, lKnee, lAnkle]);
    final rightVis = _avgVisibility([rShoulder, rHip, rKnee, rAnkle]);

    // KUNCI SISI TUBUH: Hanya boleh evaluasi dan ganti sisi saat sedang IDLE (diam/bersiap)
    // Saat ACTIVE (sedang mengangkat), sisi tubuh dikunci agar koordinat tidak loncat-loncat
    if (_state == 'IDLE') {
      _activeSide = leftVis >= rightVis ? 'left' : 'right';
    }

    // Gunakan sisi yang sedang dikunci
    final shoulder = _activeSide == 'left' ? lShoulder : rShoulder;
    final hip      = _activeSide == 'left' ? lHip      : rHip;
    final knee     = _activeSide == 'left' ? lKnee     : rKnee;
    final ankle    = _activeSide == 'left' ? lAnkle    : rAnkle;

    if (shoulder == null || hip == null || knee == null || ankle == null) {
      return null;
    }

    if ([shoulder, hip, knee, ankle].any((kp) => kp.visibility < 0.4)) {
      return null;
    }

    return {
      'lutut': _angle3Points(
        [ankle.x, ankle.y], [knee.x, knee.y], [hip.x, hip.y],
      ),
      'pinggul': _angle3Points(
        [shoulder.x, shoulder.y], [hip.x, hip.y], [knee.x, knee.y],
      ),
      'punggung': _angleToVertical(
        [hip.x, hip.y], [shoulder.x, shoulder.y],
      ),
    };
  }

// Helper baru — tambahkan sebagai method di kelas yang sama
double _avgVisibility(List<PoseKeypoint?> kps) {
  final valid = kps.whereType<PoseKeypoint>().toList();
  if (valid.isEmpty) return 0.0;
  return valid.map((k) => k.visibility).reduce((a, b) => a + b) / valid.length;
}

  PostureStatus _buildCurrentStatus() {
    if (_hasNewResult && _lastLabel.isNotEmpty) {
      _hasNewResult = false;
      return PostureStatus.fromLabel(_lastLabel, _lastConfidence);
    }
    if (_state == 'ACTIVE') {
      return PostureStatus.recording(_activeFrameCount);
    }
    if (!_isCalibrated) {
      return PostureStatus.calibrating(
          _baselineLutut.length, _baselineWindow);
    }
    return PostureStatus.standby();
  }

  void reset() {
    _state = 'IDLE';
    _activeFrameCount = 0;
    _idleCount = 0;
    _hasNewResult = false;
    _lastLabel = '';
    _lastConfidence = 0.0;
    _lututStats.reset();
    _pinggulStats.reset();
    _punggungStats.reset();
    cameraServiceRef?.setGatekeeperState(false);
    onStateChanged?.call('IDLE');
  }

  void resetCalibration() {
    _baselineLutut.clear();
    _baselinePinggul.clear();
    _isCalibrated = false;
    _lututThreshold  = 155.0;
    _pinggulThreshold = 145.0;
  }

  void dispose() {
    _classifierIsolate?.kill(priority: Isolate.immediate);
    _classifierReceivePort?.close();
    _classifierIsolate = null;
    _classifierSendPort = null;
    _isolateReady = false;
  }
}


















// // SEBELUM OPTIMASI
// import 'dart:math';
// import '../models/pose_keypoint.dart';
// import '../models/posture_status.dart';
// import 'deadlift_classifier_modelv2.dart';

// class PostureAnalysisService {
//   // UNOPTIMIZED: ML Model di Main Thread (Bukan Isolate)
//   final DeadliftClassifier _classifier = DeadliftClassifier();

//   Function(PostureStatus)? onClassificationResult;
//   Function(String)? onStateChanged;

//   String _state = 'ACTIVE'; // UNOPTIMIZED: Selalu aktif agar memproses ML setiap saat
  
//   // Menggunakan List memori biasa, bukan Welford algorithm
//   final List<Map<String, double>> _frameBuffer = [];
//   static const int _windowSize = 30; // Simpan 30 frame terakhir untuk klasifikasi

//   String _lastLabel = '';
//   double _lastConfidence = 0.0;

//   String get state => _state;
//   bool get isCalibrated => true; // Bypass kalibrasi
  
//   // Dummy method agar UI tidak error
//   Future<void> initIsolate() async {}

//   PostureStatus analyzePosture(List<PoseKeypoint> keypoints) {
//     if (keypoints.length < 25) return PostureStatus.notDetected();

//     try {
//       final angles = _calculateAngles(keypoints);
//       if (angles == null) return PostureStatus.notClear();

//       // UNOPTIMIZED: Masukkan data ke buffer di SETIAP FRAME tanpa ada Frame Skipping (_frameSkip = 1)
//       _frameBuffer.add(angles);
//       if (_frameBuffer.length > _windowSize) {
//         _frameBuffer.removeAt(0); // O(N) operation membuang elemen pertama
//       }

//       // UNOPTIMIZED: EKSEKUSI MACHINE LEARNING DI SETIAP FRAME!
//       // Ini akan menyiksa CPU karena menghitung mean, std, min, max dari list berulang-ulang
//       if (_frameBuffer.length >= 15) {
//          _runClassificationSync();
//       }

//       return _buildCurrentStatus();
//     } catch (e) {
//       return PostureStatus.error();
//     }
//   }

//   void _runClassificationSync() {
//     try {
//       final features = _extractFeatures(_frameBuffer);
//       final result = _classifier.predict(features); // Eksekusi ratusan if-else di main thread
      
//       _lastLabel = result['label'] as String;
//       _lastConfidence = result['confidence'] as double;

//       // Beritahu UI
//       onClassificationResult?.call(PostureStatus.fromLabel(_lastLabel, _lastConfidence));
//     } catch (_) {}
//   }

//   // UNOPTIMIZED: Loop berulang-ulang untuk menghitung array mentah setiap 33ms
//   Map<String, double> _extractFeatures(List<Map<String, double>> frames) {
//     final lututs = frames.map((f) => f['lutut']!).toList();
//     final pingguls = frames.map((f) => f['pinggul']!).toList();
//     final punggung = frames.map((f) => f['punggung']!).toList();

//     final velocities = <double>[];
//     for (int i = 1; i < pingguls.length; i++) {
//       velocities.add((pingguls[i] - pingguls[i - 1]) / (1/30.0));
//     }
//     if (velocities.isEmpty) velocities.add(0.0);

//     final lutut_min = lututs.reduce(min);
//     final lutut_max = lututs.reduce(max);
//     final pinggul_min = pingguls.reduce(min);
//     final pinggul_max = pingguls.reduce(max);
    
//     final lutut_range = lutut_max - lutut_min;
//     final pinggul_range = pinggul_max - pinggul_min;

//     final back_quality = punggung.where((v) => v < 45).length / punggung.length;
//     final hip_quality = pingguls.where((v) => v > 80 && v < 130).length / pingguls.length;

//     return {
//       'lutut_mean': _mean(lututs),
//       'lutut_std': _std(lututs),
//       'lutut_min': lutut_min,
//       'lutut_max': lutut_max,
//       'lutut_range': lutut_range,
//       'pinggul_mean': _mean(pingguls),
//       'pinggul_std': _std(pingguls),
//       'pinggul_min': pinggul_min,
//       'pinggul_max': pinggul_max,
//       'pinggul_range': pinggul_range,
//       'punggung_mean': _mean(punggung),
//       'punggung_std': _std(punggung),
//       'hip_dominance': pinggul_range / (lutut_range + 1e-6),
//       'back_quality': back_quality,
//       'hip_quality': hip_quality,
//       'velocity_std': _std(velocities.map((v) => v.abs()).toList()),
//       'form_score': back_quality * 0.6 + hip_quality * 0.4,
//     };
//   }

//   double _angle3Points(List<double> a, List<double> b, List<double> c) {
//     final ba = [a[0] - b[0], a[1] - b[1]];
//     final bc = [c[0] - b[0], c[1] - b[1]];
//     final dot = ba[0] * bc[0] + ba[1] * bc[1];
//     final magBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
//     final magBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);
//     if (magBA < 1e-6 || magBC < 1e-6) return 0.0;
//     return acos((dot / (magBA * magBC)).clamp(-1.0, 1.0)) * 180 / pi;
//   }

//   double _angleToVertical(List<double> bottom, List<double> top) {
//     final dx = (top[0] - bottom[0]).abs();
//     final dy = (top[1] - bottom[1]).abs();
//     return (atan2(dx, dy + 1e-6) * 180 / pi).clamp(0.0, 90.0);
//   }

//   Map<String, double>? _calculateAngles(List<PoseKeypoint> keypoints) {
//     final kpMap = {for (var kp in keypoints) kp.name: kp};
//     final shoulder = kpMap['leftShoulder'];
//     final hip = kpMap['leftHip'];
//     final knee = kpMap['leftKnee'];
//     final ankle = kpMap['leftAnkle'];

//     if (shoulder == null || hip == null || knee == null || ankle == null) return null;
//     if ([shoulder, hip, knee, ankle].any((kp) => kp.visibility < 0.5)) return null;

//     return {
//       'lutut': _angle3Points([ankle.x, ankle.y], [knee.x, knee.y], [hip.x, hip.y]),
//       'pinggul': _angle3Points([shoulder.x, shoulder.y], [hip.x, hip.y], [knee.x, knee.y]),
//       'punggung': _angleToVertical([hip.x, hip.y], [shoulder.x, shoulder.y]),
//     };
//   }

//   PostureStatus _buildCurrentStatus() {
//     if (_lastLabel.isNotEmpty) {
//       return PostureStatus.fromLabel(_lastLabel, _lastConfidence);
//     }
//     return PostureStatus.recording(_frameBuffer.length);
//   }

//   double _mean(List<double> vals) {
//     if (vals.isEmpty) return 0.0;
//     return vals.reduce((a, b) => a + b) / vals.length;
//   }

//   double _std(List<double> vals) {
//     if (vals.length < 2) return 0.0;
//     final m = _mean(vals);
//     final variance = vals.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) / vals.length;
//     return sqrt(variance);
//   }

//   void reset() {
//     _frameBuffer.clear();
//     _lastLabel = '';
//     _lastConfidence = 0.0;
//   }

//   void dispose() {}
//   void resetCalibration() {}
// }