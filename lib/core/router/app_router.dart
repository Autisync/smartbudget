import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:smartbudget/core/theme/app_icons.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:smartbudget/features/dashboard/presentation/screens/financial_health_screen.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:smartbudget/features/transactions/presentation/screens/edit_transaction_screen.dart';
import 'package:smartbudget/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:smartbudget/features/budgets/presentation/screens/budget_screen.dart';
import 'package:smartbudget/features/savings/presentation/screens/savings_screen.dart';
import 'package:smartbudget/features/insights/presentation/screens/insights_screen.dart';
import 'package:smartbudget/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:smartbudget/features/exchange_rates/presentation/screens/exchange_rates_screen.dart';
import 'package:smartbudget/features/balance_sheet/presentation/screens/recurring_balance_sheet_screen.dart';
import 'package:smartbudget/features/scenario_lab/presentation/screens/scenario_lab_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/edit_subscription_screen.dart';
import 'package:smartbudget/features/reports/presentation/screens/reports_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/security_screen.dart';
import 'package:smartbudget/features/settings/presentation/screens/settings_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/login_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/signup_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/legal_document_screen.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/legal_center_screen.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:smartbudget/core/services/onboarding_service.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/widgets/logo_loading_indicator.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(RouterRef ref) {
  final sessionState = ref.watch(sessionControllerProvider);
  final onboardingState = ref.watch(onboardingStatusProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      if (sessionState.initializing || onboardingState.isLoading) {
        return '/splash';
      }

      final onboardingStatus = onboardingState.valueOrNull ??
          const OnboardingStatus(
            onboardingComplete: false,
            legalAccepted: false,
          );
      final onboardingComplete = onboardingStatus.isReady;

      final isAuthenticated = sessionState.authenticated;
      final localUnlockRequired =
          sessionState.authenticated && sessionState.localUnlockRequired;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';
      final isSignupRoute = state.matchedLocation == '/signup';
      final isForgotPasswordRoute = state.matchedLocation == '/forgot-password';
      final isResetPasswordRoute = state.matchedLocation == '/reset-password';
      final isVerifyEmailRoute = state.matchedLocation == '/verify-email';
      final isAuthRoute = isLoginRoute ||
          isSignupRoute ||
          isForgotPasswordRoute ||
          isResetPasswordRoute ||
          isVerifyEmailRoute;
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isLegalRoute = state.matchedLocation == '/legal' ||
          state.matchedLocation.startsWith('/legal/');
      final isPublicRoute =
          isSplashRoute || isAuthRoute || isOnboardingRoute || isLegalRoute;

      if (!onboardingComplete && !isOnboardingRoute && !isLegalRoute) {
        return '/onboarding';
      }

      if (onboardingComplete && isOnboardingRoute) {
        return isAuthenticated ? '/' : '/login';
      }

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated && localUnlockRequired && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && !localUnlockRequired && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: LogoLoadingIndicator(
              label: 'Loading SmartSpend...',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalCenterScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.terms),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.privacy),
      ),
      GoRoute(
        path: '/legal/cookies',
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.cookies),
      ),
      GoRoute(
        path: '/legal/acceptable-use',
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.acceptableUse),
      ),
      GoRoute(
        path: '/legal/data-retention',
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.dataRetention),
      ),
      GoRoute(
        path: '/legal/security-disclosure',
        builder: (context, state) => const LegalDocumentScreen(
          type: LegalDocumentType.securityDisclosure,
        ),
      ),
      GoRoute(
        path: '/legal/third-party-services',
        builder: (context, state) => const LegalDocumentScreen(
          type: LegalDocumentType.thirdPartyServices,
        ),
      ),
      GoRoute(
        path: '/legal/disclaimers',
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.disclaimers),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => VerifyEmailScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionListScreen(),
          ),
          GoRoute(
            path: '/transactions/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return EditTransactionScreen(transactionId: id!);
            },
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetScreen(),
          ),
          GoRoute(
            path: '/savings',
            builder: (context, state) => const SavingsScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/exchange-rates',
            builder: (context, state) => const ExchangeRatesScreen(),
          ),
          GoRoute(
            path: '/balance-sheet',
            builder: (context, state) => const RecurringBalanceSheetScreen(),
          ),
          GoRoute(
            path: '/scenario-lab',
            builder: (context, state) => const ScenarioLabScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/health',
            builder: (context, state) => const FinancialHealthScreen(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => const SecurityScreen(),
          ),
        ],
      ),
      // Present AddTransaction on the root navigator so it appears above the
      // ShellRoute's scaffold (full-screen modal/push). It must be a top-level
      // route because it uses _rootNavigatorKey as its parentNavigatorKey.
      GoRoute(
        path: '/transactions/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/subscriptions/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddSubscriptionScreen(),
      ),
      GoRoute(
        path: '/subscriptions/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return EditSubscriptionScreen(subscriptionId: id!);
        },
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  bool _isMoreSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              selectedIndex: _calculateRailSelectedIndex(context),
              onDestinationSelected: (index) => _onRailItemTapped(index),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long_rounded),
                  label: Text(l10n.transactionsTitle),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon:
                      const Icon(Icons.account_balance_wallet_rounded),
                  label: Text(l10n.navBudgets),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: Text(l10n.navHome),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.savings_outlined),
                  selectedIcon: const Icon(Icons.savings_rounded),
                  label: Text(l10n.navSavings),
                ),
                const NavigationRailDestination(
                  icon: Icon(AppIcons.moreGrid),
                  selectedIcon: Icon(AppIcons.moreGridFilled),
                  label: Text('More'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _calculateBottomIndex(context),
        moreTemporarilyActive: _isMoreSheetOpen,
        onTabSelected: _onBottomTabSelected,
      ),
    );
  }

  int _calculateBottomIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/transactions')) return 0;
    if (location.startsWith('/budgets')) return 1;
    if (location == '/' || location.startsWith('/health')) return 2;
    if (location.startsWith('/savings')) return 3;
    if (location.startsWith('/reports') ||
        location.startsWith('/subscriptions') ||
        location.startsWith('/settings') ||
        location.startsWith('/security') ||
        location.startsWith('/legal') ||
        location.startsWith('/insights') ||
        location.startsWith('/notifications') ||
        location.startsWith('/exchange-rates') ||
        location.startsWith('/balance-sheet')) {
      return 4;
    }
    return 2;
  }

  int _calculateRailSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/transactions')) return 0;
    if (location.startsWith('/budgets')) return 1;
    if (location == '/' || location.startsWith('/health')) return 2;
    if (location.startsWith('/savings')) return 3;
    return 4;
  }

  void _onRailItemTapped(int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/transactions');
        break;
      case 1:
        GoRouter.of(context).go('/budgets');
        break;
      case 2:
        GoRouter.of(context).go('/');
        break;
      case 3:
        GoRouter.of(context).go('/savings');
        break;
      case 4:
        _onBottomTabSelected(4);
        break;
    }
  }

  Future<void> _onBottomTabSelected(int index) async {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/transactions');
        break;
      case 1:
        GoRouter.of(context).go('/budgets');
        break;
      case 2:
        GoRouter.of(context).go('/');
        break;
      case 3:
        GoRouter.of(context).go('/savings');
        break;
      case 4:
        if (mounted) {
          setState(() => _isMoreSheetOpen = true);
        }
        await _showMoreSheet();
        if (mounted) {
          setState(() => _isMoreSheetOpen = false);
        }
        break;
    }
  }

  Future<void> _showMoreSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);

    await showCupertinoModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;
        final container = ProviderScope.containerOf(sheetContext);
        var isDarkMode =
            container.read(themeModeControllerProvider) == ThemeMode.dark;

        void goTo(String route) {
          Navigator.of(sheetContext).pop();
          router.go(route);
        }

        void pushTo(String route) {
          Navigator.of(sheetContext).pop();
          router.push(route);
        }

        Future<void> openHelpWebsite() async {
          final websiteUri = Uri.parse('https://www.smaartspend.com');
          final launched = await launchUrl(
            websiteUri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched && sheetContext.mounted) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(
                content: Text('Unable to open website right now.'),
              ),
            );
          }
        }

        return Material(
          color: Colors.transparent,
          child: AnimatedPadding(
            duration: UiTokens.motionFast,
            curve: UiTokens.motionCurve,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(UiTokens.radius2xl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.86,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: UiTokens.space12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'More',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: MaterialLocalizations.of(sheetContext)
                                .closeButtonTooltip,
                          ),
                        ],
                      ),
                      const _MoreSectionHeader(title: 'Account'),
                      AppSettingsTile(
                        icon: AppIcons.settingsFilled,
                        title: l10n.settings,
                        onTap: () => goTo('/settings'),
                      ),
                      const SizedBox(height: UiTokens.space8),
                      Row(
                        children: [
                          Expanded(
                            child: _MoreQuickAction(
                              icon: AppIcons.subscriptionsFilled,
                              label: l10n.navSubscriptions,
                              onTap: () => goTo('/subscriptions'),
                            ),
                          ),
                          const SizedBox(width: UiTokens.space8),
                          Expanded(
                            child: _MoreQuickAction(
                              icon: AppIcons.reportsFilled,
                              label: l10n.reportsTitle,
                              onTap: () => goTo('/reports'),
                            ),
                          ),
                          const SizedBox(width: UiTokens.space8),
                          Expanded(
                            child: _MoreQuickAction(
                              icon: AppIcons.exchangeRates,
                              label: l10n.navExchangeRates,
                              onTap: () => goTo('/exchange-rates'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UiTokens.space8),
                      Row(
                        children: [
                          Expanded(
                            child: _MoreQuickAction(
                              icon: AppIcons.insightsFilled,
                              label: l10n.insightsFinancialCopilot,
                              onTap: () => goTo('/insights'),
                            ),
                          ),
                          const SizedBox(width: UiTokens.space8),
                          Expanded(
                            child: _MoreQuickAction(
                              icon: Icons.ios_share_rounded,
                              label: 'Export',
                              onTap: () => goTo('/reports'),
                            ),
                          ),
                          const SizedBox(width: UiTokens.space8),
                          Expanded(
                            child: _MoreQuickAction(
                              icon: Icons.science_rounded,
                              label: 'Scenario Lab',
                              onTap: () => goTo('/scenario-lab'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UiTokens.space16),
                      AppSettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Authentication settings',
                        onTap: () => goTo('/security'),
                      ),
                      const SizedBox(height: UiTokens.space12),
                      const _MoreSectionHeader(title: 'Support'),
                      StatefulBuilder(
                        builder: (context, setTileState) {
                          Future<void> updateTheme(bool value) async {
                            setTileState(() => isDarkMode = value);
                            await container
                                .read(themeModeControllerProvider.notifier)
                                .setThemeMode(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                );
                          }

                          return AppSettingsTile(
                            icon: Icons.dark_mode_rounded,
                            title: 'Dark Mode Settings',
                            subtitle: isDarkMode ? 'Night mode' : 'Light mode',
                            trailing: Switch.adaptive(
                              value: isDarkMode,
                              onChanged: updateTheme,
                            ),
                            onTap: () => updateTheme(!isDarkMode),
                          );
                        },
                      ),
                      const SizedBox(height: UiTokens.space8),
                      AppSettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help / Feedback',
                        onTap: openHelpWebsite,
                      ),
                      const SizedBox(height: UiTokens.space8),
                      AppSettingsTile(
                        icon: Icons.gavel_rounded,
                        title: l10n.legalCenterTitle,
                        onTap: () => pushTo('/legal'),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoreSectionHeader extends StatelessWidget {
  const _MoreSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.9),
            ),
      ),
    );
  }
}

class _MoreQuickAction extends StatelessWidget {
  const _MoreQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(UiTokens.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UiTokens.space8,
          vertical: UiTokens.space12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(UiTokens.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(height: UiTokens.space4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
