import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/dependents/data/dependents_repository.dart';
import 'package:odaa_mobile/features/dependents/data/models/dependent.dart';

final dependentsRepositoryProvider = Provider<DependentsRepository>((ref) {
  return DependentsRepository(ref.watch(apiClientProvider));
});

final dependentsProvider = FutureProvider<List<Dependent>>((ref) async {
  final session = ref.watch(sessionProvider);
  final memberId = switch (session) {
    SessionSignedIn(:final memberId) => memberId,
    _ => '',
  };
  if (memberId.isEmpty) return const [];
  return ref.watch(dependentsRepositoryProvider).fetchMine(memberId);
});