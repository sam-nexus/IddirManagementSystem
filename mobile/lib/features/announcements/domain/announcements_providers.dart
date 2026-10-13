import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/announcements/data/announcements_repository.dart';
import 'package:odaa_mobile/features/announcements/data/models/announcement.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(ref.watch(apiClientProvider));
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return ref.watch(announcementsRepositoryProvider).fetchAll();
});

final announcementProvider =
    FutureProvider.family<Announcement?, String>((ref, id) async {
  return ref.watch(announcementsRepositoryProvider).fetchOne(id);
});