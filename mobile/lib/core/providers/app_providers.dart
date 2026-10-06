import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/storage/prefs_store.dart';
import 'package:odaa_mobile/core/storage/secure_store.dart';

// ---------- Infrastructure ----------
final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  throw UnimplementedError('Override prefsStoreProvider in main()');
});

// ---------- Language ----------
/// The user's selected language. `null` until chosen.
class LanguageNotifier extends StateNotifier<Locale?> {
  LanguageNotifier(this._prefs) : super(null) {
    final stored = _prefs.readLanguage();
    if (stored != null && stored.isNotEmpty) {
      state = Locale(stored);
    }
  }

  final PrefsStore _prefs;

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    await _prefs.writeLanguage(code);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, Locale?>((ref) {
  return LanguageNotifier(ref.watch(prefsStoreProvider));
});

// ---------- Auth session ----------
/// Whether we have a valid access token on disk. Populated on app start.
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._secure) : super(const SessionState.unknown());

  final SecureStore _secure;

  Future<void> restore() async {
    final token = await _secure.readAccessToken();
    state = token == null
        ? const SessionState.signedOut()
        : SessionState.signedIn(token: token);
  }

  Future<void> signIn({required String accessToken, required String refreshToken}) async {
    await _secure.writeAccessToken(accessToken);
    await _secure.writeRefreshToken(refreshToken);
    state = SessionState.signedIn(token: accessToken);
  }

  Future<void> signOut() async {
    await _secure.deleteAccessToken();
    await _secure.deleteRefreshToken();
    state = const SessionState.signedOut();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.watch(secureStoreProvider));
});

/// Sealed state for session.
sealed class SessionState {
  const SessionState();

  const factory SessionState.unknown() = SessionUnknown;
  const factory SessionState.signedOut() = SessionSignedOut;
  const factory SessionState.signedIn({required String token}) = SessionSignedIn;
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn({required this.token});
  final String token;
}