import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page data
// ─────────────────────────────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.gradientTop,
    required this.gradientBottom,
    required this.accentLight,
    required this.buildIllustration,
  });

  final Color gradientTop;
  final Color gradientBottom;
  final Color accentLight;
  final Widget Function(Animation<double> stagger, Animation<double> idle)
      buildIllustration;
}

final _pages = <_PageData>[
  _PageData(
    gradientTop: const Color(0xFF1A1060),
    gradientBottom: const Color(0xFF5548F0),
    accentLight: const Color(0xFFB4B0FF),
    buildIllustration: (stagger, idle) =>
        _SpendingIllustration(stagger: stagger, idle: idle),
  ),
  _PageData(
    gradientTop: const Color(0xFF0C2340),
    gradientBottom: const Color(0xFF1B7FD4),
    accentLight: const Color(0xFF90CAFF),
    buildIllustration: (stagger, idle) =>
        _InsightsIllustration(stagger: stagger, idle: idle),
  ),
  _PageData(
    gradientTop: const Color(0xFF0B2D1E),
    gradientBottom: const Color(0xFF169B62),
    accentLight: const Color(0xFF80E8BA),
    buildIllustration: (stagger, idle) =>
        _SecurityIllustration(stagger: stagger, idle: idle),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  // Gradient background interpolation
  late final AnimationController _bgCtrl;
  int _bgFrom = 0;
  int _bgTo = 0;

  // Per-step stagger (reset on page change)
  late AnimationController _stagger;

  // Idle floating animation (continuous loop)
  late final AnimationController _idleCtrl;

  // Entrance of the entire screen
  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _stagger = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _idleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgCtrl.dispose();
    _stagger.dispose();
    _idleCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _pages.length) return;
    _bgFrom = _page;
    _bgTo = page;
    _bgCtrl..reset()..forward();
    _stagger..reset()..forward();
    _pageCtrl.animateToPage(page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
    setState(() => _page = page);
    HapticFeedback.selectionClick();
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    await ref.read(onboardingServiceProvider).completeOnboarding(
          acceptedLegal: true,
          reviewedAt: DateTime.now().toUtc(),
        );
    ref.invalidate(onboardingStatusProvider);
    // Wait for the refreshed onboarding status to SETTLE before navigating.
    // Otherwise the router redirect can evaluate the half-refreshed provider
    // (stale "not complete") and ping-pong /onboarding <-> /login until GoRouter
    // throws "redirect loop detected". Once the future resolves, the status is
    // ready and the redirect (which listens to this provider) moves us to /login
    // deterministically — the go() below is just a fallback.
    try {
      await ref.read(onboardingStatusProvider.future);
    } catch (_) {
      // ignore — redirect/refresh will still react to the invalidation
    }
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final safeTop = MediaQuery.paddingOf(context).top;
    final isLast = _page == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _pages[0].gradientTop,
        body: AnimatedBuilder(
          animation: _enterCtrl,
          builder: (context, child) {
            final t = CurvedAnimation(
                    parent: _enterCtrl, curve: Curves.easeOutCubic)
                .value;
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - t)),
                child: child,
              ),
            );
          },
          child: Stack(
            children: [
              // ── Animated gradient fill ──────────────────────────────────
              Positioned.fill(
                child: _GradientBg(
                  fromIdx: _bgFrom,
                  toIdx: _bgTo,
                  animation: CurvedAnimation(
                      parent: _bgCtrl, curve: Curves.easeInOutCubic),
                ),
              ),

              // ── Illustration area (swipeable pages) ─────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: PageView.builder(
                  controller: _pageCtrl,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _pages.length,
                  onPageChanged: (p) {
                    if (p != _page) {
                      _bgFrom = _page;
                      _bgTo = p;
                      _bgCtrl..reset()..forward();
                      _stagger..reset()..forward();
                      setState(() => _page = p);
                      HapticFeedback.selectionClick();
                    }
                  },
                  itemBuilder: (context, i) {
                    final anim = CurvedAnimation(
                        parent: _stagger,
                        curve: const Interval(0.0, 0.65,
                            curve: Curves.easeOutBack));
                    return Padding(
                      padding: EdgeInsets.only(
                          top: safeTop + 70,
                          bottom: _kPanelMinHeight(context) + 16),
                      child: AnimatedBuilder(
                        animation: anim,
                        builder: (context, child) => Transform.scale(
                          scale: 0.82 + 0.18 * anim.value,
                          child: Opacity(
                            opacity: anim.value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        ),
                        child: _pages[i]
                            .buildIllustration(_stagger, _idleCtrl),
                      ),
                    );
                  },
                ),
              ),

              // ── Top bar: progress + skip ─────────────────────────────────
              Positioned(
                top: safeTop + 12,
                left: 20,
                right: 20,
                child: _TopBar(
                  page: _page,
                  total: _pages.length,
                  stagger: _stagger,
                  // Skip jumps past the slides but must still COMPLETE
                  // onboarding (and accept legal) like finishing — otherwise the
                  // router bounces straight back to /onboarding because the
                  // status is not "ready" (onboardingComplete && legalAccepted).
                  onSkip: _finish,
                  isLast: isLast,
                ),
              ),

              // ── Bottom panel ─────────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomPanel(
                  page: _page,
                  isLast: isLast,
                  stagger: _stagger,
                  safeBottom: safeBottom,
                  onNext: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _goTo(_page + 1);
                    }
                  },
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom panel approximate height for illustration padding
double _kPanelMinHeight(BuildContext context) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  return safeBottom + 220;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated gradient background
// ─────────────────────────────────────────────────────────────────────────────

