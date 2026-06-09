import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';

// ---------------------------------------------------------------------------
// Tour step data
// ---------------------------------------------------------------------------

class _TourStep {
  const _TourStep({
    required this.icon,
    required this.title,
    required this.body,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? accentColor;
}

const _steps = <_TourStep>[
  _TourStep(
    icon: Icons.waving_hand_rounded,
    title: 'Welcome to SmartSpend',
    body:
        'Your personal finance companion. Track spending, set budgets, grow savings — all in one place.',
    accentColor: AppColors.brand,
  ),
  _TourStep(
    icon: Icons.add_circle_rounded,
    title: 'Add anything with "+"',
    body:
        'The "+" button in the bottom-right opens a quick menu to add a transaction, subscription, savings goal, or budget.',
    accentColor: AppColors.success,
  ),
  _TourStep(
    icon: Icons.grid_view_rounded,
    title: 'Explore with the grid icon',
    body:
        'The four-squares icon in the nav bar opens your full menu — settings, reports, AI insights, exchange rates and more.',
    accentColor: AppColors.info,
  ),
  _TourStep(
    icon: Icons.insights_rounded,
    title: 'Stay on track',
    body:
        'Your dashboard shows a live snapshot of your net balance, budget health and savings progress every time you open the app.',
    accentColor: AppColors.warning,
  ),
];

// ---------------------------------------------------------------------------
// Overlay widget (wraps the shell with the tour on first launch)
// ---------------------------------------------------------------------------

/// Wraps [child] with a full-screen tour overlay on the user's first launch
/// after completing the account and legal onboarding.
class AppTourOverlay extends ConsumerStatefulWidget {
  const AppTourOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends ConsumerState<AppTourOverlay>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  bool _dismissed = false;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: UiTokens.motionMedium,
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: UiTokens.motionCurve);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    if (!mounted) return;
    setState(() => _dismissed = true);
    // Persist so the tour never shows again.
    await ref.read(onboardingServiceProvider).markAppTourSeen();
    // Invalidate the provider so the overlay is not shown again this session.
    ref.invalidate(appTourSeenProvider);
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show once tour-seen status has loaded and is false.
    final tourSeenAsync = ref.watch(appTourSeenProvider);
    final showTour = tourSeenAsync.valueOrNull == false && !_dismissed;

    return Stack(
      children: [
        widget.child,
        if (showTour)
          FadeTransition(
            opacity: _fade,
            child: _TourCard(
              step: _step,
              totalSteps: _steps.length,
              onNext: _next,
              onSkip: _dismiss,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tour card
// ---------------------------------------------------------------------------

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final data = _steps[step];
    final isLast = step == totalSteps - 1;
    final accent = data.accentColor ?? cs.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen backdrop blur + dim
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.45),
              ),
            ),
          ),
          // Tap outside to skip (full-screen GestureDetector behind the card)
          Positioned.fill(
            child: GestureDetector(
              onTap: onSkip,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // Centred card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedSwitcher(
                duration: UiTokens.motionMedium,
                switchInCurve: UiTokens.motionCurve,
                switchOutCurve: UiTokens.motionCurve.flipped,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _StepCard(
                  key: ValueKey(step),
                  data: data,
                  step: step,
                  totalSteps: totalSteps,
                  accent: accent,
                  isDark: isDark,
                  cs: cs,
                  isLast: isLast,
                  onNext: onNext,
                  onSkip: onSkip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.data,
    required this.step,
    required this.totalSteps,
    required this.accent,
    required this.isDark,
    required this.cs,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final _TourStep data;
  final int step;
  final int totalSteps;
  final Color accent;
  final bool isDark;
  final ColorScheme cs;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? cs.surfaceContainerHigh.withValues(alpha: 0.92)
        : cs.surface.withValues(alpha: 0.96);

    return ClipRRect(
      borderRadius: BorderRadius.circular(UiTokens.radius2xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(UiTokens.radius2xl),
            border: Border.all(
              color: cs.outline.withValues(alpha: isDark ? 0.25 : 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress dots
              Row(
                children: List.generate(totalSteps, (i) {
                  final active = i == step;
                  return AnimatedContainer(
                    duration: UiTokens.motionFast,
                    curve: UiTokens.motionCurve,
                    width: active ? 24 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? accent
                          : cs.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, size: 32, color: accent),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                data.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 10),
              // Body
              Text(
                data.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 28),
              // Buttons
              Row(
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurfaceVariant,
                      ),
                      child: const Text('Skip tour'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isLast ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
