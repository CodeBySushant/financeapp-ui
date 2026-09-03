import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/widgets/screen_header.dart';
import '../application/assistant_provider.dart';
import '../domain/chat_message.dart';

/// Ask a question about your own money.
///
/// The server refuses to answer with any figure it cannot trace back to the
/// user's records — an ungrounded number in a finance app is worse than no
/// answer — so a refused reply is marked rather than dressed up as a result.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  static const _starters = [
    'What did I spend most on this month?',
    'How am I doing against my budget?',
    'Is my food spending going up?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _input.text;
    if (text.trim().length < 3) return;
    _input.clear();
    await ref.read(chatProvider.notifier).send(text);
    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent + 240,
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final state = ref.watch(chatProvider);

    return Column(
      children: [
        ScreenHeader(
          title: 'Ask my money',
          subtitle: 'Answers built only from your own records',
          onBack: widget.onBack,
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              if (state.messages.isEmpty) ...[
                _Intro(onPick: _send, starters: _starters),
              ] else
                for (final m in state.messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _Bubble(message: m),
                  ),

              if (state.sending)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: g.textMuted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Checking your records',
                            style: TextStyle(fontSize: 13.5, color: g.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (state.premiumRequired) const _PremiumNote(),
              if (state.error != null) _ErrorNote(message: state.error!),
            ],
          ),
        ),
        _Composer(
          controller: _input,
          enabled: !state.sending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onPick, required this.starters});

  final ValueChanged<String> onPick;
  final List<String> starters;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassPanel(
          blurred: true,
          child: Text(
            'Ask about your spending, budgets or goals. Every figure in an '
            'answer comes from your own transactions — nothing is estimated.',
            style: context.text.voice.copyWith(color: g.text),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Try one of these',
          style: TextStyle(fontSize: 12.5, color: g.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final s in starters)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassPanel(
              onTap: () => onPick(s),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(fontSize: 14, color: g.textSecondary),
                    ),
                  ),
                  Icon(Icons.north_east_rounded, size: 15, color: g.textMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: g.accent,
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: g.onAccent,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: GlassPanel(
          blurred: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.flagged) ...[
                Row(
                  children: [
                    Icon(
                      Icons.report_gmailerrorred_rounded,
                      size: 15,
                      color: g.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Not verified against your records',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: g.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                message.content,
                style: TextStyle(fontSize: 14.5, height: 1.45, color: g.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        bottom + AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: TextStyle(color: g.text, fontSize: 14.5),
              decoration: const InputDecoration(hintText: 'Ask a question'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 50,
            height: 50,
            child: Material(
              color: enabled ? g.accent : g.accent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: InkWell(
                onTap: enabled ? onSend : null,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: g.onAccent,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumNote extends StatelessWidget {
  const _PremiumNote();

  @override
  Widget build(BuildContext context) {
    return const GlassEmpty(
      icon: Icons.workspace_premium_outlined,
      title: 'Part of Fintrak Premium',
      body:
          'The assistant reads your whole history to answer, which costs money '
          'to run. Everything else in the app keeps working without it.',
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.control),
        color: g.danger.withValues(alpha: g.isDark ? 0.16 : 0.10),
        border: Border.all(color: g.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: g.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.4, color: g.danger),
            ),
          ),
        ],
      ),
    );
  }
}
