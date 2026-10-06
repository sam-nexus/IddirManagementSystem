import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage.
/// Used for tokens, PINs, device IDs — anything sensitive.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kDeviceId = 'device_id';

  // ---------- Access token ----------
  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);
  Future<void> writeAccessToken(String value) =>
      _storage.write(key: _kAccessToken, value: value);
  Future<void> deleteAccessToken() => _storage.delete(key: _kAccessToken);

  // ---------- Refresh token ----------
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<void> writeRefreshToken(String value) =>
      _storage.write(key: _kRefreshToken, value: value);
  Future<void> deleteRefreshToken() => _storage.delete(key: _kRefreshToken);

  // ---------- Device ID ----------
  Future<String?> readDeviceId() => _storage.read(key: _kDeviceId);
  Future<void> writeDeviceId(String value) =>
      _storage.write(key: _kDeviceId, value: value);

  /// Wipe everything (used on logout or PIN reset).
  Future<void> clearAll() => _storage.deleteAll();
}