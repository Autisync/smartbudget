import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppShimmer — animated shimmer effect wrapping any widget.
// ─────────────────────────────────────────────────────────────────────────────

class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E2130) : const Color(0xFFE8EAF0);
    final highlight =
        isDark ? const Color(0xFF2C3048) : const Color(0xFFF4F5FA);

    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final slide = (_ctrl.value * 2 - 0.5).clamp(0.0, 1.0);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (slide - 0.3).clamp(0.0, 1.0),
                slide.clamp(0.0, 1.0),
                (slide + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton building blocks
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height = 14,
  });

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppShimmerSkeleton — full-screen shimmer for screen-level async loading
// ─────────────────────────────────────────────────────────────────────────────

enum AppShimmerVariant {
  /// Generic vertical list of row skeletons (transactions, notifications, etc.)
  list,

  /// Cards arranged vertically (budgets, savings, subscriptions)
  cards,

  /// Dashboard-style: big balance card + stats row + list
  dashboard,
}

class AppShimmerSkeleton extends StatelessWidget {
  const AppShimmerSkeleton({
    super.key,
    this.variant = AppShimmerVariant.list,
    this.itemCount = 5,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 16),
  });

  final AppShimmerVariant variant;
  final int itemCount;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        children: switch (variant) {
          AppShimmerVariant.list => _listItems(),
          AppShimmerVariant.cards => _cardItems(),
          AppShimmerVariant.dashboard => _dashboardItems(),
        },
      ),
    );
  }

  List<Widget> _listItems() => List.generate(
        itemCount,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _SkeletonRowTile(),
        ),
      );

  List<Widget> _cardItems() => List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SkeletonCard(tall: i == 0),
        ),
      );

  List<Widget> _dashboardItems() => [
        const _SkeletonCard(tall: true, height: 140),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _SkeletonCard(height: 80)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonCard(height: 80)),
          ],
        ),
        const SizedBox(height: 16),
        const _SkeletonBox(width: 140, height: 12),
        const SizedBox(height: 12),
        ..._listItems(),
      ];
}

class _SkeletonRowTile extends StatelessWidget {
  const _SkeletonRowTile();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2130) : const Color(0xFFE8EAF0);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 140, height: 13),
              SizedBox(height: 6),
              _SkeletonBox(width: 90, height: 11),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _SkeletonBox(width: 60, height: 13),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.tall = false, this.height});

  final bool tall;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2130) : const Color(0xFFE8EAF0);
    final actualHeight = height ?? (tall ? 120.0 : 72.0);
    return Container(
      height: actualHeight,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _SkeletonBox(width: 110, height: 12),
          if (tall) ...[
            const SizedBox(height: 10),
            const _SkeletonBox(width: 180, height: 20),
            const SizedBox(height: 10),
            const _SkeletonBox(width: 90, height: 11),
          ],
        ],
      ),
    );
  }
}
