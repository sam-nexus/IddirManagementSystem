import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/meetings/data/models/meeting.dart';

class MeetingsRepository {
  MeetingsRepository(this._api);

  final ApiClient _api;

  Future<List<Meeting>> fetchAll() async {
    final raw = await _api.get<dynamic>('/meetings', query: {'limit': 50});
    final items = extractList(raw);
    return items.map(_toModel).toList();
  }

  Future<Meeting?> fetchOne(String id) async {
    final raw = await _api.get<dynamic>('/meetings/$id');
    if (raw is! Map) return null;
    return _toModel(raw.cast<String, dynamic>());
  }

  Meeting _toModel(Map<String, dynamic> json) {
    final minutesEn = json['minutes_en'] as String?;
    final minutesOm = json['minutes_om'] as String?;
    return Meeting(
      id: json['id'] as String,
      titleEn: (json['title_en'] as String?) ?? '',
      titleOm: (json['title_om'] as String?) ?? '',
      scheduledAt: _parseDate(json['scheduled_at']) ?? DateTime.now(),
      location: json['location'] as String?,
      agendaEn: json['agenda_en'] as String?,
      agendaOm: json['agenda_om'] as String?,
      minutesEn: minutesEn,
      minutesOm: minutesOm,
      isPublished: (json['minutes_published'] as bool?) ?? false,
      hasMinutes: (minutesEn != null && minutesEn.isNotEmpty) ||
          (minutesOm != null && minutesOm.isNotEmpty),
    );
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    return null;
  }
}