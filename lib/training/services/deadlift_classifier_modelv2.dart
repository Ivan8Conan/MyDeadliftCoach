// Model: GB_EarlyStop
// Akurasi: 86.67%

import 'dart:math';

class DeadliftClassifier {
  // Parameter RobustScaler (Median dan IQR)
  final List<double> _scalerCenter = [137.2956138975967, 26.3417530174139, 81.57, 173.8, 93.405, 112.62809612259113, 42.32618860734979, 48.55500000000001, 178.45499999999998, 128.82, 38.18357744107744, 24.886206951799828, 1.3874136289875065, 0.5609756097560976, 0.3044172932330827, 93.45352427484599, 0.46378233719892953];
  final List<double> _scalerScale = [33.10509074259076, 17.698876818806283, 59.17000000000001, 9.382500000000022, 54.505, 9.051229655425246, 4.331179217275455, 10.175000000000004, 4.719999999999999, 10.107499999999987, 11.736547613913114, 9.448192676783805, 0.9243758997502474, 0.1519951679526147, 0.06767346938775509, 68.60151476284014, 0.0932954227297148];
  
  // Daftar fitur yang harus disuplai (Urutan sama)
  final List<String> requiredFeatures = [
    'lutut_mean',
    'lutut_std',
    'lutut_min',
    'lutut_max',
    'lutut_range',
    'pinggul_mean',
    'pinggul_std',
    'pinggul_min',
    'pinggul_max',
    'pinggul_range',
    'punggung_mean',
    'punggung_std',
    'hip_dominance',
    'back_quality',
    'hip_quality',
    'velocity_std',
    'form_score'
  ];
  
  // Kelas Target
  final List<String> classes = [
    'gerakan_benar',
    'lutut_lebih_jari_kaki',
    'punggung_bungkuk'
  ];

  // Fungsi utama untuk memprediksi
  Map<String, dynamic> predict(Map<String, double> rawFeatures) {
    // 1. Validasi input
    for (var feat in requiredFeatures) {
      if (!rawFeatures.containsKey(feat)) {
        throw Exception('Fitur $feat tidak ditemukan dalam input!');
      }
    }

    // 2. Scaling (RobustScaler: (X - median) / IQR)
    Map<String, double> scaledFeatures = {};
    for (int i = 0; i < requiredFeatures.length; i++) {
      String featName = requiredFeatures[i];
      double val = rawFeatures[featName]!;
      // Pencegahan pembagian dengan nol jika IQR = 0
      double scale = _scalerScale[i] == 0.0 ? 1.0 : _scalerScale[i];
      scaledFeatures[featName] = (val - _scalerCenter[i]) / scale;
    }

    // 3. Evaluasi semua pohon (Gradient Boosting)
    List<double> totalProba = List.filled(classes.length, 0.0);

    // Inisialisasi Prior
    List<double> rawScores = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333];

