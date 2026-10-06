/// Everything the login flow needs to know about its own state.
library;

enum AuthError {
  none,
  wrongCredentials,
  unknownPhone,
  accountLocked,
  accountSuspended,
  network,
  server,
  unknown,
}

/// The result of a successful login.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.memberId,
    required this.firstName,
    required this.lastName,
    required this.mustChangePin,
  });

  final String accessToken;
  final String refreshToken;
  final String memberId;
  final String firstName;
  final String lastName;
  final bool mustChangePin;
}

/// A failure return value — never thrown across the repository boundary.
class AuthFailure {
  const AuthFailure(this.error, {this.lockedUntil});

  final AuthError error;

  /// Only set when [error] is [AuthError.accountLocked].
  final DateTime? lockedUntil;

  int? get minutesRemaining {
    final u = lockedUntil;
    if (u == null) return null;
    final diff = u.difference(DateTime.now()).inMinutes;
    return diff < 0 ? 0 : diff;
  }
}

/// A discriminated result — either a session or a failure.
sealed class AuthResult {
  const AuthResult();
}

class AuthOk extends AuthResult {
  const AuthOk(this.session);
  final AuthSession session;
}

class AuthErr extends AuthResult {
  const AuthErr(this.failure);
  final AuthFailure failure;
}