import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// The signed-in user's currency, defaulted rather than nullable so no mapper
/// has to branch on "not signed in yet" — nothing fetches while signed out.
final currencyProvider = Provider<String>(
  (ref) => ref.watch(currentUserProvider)?.currency ?? 'INR',
);
