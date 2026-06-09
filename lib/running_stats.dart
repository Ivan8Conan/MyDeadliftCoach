import 'dart:math';

/// Algoritma Welford — O(1) memory, O(1) per update
class RunningStats {
  int _n = 0;
  double _mean = 0;
  double _m2 = 0; // Menyimpan selisih kuadrat untuk varians
  double _min = double.infinity;
  double _max = double.negativeInfinity;

  // Untuk velocity
  double? _prevValue;
  final List<double> _velocities = [];
  double _velocityStd = 0.0;

  // Fungsi ini berjalan setiap ada frame baru.
  // Mencegah Memory Leak karena kita tidak menyimpan List koordinat yang terus memanjang.
  // Memori yang dipakai konstan O(1).
  void update(double x) {
    _n++;
    final delta = x - _mean;
    _mean += delta / _n;
    final delta2 = x - _mean;
    _m2 += delta * delta2;

    if (x < _min) _min = x;
    if (x > _max) _max = x;
  }

  /// Update dengan perhitungan velocity (untuk pinggul)
  void updateWithVelocity(double x, double frameTime) {
    update(x);
    if (_prevValue != null) {
      final vel = (x - _prevValue!).abs() / frameTime;
      _velocities.add(vel);
      // Hitung std velocity secara incremental jika terlalu banyak simpan max 100
      if (_velocities.length > 100) _velocities.removeAt(0);
      _velocityStd = _calcStd(_velocities);
    }
    _prevValue = x;
  }

  double _calcStd(List<double> vals) {
    if (vals.length < 2) return 0.0;
    final m = vals.reduce((a, b) => a + b) / vals.length;
    final variance =
        vals.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) /
            vals.length;
    return sqrt(variance);
  }

  double get mean => _n == 0 ? 0.0 : _mean;
  double get std => _n < 2 ? 0.0 : sqrt(_m2 / _n);
  double get min => _n == 0 ? 0.0 : _min;
  double get max => _n == 0 ? 0.0 : _max;
  double get range => _n == 0 ? 0.0 : (_max - _min);
  double get velocityStd => _velocityStd;
  int get count => _n;

  void reset() {
    _n = 0;
    _mean = 0;
    _m2 = 0;
    _min = double.infinity;
    _max = double.negativeInfinity;
    _prevValue = null;
    _velocities.clear();
    _velocityStd = 0.0;
  }
}