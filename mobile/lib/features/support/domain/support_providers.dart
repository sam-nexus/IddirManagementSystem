import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/support/data/models/support_request.dart';
import 'package:odaa_mobile/features/support/data/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

final supportRequestsProvider =
    FutureProvider<List<SupportRequest>>((ref) async {
  return ref.watch(supportRepositoryProvider).fetchMine();
});

final supportRequestProvider =
    FutureProvider.family<SupportRequest?, String>((ref, id) async {
  return ref.watch(supportRepositoryProvider).fetchOne(id);
});