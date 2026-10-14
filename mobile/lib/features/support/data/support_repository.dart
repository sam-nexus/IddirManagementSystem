import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/support/data/models/support_request.dart';

class SupportRepository {
  SupportRepository(this._api);

  final ApiClient _api;

  Future<List<SupportRequest>> fetchMine() async {
    final raw = await _api.get<dynamic>('/support/requests', query: {'limit': 50});
    final items = extractList(raw);
    return items.map(_toModel).toList();
  }

  Future<SupportRequest?> fetchOne(String id) async {
    final raw = await _api.get<dynamic>('/support/requests/$id');
    if (raw is! Map) return null;
    return _toModel(raw.cast<String, dynamic>());
  }

  Future<SupportRequest> submit({
    required SupportType type,
    required String description,
    double? amountRequested,
    String? dependentId,
  }) async {
    final raw = await _api.post<Map<String, dynamic>>(
      '/support/requests',
      body: {
        'type': _typeToJson(type),
        'description': description,
        if (amountRequested != null) 'amount_requested': amountRequested,
        if (dependentId != null) 'dependent_id': dependentId,
      },
    );
    return _toModel(raw);
  }

  SupportRequest _toModel(Map<String, dynamic> json) {
    final payout = json['payout'] as Map<String, dynamic>?;
    return SupportRequest(
      id: json['id'] as String,
      type: _typeFromJson(json['type'] as String?),
      description: (json['description'] as String?) ?? '',
      status: _statusFromJson(json['status'] as String?),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      dependentName: json['dependent_name'] as String?,
      amountRequested: _parseNum(json['amount_requested']),
      amountApproved: _parseNum(json['amount_approved']),
      decidedNote: null,
      payoutAmount: payout == null ? null : _parseNum(payout['amount']),
      payoutMethod: payout?['method'] as String?,
    );
  }

  SupportType _typeFromJson(String? s) {
    switch (s) {
      case 'death':
        return SupportType.death;
      case 'illness':
        return SupportType.illness;
      case 'emergency':
        return SupportType.emergency;
      default:
        return SupportType.other;
    }
  }

  String _typeToJson(SupportType t) {
    switch (t) {
      case SupportType.death:
        return 'death';
      case SupportType.illness:
        return 'illness';
      case SupportType.emergency:
        return 'emergency';
      case SupportType.other:
        return 'other';
    }
  }

  SupportStatus _statusFromJson(String? s) {
    switch (s) {
      case 'pending':
        return SupportStatus.pending;
      case 'under_review':
        return SupportStatus.underReview;
      case 'approved':
        return SupportStatus.approved;
      case 'rejected':
        return SupportStatus.rejected;
      case 'paid':
        return SupportStatus.paid;
      case 'cancelled':
        return SupportStatus.cancelled;
      default:
        return SupportStatus.pending;
    }
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    return null;
  }

  double? _parseNum(Object? raw) {
    if (raw == null) return null;
    return double.tryParse('$raw');
  }
}