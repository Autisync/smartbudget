import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step definitions
// ─────────────────────────────────────────────────────────────────────────────

class _TourStep {
  const _TourStep({
    required this.title,
    required this.subtitle,
    required this.gradientTop,
    required this.gradientBottom,
    required this.illustration,
  });

  final String title;
  final String subtitle;
  final Color gradientTop;
  final Color gradientBottom;
  final Widget Function(BuildContext, Animation<double>) illustration;
}

final _steps = <_TourStep>[
  _TourStep(
    title: 'Welcome to SmartSpend',
    subtitle:
        'Your all-in-one personal finance app. Track spending, build budgets, and grow savings — all in one place.',
    gradientTop: const Color(0xFF1A1060),
    gradientBottom: const Color(0xFF4C3BE8),
    illustration: (ctx, anim) => _WelcomeIllustration(progress: anim),
  ),
  _TourStep(
    title: 'Track every transaction',
    subtitle:
        'Log cash, bank transfers and credit card payments. See exactly where your money goes in real time.',
    gradientTop: const Color(0xFF0B3528),
    gradientBottom: const Color(0xFF1A9E6A),
    illustration: (ctx, anim) => _TransactionsIllustration(progress: anim),
  ),
  _TourStep(
    title: 'Set budgets & goals',
    subtitle:
        'Create category budgets and savings goals. SmartSpend tracks your progress and warns you before you overspend.',
    gradientTop: const Color(0xFF3A1200),
    gradientBottom: const Color(0xFFF09030),
    illustration: (ctx, anim) => _BudgetsIllustration(progress: anim),
  ),
  _TourStep(
    title: 'Add anything in one tap',
    subtitle:
        'The "+" button launches a quick-add menu. The grid icon opens navigation — reports, accounts, AI insights and more.',
    gradientTop: const Color(0xFF0D1F3C),
    gradientBottom: const Color(0xFF3B7BFF),
    illustration: (ctx, anim) => _NavIllustration(progress: anim),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Root overlay widget
// ─────────────────────────────────────────────────────────────────────────────

class AppTourOverlay extends ConsumerStatefulWidget {
  const AppTourOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends ConsumerState<AppTourOverlay>
    with TickerProviderStateMixin {
  bool _dismissed = false;
  late final AnimationController _enterCtrl;
  late final AnimationController _exitCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..forward();
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    HapticFeedback.lightImpact();
    await _exitCtrl.forward();
    if (!mounted) return;
    setState(() => _dismissed = true);
    await ref.read(onboardingServiceProvider).markAppTourSeen();
    ref.invalidate(appTourSeenProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tourSeenAsync = ref.watch(appTourSeenProvider);
    final showTour = tourSeenAsync.valueOrNull == false && !_dismissed;

    return Stack(
      children: [
        widget.child,
        if (showTour)
          AnimatedBuilder(
            animation: Listenable.merge([_enterCtrl, _exitCtrl]),
            builder: (context, _) {
              final enterT = CurvedAnimation(
                      parent: _enterCtrl, curve: Curves.easeOutCubic)
                  .value;
              final exitT = CurvedAnimation(
                      parent: _exitCtrl, curve: Curves.easeInCubic)
                  .value;
              final opacity = enterT * (1 - exitT);
              final slide = (1 - enterT) * 0.06 + exitT * 0.04;
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, MediaQuery.sizeOf(context).height * slide),
                  child: _TourFlow(onDismiss: _dismiss),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen tour flow (PageView + state)
// ─────────────────────────────────────────────────────────────────────────────

class _TourFlow extends StatefulWidget {
  const _TourFlow({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_TourFlow> createState() => _TourFlowState();
}

class _TourFlowState extends State<_TourFlow> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  // Per-step stagger controller (reset on every page change).
  late AnimationController _stagger;

  // Background gradient interpolation (driven by page scroll).
  late AnimationController _bgCtrl;
  int _bgFrom = 0;
  int _bgTo = 0;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _stagger.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _steps.length) return;
    _bgFrom = _page;
    _bgTo = page;
    _bgCtrl
      ..reset()
      ..forward();
    _stagger
      ..reset()
      ..forward();
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _page = page);
    HapticFeedback.selectionClick();
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _goTo(_page + 1);
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background gradient
          Positioned.fill(child: _AnimatedBg(
            fromStep: _bgFrom,
            toStep: _bgTo,
            animation: CurvedAnimation(
                parent: _bgCtrl, curve: Curves.easeInOutCubic),
          )),

          // Swipeable page content (illustration area only — no swiping text)
          Positioned.fill(
            child: PageView.builder(
              controller: _pageCtrl,
              physics: const BouncingScrollPhysics(),
              itemCount: _steps.length,
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
              itemBuilder: (context, i) => _PageSlide(
                step: _steps[i],
                stagger: _stagger,
              ),
            ),
          ),

          // Bottom text + controls panel (slides up once, stays put)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomPanel(
              step: _page,
              totalSteps: _steps.length,
              stagger: _stagger,
              onNext: _next,
              onSkip: widget.onDismiss,
            ),
          ),

          // Top safe-area skip button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: 20,
            child: AnimatedBuilder(
              animation: _stagger,
              builder: (context, _) {
                final t = CurvedAnimation(
                        parent: _stagger,
                        curve: const Interval(0.6, 1.0,
                            curve: Curves.easeOut))
                    .value;
                return Opacity(
                  opacity: t,
                  child: _page < _steps.length - 1
                      ? TextButton(
                          onPressed: widget.onDismiss,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white60,
                          ),
                          child: Text(AppLocalizations.of(context)!.onboardingSkip),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated gradient background
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBg extends AnimatedWidget {
  const _AnimatedBg({
    required this.fromStep,
    required this.toStep,
    required Animation<double> animation,
  }) : super(listenable: animation);

  final int fromStep;
  final int toStep;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    final from = _steps[fromStep.clamp(0, _steps.length - 1)];
    final to = _steps[toStep.clamp(0, _steps.length - 1)];
    final top = Color.lerp(from.gradientTop, to.gradientTop, t)!;
    final bottom = Color.lerp(from.gradientBottom, to.gradientBottom, t)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-height page slide (illustration)
// ─────────────────────────────────────────────────────────────────────────────

class _PageSlide extends StatelessWidget {
  const _PageSlide({required this.step, required this.stagger});

  final _TourStep step;
  final AnimationController stagger;

  @override
  Widget build(BuildContext context) {
    final illustAnim = CurvedAnimation(
        parent: stagger,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack));
    return Align(
      alignment: const Alignment(0, -0.15),
      child: AnimatedBuilder(
        animation: illustAnim,
        builder: (context, child) => Transform.scale(
          scale: 0.85 + 0.15 * illustAnim.value,
          child: Opacity(
            opacity: illustAnim.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.44,
          // Drive the illustrations from the raw [stagger] controller (range
          // [0,1]). They each nest their own CurvedAnimation/Interval, and the
          // overshooting easeOutBack of [illustAnim] would push the parent value
          // above 1.0, tripping Flutter's Curve.transform assertion.
          child: step.illustration(context, stagger),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom panel — text + dots + buttons
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.step,
    required this.totalSteps,
    required this.stagger,
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final int totalSteps;
  final AnimationController stagger;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final data = _steps[step];
    final isLast = step == totalSteps - 1;
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.tourWelcomeTitle,
      l10n.tourTrackTitle,
      l10n.tourBudgetsTitle,
      l10n.tourAddTitle,
    ];
    final subtitles = [
      l10n.tourWelcomeSubtitle,
      l10n.tourTrackSubtitle,
      l10n.tourBudgetsSubtitle,
      l10n.tourAddSubtitle,
    ];
    final stepTitle = step < titles.length ? titles[step] : data.title;
    final stepSubtitle =
        step < subtitles.length ? subtitles[step] : data.subtitle;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(28, 32, 28, bottom + 28),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity( 0.35),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withOpacity( 0.12), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step dots
              AnimatedBuilder(
                animation: stagger,
                builder: (context, _) {
                  final t = CurvedAnimation(
                          parent: stagger,
                          curve: const Interval(0.1, 0.5,
                              curve: Curves.easeOut))
                      .value;
                  return Opacity(
                    opacity: t,
                    child: Row(
                      children: List.generate(totalSteps, (i) {
                        final active = i == step;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: active ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity( 0.28),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
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
                        offset: Offset(0, 16 * (1 - t)), child: child),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    stepTitle,
                    key: ValueKey(step),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
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
                        offset: Offset(0, 12 * (1 - t)), child: child),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    stepSubtitle,
                    key: ValueKey(step),
                    style: TextStyle(
                      color: Colors.white.withOpacity( 0.75),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Buttons
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
                child: Row(
                  children: [
                    if (!isLast)
                      GestureDetector(
                        onTap: onSkip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withOpacity( 0.45),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Next / Get started button
                    GestureDetector(
                      onTap: onNext,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity( 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Get started' : 'Next',
                              style: const TextStyle(
                                color: Color(0xFF14161D),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 16, color: Color(0xFF14161D)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Welcome illustration (floating cards + brand mark)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeIllustration extends StatefulWidget {
  const _WelcomeIllustration({required this.progress});
  final Animation<double> progress;
  @override
  State<_WelcomeIllustration> createState() => _WelcomeIllustrationState();
}

class _WelcomeIllustrationState extends State<_WelcomeIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) {
        final f = math.sin(_float.value * math.pi);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity( 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Central logo mark
            Transform.translate(
              offset: Offset(0, f * 6),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity( 0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withOpacity( 0.3), width: 1.5),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 48, color: Colors.white),
              ),
            ),
            // Floating mini-cards
            ..._floatingCard(-130, -60, f, 0, '+ Kz 45,000', Icons.arrow_upward_rounded, AppColors.success),
            ..._floatingCard(100, -80, f, 0.4, '− Kz 3,200', Icons.arrow_downward_rounded, AppColors.danger),
            ..._floatingCard(-80, 90, f, 0.7, 'Kz 1.2M', Icons.savings_rounded, AppColors.brand),
            ..._floatingCard(110, 70, f, 0.2, '87% budget', Icons.pie_chart_rounded, AppColors.warning),
          ],
        );
      },
    );
  }

  List<Widget> _floatingCard(
      double dx, double dy, double f, double phase, String label,
      IconData icon, Color color) {
    final offset = math.sin((f + phase) * math.pi) * 5;
    return [
      Transform.translate(
        offset: Offset(dx, dy + offset),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity( 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity( 0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Transaction list illustration
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionsIllustration extends StatelessWidget {
  const _TransactionsIllustration({required this.progress});
  final Animation<double> progress;

  static const _items = [
    ('Grocery Store', '−Kz 4,200', Icons.shopping_cart_rounded, false),
    ('Salary', '+Kz 280,000', Icons.work_rounded, true),
    ('Netflix', '−Kz 1,800', Icons.play_circle_rounded, false),
    ('Freelance', '+Kz 55,000', Icons.computer_rounded, true),
    ('Electricity', '−Kz 6,500', Icons.bolt_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_items.length, (i) {
          final delay = i * 0.12;
          final t = CurvedAnimation(
            parent: progress,
            curve: Interval(delay, (delay + 0.45).clamp(0, 1),
                curve: Curves.easeOutBack),
          );
          final item = _items[i];
          final isIncome = item.$4;
          return AnimatedBuilder(
            animation: t,
            builder: (context, _) => Opacity(
              opacity: t.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(30 * (1 - t.value), 0),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity( 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity( 0.15), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (isIncome ? AppColors.success : AppColors.danger)
                              .withOpacity( 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.$3, size: 18,
                            color: isIncome ? AppColors.success : AppColors.danger),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item.$1,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text(item.$2,
                          style: TextStyle(
                              color: isIncome ? AppColors.success : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Budgets illustration (progress bars)
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetsIllustration extends StatelessWidget {
  const _BudgetsIllustration({required this.progress});
  final Animation<double> progress;

  static const _budgets = [
    ('Groceries', 0.72, AppColors.success),
    ('Transport', 0.45, AppColors.info),
    ('Entertainment', 0.91, AppColors.danger),
    ('Utilities', 0.33, AppColors.success),
    ('Savings goal', 0.62, AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_budgets.length, (i) {
          final delay = i * 0.1;
          final appear = CurvedAnimation(
            parent: progress,
            curve: Interval(delay, (delay + 0.4).clamp(0, 1),
                curve: Curves.easeOut),
          );
          final fill = CurvedAnimation(
            parent: progress,
            curve: Interval((delay + 0.15).clamp(0, 1),
                (delay + 0.75).clamp(0, 1),
                curve: Curves.easeOutCubic),
          );
          final item = _budgets[i];
          return AnimatedBuilder(
            animation: Listenable.merge([appear, fill]),
            builder: (context, _) {
              final barWidth = item.$2 * fill.value;
              final isOver = item.$2 > 0.85;
              return Opacity(
                opacity: appear.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - appear.value)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.$1,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text('${(item.$2 * 100).toInt()}%',
                                style: TextStyle(
                                    color: isOver
                                        ? AppColors.danger
                                        : Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity( 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: barWidth.clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: item.$3,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.$3.withOpacity( 0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Nav bar illustration
// ─────────────────────────────────────────────────────────────────────────────

class _NavIllustration extends StatelessWidget {
  const _NavIllustration({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final capsule = CurvedAnimation(
        parent: progress,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack));
    final menu = CurvedAnimation(
        parent: progress,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutBack));
    final items = CurvedAnimation(
        parent: progress,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    const menuItems = [
      (Icons.settings_rounded, 'Settings'),
      (Icons.account_balance_wallet_rounded, 'Accounts'),
      (Icons.layers_rounded, 'Subscriptions'),
      (Icons.bar_chart_rounded, 'Reports'),
      (Icons.swap_horiz_rounded, 'FX Rates'),
      (Icons.insights_rounded, 'AI Insights'),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Menu panel
        AnimatedBuilder(
          animation: menu,
          builder: (context, _) => Transform.scale(
            scale: 0.85 + 0.15 * menu.value,
            alignment: Alignment.bottomRight,
            child: Opacity(
              opacity: menu.value.clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity( 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity( 0.2), width: 1),
                ),
                child: AnimatedBuilder(
                  animation: items,
                  builder: (context, _) => GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.15,
                    children: List.generate(menuItems.length, (i) {
                      final delay = i * 0.07;
                      final t = CurvedAnimation(
                        parent: items,
                        curve: Interval(delay, (delay + 0.4).clamp(0, 1),
                            curve: Curves.easeOut),
                      ).value;
                      return Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * t,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity( 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(menuItems[i].$1,
                                    size: 18, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(menuItems[i].$2,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Nav capsule + plus button
        AnimatedBuilder(
          animation: capsule,
          builder: (context, _) => Opacity(
            opacity: capsule.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - capsule.value)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity( 0.15),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                              color: Colors.white.withOpacity( 0.25),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icons.home_rounded,
                            Icons.receipt_long_rounded,
                            Icons.account_balance_wallet_rounded,
                            Icons.savings_rounded,
                            Icons.grid_view_rounded,
                          ].map((icon) => Icon(icon, size: 20, color: Colors.white70)).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity( 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity( 0.3),
                            width: 1),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
