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
            Dio(BaseOptions(
              baseUrl: baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              contentType: 'application/json',
              responseType: ResponseType.json,
              headers: {'X-Lang': 'en'},
            ),) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final Dio _dio;
  final SecureStore _secure;

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
      // Not a refresh-worthy case.
      return handler.reject(err);
    }

    try {
      final refresh = await _secure.readRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _clearTokens();
        return handler.reject(err);
      }

      // Use a fresh Dio to avoid interceptor recursion.
      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final refreshRes = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );

      final data = refreshRes.data as Map?;
      final newAccess = data?['data']?['access_token'] as String?;
      final newRefresh = data?['data']?['refresh_token'] as String?;

      if (newAccess == null) {
        await _clearTokens();
        return handler.reject(err);
      }

      await _secure.writeAccessToken(newAccess);
      if (newRefresh != null) {
        await _secure.writeRefreshToken(newRefresh);
      }

      // Retry the original request with the new token.
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';
      final retry = await _dio.fetch(opts);
      return handler.resolve(retry);
    } catch (_) {
      await _clearTokens();
      return handler.reject(err);
    }
  }

  Future<void> _clearTokens() async {
    await _secure.deleteAccessToken();
    await _secure.deleteRefreshToken();
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

}