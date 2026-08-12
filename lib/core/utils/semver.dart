/// Semver helpers for client version enforcement (`1.10.0` > `1.9.0`).
class Semver {
  Semver._();

  /// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
  /// Accepts `1.4.0`, `1.4.0+45`, `v1.4.0`. Build metadata after `+` is ignored.
  static int compare(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    for (var i = 0; i < 3; i++) {
      final c = pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return 0;
  }

  static bool isLessThan(String local, String minVersion) =>
      compare(local, minVersion) < 0;

  static List<int> _parts(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return const [0, 0, 0];
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1).trim();
    }
    final plus = s.indexOf('+');
    if (plus >= 0) s = s.substring(0, plus);
    final paren = s.indexOf('(');
    if (paren >= 0) s = s.substring(0, paren).trim();
    final bits = s.split('.');
    int part(int i) {
      if (i >= bits.length) return 0;
      final m = RegExp(r'^\d+').firstMatch(bits[i].trim());
      return m == null ? 0 : int.tryParse(m.group(0)!) ?? 0;
    }

    return [part(0), part(1), part(2)];
  }
}
