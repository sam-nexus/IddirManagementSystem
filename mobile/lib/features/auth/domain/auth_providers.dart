import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/features/auth/data/auth_repository.dart';

/// Swap this override with the real implementation when the API contract
/// is ready. Screens never import the repository directly.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});