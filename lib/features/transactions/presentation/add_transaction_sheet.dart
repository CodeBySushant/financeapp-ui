import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/currency_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../../accounts/application/accounts_provider.dart';
import '../../accounts/domain/account.dart';
import '../../categories/application/categories_provider.dart';
import '../../categories/domain/category.dart';
import '../application/transactions_provider.dart';
import '../domain/transaction.dart';

/// Opens the add-transaction sheet. Resolves true when something was saved, so
/// the caller knows whether to refresh.
Future<bool> showAddTransactionSheet(
  BuildContext context, {
  String? initialCategorySlug,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) =>
        AddTransactionSheet(initialCategorySlug: initialCategorySlug),
  );
  return saved ?? false;
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.initialCategorySlug});

  final String? initialCategorySlug;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amount = TextEditingController();
  final _merchant = TextEditingController();

  TxType _type = TxType.expense;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Money? get _parsed =>
      Money.tryParse(_amount.text, ref.read(currencyProvider));

  bool get _canSave {
    final m = _parsed;
    if (m == null || m.minor <= 0 || _saving) return false;
    if (_accountId == null) return false;
    if (_type == TxType.transfer) {
      return _toAccountId != null && _toAccountId != _accountId;
    }
    return true;
  }

  CategoryKind get _kind =>
      _type == TxType.income ? CategoryKind.income : CategoryKind.expense;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _date = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _date.hour,
            _date.minute,
          ));
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(transactionsRepositoryProvider).create(
            currency: ref.read(currencyProvider),
            type: _type,
            accountId: _accountId!,
            amountMinor: _parsed!.minor,
            transactionDate: _date,
            toAccountId: _type == TxType.transfer ? _toAccountId : null,
            categoryId: _type == TxType.transfer ? null : _categoryId,
            merchant: _merchant.text,
          );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save that. Please try again.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9 - keyboard;

    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories = ref.watch(categoriesOfKindProvider(_kind));

    // Default the source account once the list arrives.
    if (_accountId == null && accounts.isNotEmpty) {
      final fallback = ref.read(defaultAccountProvider) ?? accounts.first;
      _accountId = fallback.id;
    }
    if (_categoryId == null &&
        widget.initialCategorySlug != null &&
        categories.isNotEmpty) {
      for (final c in categories) {
        if (c.slug == widget.initialCategorySlug) {
          _categoryId = c.id;
          break;
        }
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ClipRRect(
        borderRadius: AppRadius.sheet,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              bottom + AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.sheet,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  g.isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.86),
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: g.strokeSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (_error != null) ...[
                    _ErrorNote(message: _error!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  _TypeToggle(
                    value: _type,
                    onChanged: (t) => setState(() {
                      _type = t;
                      // Category sets differ per side of the ledger, so a
                      // selection made under the other type is no longer valid.
                      _categoryId = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Money.symbolOf(ref.watch(currencyProvider)),
                          style: context.text.moneyLg.copyWith(
                            color: g.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amount,
                            autofocus: true,
                            enabled: !_saving,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                            style: context.text.moneyXl.copyWith(color: g.text),
                            decoration: InputDecoration(
                              filled: false,
                              hintText: '0',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              hintStyle: context.text.moneyXl
                                  .copyWith(color: g.textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  if (accounts.isEmpty)
                    _NoAccountsNote()
                  else ...[
                    _FieldLabel(_type == TxType.transfer ? 'From' : 'Account'),
                    _AccountPicker(
                      accounts: accounts,
                      selectedId: _accountId,
                      onSelect: (id) => setState(() => _accountId = id),
                    ),
                    if (_type == TxType.transfer) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const _FieldLabel('To'),
                      _AccountPicker(
                        accounts: accounts
                            .where((a) => a.id != _accountId)
                            .toList(growable: false),
                        selectedId: _toAccountId,
                        onSelect: (id) => setState(() => _toAccountId = id),
                      ),
                    ],
                  ],

                  if (_type != TxType.transfer) ...[
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _merchant,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: g.text, fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: 'Where? (optional)',
                        prefixIcon: Icon(
                          Icons.storefront_outlined,
                          size: 19,
                          color: g.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _FieldLabel('Category'),
                    if (categories.isEmpty)
                      Text(
                        'Loading categories…',
                        style: TextStyle(fontSize: 13, color: g.textMuted),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final c in categories)
                            GlassChip(
                              label: c.name,
                              icon: GlassPalette.categoryIcon(c.slug),
                              selected: c.id == _categoryId,
                              tone: g.accent,
                              onTap: () => setState(() => _categoryId = c.id),
                            ),
                        ],
                      ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  _DateRow(date: _date, onTap: _saving ? null : _pickDate),
                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canSave ? _save : null,
                      child: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: g.onAccent,
                              ),
                            )
                          : Text(switch (_type) {
                              TxType.income => 'Add income',
                              TxType.transfer => 'Transfer',
                              TxType.expense => 'Add spending',
                            }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, color: g.textMuted),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});

  final TxType value;
  final ValueChanged<TxType> onChanged;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.control),
        color: g.strokeSoft,
        border: Border.all(color: g.surfaceLow),
      ),
      child: Row(
        children: [
          for (final t in TxType.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(t),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: AppMotion.emphasized,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: t == value
                        ? g.accent.withValues(alpha: g.isDark ? 0.20 : 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: t == value
                          ? g.accent.withValues(alpha: 0.45)
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: t == value ? g.accent : g.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final a in accounts)
          GlassChip(
            label: a.name,
            icon: a.type.icon,
            selected: a.id == selectedId,
            tone: g.accent,
            onTap: () => onSelect(a.id),
          ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback? onTap;

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassPanel(
      elevated: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined, size: 18, color: g.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Date',
              style: TextStyle(fontSize: 14, color: g.textSecondary),
            ),
          ),
          Text(
            _label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: g.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAccountsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return Text(
      'No accounts yet. Create one in Profile before adding a transaction.',
      style: TextStyle(fontSize: 13.5, height: 1.4, color: g.textMuted),
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
