import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-credential lock in front of the app.
///
/// Deliberately uses [AuthenticationOptions.biometricOnly] = false, so a device
/// with no fingerprint enrolled can still lock behind a PIN or pattern. Offering
/// the setting and then refusing to work on a phone without a sensor would be
/// worse than not offering it.
class AppLock extends ChangeNotifier {
  AppLock._();

  static final AppLock instance = AppLock._();

  static const _key = 'fintrak.lock.enabled';

  final _auth = LocalAuthentication();

  bool _enabled = false;
  bool _unlocked = false;
  bool _supported = false;

  bool get enabled => _enabled;
  bool get supported => _supported;

  /// True when the app may be shown: either the lock is off, or it has been
  /// satisfied for this session.
  bool get isOpen => !_enabled || _unlocked;

  Future<void> load() async {
    try {
      _supported = await _auth.isDeviceSupported();
    } catch (_) {
      _supported = false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = _supported && (prefs.getBool(_key) ?? false);
    } catch (_) {
      _enabled = false;
    }
    _unlocked = !_enabled;
    notifyListeners();
  }

  Future<bool> setEnabled(bool value) async {
    if (value) {
      // Prove the device can actually authenticate before storing the setting,
      // or the user locks themselves out of their own app.
      final ok = await _authenticate('Turn on the app lock');
      if (!ok) return false;
    }
    _enabled = value;
    _unlocked = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
    return true;
  }

  Future<bool> unlock() async {
    final ok = await _authenticate('Unlock Fintrak');
    if (ok) {
      _unlocked = true;
      notifyListeners();
    }
    return ok;
  }

  /// Re-locks when the app leaves the foreground.
  void lock() {
    if (!_enabled) return;
    _unlocked = false;
    notifyListeners();
  }

  Future<bool> _authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

final appLockProvider = ChangeNotifierProvider<AppLock>(
  (ref) => AppLock.instance,
);
