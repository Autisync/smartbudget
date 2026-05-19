import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = [
      _OnboardingPageData(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.onboardingPage1Title,
        description: l10n.onboardingPage1Description,
        colors: const [Color(0xFF24184E), Color(0xFF6D5DF6)],
      ),
      _OnboardingPageData(
        icon: Icons.insights_outlined,
        title: l10n.onboardingPage2Title,
        description: l10n.onboardingPage2Description,
        colors: const [Color(0xFF0E3A5B), Color(0xFF2EA7FF)],
      ),
      _OnboardingPageData(
        icon: Icons.security_outlined,
        title: l10n.onboardingPage3Title,
        description: l10n.onboardingPage3Description,
        colors: const [Color(0xFF12372A), Color(0xFF10A66A)],
      ),
    ];
    final isLastPage = _pageIndex == pages.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surface,
                    colorScheme.primary.withOpacity(0.08),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(pages.length, (index) {
                            final isActive = index == _pageIndex;
                            return Expanded(
                              child: AnimatedContainer(
                                duration: UiTokens.motionMedium,
                                curve: UiTokens.motionCurve,
                                margin: EdgeInsets.only(
                                  right: index == pages.length - 1 ? 0 : 8,
                                ),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.14,
                                        ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(l10n.onboardingSkip),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) =>
                          setState(() => _pageIndex = index),
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return AnimatedSwitcher(
                          duration: UiTokens.motionMedium,
                          child: Column(
                            key: ValueKey(page.title),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(maxHeight: 280),
                                padding: const EdgeInsets.all(24),
                                decoration: AppSurfaces.gradientCard(
                                  context,
                                  colors: page.colors,
                                  radius: UiTokens.radius2xl,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1.45,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: -18,
                                        top: -18,
                                        child: Icon(
                                          page.icon,
                                          size: 132,
                                          color: Colors.white.withOpacity(0.16,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.18,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(22),
                                          ),
                                          child: Icon(
                                            page.icon,
                                            size: 34,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                page.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      height: 1.45,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final router = GoRouter.of(context);

                        if (!isLastPage) {
                          await _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                          return;
                        }

                        await ref
                            .read(onboardingServiceProvider)
                            .completeOnboarding(
                              acceptedLegal: true,
                              reviewedAt: DateTime.now().toUtc(),
                            );
                        ref.invalidate(onboardingStatusProvider);

                        if (!mounted) return;
                        router.go('/login');
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        isLastPage
                            ? l10n.onboardingGetStarted
                            : l10n.onboardingContinue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> colors;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
  });
}




