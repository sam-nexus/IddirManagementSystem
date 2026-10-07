import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/core/storage/device_id.dart';
import 'package:odaa_mobile/core/storage/prefs_store.dart';
import 'package:odaa_mobile/core/storage/secure_store.dart';

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  throw UnimplementedError('Override prefsStoreProvider in main()');
});

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService(ref.watch(secureStoreProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(secure: ref.watch(secureStoreProvider));
});

/// A one-shot flag set on login, consumed by Home to show a welcome toast.
final welcomeToastProvider = StateProvider<String?>((ref) => null);

// Language
class LanguageNotifier extends StateNotifier<Locale?> {
  LanguageNotifier(this._prefs, this._ref) : super(null) {
    final stored = _prefs.readLanguage();
    if (stored != null && stored.isNotEmpty) {
      state = Locale(stored);
      _ref.read(apiClientProvider).setLanguage(stored);
    }
  }

  final PrefsStore _prefs;
  final Ref _ref;

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    _ref.read(apiClientProvider).setLanguage(code);
    await _prefs.writeLanguage(code);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, Locale?>((ref) {
  return LanguageNotifier(ref.watch(prefsStoreProvider), ref);
});

// Session (unchanged)
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._secure, this._ref) : super(const SessionState.unknown());
  final SecureStore _secure;
  final Ref _ref;

  Future<void> restore() async {
    final token = await _secure.readAccessToken();
    if (token == null || token.isEmpty) {
      state = const SessionState.signedOut();
      return;
    }

    // Try to fetch the profile so we know the member's name.
    // If it fails, still mark as signed in with an empty name — Home will
    // show "Member" and the user can still browse until the token expires.
    try {
      final api = _ref.read(apiClientProvider);
      final me = await api.get<Map<String, dynamic>>('/auth/me');
      state = SessionState.signedIn(
        token: token,
        firstName: (me['first_name'] as String?) ?? '',
        lastName: (me['last_name'] as String?) ?? '',
        memberId: (me['id'] as String?) ?? '',
      );
    } catch (_) {
      state = SessionState.signedIn(
        token: token,
        firstName: '',
        lastName: '',
        memberId: '',
      );
    }
  }

  Future<void> signIn({
    required String accessToken,
    required String refreshToken,
    required String firstName,
    required String lastName,
    required String memberId,
  }) async {
    await _secure.writeAccessToken(accessToken);
    await _secure.writeRefreshToken(refreshToken);
    state = SessionState.signedIn(
      token: accessToken,
      firstName: firstName,
      lastName: lastName,
      memberId: memberId,
    );
  }

  Future<void> signOut() async {
    await _secure.deleteAccessToken();
    await _secure.deleteRefreshToken();
    state = const SessionState.signedOut();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.watch(secureStoreProvider), ref);
});

sealed class SessionState {
  const SessionState();
  const factory SessionState.unknown() = SessionUnknown;
  const factory SessionState.signedOut() = SessionSignedOut;
  const factory SessionState.signedIn({
    required String token,
    required String firstName,
    required String lastName,
    required String memberId,
  }) = SessionSignedIn;
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn({
    required this.token,
    required this.firstName,
    required this.lastName,
    required this.memberId,
  });
  final String token;
  final String firstName;
  final String lastName;
  final String memberId;
}
