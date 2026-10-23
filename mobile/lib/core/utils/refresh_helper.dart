import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invalidates a FutureProvider and waits for the new value.
Future<void> refreshFutureProvider<T>(
  WidgetRef ref,
  FutureProvider<T> provider,
) async {
  ref.invalidate(provider);
  try {
    await ref.read(provider.future);
  } catch (_) {
    // Errors are handled by the provider's own .when(error: ...) branch.
  }
}