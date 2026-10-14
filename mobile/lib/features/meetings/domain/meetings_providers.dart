import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/meetings/data/meetings_repository.dart';
import 'package:odaa_mobile/features/meetings/data/models/meeting.dart';

final meetingsRepositoryProvider = Provider<MeetingsRepository>((ref) {
  return MeetingsRepository(ref.watch(apiClientProvider));
});

final meetingsProvider = FutureProvider<List<Meeting>>((ref) async {
  return ref.watch(meetingsRepositoryProvider).fetchAll();
});

final meetingProvider =
    FutureProvider.family<Meeting?, String>((ref, id) async {
  return ref.watch(meetingsRepositoryProvider).fetchOne(id);
});