import 'package:flutter/material.dart';

/// Standard right-to-left push transition used for every screen navigation
/// in the app (home -> job detail, job detail -> chapters, etc.).
PageRoute slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animation, _, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
