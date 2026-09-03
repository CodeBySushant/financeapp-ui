import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/glass.dart';

/// Asks the person what to call them. Shown once, on first launch, until there
/// is a real sign-in flow to replace it.
Future<String?> showNameSheet(BuildContext context, {String? initial}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: initial != null,
    enableDrag: initial != null,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _NameSheet(initial: initial),
  );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({this.initial});

  final String? initial;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // paddingOf, not viewPaddingOf: viewPadding keeps reporting the gesture-bar
    // strip while the keyboard is up, so adding it on top of viewInsets counted
    // the same space twice and pushed the content past the bottom edge.
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9 - keyboard;
    final editing = widget.initial != null;

    return PopScope(
      // On first run there is nothing behind this to go back to.
      canPop: editing,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                bottom + AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    g.stroke,
                  g.canvasBottom.withValues(alpha: g.isDark ? 0.86 : 0.92),
                  ],
                ),
                border: Border.all(color: g.stroke),
              ),
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing ? 'Change your name' : 'What should we call you?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: g.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Only used to greet you. It stays on this device.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: g.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    maxLength: 40,
                    style: TextStyle(
                      color: g.text,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      counterText: '',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: g.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _valid ? _submit : null,
                      child: Text(editing ? 'Save name' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
