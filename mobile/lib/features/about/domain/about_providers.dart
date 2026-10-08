import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/about/data/about_repository.dart';
import 'package:odaa_mobile/features/about/data/models/organization_info.dart';

final aboutRepositoryProvider = Provider<AboutRepository>((ref) {
  return AboutRepository(ref.watch(apiClientProvider));
});

final organizationInfoProvider = FutureProvider<OrganizationInfo>((ref) async {
  return ref.watch(aboutRepositoryProvider).fetchOrganization();
});