class _GradientBg extends AnimatedWidget {
  const _GradientBg({
    required this.fromIdx,
    required this.toIdx,
    required Animation<double> animation,
  }) : super(listenable: animation);

  final int fromIdx;
  final int toIdx;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    final from = _pages[fromIdx.clamp(0, _pages.length - 1)];
    final to = _pages[toIdx.clamp(0, _pages.length - 1)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(from.gradientTop, to.gradientTop, t)!,
            Color.lerp(from.gradientBottom, to.gradientBottom, t)!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.page,
    required this.total,
    required this.stagger,
    required this.onSkip,
    required this.isLast,
  });

  final int page;
  final int total;
  final AnimationController stagger;
  final VoidCallback onSkip;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Progress bar segments
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              final done = i < page;
              final active = i == page;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    height: 4,
                    decoration: BoxDecoration(
                      color: done
                          ? Colors.white
                          : active
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    // Fill animation for active bar
                    child: active
                        ? AnimatedBuilder(
                            animation: stagger,
                            builder: (context, _) {
                              final pct = CurvedAnimation(
                                parent: stagger,
                                curve: const Interval(0.0, 0.8,
                                    curve: Curves.easeInOut),
                              ).value;
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: pct,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 16),
        if (!isLast)
          GestureDetector(
            onTap: onSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom panel
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.page,
    required this.isLast,
    required this.stagger,
    required this.safeBottom,
    required this.onNext,
    required this.l10n,
  });

  final int page;
  final bool isLast;
  final AnimationController stagger;
  final double safeBottom;
  final VoidCallback onNext;
  final AppLocalizations l10n;

  String _title(AppLocalizations l10n) => switch (page) {
        0 => l10n.onboardingPage1Title,
        1 => l10n.onboardingPage2Title,
        _ => l10n.onboardingPage3Title,
      };

  String _desc(AppLocalizations l10n) => switch (page) {
        0 => l10n.onboardingPage1Description,
        1 => l10n.onboardingPage2Description,
        _ => l10n.onboardingPage3Description,
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
        padding: EdgeInsets.fromLTRB(28, 28, 28, safeBottom + 24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            AnimatedBuilder(
              animation: stagger,
              builder: (context, child) {
                final t = CurvedAnimation(
                        parent: stagger,
                        curve: const Interval(0.2, 0.65,
                            curve: Curves.easeOut))
                    .value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                      offset: Offset(0, 18 * (1 - t)), child: child),
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  _title(l10n),
                  key: ValueKey(page),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.4,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF12141C),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Description
            AnimatedBuilder(
              animation: stagger,
              builder: (context, child) {
                final t = CurvedAnimation(
                        parent: stagger,
                        curve: const Interval(0.35, 0.8,
                            curve: Curves.easeOut))
                    .value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                      offset: Offset(0, 14 * (1 - t)), child: child),
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  _desc(l10n),
                  key: ValueKey(page),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : const Color(0xFF5A5F72),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Button
            AnimatedBuilder(
              animation: stagger,
              builder: (context, child) {
                final t = CurvedAnimation(
                        parent: stagger,
                        curve: const Interval(0.55, 1.0,
                            curve: Curves.easeOut))
                    .value;
                return Opacity(
                    opacity: t,
                    child: Transform.translate(
                        offset: Offset(0, 10 * (1 - t)), child: child));
              },
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? l10n.onboardingGetStarted : l10n.onboardingContinue,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration 1 — Spending tracker (mock balance card + bar chart)
// ─────────────────────────────────────────────────────────────────────────────

class _SpendingIllustration extends StatelessWidget {
  const _SpendingIllustration(
      {required this.stagger, required this.idle});

  final Animation<double> stagger;
  final Animation<double> idle;

  static const _bars = [0.45, 0.72, 0.38, 0.88, 0.55, 0.63, 0.40];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Balance card
          AnimatedBuilder(
            animation: idle,
            builder: (context, _) {
              final f = math.sin(idle.value * math.pi);
              return Transform.translate(
                offset: Offset(0, f * 5 - 2.5),
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _Label('Total Balance', Colors.white60),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Monthly',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Kz 1,284,500',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8)),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              size: 13, color: Color(0xFF5EEAAA)),
                          SizedBox(width: 3),
                          _Label('+8.4% vs last month',
                              Color(0xFF5EEAAA)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Bar chart card
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Weekly Spending', Colors.white60),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_bars.length, (i) {
                    final delay = i * 0.07;
                    final barAnim = CurvedAnimation(
                      parent: stagger,
                      curve: Interval(
                          (0.3 + delay).clamp(0, 1),
                          (0.7 + delay).clamp(0, 1),
                          curve: Curves.easeOutCubic),
                    );
                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedBuilder(
                          animation: barAnim,
                          builder: (context, _) => Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 60,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor:
                                        (_bars[i] * barAnim.value)
                                            .clamp(0.0, 1.0),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: i == 3
                                            ? Colors.white
                                                .withValues(alpha: 0.85)
                                            : Colors.white
                                                .withValues(alpha: 0.35),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(_labels[i],
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration 2 — AI Insights (trend line + insight cards)
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsIllustration extends StatelessWidget {
  const _InsightsIllustration(
      {required this.stagger, required this.idle});

  final Animation<double> stagger;
  final Animation<double> idle;

  static const _insights = [
    (Icons.trending_down_rounded, 'Food & Drinks', '−12% vs avg',
        Color(0xFF5EEAAA)),
    (Icons.warning_amber_rounded, 'Subscriptions', '3 unused',
        Color(0xFFFFC87A)),
    (Icons.auto_awesome_rounded, 'AI Forecast', '+Kz 48k saved',
        Color(0xFF8FB4FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trend line card
          AnimatedBuilder(
            animation: idle,
            builder: (context, _) {
              final f = math.sin(idle.value * math.pi);
              return Transform.translate(
                offset: Offset(0, f * 4),
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Spending Forecast', Colors.white60),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: stagger,
                        builder: (context, _) {
                          final t = CurvedAnimation(
                                  parent: stagger,
                                  curve: const Interval(0.25, 0.85,
                                      curve: Curves.easeOut))
                              .value;
                          return CustomPaint(
                            size: const Size(double.infinity, 60),
                            painter: _TrendLinePainter(progress: t),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Label('Jan', Colors.white38),
                          _Label('Feb', Colors.white38),
                          _Label('Mar', Colors.white38),
                          _Label('Apr', Colors.white38),
                          _Label('May', Colors.white38),
                          _Label('Jun', Colors.white60),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Insight cards
          ...List.generate(_insights.length, (i) {
            final delay = i * 0.1;
            final t = CurvedAnimation(
              parent: stagger,
              curve: Interval(
                  (0.4 + delay).clamp(0, 1),
                  (0.85 + delay).clamp(0, 1),
                  curve: Curves.easeOut),
            );
            final item = _insights[i];
            return AnimatedBuilder(
              animation: t,
              builder: (context, _) => Opacity(
                opacity: t.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(20 * (1 - t.value), 0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(item.$1, size: 16, color: item.$4),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(item.$3,
                            style: TextStyle(
                                color: item.$4,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      Offset(0, size.height * 0.6),
      Offset(size.width * 0.18, size.height * 0.55),
      Offset(size.width * 0.35, size.height * 0.4),
      Offset(size.width * 0.52, size.height * 0.48),
      Offset(size.width * 0.70, size.height * 0.3),
      Offset(size.width * 0.85, size.height * 0.22),
      Offset(size.width, size.height * 0.12),
    ];

    final visiblePts = <Offset>[];
    final maxIdx = (progress * (pts.length - 1)).floor();
    final frac = (progress * (pts.length - 1)) - maxIdx;

    for (var i = 0; i <= maxIdx && i < pts.length; i++) {
      if (i == maxIdx && i + 1 < pts.length) {
        visiblePts.add(Offset.lerp(pts[i], pts[i + 1], frac)!);
      } else {
        visiblePts.add(pts[i]);
      }
    }
    if (visiblePts.length < 2) return;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(visiblePts[0].dx, visiblePts[0].dy);
    for (var i = 1; i < visiblePts.length; i++) {
      path.lineTo(visiblePts[i].dx, visiblePts[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // Dot at head
    if (visiblePts.isNotEmpty) {
      canvas.drawCircle(
          visiblePts.last,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_TrendLinePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration 3 — Security (shield + check items)
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityIllustration extends StatelessWidget {
  const _SecurityIllustration(
      {required this.stagger, required this.idle});

  final Animation<double> stagger;
  final Animation<double> idle;

  static const _checks = [
    (Icons.fingerprint_rounded, 'Biometric login'),
    (Icons.lock_rounded, 'End-to-end encryption'),
    (Icons.timer_rounded, 'Auto session timeout'),
    (Icons.visibility_off_rounded, 'Private data masking'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shield badge
          AnimatedBuilder(
            animation: Listenable.merge([idle, stagger]),
            builder: (context, _) {
              final f = math.sin(idle.value * math.pi);
              final s = CurvedAnimation(
                      parent: stagger,
                      curve: const Interval(0.0, 0.5,
                          curve: Curves.easeOutBack))
                  .value;
              return Transform.translate(
                offset: Offset(0, f * 6 - 3),
                child: Transform.scale(
                  scale: 0.7 + 0.3 * s,
                  child: Opacity(
                    opacity: s.clamp(0.0, 1.0),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.white.withValues(alpha: 0.08),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded,
                          size: 58, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Check list
          ...List.generate(_checks.length, (i) {
            final delay = i * 0.1;
            final t = CurvedAnimation(
              parent: stagger,
              curve: Interval(
                  (0.3 + delay).clamp(0, 1),
                  (0.75 + delay).clamp(0, 1),
                  curve: Curves.easeOutBack),
            );
            final item = _checks[i];
            return AnimatedBuilder(
              animation: t,
              builder: (context, _) => Opacity(
                opacity: t.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - t.value)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5EEAAA)
                                .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 16, color: Color(0xFF5EEAAA)),
                        ),
                        const SizedBox(width: 12),
                        Icon(item.$1, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(item.$2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500));
  }
}
