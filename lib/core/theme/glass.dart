import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Glass design tokens.
///
/// Glassmorphism only works when there is something worth seeing *through* the
/// glass. A white page behind a frosted panel produces a grey rectangle. So the
/// backdrop here is an aurora field — four wide colour pools on a deep navy —
/// and every surface above it is translucent.
abstract final class Glass {
  // Backdrop
  static const canvas = Color(0xFF070B18);
  static const canvasDeep = Color(0xFF03050D);

  // Aurora pools. Four hues rather than one accent: a single bright accent on
  // near-black is the most over-used dark-app look there is.
  static const violet = Color(0xFF6D5DF6);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFF471B5);
  static const mint = Color(0xFF34D399);

  // Type
  static const textPrimary = Color(0xFFF7F8FC);
  static const textSecondary = Color(0xFFB6BFD4);
  static const textMuted = Color(0xFF7B8AA6);

  // Semantic
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFFB7185);

  /// Standard blur. Kept moderate on purpose — see [GlassPanel.blurred].
  static const double sigma = 16;

  static Color white(double alpha) => Colors.white.withValues(alpha: alpha);

  /// Tone for a budget bar at [fraction] consumed.
  static Color budgetTone(double fraction) {
    if (fraction >= 1.0) return danger;
    if (fraction >= 0.75) return warning;
    return mint;
  }

  /// Category hues, matched to the web product so a category keeps its colour
  /// across web and app.
  static const _categoryColor = <String, Color>{
    'salary': Color(0xFF22C55E),
    'freelance': Color(0xFF06B6D4),
    'investments': Color(0xFF818CF8),
    'food': Color(0xFFFB7185),
    'groceries': Color(0xFFA0D911),
    'transport': Color(0xFFFB923C),
    'shopping': Color(0xFF60A5FA),
    'bills': Color(0xFF22D3EE),
    'utilities': Color(0xFF22D3EE),
    'entertainment': Color(0xFFA78BFA),
    'health': Color(0xFF2DD4BF),
    'education': Color(0xFF38BDF8),
    'travel': Color(0xFFF472B6),
    'subscriptions': Color(0xFFC084FC),
    'rent': Color(0xFFF87171),
    'housing': Color(0xFFF87171),
    'coffee': Color(0xFFD9A066),
    'other': Color(0xFF94A3B8),
  };

  static const _categoryIcon = <String, IconData>{
    'salary': Icons.payments_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'investments': Icons.trending_up_rounded,
    'food': Icons.restaurant_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'transport': Icons.directions_bus_filled_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'bills': Icons.receipt_long_rounded,
    'utilities': Icons.bolt_rounded,
    'entertainment': Icons.movie_rounded,
    'health': Icons.favorite_rounded,
    'education': Icons.school_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'subscriptions': Icons.autorenew_rounded,
    'rent': Icons.home_rounded,
    'housing': Icons.home_rounded,
    'coffee': Icons.local_cafe_rounded,
    'other': Icons.category_rounded,
  };

  static Color categoryColor(String? id) =>
      _categoryColor[id?.toLowerCase()] ?? _categoryColor['other']!;

  static IconData categoryIcon(String? id) =>
      _categoryIcon[id?.toLowerCase()] ?? _categoryIcon['other']!;
}

/// The aurora field every screen sits on.
///
/// The pools are radial gradients, not blurred layers. A `BackdropFilter` per
/// pool would cost four full-screen blur passes every frame, which a mid-range
/// phone cannot afford alongside a scrolling list. A radial gradient with a
/// transparent outer stop is visually the same thing and costs nothing.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Glass.canvas, Glass.canvasDeep],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -140,
            left: -110,
            child: _Pool(color: Glass.violet, size: 420, strength: 0.42),
          ),
          const Positioned(
            top: 40,
            right: -160,
            child: _Pool(color: Glass.cyan, size: 380, strength: 0.28),
          ),
          const Positioned(
            bottom: 120,
            left: -140,
            child: _Pool(color: Glass.pink, size: 400, strength: 0.22),
          ),
          const Positioned(
            bottom: -170,
            right: -80,
            child: _Pool(color: Glass.mint, size: 360, strength: 0.20),
          ),
          child,
        ],
      ),
    );
  }
}

