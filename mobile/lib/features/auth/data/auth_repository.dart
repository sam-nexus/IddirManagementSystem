
import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/core/api/api_exception.dart';
import 'package:odaa_mobile/features/auth/data/models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthResult> login({
    required String phone,
    required String pin,
    required String deviceId,
  }) async {
    try {
      final data = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        body: {
          'phone': phone,
          'pin': pin,
          'device_id': deviceId,
          'platform': 'android',
        },
      );

      final member = data['member'] as Map<String, dynamic>;
      return AuthOk(AuthSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        memberId: member['id'] as String,
        firstName: member['first_name'] as String,
        lastName: member['last_name'] as String,
        mustChangePin: member['must_change_pin'] as bool? ?? false,
      ),);
    } on ApiException catch (e) {
      return AuthErr(_toFailure(e));
    }
  }

  Future<AuthResult> changePin({
    required String accessToken,
    required String currentPin,
    required String newPin,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/change-pin',
        body: {'current_pin': currentPin, 'new_pin': newPin},
      );
      // The backend clears must_change_pin; we don't need the response body.
      return const AuthOk(AuthSession(
        accessToken: '',
        refreshToken: '',
        memberId: '',
        firstName: '',
        lastName: '',
        mustChangePin: false,
      ),);
    } on ApiException catch (e) {
      return AuthErr(_toFailure(e));
    }
  }

  Future<void> logout({String? refreshToken}) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/logout',
        body: refreshToken == null ? null : {'refresh_token': refreshToken},
      );
    } catch (_) {
      // Logout is best-effort on the network side.
    }
  }

  AuthFailure _toFailure(ApiException e) {
    final kind = switch (e.kind) {
      ApiErrorKind.network => AuthError.network,
      ApiErrorKind.unauthorized => AuthError.wrongCredentials,
      ApiErrorKind.forbidden => AuthError.accountSuspended,
      _ => AuthError.unknown,
    };
    // Locked accounts come back as 403 with a "minutes" message.
    if (e.kind == ApiErrorKind.forbidden && e.minutesRemaining != null) {
      return AuthFailure(
        AuthError.accountLocked,
        lockedUntil: DateTime.now().add(Duration(minutes: e.minutesRemaining!)),
      );
    }
    return AuthFailure(kind);
  }
}