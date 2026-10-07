import 'package:flutter/material.dart';

/// The Odaa tree — the centerpiece of Home.
///
/// Displays the bundled `oda.png` illustration. The twelve month states
/// are carried by the growth ring below the tree, not by the tree itself.
class OdaaTree extends StatelessWidget {
  const OdaaTree({
    this.height = 220,
    super.key,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
       return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/images/oda.png',
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stack) {
            // Fallback so a missing asset never breaks the layout.
            return Icon(
              Icons.park_outlined,
              size: height * 0.6,
              color: Theme.of(context).colorScheme.primary,
            );
          },
        ),
      ),
    );
  }
}