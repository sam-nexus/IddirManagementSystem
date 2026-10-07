import 'dart:math';

import 'package:odaa_mobile/core/storage/secure_store.dart';

/// Ensures a stable device UUID exists for this install.
/// The backend expects `device_id` on login and refresh calls.
class DeviceIdService {
  DeviceIdService(this._store);

  final SecureStore _store;

  Future<String> getOrCreate() async {
    final existing = await _store.readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _generate();
    await _store.writeDeviceId(id);
    return id;
  }

  String _generate() {
    // A minimal UUIDv4-shaped string. No external package required.
    final r = Random.secure();
    String hex(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
  }
}