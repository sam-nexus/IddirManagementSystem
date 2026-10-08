import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odaa_mobile/core/api/api_exception.dart';
import 'package:odaa_mobile/core/api/error_mapper.dart';
import 'package:odaa_mobile/core/storage/secure_store.dart';

/// Central HTTP client. Every repository talks through this.
///
/// On any 401 it tries once to refresh the access token using the stored
/// refresh token, then retries the original request. If refresh fails,
/// the stored tokens are cleared and callers get an `unauthorized`
/// [ApiException] so a screen can route to login.
class ApiClient {
  ApiClient({
    required SecureStore secure,
    Dio? dio,
    String? baseUrl,
  })  : _secure = secure,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ??
                    dotenv.env['API_BASE_URL'] ??
                    'http://localhost:4000',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
                contentType: 'application/json',
                responseType: ResponseType.json,
                headers: {'X-Lang': 'en'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final Dio _dio;
  final SecureStore _secure;

  Future<String?>? _refreshing;

  /// Called when tokens are cleared because the session is truly dead.
  /// Wired from main() to send the user to the login screen.
  void Function()? onSessionExpired;

  Dio get raw => _dio;

  /// Call this once after the user picks a language, so all requests carry
  /// the correct `X-Lang` header.
  void setLanguage(String code) {
    _dio.options.headers['X-Lang'] = code;
  }

  // ---------- Request: attach JWT ----------
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Public endpoints don't need a token.
    final path = options.path;
    final isPublic = path.contains('/auth/login') ||
        path.contains('/auth/otp') ||
        path.contains('/auth/refresh');

    if (!isPublic) {
      final token = await _secure.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  // ---------- Error: refresh on 401 ----------

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final res = err.response;
    final is401 = res?.statusCode == 401;
    final isAuthPath = err.requestOptions.path.contains('/auth/');

    if (!is401 || isAuthPath) {
      return handler.reject(err);
    }

    try {
      final newToken = await _refreshOnce();
      if (newToken == null) {
        await _clearTokens();
        return handler.reject(err);
      }

      // Retry the original request with the fresh token.
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      final retry = await _dio.fetch(opts);
      return handler.resolve(retry);
    } catch (_) {
      await _clearTokens();
      return handler.reject(err);
    }
  }

  /// Performs at most one refresh at a time. Concurrent callers share the result.
  Future<String?> _refreshOnce() {
    // If a refresh is already running, piggyback on it.
    final existing = _refreshing;
    if (existing != null) return existing;

    // Otherwise start a new one and cache the future.
    final future = _doRefresh();
    _refreshing = future;
    future.whenComplete(() => _refreshing = null);
    return future;
  }

  Future<String?> _doRefresh() async {
    final refresh = await _secure.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    // Use a fresh Dio so the interceptor doesn't recurse.
    final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
    final refreshRes = await refreshDio.post(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );

    final data = refreshRes.data as Map?;
    final newAccess = data?['data']?['access_token'] as String?;
    final newRefresh = data?['data']?['refresh_token'] as String?;

    if (newAccess == null) return null;

    await _secure.writeAccessToken(newAccess);
    if (newRefresh != null) {
      await _secure.writeRefreshToken(newRefresh);
    }
    return newAccess;
  }

  Future<void> _clearTokens() async {
    await _secure.deleteAccessToken();
    await _secure.deleteRefreshToken();
    onSessionExpired?.call();
  }

  /// Convenience: GET returning the `data` field or throwing ApiException.
  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _run<T>(() => _dio.get(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run<T>(() => _dio.post(path, data: body, queryParameters: query));

  Future<T> patch<T>(String path, {Object? body}) =>
      _run<T>(() => _dio.patch(path, data: body));

  Future<T> delete<T>(String path, {Map<String, dynamic>? query}) =>
      _run<T>(() => _dio.delete(path, queryParameters: query));

  Future<T> _run<T>(Future<Response> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body == null) {
        // 304 or empty body — return an empty map so callers don't crash.
        return <String, dynamic>{} as T;
      }
      if (body is Map && body.containsKey('data')) {
        return body['data'] as T;
      }
      return body as T;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      // A cast or parse error — log for debugging, throw a clear error.
      // ignore: avoid_print
      print('[api] parse error: $e\n$st');
      throw const ApiException(
        kind: ApiErrorKind.unknown,
        message: 'Unexpected response from the server.',
      );
    }
  }

  /// Extracts a list of items from a backend response that may be:
  ///   - a bare array:            [ ... ]
  ///   - a paginated object:      { items: [ ... ], pagination: { ... } }
  ///   - a wrapped object:        { data: [...] } (already unwrapped by _run, but just in case)
}

List<Map<String, dynamic>> extractList(dynamic raw) {
  if (raw == null) return const [];

  // Bare array.
  if (raw is List) {
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  // Paginated object with .items
  if (raw is Map) {
    final items = raw['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    // Nested under .data.items
    final data = raw['data'];
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
  }

  return const [];
}
