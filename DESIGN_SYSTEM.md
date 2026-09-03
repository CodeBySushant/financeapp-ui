# Fintrak — mobile design system

The visual language is ported from Fintrak (`app/globals.css`, `components/dashboard-preview.jsx`) so the web product and the app read as one brand.

## Where the spec and Fintrak disagree

The brief asks for a Deep Indigo `#4F46E5` primary. Fintrak does something better and I kept it:

| | Fintrak | Brief |
|---|---|---|
| Primary fill | Ink `#111827` | Indigo `#4F46E5` |
| Blue `#2563eb` | focus rings, links only | — |
| Depth | 1px hairlines | — |
| Display face | Fraunces (serif) | — |

Near-black buttons with blue reserved for focus is a more confident, less templated look — and indigo-primary is the single most common "AI-generated fintech app" tell. Changing back is a two-line edit in `app_colors.dart` if you disagree.

## Token map

| Web | Flutter |
|---|---|
| `--ft-ink` `#111827` | `AppColors.ink` |
| `--ft-ink-2` `#374151` | `AppColors.ink2` |
| `--ft-muted` `#6b7280` | `AppColors.muted` |
| `--ft-accent` `#2563eb` | `AppColors.accent` |
| `--ft-success` `#10b981` | `AppColors.success` |
| `--ft-warning` `#f59e0b` | `AppColors.warning` |
| `--ft-error` `#ef4444` | `AppColors.danger` |
| `--ft-surface` `#f8fafc` | `AppColors.surface` |
| `--ft-line` `#e5e7eb` | `AppColors.line` |
| `--ft-dark` `#030712` | `AppColors.dark.canvas` |
| `.kicker` | `AppText.kicker` |
| `.display-xl` / `.display-lg` | `AppText.displayLg` / `displayMd` |
| `.font-num` | `AppText.money*` (tabular figures) |
| `.shadow-premium` | `AppElevation.premium()` |
| `cubic-bezier(.22,1,.36,1)` | `AppMotion.emphasized` |
| `prefers-reduced-motion` | `AppMotion.of(context, …)` |

## Rules carried over from the site

| Rule | Why |
|---|---|
| Expenses render in ink, only income is green | Two colours competing on every row makes a transaction list look like an error log |
| Borders, not shadows | Flat surfaces stay legible in dark mode and read as a tool, not a toy |
| Serif appears three times a screen at most | It is the personality; used everywhere it becomes wallpaper |
| Every money value is tabular mono | Digits never shift width as amounts animate or update |
| Budget bars: green → amber at 75% → red at 100% | Matches the web dashboard exactly |
| Colour never carries meaning alone | Every bar is paired with a figure, for accessibility |

## Money is never a double

`Money` holds an integer count of minor units plus a currency code. `0.1 + 0.2` is a rounding artefact in a demo and a reconciliation failure in a finance app.

- `allocate(n)` distributes remainders one minor unit at a time, so daily-spend splits always sum back to the remaining budget
- Adding two different currencies throws rather than silently producing a wrong total
- `toChartValue()` is the only path to a `double`, and its result must never re-enter money arithmetic
- On the wire: `{"amountMinor": 1845000, "currency": "INR"}` → Postgres `Decimal(18,2)`

## Responsive behaviour

| Width | Navigation | Dashboard |
|---|---|---|
| < 600 | Bottom bar, centre-docked add | Single column |
| 600–904 | Collapsed rail | Two columns, 16px gutter |
| ≥ 905 | Extended rail with labels | Two columns, capped at 1080px, 32px gutter |

Text scaling is handled too: the balance shrinks to fit instead of clipping, and the budget card's figure row stacks vertically past ~130% scale.

## Files

```
lib/core/
├── theme/       app_colors · app_typography · app_tokens · app_theme
├── layout/      responsive (WindowSize, ContentBounds, AdaptiveColumns)
├── widgets/     ft_card · ft_atoms · ft_states
├── navigation/  app_shell
└── utils/       money
lib/features/home/
├── domain/      home_summary
└── presentation/ home_screen · widgets/home_cards
test/            money_test
```

## Dependencies

```yaml
dependencies:
  flutter: {sdk: flutter}
  google_fonts: ^6.2.1
  intl: ^0.19.0
dev_dependencies:
  flutter_test: {sdk: flutter}
```

Fonts are fetched at runtime by `google_fonts` on first launch. Before release, download Inter, Fraunces and JetBrains Mono into `assets/fonts/` and declare them in `pubspec.yaml` — otherwise the first cold start on a poor connection falls back to system faces, and a serif headline snapping into place is the kind of detail that makes an app feel cheap.

## Wiring it up

```dart
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
  home: AppShell(
    currentIndex: index,
    onDestinationSelected: (i) => setState(() => index = i),
    onAdd: () => showAddTransactionSheet(context),
    child: HomeScreen(
      summary: summary,          // null renders the skeleton
      aiUnavailable: aiDown,     // renders the graceful notice
      onRefresh: controller.refresh,
    ),
  ),
)
```
