import 'package:dio/dio.dart';
import 'package:odaa_mobile/core/api/api_exception.dart';

/// Turns a Dio error into an [ApiException] the app understands.
ApiException mapDioError(DioException err) {
  // No response → network problem.
  if (err.response == null) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        kind: ApiErrorKind.network,
        message: 'The server is taking too long to respond. Please try again.',
      );
    }
    if (err.type == DioExceptionType.connectionError) {
      return const ApiException(
        kind: ApiErrorKind.network,
        message: 'You appear to be offline. Please check your connection.',
      );
    }
    return const ApiException(
      kind: ApiErrorKind.network,
      message: 'Could not reach the server. Please try again.',
    );
  }

  final res = err.response!;
  final status = res.statusCode ?? 0;
  final data = res.data;

  // Extract backend message.
  String message = 'Something went wrong.';
  if (data is Map && data['message'] is String) {
    message = data['message'] as String;
  }

  // Extract field errors if present.
  Map<String, String>? fieldErrors;
  if (data is Map && data['errors'] is List) {
    final list = data['errors'] as List;
    fieldErrors = {};
    for (final e in list) {
      if (e is Map && e['field'] is String && e['message'] is String) {
        fieldErrors[e['field'] as String] = e['message'] as String;
      }
    }
  }

  // Extract minutes remaining for locked accounts.
  int? minutesRemaining;
  if (message.contains('minutes')) {
    final m = RegExp(r'(\d+)\s+minute').firstMatch(message);
    if (m != null) minutesRemaining = int.tryParse(m.group(1)!);
  }

  return ApiException(
    kind: switch (status) {
      400 => ApiErrorKind.badRequest,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      409 => ApiErrorKind.conflict,
      429 => ApiErrorKind.tooMany,
      _ when status >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    },
    message: message,
    statusCode: status,
    fieldErrors: fieldErrors,
    minutesRemaining: minutesRemaining,
  );
}
