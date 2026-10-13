import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/announcements/data/models/announcement.dart';

class AnnouncementsRepository {
  AnnouncementsRepository(this._api);

  final ApiClient _api;

  Future<List<Announcement>> fetchAll() async {
    final raw = await _api.get<dynamic>('/announcements', query: {'limit': 50});
    final items = extractList(raw);
    return items.map(_toModel).toList();
  }

  Future<Announcement?> fetchOne(String id) async {
    final raw = await _api.get<dynamic>('/announcements/$id');
    if (raw is! Map) return null;
    return _toModel(raw.cast<String, dynamic>());
  }

  Announcement _toModel(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      titleEn: (json['title_en'] as String?) ?? '',
      titleOm: (json['title_om'] as String?) ?? '',
      bodyEn: (json['body_en'] as String?) ?? '',
      bodyOm: (json['body_om'] as String?) ?? '',
      publishedAt: _parseDate(json['published_at'] ?? json['created_at']),
      isUrgent: (json['is_urgent'] as bool?) ?? false,
      sendSms: (json['send_sms'] as bool?) ?? false,
    );
  }

  DateTime _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}