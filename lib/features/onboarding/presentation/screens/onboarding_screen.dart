import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _acceptedLegal = false;

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
      ),
      _OnboardingPageData(
        icon: Icons.insights_outlined,
        title: l10n.onboardingPage2Title,
        description: l10n.onboardingPage2Description,
      ),
      _OnboardingPageData(
        icon: Icons.security_outlined,
        title: l10n.onboardingPage3Title,
        description: l10n.onboardingPage3Description,
      ),
    ];
    final isLastPage = _pageIndex == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(pages.length, (index) {
                  final isActive = index == _pageIndex;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                          right: index == pages.length - 1 ? 0 : 8),
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.onboardingSkip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(page.icon,
                              size: 44, color: Colors.tealAccent),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.72),
                                  ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (isLastPage) ...[
                CheckboxListTile(
                  value: _acceptedLegal,
                  onChanged: (value) {
                    setState(() => _acceptedLegal = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.onboardingAcceptLegal),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/legal/terms'),
                      child: Text(l10n.legalTermsTitle),
                    ),
                    TextButton(
                      onPressed: () => context.push('/legal/privacy'),
                      child: Text(l10n.legalPrivacyTitle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
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

                    if (!_acceptedLegal) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.onboardingAcceptLegalError),
                        ),
                      );
                      return;
                    }

                    await ref
                        .read(onboardingServiceProvider)
                        .completeOnboarding(acceptedLegal: true);
                    ref.invalidate(onboardingStatusProvider);

                    if (!mounted) return;
                    router.go('/login');
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
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
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
