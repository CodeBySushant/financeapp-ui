import 'package:flutter/material.dart';

/// Material 3 window size classes. The app is phone-first, but every screen is
/// laid out against these so a foldable, a tablet or a desktop window gets a
/// real layout rather than a stretched phone one.
enum WindowSize {
  /// Phones in portrait, and small foldables closed.
  compact,

  /// Large phones in landscape, small tablets, foldables open.
  medium,

  /// Tablets in landscape, desktop windows.
  expanded;

  bool get isCompact => this == WindowSize.compact;
  bool get isAtLeastMedium => index >= WindowSize.medium.index;
  bool get isExpanded => this == WindowSize.expanded;
}

extension ResponsiveX on BuildContext {
  WindowSize get windowSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w >= 905) return WindowSize.expanded;
    if (w >= 600) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// Pick a value per size class without writing a chain of ifs.
  T responsive<T>({required T compact, T? medium, T? expanded}) {
    switch (windowSize) {
      case WindowSize.expanded:
        return expanded ?? medium ?? compact;
      case WindowSize.medium:
        return medium ?? compact;
      case WindowSize.compact:
        return compact;
    }
  }

  /// True once the user has pushed text past ~130%, at which point rows that
  /// pack a label and a number side by side should stack instead.
  bool get isLargeText => MediaQuery.textScalerOf(this).scale(14) > 18.2;
}

/// Centres and caps content on wide windows so a dashboard does not become a
/// single 1400px-wide column of stretched cards.
class ContentBounds extends StatelessWidget {
  const ContentBounds({super.key, required this.child, this.maxWidth = 1080});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lays children out in one column on compact windows and in balanced columns
/// on wider ones, keeping vertical rhythm identical in both.
///
/// Children are distributed round-robin, so the visual order down each column
/// stays predictable as the window resizes.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columnCount = context.responsive(compact: 1, medium: 2, expanded: 2);

    if (columnCount == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    final buckets = List.generate(columnCount, (_) => <Widget>[]);
    for (var i = 0; i < children.length; i++) {
      buckets[i % columnCount].add(children[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columnCount; c++) ...[
          if (c > 0) SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buckets[c].length; i++) ...[
                  if (i > 0) SizedBox(height: spacing),
                  buckets[c][i],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
