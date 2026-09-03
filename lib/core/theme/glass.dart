import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// The glass palette, resolved per brightness.
///
/// Light and dark glass are not the same effect with different numbers. Dark
/// glass separates a panel from its backdrop with a bright hairline; on a pale
/// backdrop that hairline is invisible, so light glass separates with a soft
/// shadow instead and pushes the panel fill close to opaque white. Both are
/// encoded here so no widget has to know which theme it is in.
@immutable
class GlassPalette extends ThemeExtension<GlassPalette> {
  const GlassPalette({
    required this.isDark,
    required this.canvasTop,
    required this.canvasBottom,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentAlt,
    required this.success,
    required this.warning,
    required this.danger,
    required this.surfaceHigh,
    required this.surfaceLow,
    required this.stroke,
    required this.strokeSoft,
    required this.shadow,
    required this.onAccent,
  });

  final bool isDark;

  /// Backdrop gradient.
  final Color canvasTop;
  final Color canvasBottom;

  final Color text;
  final Color textSecondary;
  final Color textMuted;

  /// Primary action colour.
  final Color accent;

  /// Links and selected states. Deliberately not the primary fill.
  final Color accentAlt;

  final Color success;
  final Color warning;
  final Color danger;

  /// Card and sheet fill.
  final Color surfaceHigh;

  /// Chips, inputs, inset rows.
  final Color surfaceLow;

  /// Panel border.
  final Color stroke;

  /// Dividers inside a panel.
  final Color strokeSoft;

  /// Panel drop shadow. Transparent in dark, where the stroke does the work.
  final Color shadow;

  final Color onAccent;

  static const light = GlassPalette(
    isDark: false,
    canvasTop: Color(0xFFCFE4F5),
    canvasBottom: Color(0xFFF3F7FB),
    text: Color(0xFF0B1B33),
    textSecondary: Color(0xFF46586F),
    textMuted: Color(0xFF7D90A8),
    accent: Color(0xFF5A4AE3),
    accentAlt: Color(0xFF0E85B8),
    success: Color(0xFF0E9F6E),
    warning: Color(0xFFC2740A),
    danger: Color(0xFFDC2F55),
    surfaceHigh: Color(0xCCFFFFFF),
    surfaceLow: Color(0x80FFFFFF),
    stroke: Color(0xE6FFFFFF),
    strokeSoft: Color(0x1A0B1B33),
    shadow: Color(0x140B2A52),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = GlassPalette(
    isDark: true,
    canvasTop: Color(0xFF070B18),
    canvasBottom: Color(0xFF03050D),
    text: Color(0xFFF7F8FC),
    textSecondary: Color(0xFFB6BFD4),
    textMuted: Color(0xFF7B8AA6),
    accent: Color(0xFF6D5DF6),
    accentAlt: Color(0xFF22D3EE),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFFB7185),
    surfaceHigh: Color(0x14FFFFFF),
    surfaceLow: Color(0x0FFFFFFF),
    stroke: Color(0x24FFFFFF),
    strokeSoft: Color(0x12FFFFFF),
    shadow: Color(0x00000000),
    onAccent: Color(0xFFFFFFFF),
  );

  /// A translucent wash of [c], used for category tints and selected chips.
  Color tint(Color c, double alpha) => c.withValues(alpha: alpha);

  /// Tone for a budget or progress bar at [fraction] consumed.
  Color budgetTone(double fraction) {
    if (fraction >= 1.0) return danger;
    if (fraction >= 0.75) return warning;
    return success;
  }

  /// Category hue, darkened for light mode so it clears contrast on white.
  Color categoryColor(String? id) {
    final key = id?.toLowerCase();
    final map = isDark ? _categoryDark : _categoryLight;
    return map[key] ?? map['other']!;
  }

  static IconData categoryIcon(String? id) =>
      _categoryIcons[id?.toLowerCase()] ?? _categoryIcons['other']!;

  static const _categoryDark = <String, Color>{
    'salary': Color(0xFF22C55E),
    'freelance': Color(0xFF06B6D4),
    'investments': Color(0xFF818CF8),
    'food': Color(0xFFFB7185),
    'groceries': Color(0xFFA3D93B),
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

  static const _categoryLight = <String, Color>{
    'salary': Color(0xFF15803D),
    'freelance': Color(0xFF0E7490),
    'investments': Color(0xFF4F46E5),
    'food': Color(0xFFE11D48),
    'groceries': Color(0xFF4D7C0F),
    'transport': Color(0xFFC2410C),
    'shopping': Color(0xFF1D4ED8),
    'bills': Color(0xFF0E7490),
    'utilities': Color(0xFF0E7490),
    'entertainment': Color(0xFF6D28D9),
    'health': Color(0xFF0F766E),
    'education': Color(0xFF0369A1),
    'travel': Color(0xFFBE185D),
    'subscriptions': Color(0xFF7E22CE),
    'rent': Color(0xFFB91C1C),
    'housing': Color(0xFFB91C1C),
    'coffee': Color(0xFF92400E),
    'other': Color(0xFF52647C),
  };

  static const _categoryIcons = <String, IconData>{
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

  @override
  GlassPalette copyWith({bool? isDark}) => isDark == null || isDark == this.isDark
      ? this
      : (isDark ? GlassPalette.dark : GlassPalette.light);

  @override
  GlassPalette lerp(covariant GlassPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GlassPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      canvasTop: l(canvasTop, other.canvasTop),
      canvasBottom: l(canvasBottom, other.canvasBottom),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentAlt: l(accentAlt, other.accentAlt),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      surfaceLow: l(surfaceLow, other.surfaceLow),
      stroke: l(stroke, other.stroke),
      strokeSoft: l(strokeSoft, other.strokeSoft),
      shadow: l(shadow, other.shadow),
      onAccent: l(onAccent, other.onAccent),
    );
  }
}

extension GlassX on BuildContext {
  GlassPalette get glass => Theme.of(this).extension<GlassPalette>()!;
}

/// The backdrop every screen sits on.
///
/// Light mode is a sky: a pale blue-to-white gradient with a bright pool
/// overhead, which is what gives near-white panels something to sit against.
/// Dark mode is an aurora. Both are radial gradients rather than blurred
/// layers — four full-screen blur passes per frame is not affordable on a
/// mid-range phone alongside a scrolling list.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    final pools = g.isDark
        ? const [
            _Pool(color: Color(0xFF6D5DF6), size: 420, strength: 0.42, top: -140, left: -110),
            _Pool(color: Color(0xFF22D3EE), size: 380, strength: 0.28, top: 40, right: -160),
            _Pool(color: Color(0xFFF471B5), size: 400, strength: 0.22, bottom: 120, left: -140),
            _Pool(color: Color(0xFF34D399), size: 360, strength: 0.20, bottom: -170, right: -80),
          ]
        : const [
            _Pool(color: Color(0xFFFFFFFF), size: 460, strength: 0.95, top: -170, left: -40),
            _Pool(color: Color(0xFF7FB5DC), size: 400, strength: 0.55, top: -80, right: -150),
            _Pool(color: Color(0xFFBFD9F0), size: 380, strength: 0.45, bottom: 180, left: -150),
            _Pool(color: Color(0xFFD7DCFB), size: 340, strength: 0.40, bottom: -140, right: -70),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [g.canvasTop, g.canvasBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [...pools, child],
      ),
    );
  }
}

