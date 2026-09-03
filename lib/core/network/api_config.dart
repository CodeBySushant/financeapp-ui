import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where the app looks for the API.
///
/// Override at build time so no host is ever hard-coded into a release:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:4000
///
/// The defaults below only apply in debug. `localhost` on a phone means the
/// phone, not your machine, so a physical device needs your computer's LAN
/// address (or `adb reverse tcp:4000 tcp:4000`, after which localhost works).
/// The Android emulator reaches the host loopback at 10.0.2.2.
abstract final class ApiConfig {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL was not provided. Release builds must be built with '
        '--dart-define=API_BASE_URL=https://your-api-host',
      );
    }
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000';
  }

  static const connectTimeout = Duration(seconds: 12);
  static const receiveTimeout = Duration(seconds: 20);
}
