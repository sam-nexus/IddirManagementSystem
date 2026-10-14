import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/core/api/error_mapper.dart';

/// Repository for the manual payment proof upload.
/// Uses a raw Dio call because we need multipart, which our ApiClient
/// does not currently expose.
class ManualPaymentRepository {
  ManualPaymentRepository(this._api);

  final ApiClient _api;

  /// Uploads a proof screenshot + amount + note to POST /contributions/manual.
  /// Returns the newly-created payment id, or null on failure.
  Future<String?> submit({
    required Uint8List fileBytes,
    required String filename,
    required double amount,
    String? note,
  }) async {
    final form = dio.FormData.fromMap({
      'amount': amount.toStringAsFixed(2),
      if (note != null && note.isNotEmpty) 'note': note,
      'file': dio.MultipartFile.fromBytes(
        fileBytes,
        filename: filename,
      ),
    });

    try {
      final res = await _api.raw.post<Map<String, dynamic>>(
        '/contributions/manual',
        data: form,
      );
      final body = res.data;
      final data = (body?['data'] as Map?)?.cast<String, dynamic>();
      return data?['id'] as String?;
    } on dio.DioException catch (e) {
      throw mapDioError(e);
    }
  }
}