import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/core/api/api_exception.dart';
import 'package:odaa_mobile/core/push/push_service.dart';
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

// ============================================================================
// LANGUAGE
// ============================================================================
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

// ============================================================================
// REMEMBERED PHONE
// ============================================================================
/// The phone number we last logged in with. When set, the login screen
/// opens directly on the PIN step — the member only needs to re-enter
/// their PIN.
class RememberedPhoneNotifier extends StateNotifier<String?> {
  RememberedPhoneNotifier(this._prefs) : super(_prefs.readPhone());

  final PrefsStore _prefs;

  Future<void> remember(String phone) async {
    state = phone;
    await _prefs.writePhone(phone);
  }

  Future<void> forget() async {
    state = null;
    await _prefs.clearPhone();
  }
}

final rememberedPhoneProvider =
    StateNotifierProvider<RememberedPhoneNotifier, String?>((ref) {
  return RememberedPhoneNotifier(ref.watch(prefsStoreProvider));
});

// ============================================================================
// SESSION
// ============================================================================
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._secure, this._ref)
      : super(const SessionState.unknown());

  final SecureStore _secure;
  final Ref _ref;

  Future<void> restore() async {
    final token = await _secure.readAccessToken();
    if (token == null || token.isEmpty) {
      state = const SessionState.signedOut();
      return;
    }

    try {
      final api = _ref.read(apiClientProvider);
      final me = await api.get<Map<String, dynamic>>('/auth/me');
      state = SessionState.signedIn(
        token: token,
        firstName: (me['first_name'] as String?) ?? '',
        lastName: (me['last_name'] as String?) ?? '',
        memberId: (me['id'] as String?) ?? '',
      );
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized ||
          e.kind == ApiErrorKind.forbidden) {
        await _secure.deleteAccessToken();
        await _secure.deleteRefreshToken();
        state = const SessionState.signedOut();
      } else {
        // Network error — keep the session but tolerate an empty name.
        state = SessionState.signedIn(
          token: token,
          firstName: '',
          lastName: '',
          memberId: '',
        );
      }
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


/// The current member's first name, or "Member" if unknown.
final firstNameProvider = Provider<String>((ref) {
  final session = ref.watch(sessionProvider);
  return switch (session) {
    SessionSignedIn(:final firstName) =>
      firstName.isEmpty ? 'Member' : firstName,
    _ => 'Member',
  };
});

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(api: ref.watch(apiClientProvider));
});


// ============================================================================
// WELCOME TOAST (one-shot)
// ============================================================================
final welcomeToastProvider = StateProvider<String?>((ref) => null);