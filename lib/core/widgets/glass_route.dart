import 'package:flutter/material.dart';

import '../theme/glass.dart';

/// Pushes a full screen that keeps the app's backdrop.
///
/// Screens reached this way are not bar destinations, so they build their own
/// Scaffold rather than borrowing the shell's.
Route<T> glassRoute<T>(Widget child) {
  return MaterialPageRoute<T>(
    builder: (_) => GlassBackground(
      child: Scaffold(backgroundColor: Colors.transparent, body: child),
    ),
  );
}