    // Tahap 0, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_0_0(scaledFeatures)[0];
    // Tahap 0, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_0_1(scaledFeatures)[0];
    // Tahap 0, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_0_2(scaledFeatures)[0];
    // Tahap 1, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_1_0(scaledFeatures)[0];
    // Tahap 1, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_1_1(scaledFeatures)[0];
    // Tahap 1, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_1_2(scaledFeatures)[0];
    // Tahap 2, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_2_0(scaledFeatures)[0];
    // Tahap 2, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_2_1(scaledFeatures)[0];
    // Tahap 2, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_2_2(scaledFeatures)[0];
    // Tahap 3, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_3_0(scaledFeatures)[0];
    // Tahap 3, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_3_1(scaledFeatures)[0];
    // Tahap 3, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_3_2(scaledFeatures)[0];
    // Tahap 4, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_4_0(scaledFeatures)[0];
    // Tahap 4, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_4_1(scaledFeatures)[0];
    // Tahap 4, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_4_2(scaledFeatures)[0];
    // Tahap 5, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_5_0(scaledFeatures)[0];
    // Tahap 5, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_5_1(scaledFeatures)[0];
    // Tahap 5, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_5_2(scaledFeatures)[0];
    // Tahap 6, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_6_0(scaledFeatures)[0];
    // Tahap 6, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_6_1(scaledFeatures)[0];
    // Tahap 6, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_6_2(scaledFeatures)[0];
    // Tahap 7, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_7_0(scaledFeatures)[0];
    // Tahap 7, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_7_1(scaledFeatures)[0];
    // Tahap 7, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_7_2(scaledFeatures)[0];
    // Tahap 8, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_8_0(scaledFeatures)[0];
    // Tahap 8, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_8_1(scaledFeatures)[0];
    // Tahap 8, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_8_2(scaledFeatures)[0];
    // Tahap 9, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_9_0(scaledFeatures)[0];
    // Tahap 9, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_9_1(scaledFeatures)[0];
    // Tahap 9, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_9_2(scaledFeatures)[0];
    // Tahap 10, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_10_0(scaledFeatures)[0];
    // Tahap 10, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_10_1(scaledFeatures)[0];
    // Tahap 10, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_10_2(scaledFeatures)[0];
    // Tahap 11, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_11_0(scaledFeatures)[0];
    // Tahap 11, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_11_1(scaledFeatures)[0];
    // Tahap 11, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_11_2(scaledFeatures)[0];
    // Tahap 12, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_12_0(scaledFeatures)[0];
    // Tahap 12, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_12_1(scaledFeatures)[0];
    // Tahap 12, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_12_2(scaledFeatures)[0];
    // Tahap 13, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_13_0(scaledFeatures)[0];
    // Tahap 13, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_13_1(scaledFeatures)[0];
    // Tahap 13, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_13_2(scaledFeatures)[0];
    // Tahap 14, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_14_0(scaledFeatures)[0];
    // Tahap 14, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_14_1(scaledFeatures)[0];
    // Tahap 14, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_14_2(scaledFeatures)[0];
    // Tahap 15, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_15_0(scaledFeatures)[0];
    // Tahap 15, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_15_1(scaledFeatures)[0];
    // Tahap 15, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_15_2(scaledFeatures)[0];
    // Tahap 16, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_16_0(scaledFeatures)[0];
    // Tahap 16, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_16_1(scaledFeatures)[0];
    // Tahap 16, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_16_2(scaledFeatures)[0];
    // Tahap 17, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_17_0(scaledFeatures)[0];
    // Tahap 17, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_17_1(scaledFeatures)[0];
    // Tahap 17, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_17_2(scaledFeatures)[0];
    // Tahap 18, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_18_0(scaledFeatures)[0];
    // Tahap 18, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_18_1(scaledFeatures)[0];
    // Tahap 18, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_18_2(scaledFeatures)[0];
    // Tahap 19, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_19_0(scaledFeatures)[0];
    // Tahap 19, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_19_1(scaledFeatures)[0];
    // Tahap 19, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_19_2(scaledFeatures)[0];
    // Tahap 20, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_20_0(scaledFeatures)[0];
    // Tahap 20, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_20_1(scaledFeatures)[0];
    // Tahap 20, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_20_2(scaledFeatures)[0];
    // Tahap 21, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_21_0(scaledFeatures)[0];
    // Tahap 21, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_21_1(scaledFeatures)[0];
    // Tahap 21, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_21_2(scaledFeatures)[0];
    // Tahap 22, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_22_0(scaledFeatures)[0];
    // Tahap 22, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_22_1(scaledFeatures)[0];
    // Tahap 22, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_22_2(scaledFeatures)[0];
    // Tahap 23, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_23_0(scaledFeatures)[0];
    // Tahap 23, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_23_1(scaledFeatures)[0];
    // Tahap 23, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_23_2(scaledFeatures)[0];
    // Tahap 24, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_24_0(scaledFeatures)[0];
    // Tahap 24, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_24_1(scaledFeatures)[0];
    // Tahap 24, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_24_2(scaledFeatures)[0];
    // Tahap 25, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_25_0(scaledFeatures)[0];
    // Tahap 25, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_25_1(scaledFeatures)[0];
    // Tahap 25, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_25_2(scaledFeatures)[0];
    // Tahap 26, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_26_0(scaledFeatures)[0];
    // Tahap 26, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_26_1(scaledFeatures)[0];
    // Tahap 26, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_26_2(scaledFeatures)[0];
    // Tahap 27, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_27_0(scaledFeatures)[0];
    // Tahap 27, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_27_1(scaledFeatures)[0];
    // Tahap 27, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_27_2(scaledFeatures)[0];
    // Tahap 28, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_28_0(scaledFeatures)[0];
    // Tahap 28, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_28_1(scaledFeatures)[0];
    // Tahap 28, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_28_2(scaledFeatures)[0];
    // Tahap 29, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_29_0(scaledFeatures)[0];
    // Tahap 29, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_29_1(scaledFeatures)[0];
    // Tahap 29, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_29_2(scaledFeatures)[0];
    // Tahap 30, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_30_0(scaledFeatures)[0];
    // Tahap 30, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_30_1(scaledFeatures)[0];
    // Tahap 30, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_30_2(scaledFeatures)[0];
    // Tahap 31, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_31_0(scaledFeatures)[0];
    // Tahap 31, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_31_1(scaledFeatures)[0];
    // Tahap 31, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_31_2(scaledFeatures)[0];
    // Tahap 32, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_32_0(scaledFeatures)[0];
    // Tahap 32, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_32_1(scaledFeatures)[0];
    // Tahap 32, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_32_2(scaledFeatures)[0];
    // Tahap 33, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_33_0(scaledFeatures)[0];
    // Tahap 33, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_33_1(scaledFeatures)[0];
    // Tahap 33, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_33_2(scaledFeatures)[0];
    // Tahap 34, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_34_0(scaledFeatures)[0];
    // Tahap 34, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_34_1(scaledFeatures)[0];
    // Tahap 34, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_34_2(scaledFeatures)[0];
    // Tahap 35, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_35_0(scaledFeatures)[0];
    // Tahap 35, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_35_1(scaledFeatures)[0];
    // Tahap 35, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_35_2(scaledFeatures)[0];
    // Tahap 36, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_36_0(scaledFeatures)[0];
    // Tahap 36, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_36_1(scaledFeatures)[0];
    // Tahap 36, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_36_2(scaledFeatures)[0];
    // Tahap 37, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_37_0(scaledFeatures)[0];
    // Tahap 37, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_37_1(scaledFeatures)[0];
    // Tahap 37, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_37_2(scaledFeatures)[0];
    // Tahap 38, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_38_0(scaledFeatures)[0];
    // Tahap 38, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_38_1(scaledFeatures)[0];
    // Tahap 38, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_38_2(scaledFeatures)[0];
    // Tahap 39, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_39_0(scaledFeatures)[0];
    // Tahap 39, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_39_1(scaledFeatures)[0];
    // Tahap 39, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_39_2(scaledFeatures)[0];
    // Tahap 40, Kelas 0
    rawScores[0] += 0.05 * _evaluateTree_40_0(scaledFeatures)[0];
    // Tahap 40, Kelas 1
    rawScores[1] += 0.05 * _evaluateTree_40_1(scaledFeatures)[0];
    // Tahap 40, Kelas 2
    rawScores[2] += 0.05 * _evaluateTree_40_2(scaledFeatures)[0];

