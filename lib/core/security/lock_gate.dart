import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/glass.dart';
import 'app_lock.dart';

/// Sits above everything and hides the app until the lock is satisfied.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final _lock = AppLock.instance;
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lock.addListener(_onLockChanged);
    if (!_lock.isOpen) _prompt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lock.removeListener(_onLockChanged);
    super.dispose();
  }

  void _onLockChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock as soon as the app is backgrounded, not on resume: locking on
    // resume means the balance is briefly visible in the task switcher.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lock.lock();
    }
    if (state == AppLifecycleState.resumed && !_lock.isOpen) {
      _prompt();
    }
  }

  Future<void> _prompt() async {
    if (_prompting) return;
    _prompting = true;
    await _lock.unlock();
    _prompting = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_lock.isOpen) return widget.child;
    return _LockedScreen(onUnlock: _prompt);
  }
}

class _LockedScreen extends StatelessWidget {
  const _LockedScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: g.surfaceLow,
                    border: Border.all(color: g.stroke),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: g.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Fintrak is locked',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: g.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Unlock with your device credential to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: g.textMuted),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(onPressed: onUnlock, child: const Text('Unlock')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
