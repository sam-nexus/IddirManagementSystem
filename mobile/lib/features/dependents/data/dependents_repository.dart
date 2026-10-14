import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/dependents/data/models/dependent.dart';

class DependentsRepository {
  DependentsRepository(this._api);

  final ApiClient _api;

  /// The backend exposes dependents under `/members/:id/dependents`.
  /// The current member's id comes from the session.
  Future<List<Dependent>> fetchMine(String memberId) async {
    final raw = await _api.get<dynamic>('/members/$memberId/dependents');
    final items = extractList(raw);
    return items.map(_toModel).toList();
  }

  Dependent _toModel(Map<String, dynamic> json) {
    return Dependent(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      relationship: (json['relationship'] as String?) ?? 'other',
      isActive: (json['is_active'] as bool?) ?? true,
      dateOfBirth: _parseDate(json['date_of_birth']),
    );
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}