class _Pool extends StatelessWidget {
  const _Pool({
    required this.color,
    required this.size,
    required this.strength,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final Color color;
  final double size;
  final double strength;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
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
      ),
    );
  }
}

/// A frosted panel.
///
/// [blurred] defaults to false. Real BackdropFilter blur is reserved for the
/// few surfaces where it is perceptible — the balance hero, the floating nav,
/// modal sheets. On every row of a scrolling list it is a full-screen blur pass
/// per frame, which a mid-range device cannot absorb.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = 22,
    this.blurred = false,
    this.tint,
    this.elevated = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blurred;

  /// Optional hue washed through the panel, used to colour-code a card.
  final Color? tint;

  /// Applies the soft drop shadow in light mode. Off for panels that sit
  /// directly on another panel.
  final bool elevated;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final border = BorderRadius.circular(radius);
    final t = tint;

    final fills = t == null
        ? (g.isDark
            ? [Colors.white.withValues(alpha: 0.11), Colors.white.withValues(alpha: 0.07)]
            : [Colors.white.withValues(alpha: 0.88), Colors.white.withValues(alpha: 0.68)])
        : (g.isDark
            ? [t.withValues(alpha: 0.26), t.withValues(alpha: 0.08)]
            : [t.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.72)]);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fills,
        ),
        border: Border.all(
          color: t == null || g.isDark ? g.stroke : t.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (blurred) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: surface,
      );
    }

    Widget panel = ClipRRect(borderRadius: border, child: surface);

    // In light mode the panel and the sky are both nearly white, so the shadow
    // is the only thing that separates them. In dark mode the stroke does it.
    if (elevated && !g.isDark) {
      panel = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: border,
          boxShadow: [
            BoxShadow(color: g.shadow, blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: panel,
      );
    }

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
                splashColor: g.accent.withValues(alpha: 0.10),
                highlightColor: g.accent.withValues(alpha: 0.05),
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
    final g = context.glass;
    final c = tone ?? g.textSecondary;
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
            color: selected
                ? c.withValues(alpha: g.isDark ? 0.22 : 0.14)
                : g.surfaceLow,
            border: Border.all(
              color: selected ? c.withValues(alpha: 0.55) : g.stroke,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? c : g.textSecondary),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: selected ? c : g.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded category glyph. Makes a transaction list scannable without reading
/// a word of it.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({super.key, required this.categoryId, this.size = 42});

  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final tone = g.categoryColor(categoryId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: g.isDark
              ? [tone.withValues(alpha: 0.36), tone.withValues(alpha: 0.14)]
              : [tone.withValues(alpha: 0.20), tone.withValues(alpha: 0.09)],
        ),
        border: Border.all(
          color: tone.withValues(alpha: g.isDark ? 0.34 : 0.22),
        ),
      ),
      child: Icon(
        GlassPalette.categoryIcon(categoryId),
        size: size * 0.46,
        color: tone,
      ),
    );
  }
}

/// A flat progress track. Used for budgets.
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
    final g = context.glass;
    final clamped = fraction.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: g.isDark
                ? Colors.white.withValues(alpha: 0.09)
                : const Color(0xFF0B1B33).withValues(alpha: 0.08),
          ),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(
                  colors: [tone.withValues(alpha: 0.72), tone],
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
    final g = context.glass;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction.clamp(0.0, 1.0),
          tone: tone,
          stroke: stroke,
          track: g.isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFF0B1B33).withValues(alpha: 0.08),
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
    required this.track,
  });

  final double fraction;
  final Color tone;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track,
    );

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [tone.withValues(alpha: 0.55), tone],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.tone != tone ||
      old.stroke != stroke ||
      old.track != track;
}

/// Section heading. Names the block and, optionally, offers one action.
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
    final g = context.glass;

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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: g.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: g.accentAlt,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
    final g = context.glass;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: g.surfaceLow,
        border: Border.all(color: g.stroke),
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
    final g = context.glass;

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
              color: g.surfaceLow,
              border: Border.all(color: g.stroke),
            ),
            child: Icon(icon, color: g.textSecondary, size: 24),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: g.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.45, color: g.textMuted),
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
