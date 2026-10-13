import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/reports/data/models/report.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  Future<List<Report>> fetchAll() async {
    final raw = await _api.get<dynamic>('/reports', query: {'limit': 50});
    final items = extractList(raw);
    return items.map(_toModel).toList();
  }

  Future<Report?> fetchOne(String id) async {
    final raw = await _api.get<dynamic>('/reports/$id');
    if (raw is! Map) return null;
    return _toModel(raw.cast<String, dynamic>());
  }

  Report _toModel(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      titleEn: (json['title_en'] as String?) ?? '',
      titleOm: (json['title_om'] as String?) ?? '',
      periodStart: _parseDate(json['period_start']) ?? DateTime.now(),
      periodEnd: _parseDate(json['period_end']) ?? DateTime.now(),
      summary: (json['summary'] as Map?)?.cast<String, dynamic>() ?? {},
      publishedAt: _parseDate(json['published_at']) ?? DateTime.now(),
    );
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    return null;
  }
}