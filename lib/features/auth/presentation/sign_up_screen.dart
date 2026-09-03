import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/auth_controller.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/glass.dart';
import 'auth_form_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  bool _obscure = true;
  String _currency = 'INR';
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      await ref.read(authControllerProvider.notifier).register(
            _email.text,
            _password.text,
            _name.text,
            currency: _currency,
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _fieldErrors = e.fieldErrors;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return AuthFormScaffold(
      title: 'Create your account',
      subtitle: 'Track what comes in, what goes out, and what is left.',
      children: [
        if (_error != null) AuthErrorBanner(message: _error!),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                style: TextStyle(color: g.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Name',
                  errorText: _fieldErrors['name'],
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    size: 19,
                    color: g.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: TextStyle(color: g.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Email',
                  errorText: _fieldErrors['email'],
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    size: 19,
                    color: g.textMuted,
                  ),
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.newPassword],
                style: TextStyle(color: g.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Password',
                  errorText: _fieldErrors['password'],
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 19,
                    color: g.textMuted,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                      color: g.textMuted,
                    ),
                  ),
                ),
                // Matches the server rule in auth.routes.ts, so the length is
                // caught here rather than after a round trip.
                validator: (v) => (v == null || v.length < 10)
                    ? 'Use at least 10 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ten characters or more. Length matters more than symbols.',
                style: TextStyle(fontSize: 12.5, color: g.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Asked here because it is the only place it can be asked: the
              // register endpoint accepts a currency and there is no endpoint
              // to change one afterwards.
              Text(
                'Currency',
                style: TextStyle(fontSize: 12.5, color: g.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in const ['INR', 'USD', 'EUR', 'GBP', 'AED', 'NPR'])
                    GlassChip(
                      label: c,
                      selected: c == _currency,
                      tone: g.accent,
                      onTap: _busy ? null : () => setState(() => _currency = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: g.onAccent,
                        ),
                      )
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('I already have an account'),
          ),
        ),
      ],
    );
  }
}
