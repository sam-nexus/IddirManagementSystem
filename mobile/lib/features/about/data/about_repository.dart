import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/about/data/models/organization_info.dart';

class AboutRepository {
  AboutRepository(this._api);

  final ApiClient _api;

  Future<OrganizationInfo> fetchOrganization() async {
    final raw = await _api.get<dynamic>('/organization');
    final rows = extractList(raw);

    // Find each section by `key`.
    Map<String, dynamic>? byKey(String key) {
      for (final r in rows) {
        if (r['key'] == key) return r;
      }
      return null;
    }

    final mission = byKey('mission');
    final vision = byKey('vision');
    final bylaws = byKey('bylaws');
    final contact = byKey('contact');

    final committee = <CommitteeMember>[];
    if (contact != null && contact['metadata'] is List) {
      for (final m in contact['metadata'] as List) {
        if (m is Map) {
          committee.add(CommitteeMember(
            name: (m['name'] as String?) ?? '',
            role: (m['role'] as String?) ?? 'member',
            phone: (m['phone'] as String?) ?? '',
          ),);
        }
      }
    }

    return OrganizationInfo(
      missionEn: (mission?['content_en'] as String?) ?? '',
      missionOm: (mission?['content_om'] as String?) ?? '',
      visionEn: (vision?['content_en'] as String?) ?? '',
      visionOm: (vision?['content_om'] as String?) ?? '',
      bylawsEn: (bylaws?['content_en'] as String?) ?? '',
      bylawsOm: (bylaws?['content_om'] as String?) ?? '',
      committee: committee,
    );
  }
}