    // 4. Softmax Function (Mengubah raw score menjadi probabilitas)
    double maxScore = rawScores.reduce(max);
    double sumExp = 0.0;
    for (int i = 0; i < rawScores.length; i++) {
      rawScores[i] = exp(rawScores[i] - maxScore);
      sumExp += rawScores[i];
    }
    
    for (int i = 0; i < rawScores.length; i++) {
      totalProba[i] = rawScores[i] / sumExp;
    }

    // 5. Cari kelas dengan probabilitas tertinggi
    int maxIdx = 0;
    double maxProb = totalProba[0];
    for (int i = 1; i < totalProba.length; i++) {
      if (totalProba[i] > maxProb) {
        maxProb = totalProba[i];
        maxIdx = i;
      }
    }

    return {
      'label': classes[maxIdx],
      'confidence': maxProb,
      'probabilities': totalProba,
    };
  }

  List<double> _evaluateTree_0_0(Map<String, double> features) {
    if (features['lutut_std']! <= -0.614660) {
      return [0.000000];
    } else {
      if (features['pinggul_mean']! <= -0.230258) {
        if (features['velocity_std']! <= 1.318873) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= -0.692802) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_0_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['lutut_std']! <= 0.202054) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['hip_quality']! <= -0.890241) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      return [0.000000];
    }
  }

  List<double> _evaluateTree_0_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.614660) {
      if (features['pinggul_std']! <= -0.302959) {
        return [1.000000];
      } else {
        if (features['hip_quality']! <= 0.161663) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['punggung_mean']! <= 0.391661) {
        return [0.000000];
      } else {
        if (features['pinggul_max']! <= -0.435925) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_1_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.300452) {
      if (features['velocity_std']! <= 2.026865) {
        if (features['lutut_std']! <= 0.454242) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['velocity_std']! <= 3.604891) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.632088) {
        return [0.000000];
      } else {
        if (features['lutut_mean']! <= 0.690151) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_1_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_std']! <= 0.183079) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        return [0.000000];
      }
    } else {
      if (features['lutut_mean']! <= 0.065507) {
        if (features['velocity_std']! <= 1.183564) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_min']! <= 1.371990) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_1_2(Map<String, double> features) {
    if (features['punggung_std']! <= 0.180952) {
      if (features['pinggul_mean']! <= -1.676011) {
        if (features['punggung_mean']! <= -0.384354) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_min']! <= -2.314496) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_std']! <= -0.060163) {
        if (features['velocity_std']! <= 0.819927) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.542762) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_2_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.088776) {
      if (features['velocity_std']! <= 1.265606) {
        if (features['hip_dominance']! <= -0.080451) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['back_quality']! <= 1.791884) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_range']! <= -0.528421) {
        if (features['pinggul_mean']! <= 1.048891) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= -0.410380) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_2_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.480558) {
      if (features['lutut_std']! <= 0.212176) {
        if (features['pinggul_mean']! <= 0.220383) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_std']! <= 0.929561) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['hip_quality']! <= -1.580792) {
        return [1.000000];
      } else {
        if (features['punggung_std']! <= -0.410107) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_2_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['punggung_std']! <= 0.552518) {
        if (features['pinggul_std']! <= -0.244497) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_min']! <= -0.392039) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_min']! <= -0.604360) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.638932) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_3_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.296508) {
      if (features['punggung_std']! <= -0.380457) {
        if (features['pinggul_mean']! <= 0.196924) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.227916) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.671977) {
        return [0.000000];
      } else {
        if (features['lutut_mean']! <= 0.690151) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_3_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.380457) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_std']! <= 0.260339) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_range']! <= 0.149895) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.227916) {
        if (features['punggung_mean']! <= 0.076897) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.557273) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_3_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.227916) {
      if (features['pinggul_mean']! <= -1.870539) {
        if (features['pinggul_mean']! <= -2.099485) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= -0.438979) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_std']! <= -0.060163) {
        if (features['form_score']! <= -0.667139) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.288272) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_4_0(Map<String, double> features) {
    if (features['lutut_std']! <= 0.391125) {
      if (features['lutut_std']! <= -0.609050) {
        if (features['form_score']! <= -0.654159) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -0.435925) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.023384) {
        if (features['velocity_std']! <= 1.486113) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        return [1.000000];
      }
    }
  }

  List<double> _evaluateTree_4_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.410107) {
      if (features['lutut_std']! <= 0.212176) {
        if (features['hip_dominance']! <= -0.087227) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['velocity_std']! <= 1.897195) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= -0.044136) {
        if (features['pinggul_mean']! <= 0.029357) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['form_score']! <= -0.862304) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_4_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.609050) {
      if (features['form_score']! <= -0.654159) {
        if (features['hip_dominance']! <= 1.866601) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.632566) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['punggung_mean']! <= 0.391661) {
        if (features['pinggul_mean']! <= -1.676011) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -0.310925) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_5_0(Map<String, double> features) {
    if (features['lutut_max']! <= 0.622927) {
      if (features['punggung_std']! <= 0.530773) {
        if (features['punggung_std']! <= -0.480558) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.544249) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_max']! <= -1.263523) {
        if (features['lutut_max']! <= 0.646392) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['back_quality']! <= 0.129781) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_5_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.410107) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_std']! <= 0.196164) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= -0.883980) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.180952) {
        if (features['pinggul_mean']! <= 0.029357) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.851121) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_5_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.481421) {
      if (features['punggung_std']! <= 0.530773) {
        if (features['pinggul_max']! <= -1.888771) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.653877) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.765907) {
        if (features['pinggul_max']! <= -1.802966) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.582609) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_6_0(Map<String, double> features) {
    if (features['punggung_std']! <= -0.480558) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['pinggul_max']! <= 0.168595) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        return [1.000000];
      }
    } else {
      if (features['lutut_std']! <= -0.609050) {
        if (features['punggung_mean']! <= 0.834649) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_mean']! <= -0.164218) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_6_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.394273) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['lutut_mean']! <= -0.182051) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_mean']! <= -0.238886) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.337548) {
        if (features['velocity_std']! <= 0.176211) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.557273) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_6_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.377637) {
      if (features['punggung_std']! <= 0.419962) {
        if (features['pinggul_max']! <= -0.343220) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['back_quality']! <= 0.053375) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.737660) {
        if (features['lutut_range']! <= 0.431520) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.650679) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_7_0(Map<String, double> features) {
    if (features['punggung_std']! <= -0.480558) {
      if (features['lutut_std']! <= 0.202054) {
        return [1.000000];
      } else {
        if (features['pinggul_mean']! <= 0.150634) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.377637) {
        if (features['punggung_std']! <= 0.317351) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -2.179837) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_7_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['lutut_std']! <= 0.202054) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['form_score']! <= 0.864588) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.130008) {
        if (features['punggung_std']! <= 0.534721) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.235991) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_7_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.241388) {
      if (features['pinggul_mean']! <= -1.886633) {
        if (features['form_score']! <= -0.301631) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.169067) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.317351) {
        if (features['hip_quality']! <= -0.089841) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_std']! <= 0.508778) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_8_0(Map<String, double> features) {
    if (features['punggung_std']! <= -0.480558) {
      if (features['lutut_std']! <= 0.196164) {
        return [1.000000];
      } else {
        if (features['pinggul_max']! <= 0.272246) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.508306) {
        if (features['punggung_std']! <= 0.552518) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= -1.886633) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_8_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.480558) {
      if (features['lutut_std']! <= 0.196164) {
        return [0.000000];
      } else {
        if (features['lutut_std']! <= 0.260339) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= -0.410107) {
        if (features['back_quality']! <= 0.347295) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.331399) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_8_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['punggung_std']! <= 0.552518) {
        if (features['pinggul_range']! <= -0.903290) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.601299) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.886633) {
        if (features['lutut_max']! <= -0.507726) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.575766) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_9_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.296508) {
      if (features['velocity_std']! <= 1.265606) {
        if (features['pinggul_max']! <= 0.163136) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= -0.532694) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.632088) {
        if (features['pinggul_min']! <= -1.521376) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.690151) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_9_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.483358) {
      if (features['lutut_std']! <= 0.196164) {
        return [0.000000];
      } else {
        if (features['pinggul_mean']! <= 0.196924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= -0.408418) {
        if (features['pinggul_max']! <= -0.009379) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.306179) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_9_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['punggung_mean']! <= 0.189377) {
        if (features['pinggul_range']! <= -0.063814) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['velocity_std']! <= 2.099977) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_min']! <= -0.604360) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_max']! <= -2.197913) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_10_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.300452) {
      if (features['punggung_std']! <= -0.396292) {
        if (features['lutut_std']! <= 0.183079) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.395203) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.632088) {
        if (features['pinggul_min']! <= -1.484053) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.690151) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_10_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['lutut_std']! <= 0.193202) {
        if (features['pinggul_mean']! <= 0.220383) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.368215) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.520977) {
        if (features['pinggul_mean']! <= 0.228862) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= 0.289195) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_10_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['punggung_mean']! <= 0.189377) {
        if (features['hip_dominance']! <= 1.310983) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.405845) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.870539) {
        if (features['lutut_mean']! <= -1.082043) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.653344) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_11_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.296508) {
      if (features['velocity_std']! <= 2.026865) {
        if (features['velocity_std']! <= -0.652138) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= -0.842490) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_range']! <= -0.795226) {
        if (features['pinggul_min']! <= -1.521376) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.690151) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_11_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.251090) {
        if (features['punggung_std']! <= -0.490355) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= 0.672931) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.242168) {
        if (features['lutut_min']! <= 0.312658) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.210116) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_11_2(Map<String, double> features) {
    if (features['punggung_mean']! <= 0.147662) {
      if (features['pinggul_mean']! <= -1.638932) {
        if (features['hip_quality']! <= -0.707166) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['hip_dominance']! <= 0.004402) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['hip_dominance']! <= -0.327780) {
        if (features['pinggul_max']! <= -0.966102) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.316810) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_12_0(Map<String, double> features) {
    if (features['lutut_std']! <= -0.599920) {
      if (features['punggung_std']! <= 0.535294) {
        if (features['back_quality']! <= -0.619940) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_min']! <= -0.123342) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -0.230258) {
        if (features['velocity_std']! <= 1.318873) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= -0.784723) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_12_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.410107) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_std']! <= 0.196164) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= 0.394008) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.331399) {
        if (features['velocity_std']! <= -0.602678) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.619267) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_12_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['punggung_mean']! <= 0.147662) {
        if (features['pinggul_range']! <= -0.383379) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.520977) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.575766) {
        if (features['pinggul_mean']! <= -1.835476) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['form_score']! <= -0.224748) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_13_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.196924) {
      if (features['velocity_std']! <= 1.318873) {
        if (features['lutut_max']! <= 0.645327) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_range']! <= -0.318575) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.632088) {
        if (features['pinggul_std']! <= -0.294759) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.674584) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_13_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.380457) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['punggung_std']! <= -0.488800) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= -0.896372) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.530773) {
        if (features['pinggul_mean']! <= 0.187055) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.220141) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_13_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.431570) {
      if (features['punggung_mean']! <= 0.147662) {
        if (features['back_quality']! <= -0.016422) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['form_score']! <= -0.667662) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_range']! <= 0.431520) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -2.197913) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_14_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.197873) {
      if (features['velocity_std']! <= 1.318873) {
        if (features['velocity_std']! <= -0.587364) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -0.069915) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.671977) {
        if (features['pinggul_mean']! <= 0.920163) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.674584) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_14_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.343615) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['punggung_std']! <= -0.490355) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_mean']! <= -0.205794) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.422513) {
        if (features['velocity_std']! <= -0.602678) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.218135) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_14_2(Map<String, double> features) {
    if (features['punggung_mean']! <= 0.147662) {
      if (features['pinggul_mean']! <= -1.899827) {
        if (features['pinggul_max']! <= -1.489658) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= -0.240712) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.177400) {
        if (features['velocity_std']! <= 0.131496) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.929311) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_15_0(Map<String, double> features) {
    if (features['pinggul_max']! <= 0.115466) {
      if (features['hip_quality']! <= -0.567887) {
        if (features['lutut_std']! <= 0.858941) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['form_score']! <= -0.667662) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= 0.289941) {
        if (features['lutut_std']! <= -0.668304) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['velocity_std']! <= 2.888147) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_15_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.063141) {
        if (features['lutut_std']! <= 0.183079) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= 0.957958) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.530773) {
        if (features['pinggul_mean']! <= 0.187055) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['back_quality']! <= 0.010286) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_15_2(Map<String, double> features) {
    if (features['punggung_std']! <= 0.189984) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['pinggul_std']! <= 0.811905) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.123608) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_mean']! <= 0.129959) {
        if (features['pinggul_std']! <= 0.347883) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['form_score']! <= -0.667662) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_16_0(Map<String, double> features) {
    if (features['pinggul_max']! <= 0.115466) {
      if (features['velocity_std']! <= 2.026865) {
        if (features['pinggul_mean']! <= 0.271665) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= 0.010477) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.671284) {
        if (features['lutut_min']! <= 0.711357) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= -0.483358) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_16_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.410107) {
      if (features['pinggul_mean']! <= 0.251090) {
        if (features['lutut_std']! <= 0.260339) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.425991) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.242168) {
        if (features['pinggul_range']! <= 0.408607) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.630962) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_16_2(Map<String, double> features) {
    if (features['punggung_std']! <= 0.189984) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['velocity_std']! <= 0.373160) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= -0.375579) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['velocity_std']! <= 0.819927) {
        if (features['punggung_mean']! <= 0.147662) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.574324) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_17_0(Map<String, double> features) {
    if (features['pinggul_max']! <= 0.129237) {
      if (features['hip_quality']! <= -0.798854) {
        if (features['lutut_std']! <= 0.859446) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_min']! <= -0.122511) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['hip_dominance']! <= 1.448993) {
        if (features['lutut_std']! <= 0.296437) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_min']! <= 0.741846) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_17_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.022488) {
        if (features['pinggul_max']! <= 0.212924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_max']! <= -0.044231) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= -0.128661) {
        if (features['punggung_std']! <= -0.156688) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.530773) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_17_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.241388) {
      if (features['pinggul_mean']! <= -1.863723) {
        if (features['hip_dominance']! <= -0.322910) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.431790) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_std']! <= -0.062524) {
        if (features['form_score']! <= -0.667662) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_max']! <= 0.100636) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_18_0(Map<String, double> features) {
    if (features['lutut_range']! <= 0.170627) {
      if (features['lutut_std']! <= -0.599920) {
        if (features['hip_quality']! <= 0.001894) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -0.435925) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['velocity_std']! <= 1.379976) {
        if (features['punggung_std']! <= -0.492689) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_min']! <= -1.303363) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_18_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['lutut_std']! <= 0.193202) {
        if (features['pinggul_range']! <= 0.176602) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= -0.488800) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= 0.158370) {
        if (features['punggung_std']! <= -0.096839) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['hip_dominance']! <= -0.175685) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_18_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.599920) {
      if (features['hip_quality']! <= 0.001894) {
        if (features['punggung_mean']! <= 0.786037) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.530539) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_min']! <= -0.654509) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.604498) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_19_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.197873) {
      if (features['lutut_range']! <= -0.958903) {
        return [1.000000];
      } else {
        if (features['velocity_std']! <= 1.318873) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.632088) {
        if (features['pinggul_min']! <= -2.576408) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -1.927966) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_19_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.380457) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['punggung_std']! <= -0.507321) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= 0.394008) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.552518) {
        if (features['pinggul_mean']! <= 0.187055) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.218135) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_19_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.609050) {
      if (features['form_score']! <= -0.654159) {
        if (features['hip_quality']! <= 0.001894) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.624269) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['pinggul_mean']! <= -2.105415) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.604498) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_20_0(Map<String, double> features) {
    if (features['velocity_std']! <= 2.026865) {
      if (features['pinggul_mean']! <= -0.401156) {
        if (features['pinggul_mean']! <= -2.204888) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_std']! <= -0.584069) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['hip_quality']! <= 2.378053) {
        if (features['punggung_std']! <= -0.166037) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        return [1.000000];
      }
    }
  }

  List<double> _evaluateTree_20_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['lutut_std']! <= 0.183079) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_range']! <= 0.316118) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= -0.128661) {
        if (features['back_quality']! <= 0.414818) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.306179) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_20_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.241388) {
      if (features['pinggul_mean']! <= -1.765907) {
        if (features['pinggul_mean']! <= -2.204888) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.131208) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= 0.300452) {
        if (features['lutut_range']! <= -0.958903) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['hip_dominance']! <= 1.410581) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_21_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= -0.224463) {
      if (features['velocity_std']! <= 1.318873) {
        if (features['punggung_std']! <= 0.609618) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= 0.916781) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_min']! <= 0.569723) {
        if (features['punggung_std']! <= -0.704185) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.746030) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_21_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['lutut_std']! <= 0.202054) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= 0.394008) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= -0.097734) {
        if (features['back_quality']! <= 0.640698) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.331399) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_21_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['hip_quality']! <= 2.424964) {
        if (features['punggung_std']! <= 0.544208) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        return [0.000000];
      }
    } else {
      if (features['pinggul_mean']! <= -1.863723) {
        if (features['hip_dominance']! <= -0.322910) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.644285) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_22_0(Map<String, double> features) {
    if (features['velocity_std']! <= 2.099977) {
      if (features['pinggul_mean']! <= -0.070712) {
        if (features['lutut_std']! <= 0.013134) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.187370) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.574324) {
        if (features['back_quality']! <= 0.086631) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        return [1.000000];
      }
    }
  }

  List<double> _evaluateTree_22_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_max']! <= 0.588746) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['form_score']! <= 0.864588) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.306179) {
        if (features['pinggul_mean']! <= 0.291046) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.187370) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_22_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.346320) {
      if (features['punggung_mean']! <= 0.187370) {
        if (features['pinggul_min']! <= 0.624079) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['velocity_std']! <= 2.099977) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.737660) {
        if (features['lutut_mean']! <= -1.082043) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.653344) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_23_0(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['lutut_std']! <= 0.183079) {
        return [1.000000];
      } else {
        if (features['pinggul_mean']! <= 0.196924) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['punggung_mean']! <= 0.260149) {
        if (features['pinggul_mean']! <= -1.835476) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.180952) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_23_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['lutut_std']! <= 0.183079) {
        return [0.000000];
      } else {
        if (features['pinggul_mean']! <= 0.196924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.242168) {
        if (features['pinggul_mean']! <= 0.249410) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['back_quality']! <= -0.000216) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_23_2(Map<String, double> features) {
    if (features['punggung_mean']! <= 0.379003) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['punggung_mean']! <= -0.141336) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.686800) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['form_score']! <= -0.667662) {
        if (features['velocity_std']! <= -0.422255) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['back_quality']! <= -0.073705) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_24_0(Map<String, double> features) {
    if (features['lutut_min']! <= -0.109599) {
      if (features['punggung_std']! <= 0.098697) {
        if (features['velocity_std']! <= 3.564334) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['hip_quality']! <= -1.471002) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.609050) {
        if (features['form_score']! <= -0.654159) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -1.185381) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_24_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.251090) {
        if (features['pinggul_max']! <= 0.272246) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= 0.672931) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= 0.158370) {
        if (features['punggung_mean']! <= 0.841642) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= 0.309767) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_24_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.609050) {
      if (features['form_score']! <= -0.654159) {
        return [0.000000];
      } else {
        if (features['lutut_min']! <= 0.723067) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_max']! <= -0.587924) {
        if (features['punggung_std']! <= -0.065912) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.425112) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_25_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= -0.091393) {
      if (features['velocity_std']! <= 1.318873) {
        if (features['pinggul_max']! <= 0.166476) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['velocity_std']! <= 1.850994) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_min']! <= 0.561949) {
        if (features['pinggul_mean']! <= 0.254700) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.147662) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_25_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.030987) {
        if (features['lutut_std']! <= 0.183079) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= 0.394008) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.295782) {
        if (features['pinggul_mean']! <= 0.244544) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= 0.289195) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_25_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['punggung_mean']! <= 0.147662) {
        if (features['back_quality']! <= 0.025259) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_std']! <= -1.938282) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.863723) {
        if (features['pinggul_max']! <= -1.489658) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_max']! <= -1.994625) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_26_0(Map<String, double> features) {
    if (features['punggung_std']! <= -0.480558) {
      if (features['lutut_std']! <= 0.260339) {
        return [0.000000];
      } else {
        if (features['hip_quality']! <= -1.367662) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.227916) {
        if (features['pinggul_mean']! <= -0.797312) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.177400) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_26_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.251090) {
        if (features['lutut_max']! <= 0.588746) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= 1.013889) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= 0.255983) {
        if (features['lutut_std']! <= -0.481421) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.920163) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_26_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.227916) {
      if (features['pinggul_mean']! <= -1.737660) {
        if (features['lutut_min']! <= -0.604360) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.431790) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['velocity_std']! <= 2.099977) {
        if (features['punggung_std']! <= 0.177400) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= -0.793721) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_27_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.197873) {
      if (features['lutut_range']! <= -0.958903) {
        return [1.000000];
      } else {
        if (features['lutut_max']! <= -0.972022) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.646046) {
        if (features['back_quality']! <= 0.008663) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.690151) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_27_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.343615) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_std']! <= 0.183079) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['back_quality']! <= 1.269729) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.530773) {
        if (features['pinggul_mean']! <= -0.015374) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.220141) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_27_2(Map<String, double> features) {
    if (features['punggung_mean']! <= 0.147662) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_mean']! <= -1.081703) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.178100) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['velocity_std']! <= 1.569156) {
        if (features['back_quality']! <= -0.604995) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_range']! <= -0.736087) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_28_0(Map<String, double> features) {
    if (features['pinggul_min']! <= -0.235485) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['form_score']! <= -0.830597) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= -0.238886) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_std']! <= -0.581208) {
        if (features['velocity_std']! <= 0.678374) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['form_score']! <= -0.252507) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_28_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['pinggul_range']! <= 2.387831) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= -0.896372) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.331399) {
        if (features['back_quality']! <= -0.208063) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['form_score']! <= -0.667662) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_28_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.508306) {
      if (features['pinggul_mean']! <= -0.295406) {
        return [0.000000];
      } else {
        if (features['punggung_mean']! <= 0.129959) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['punggung_mean']! <= -0.384354) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_max']! <= -2.189371) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_29_0(Map<String, double> features) {
    if (features['lutut_std']! <= 0.653720) {
      if (features['hip_quality']! <= -0.643590) {
        if (features['pinggul_mean']! <= 0.254700) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_max']! <= -1.150946) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_max']! <= 0.169654) {
        if (features['hip_quality']! <= -1.367662) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_range']! <= 3.576552) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_29_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.380457) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_std']! <= 0.196164) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['form_score']! <= 0.864588) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -0.136657) {
        if (features['hip_quality']! <= 0.101141) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.557273) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_29_2(Map<String, double> features) {
    if (features['punggung_std']! <= 0.189984) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['punggung_std']! <= -0.292242) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.639488) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['velocity_std']! <= 1.226080) {
        if (features['punggung_std']! <= 0.521097) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.564917) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_30_0(Map<String, double> features) {
    if (features['hip_quality']! <= -0.602346) {
      if (features['lutut_std']! <= 0.653720) {
        if (features['pinggul_mean']! <= 0.254700) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_range']! <= 3.373732) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= 0.740677) {
        if (features['punggung_std']! <= 0.137200) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.709913) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_30_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['lutut_std']! <= 0.193202) {
        if (features['form_score']! <= 0.650384) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.196924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.412605) {
        if (features['punggung_std']! <= -0.322903) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= 0.289195) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_30_2(Map<String, double> features) {
    if (features['punggung_mean']! <= 0.147662) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_min']! <= -0.577184) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_min']! <= 0.312658) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.180952) {
        if (features['back_quality']! <= -0.296674) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_min']! <= -3.695823) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_31_0(Map<String, double> features) {
    if (features['velocity_std']! <= 2.053378) {
      if (features['punggung_std']! <= 0.431141) {
        if (features['lutut_std']! <= 0.214908) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.654943) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_range']! <= -0.844422) {
        return [1.000000];
      } else {
        if (features['pinggul_max']! <= 0.222458) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_31_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.410107) {
      if (features['lutut_std']! <= 0.193202) {
        if (features['lutut_max']! <= -0.326672) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.196924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.410054) {
        if (features['pinggul_mean']! <= 0.203879) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.481092) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_31_2(Map<String, double> features) {
    if (features['punggung_std']! <= 0.431141) {
      if (features['pinggul_min']! <= -0.533038) {
        if (features['pinggul_std']! <= 0.026026) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.269392) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_std']! <= 0.263557) {
        if (features['lutut_std']! <= -0.481092) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.637037) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_32_0(Map<String, double> features) {
    if (features['lutut_std']! <= -0.623790) {
      if (features['form_score']! <= -0.616171) {
        if (features['pinggul_std']! <= 0.217353) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_min']! <= -0.397864) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= 0.197873) {
        if (features['pinggul_max']! <= 0.161017) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= 0.394008) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_32_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.394273) {
      if (features['pinggul_mean']! <= 0.150634) {
        if (features['lutut_std']! <= 0.366332) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= -0.896372) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.331399) {
        if (features['pinggul_mean']! <= 0.244544) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= 0.309767) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_32_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.623790) {
      if (features['pinggul_range']! <= 0.368696) {
        if (features['pinggul_mean']! <= 0.277784) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['back_quality']! <= -0.627796) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.604498) {
        if (features['pinggul_max']! <= -1.369703) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_min']! <= 0.617404) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_33_0(Map<String, double> features) {
    if (features['pinggul_max']! <= 0.113347) {
      if (features['punggung_mean']! <= 0.152746) {
        if (features['lutut_range']! <= 0.196496) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['velocity_std']! <= 0.491510) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= -0.483358) {
        if (features['lutut_max']! <= 0.588746) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.668304) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_33_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['pinggul_mean']! <= 0.251090) {
        if (features['pinggul_max']! <= 0.266520) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['form_score']! <= 0.679617) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_mean']! <= 0.331399) {
        if (features['lutut_max']! <= 0.078337) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.557273) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_33_2(Map<String, double> features) {
    if (features['punggung_std']! <= 0.189984) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['pinggul_mean']! <= -1.895820) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= -0.414985) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_max']! <= 0.100636) {
        if (features['lutut_std']! <= -0.453591) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.668304) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_34_0(Map<String, double> features) {
    if (features['pinggul_mean']! <= 0.196924) {
      if (features['velocity_std']! <= 1.318873) {
        if (features['lutut_max']! <= 0.645327) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['form_score']! <= 1.727873) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.632088) {
        if (features['pinggul_range']! <= 0.028197) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.690151) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_34_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['lutut_std']! <= 0.148001) {
        return [0.000000];
      } else {
        if (features['pinggul_mean']! <= 0.196924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.412605) {
        if (features['pinggul_mean']! <= 0.027128) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['back_quality']! <= -0.039483) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_34_2(Map<String, double> features) {
    if (features['lutut_std']! <= -0.609050) {
      if (features['lutut_std']! <= -0.624269) {
        if (features['lutut_range']! <= -0.832624) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        return [1.000000];
      }
    } else {
      if (features['lutut_mean']! <= 0.690151) {
        if (features['pinggul_mean']! <= -1.835476) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.363444) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_35_0(Map<String, double> features) {
    if (features['velocity_std']! <= 1.318873) {
      if (features['pinggul_mean']! <= -0.338935) {
        if (features['punggung_std']! <= -0.483149) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= -0.295406) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= 0.896417) {
        if (features['pinggul_range']! <= -0.318575) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_std']! <= -1.039290) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_35_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.396292) {
      if (features['hip_dominance']! <= -0.080866) {
        if (features['pinggul_mean']! <= 0.196924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        return [0.000000];
      }
    } else {
      if (features['punggung_std']! <= 0.552518) {
        if (features['pinggul_mean']! <= 0.161519) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= -0.468702) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_35_2(Map<String, double> features) {
    if (features['punggung_std']! <= 0.552518) {
      if (features['hip_dominance']! <= 1.635726) {
        if (features['punggung_mean']! <= 0.545079) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        return [0.000000];
      }
    } else {
      if (features['velocity_std']! <= 3.565002) {
        if (features['punggung_std']! <= 0.792842) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_mean']! <= -0.399672) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_36_0(Map<String, double> features) {
    if (features['pinggul_std']! <= -0.581208) {
      if (features['velocity_std']! <= 1.367629) {
        if (features['velocity_std']! <= 0.396134) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_range']! <= -0.844422) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_range']! <= -0.235868) {
        if (features['lutut_min']! <= 0.898344) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_mean']! <= -0.397972) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_36_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.480558) {
      if (features['lutut_std']! <= 0.148001) {
        return [0.000000];
      } else {
        if (features['pinggul_mean']! <= 0.196924) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= 0.834837) {
        if (features['pinggul_mean']! <= 0.158370) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        return [1.000000];
      }
    }
  }

  List<double> _evaluateTree_36_2(Map<String, double> features) {
    if (features['punggung_mean']! <= 0.145657) {
      if (features['punggung_mean']! <= 0.042241) {
        if (features['pinggul_mean']! <= -1.886633) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_range']! <= 0.039629) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['back_quality']! <= -0.429046) {
        if (features['lutut_range']! <= -0.943491) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['back_quality']! <= -0.223678) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_37_0(Map<String, double> features) {
    if (features['hip_quality']! <= 0.227764) {
      if (features['lutut_min']! <= 0.883894) {
        if (features['pinggul_min']! <= -0.180988) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        return [1.000000];
      }
    } else {
      if (features['velocity_std']! <= 0.780248) {
        if (features['lutut_max']! <= 0.564769) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_mean']! <= 0.595862) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_37_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.410107) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['pinggul_mean']! <= 0.147024) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['back_quality']! <= 1.283599) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= -0.295406) {
        if (features['lutut_max']! <= 0.150280) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_std']! <= 0.243893) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_37_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.227916) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_range']! <= 0.431520) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.397570) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_std']! <= -0.148574) {
        if (features['lutut_std']! <= -0.481092) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_std']! <= -0.118628) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_38_0(Map<String, double> features) {
    if (features['pinggul_min']! <= -0.235485) {
      if (features['pinggul_max']! <= 0.181144) {
        if (features['punggung_std']! <= -0.468979) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_range']! <= 0.784081) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_min']! <= 0.088920) {
        if (features['punggung_mean']! <= 0.449653) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['velocity_std']! <= 1.526640) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_38_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.357431) {
      if (features['pinggul_mean']! <= 0.279889) {
        if (features['punggung_std']! <= -0.492689) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.601444) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['pinggul_mean']! <= 0.002066) {
        if (features['punggung_std']! <= 0.686832) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_std']! <= -0.695493) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_38_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.241388) {
      if (features['pinggul_mean']! <= -1.835476) {
        if (features['lutut_range']! <= 0.564321) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.431790) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['form_score']! <= -0.667662) {
        if (features['velocity_std']! <= -0.319708) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['hip_quality']! <= 2.424964) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_39_0(Map<String, double> features) {
    if (features['pinggul_min']! <= -0.180988) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['form_score']! <= -0.862304) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_range']! <= -0.611137) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['pinggul_std']! <= -0.581208) {
        if (features['velocity_std']! <= 1.414228) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['lutut_min']! <= 0.898344) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_39_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.380457) {
      if (features['pinggul_mean']! <= 0.196924) {
        if (features['lutut_mean']! <= -0.022381) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['back_quality']! <= 1.283599) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_std']! <= -0.267521) {
        if (features['form_score']! <= -0.660045) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_mean']! <= 0.228862) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_39_2(Map<String, double> features) {
    if (features['lutut_mean']! <= 0.241388) {
      if (features['punggung_mean']! <= 0.431790) {
        if (features['pinggul_mean']! <= -1.886633) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['lutut_max']! <= 0.573941) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['form_score']! <= -0.660045) {
        if (features['velocity_std']! <= -0.319708) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_max']! <= -0.069915) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_40_0(Map<String, double> features) {
    if (features['lutut_range']! <= 0.173746) {
      if (features['punggung_std']! <= 0.180952) {
        if (features['punggung_std']! <= -0.407548) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      } else {
        if (features['punggung_mean']! <= 0.147662) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['lutut_max']! <= -1.411138) {
        return [1.000000];
      } else {
        if (features['velocity_std']! <= 3.564334) {
          return [0.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_40_1(Map<String, double> features) {
    if (features['punggung_std']! <= -0.410107) {
      if (features['lutut_std']! <= 0.196164) {
        return [0.000000];
      } else {
        if (features['lutut_std']! <= 0.277874) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    } else {
      if (features['punggung_std']! <= 0.530773) {
        if (features['pinggul_mean']! <= 0.027128) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['pinggul_std']! <= 0.615389) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    }
  }

  List<double> _evaluateTree_40_2(Map<String, double> features) {
    if (features['punggung_mean']! <= 0.147662) {
      if (features['punggung_mean']! <= 0.048279) {
        if (features['pinggul_mean']! <= -1.727168) {
          return [1.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['velocity_std']! <= 0.728443) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      }
    } else {
      if (features['back_quality']! <= -0.443602) {
        if (features['lutut_min']! <= 0.883894) {
          return [0.000000];
        } else {
          return [0.000000];
        }
      } else {
        if (features['hip_dominance']! <= 0.508612) {
          return [1.000000];
        } else {
          return [1.000000];
        }
      }
    }
  }

}
