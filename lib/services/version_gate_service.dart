import 'package:firebase_database/firebase_database.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads a server-side minimum-required app version from RTDB and compares
/// it against the running binary. Used to force stale clients (who can
/// still see the champion's ability on the old battle screen) onto the
/// latest release before letting them play.
class VersionGateService {
  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref().child('config/minVersion');

  /// Fetch the required minimum version string (e.g. "1.4.2") from RTDB.
  /// Returns null on error / missing node so the gate defaults to open.
  Future<String?> fetchMinVersion() async {
    try {
      final snapshot = await _ref.get();
      if (!snapshot.exists) return null;
      final v = snapshot.value;
      if (v is String) return v.trim();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// True when [current] is strictly older than [minimum]. Compares dot-
  /// separated integer segments; unparseable segments are treated as 0.
  bool isBelow(String current, String minimum) {
    final cur = _parse(current);
    final min = _parse(minimum);
    final len = cur.length > min.length ? cur.length : min.length;
    for (int i = 0; i < len; i++) {
      final a = i < cur.length ? cur[i] : 0;
      final b = i < min.length ? min[i] : 0;
      if (a < b) return true;
      if (a > b) return false;
    }
    return false;
  }

  List<int> _parse(String v) => v
      .split('.')
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .toList();

  /// Fetch min from RTDB, read local version, and return whether an
  /// update is required. Falls back to "open" on any error.
  Future<bool> requiresUpdate() async {
    final min = await fetchMinVersion();
    if (min == null || min.isEmpty) return false;
    try {
      final info = await PackageInfo.fromPlatform();
      return isBelow(info.version, min);
    } catch (_) {
      return false;
    }
  }
}
