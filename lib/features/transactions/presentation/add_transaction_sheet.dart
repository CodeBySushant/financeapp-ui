import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';

/// Opens the add-transaction sheet and resolves to the amount entered, or null
/// if the sheet was dismissed.
Future<Money?> showAddTransactionSheet(
  BuildContext context, {
  String? initialCategoryId,
}) {
  return showModalBottomSheet<Money>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => AddTransactionSheet(initialCategoryId: initialCategoryId),
  );
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  static const _categories = [
    ('food', 'Food'),
    ('groceries', 'Groceries'),
    ('transport', 'Transport'),
    ('shopping', 'Shopping'),
    ('bills', 'Bills'),
    ('coffee', 'Coffee'),
    ('health', 'Health'),
    ('other', 'Other'),
  ];

  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  late String _category;
  bool _isExpense = true;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategoryId ?? 'food';
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Money? get _parsed => Money.tryParse(_amount.text, 'INR');

  bool get _canSave {
    final m = _parsed;
    return m != null && m.minor > 0;
  }

  void _save() {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_parsed);
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

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
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
                      color: g.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Expense / income toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: g.strokeSoft,
                    border: Border.all(color: g.surfaceLow),
                  ),
                  child: Row(
                    children: [
                      _Toggle(
                        label: 'Spending',
                        selected: _isExpense,
                        tone: g.danger,
                        onTap: () => setState(() => _isExpense = true),
                      ),
                      _Toggle(
                        label: 'Income',
                        selected: !_isExpense,
                        tone: g.success,
                        onTap: () => setState(() => _isExpense = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\u20B9',
                        style: context.text.moneyLg.copyWith(
                          fontSize: 30,
                          color: g.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amount,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          style: context.text.moneyXl.copyWith(
                            fontSize: 44,
                            color: g.text,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            hintText: '0',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: TextStyle(
                              fontSize: 44,
                              color: g.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                TextField(
                  controller: _merchant,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: g.text,
                    fontSize: 14.5,
                  ),
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

                Text(
                  'Category',
                  style: TextStyle(fontSize: 12.5, color: g.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (id, label) in _categories)
                      GlassChip(
                        label: label,
                        icon: GlassPalette.categoryIcon(id),
                        tone: g.categoryColor(id),
                        selected: id == _category,
                        onTap: () => setState(() => _category = id),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(_isExpense ? 'Add spending' : 'Add income'),
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

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.emphasized,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: selected ? tone.withValues(alpha: 0.20) : Colors.transparent,
            border: Border.all(
              color: selected ? tone.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? tone : g.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
