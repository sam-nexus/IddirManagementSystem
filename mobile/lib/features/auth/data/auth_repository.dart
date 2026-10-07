import 'package:odaa_mobile/features/auth/data/models/auth_models.dart';

/// Contract for the auth API. The real implementation will wrap Dio calls
/// to the backend. For now, a mock drives the UI so screens can be built.
abstract interface class AuthRepository {
  Future<AuthResult> login({
    required String phone,
    required String pin,
    required String deviceId,
  });

  Future<AuthResult> changePin({
    required String accessToken,
    required String currentPin,
    required String newPin,
  });

  Future<void> logout();
}

/// In-memory mock. Simulates network latency and the failure modes we need
/// to design for: wrong PIN, locked account, unknown phone, network drop.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  // A tiny state machine to make testing the lockout easy:
  // three wrong PINs in a row triggers a 15-minute lock.
  int _wrongAttempts = 0;
  DateTime? _lockedUntil;

  @override
  Future<AuthResult> login({
    required String phone,
    required String pin,
    required String deviceId,
  }) async {
    // Simulate network
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // Active lock check
    if (_lockedUntil != null && _lockedUntil!.isAfter(DateTime.now())) {
      return AuthErr(
          AuthFailure(AuthError.accountLocked, lockedUntil: _lockedUntil),);
    }

    // Normalize (accept 09..., 9..., +2519...)
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      return const AuthErr(AuthFailure(AuthError.unknownPhone));
    }

    // Simulate a server-side account suspended by the committee
    if (normalized == '+251900000000') {
      return const AuthErr(AuthFailure(AuthError.accountSuspended));
    }

    // Simulate an unknown phone
    if (normalized != '+251911223344' && normalized != '+251922334455') {
      return const AuthErr(AuthFailure(AuthError.unknownPhone));
    }

    // Correct PIN for both test numbers
    const correctPin = '1234';

    if (pin != correctPin) {
      _wrongAttempts += 1;
      if (_wrongAttempts >= 3) {
        _lockedUntil = DateTime.now().add(const Duration(minutes: 15));
        _wrongAttempts = 0;
        return AuthErr(
            AuthFailure(AuthError.accountLocked, lockedUntil: _lockedUntil),);
      }
      return const AuthErr(AuthFailure(AuthError.wrongCredentials));
    }

        // Test path: login with 0000 gives mustChangePin
    if (pin == '0000') {
      return const AuthOk(AuthSession(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        memberId: 'mock-member-id',
        firstName: 'Abebe',
        lastName: 'Kebede',
        mustChangePin: true,
      ),);
    }

    _wrongAttempts = 0;
    _lockedUntil = null;

    return const AuthOk(
      AuthSession(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        memberId: 'mock-member-id',
        firstName: 'Abebe',
        lastName: 'Kebede',
        mustChangePin: true,
      ),
    );
  }

  @override
  Future<AuthResult> changePin({
    required String accessToken,
    required String currentPin,
    required String newPin,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (currentPin != '1234') {
      return const AuthErr(AuthFailure(AuthError.wrongCredentials));
    }
    // In real API the server would reject weak PINs too; the client blocks
    // them earlier, but the mock mirrors the same guard for symmetry.
    if (newPin.length != 4) {
      return const AuthErr(AuthFailure(AuthError.wrongCredentials));
    }
    return const AuthOk(AuthSession(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      memberId: 'mock-member-id',
      firstName: 'Abebe',
      lastName: 'Kebede',
      mustChangePin: false, // now cleared
    ),);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _wrongAttempts = 0;
    _lockedUntil = null;
  }

  String? _normalizePhone(String input) {
    var s = input.replaceAll(RegExp(r'[\s\-()]'), '');
    s = s.replaceAll(RegExp(r'\D'), '');
    if (s.length == 9 && (s.startsWith('9') || s.startsWith('7'))) {
      return '+251$s';
    }
    if (s.length == 10 && s.startsWith('0')) {
      final body = s.substring(1);
      if (body.startsWith('9') || body.startsWith('7')) return '+251$body';
    }
    if (s.length == 12 && s.startsWith('251')) {
      final body = s.substring(3);
      if (body.startsWith('9') || body.startsWith('7')) return '+251$body';
    }
    return null;
  }
}
