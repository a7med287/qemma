import 'package:flutter/material.dart';
import '../helpers/build_context_extensions.dart';

/// Wraps [child] in the same soft gradient backdrop used on the Qema
/// marketing pages — light lavender/blue in Light mode, deep navy/purple
/// in Dark mode.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.backgroundGradient,
        ),
      ),
      child: child,
    );
  }
}