class _Pool extends StatelessWidget {
  const _Pool({
    required this.color,
    required this.size,
    required this.strength,
  });

  final Color color;
  final double size;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: strength),
              color.withValues(alpha: strength * 0.35),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}

/// A frosted panel.
///
/// [blurred] defaults to false. Real `BackdropFilter` blur is reserved for the
/// few surfaces where you can actually perceive it — the balance hero, the
/// floating nav, modal sheets. Applying it to every row in a scrolling list is
/// what turns a glass UI into a slideshow on a mid-range device; over an aurora
/// backdrop the translucent fill alone is indistinguishable at list scale.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = 22,
    this.fill = 0.07,
    this.stroke = 0.13,
    this.blurred = false,
    this.tint,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double fill;
  final double stroke;
  final bool blurred;

  /// Optional hue washed through the panel, used to colour-code a card.
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(radius);
    final t = tint;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t == null
              ? [Glass.white(fill + 0.04), Glass.white(fill)]
              : [
                  t.withValues(alpha: 0.26),
                  t.withValues(alpha: 0.08),
                ],
        ),
        border: Border.all(color: Glass.white(stroke)),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (blurred) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: Glass.sigma, sigmaY: Glass.sigma),
        child: surface,
      );
    }

    Widget panel = ClipRRect(borderRadius: border, child: surface);

    if (onTap != null) {
      panel = Stack(
        children: [
          panel,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: border,
                splashColor: Glass.white(0.06),
                highlightColor: Glass.white(0.03),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );
    }

    return panel;
  }
}

/// Small translucent label. Used for periods, deltas and filters.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.tone,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? tone;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? Glass.textSecondary;
    final radius = BorderRadius.circular(AppRadius.pill);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected ? c.withValues(alpha: 0.22) : Glass.white(0.06),
            border: Border.all(
              color: selected ? c.withValues(alpha: 0.55) : Glass.white(0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? c : Glass.textSecondary),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: selected ? c : Glass.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded category glyph. The single most useful icon in the app — it makes a
/// transaction list scannable without reading a word of it.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({
    super.key,
    required this.categoryId,
    this.size = 42,
  });

  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = Glass.categoryColor(categoryId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.36),
            tone.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: tone.withValues(alpha: 0.34)),
      ),
      child: Icon(
        Glass.categoryIcon(categoryId),
        size: size * 0.46,
        color: tone,
      ),
    );
  }
}

/// A flat progress track. Used for budgets and goals.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.fraction,
    required this.tone,
    this.height = 8,
  });

  final double fraction;
  final Color tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: Glass.white(0.09)),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(
                  colors: [tone.withValues(alpha: 0.75), tone],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A progress ring. Used on goal cards, where a bar would read as a budget.
class GlassRing extends StatelessWidget {
  const GlassRing({
    super.key,
    required this.fraction,
    required this.tone,
    this.size = 58,
    this.stroke = 6,
    this.child,
  });

  final double fraction;
  final Color tone;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction.clamp(0.0, 1.0),
          tone: tone,
          stroke: stroke,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.tone,
    required this.stroke,
  });

  final double fraction;
  final Color tone;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Glass.white(0.10);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [tone.withValues(alpha: 0.55), tone],
      ).createShader(rect);

    canvas.drawCircle(centre, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.tone != tone || old.stroke != stroke;
}

/// Section heading. One job: name the block and, optionally, offer one action.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        right: AppSpacing.xs,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Glass.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Glass.cyan,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown while the dashboard loads. Shaped like the real content so the layout
/// does not jump when data arrives.
class GlassSkeleton extends StatelessWidget {
  const GlassSkeleton({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Glass.white(0.05),
        border: Border.all(color: Glass.white(0.08)),
      ),
    );
  }
}

/// An empty state is an invitation to act, so it always carries the action.
class GlassEmpty extends StatelessWidget {
  const GlassEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Glass.white(0.07),
              border: Border.all(color: Glass.white(0.13)),
            ),
            child: Icon(icon, color: Glass.textSecondary, size: 24),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: Glass.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Glass.textMuted,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
