import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/auth_controller.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => DashboardRepository());

/// The dashboard payload.
///
/// Scoped to the signed-in user id, so signing in as someone else cannot show
/// the previous account's figures for a frame.
final dashboardProvider =
    FutureProvider.autoDispose<DashboardSnapshot>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError('Dashboard requested while signed out');
  }

  final snapshot = await ref.read(dashboardRepositoryProvider).fetch();

  // `/api/auth/me` has no name field, so this is where the greeting learns it.
  ref
      .read(authControllerProvider.notifier)
      .adoptDisplayName(snapshot.summary.displayName);

  return snapshot;
});
