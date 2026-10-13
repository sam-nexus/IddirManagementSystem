import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';

/// A scroll view that supports pull-to-refresh.
///
/// Always allows overscroll so the gesture works even when the content is
/// shorter than the viewport. Callers pass an async [onRefresh] that
/// typically invalidates a Riverpod provider and awaits its new value.
class RefreshableScroll extends StatelessWidget {
  const RefreshableScroll({
    required this.onRefresh,
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: tokens.primaryAction,
      backgroundColor: tokens.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}