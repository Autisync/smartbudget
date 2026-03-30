import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
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
import 'package:smartbudget/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/edit_subscription_screen.dart';
import 'package:smartbudget/features/reports/presentation/screens/reports_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/security_screen.dart';
import 'package:smartbudget/features/settings/presentation/screens/settings_screen.dart';
import 'package:smartbudget/features/auth/presentation/providers/auth_provider.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/legal_document_screen.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart' as bio;
import 'package:smartbudget/core/services/onboarding_service.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(RouterRef ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingState = ref.watch(onboardingStatusProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Wait for auth check to complete
      if (authState.isLoading || onboardingState.isLoading) return '/splash';

      final onboardingStatus = onboardingState.valueOrNull ??
          const OnboardingStatus(
            onboardingComplete: false,
            legalAccepted: false,
          );
      final onboardingComplete = onboardingStatus.isReady;

      final isAuthenticated = authState.valueOrNull ?? false;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isLegalRoute = state.matchedLocation.startsWith('/legal/');
      final isPublicRoute =
          isSplashRoute || isAuthRoute || isOnboardingRoute || isLegalRoute;

      if (!onboardingComplete && !isOnboardingRoute && !isLegalRoute) {
        return '/onboarding';
      }

      if (onboardingComplete && isOnboardingRoute) {
        return isAuthenticated ? '/' : '/login';
      }

      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final useRail = width >= 900;
    final useCompactNav = !useRail && width < 780;

    return Scaffold(
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _calculateSelectedIndex(context),
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: Text(l10n.navHome),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: Text(l10n.transactionsTitle),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: const Icon(Icons.account_balance_wallet),
                      label: Text(l10n.navBudgets),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.savings_outlined),
                      selectedIcon: const Icon(Icons.savings),
                      label: Text(l10n.navSavings),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.subscriptions_outlined),
                      selectedIcon: const Icon(Icons.subscriptions),
                      label: Text(l10n.navSubscriptions),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.description_outlined),
                      selectedIcon: const Icon(Icons.description),
                      label: Text(l10n.reportsTitle),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.insights_outlined),
                      selectedIcon: const Icon(Icons.insights),
                      label: Text(l10n.navInsights),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(l10n.settings),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: useRail
          ? null
          : useCompactNav
              ? _buildCompactNavBar(
                  context,
                  _calculateSelectedIndex(context, compact: true),
                )
              : NavigationBar(
                  selectedIndex: _calculateSelectedIndex(context),
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: l10n.navHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: l10n.transactionsTitle,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: const Icon(Icons.account_balance_wallet),
                      label: l10n.navBudgets,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.savings_outlined),
                      selectedIcon: const Icon(Icons.savings),
                      label: l10n.navSavings,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.subscriptions_outlined),
                      selectedIcon: const Icon(Icons.subscriptions),
                      label: l10n.navSubscriptions,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.description_outlined),
                      selectedIcon: const Icon(Icons.description),
                      label: l10n.reportsTitle,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.insights_outlined),
                      selectedIcon: const Icon(Icons.insights),
                      label: l10n.navInsights,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: l10n.settings,
                    ),
                  ],
                ),
    );
  }

  // Compact bar layout:
  //  0=Txns | 1=Budgets | 2=Home(center) | 3=Savings | 4=More
  int _calculateSelectedIndex(BuildContext context, {bool compact = false}) {
    final location = GoRouterState.of(context).matchedLocation;
    if (compact) {
      if (location == '/') return 2;
      if (location.startsWith('/transactions')) return 0;
      if (location.startsWith('/budgets')) return 1;
      if (location.startsWith('/savings')) return 3;
      // everything else falls under More
      return 4;
    }

    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/savings')) return 3;
    if (location.startsWith('/subscriptions')) return 4;
    if (location.startsWith('/reports')) return 5;
    if (location.startsWith('/insights')) return 6;
    if (location.startsWith('/balance-sheet')) return 6;
    if (location.startsWith('/settings')) return 7;
    if (location.startsWith('/exchange-rates')) return 7;
    if (location.startsWith('/health')) return 0;
    if (location.startsWith('/security')) return 7;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/transactions');
        break;
      case 2:
        GoRouter.of(context).go('/budgets');
        break;
      case 3:
        GoRouter.of(context).go('/savings');
        break;
      case 4:
        GoRouter.of(context).go('/subscriptions');
        break;
      case 5:
        GoRouter.of(context).go('/reports');
        break;
      case 6:
        GoRouter.of(context).go('/insights');
        break;
      case 7:
        GoRouter.of(context).go('/settings');
        break;
    }
  }

  Future<void> _onCompactItemTapped(int index, BuildContext context) async {
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
        await _showMoreSheet(context);
        break;
    }
  }

  Widget _buildCompactNavBar(BuildContext context, int selectedIndex) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget navItem({
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required int index,
    }) {
      final selected = selectedIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () => _onCompactItemTapped(index, context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 24,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              navItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: l10n.navTxns,
                index: 0,
              ),
              navItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
                label: l10n.navBudgets,
                index: 1,
              ),
              // Center Home button
              Expanded(
                child: GestureDetector(
                  onTap: () => _onCompactItemTapped(2, context),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selectedIndex == 2
                              ? colorScheme.primary
                              : colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.home,
                          size: 26,
                          color: selectedIndex == 2
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              navItem(
                icon: Icons.savings_outlined,
                selectedIcon: Icons.savings,
                label: l10n.navSavings,
                index: 3,
              ),
              navItem(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view,
                label: l10n.navMore,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final entries = [
          _MoreSheetEntry(
            icon: Icons.subscriptions_outlined,
            label: l10n.navSubscriptions,
            route: '/subscriptions',
            color: colorScheme.primary,
          ),
          _MoreSheetEntry(
            icon: Icons.description_outlined,
            label: l10n.reportsTitle,
            route: '/reports',
            color: const Color(0xFF14B8A6),
          ),
          _MoreSheetEntry(
            icon: Icons.insights_outlined,
            label: l10n.navInsights,
            route: '/insights',
            color: const Color(0xFFF59E0B),
          ),
          _MoreSheetEntry(
            icon: Icons.account_balance_rounded,
            label: l10n.navBalanceSheet,
            route: '/balance-sheet',
            color: const Color(0xFF22C55E),
          ),
          _MoreSheetEntry(
            icon: Icons.currency_exchange_rounded,
            label: l10n.navExchangeRates,
            route: '/exchange-rates',
            color: const Color(0xFF8B5CF6),
          ),
          _MoreSheetEntry(
            icon: Icons.settings_outlined,
            label: l10n.settings,
            route: '/settings',
            color: colorScheme.onSurfaceVariant,
          ),
        ];

        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _MoreGridTile(
                      icon: entry.icon,
                      label: entry.label,
                      color: entry.color,
                      onTap: () {
                        Navigator.of(context).pop();
                        router.go(entry.route);
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreSheetEntry {
  const _MoreSheetEntry({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _MoreGridTile extends StatelessWidget {
  const _MoreGridTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.2,
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

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFF6366F1)),
            const SizedBox(height: 32),
            const Text(
              'SmartSpend',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.authSecureFinancialManagement,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () async {
                final result = await ref
                    .read(authControllerProvider.notifier)
                    .authenticate();
                if (result != bio.AuthStatus.authenticated && context.mounted) {
                  final message = switch (result) {
                    bio.AuthStatus.notAvailable =>
                      l10n.authBiometricNotAvailable,
                    bio.AuthStatus.noBiometricsEnrolled =>
                      l10n.authNoBiometricsEnrolled,
                    bio.AuthStatus.lockedOut => l10n.authBiometricLockedOut,
                    bio.AuthStatus.permanentlyLockedOut =>
                      l10n.authBiometricPermanentlyLocked,
                    bio.AuthStatus.denied => l10n.authDenied,
                    bio.AuthStatus.error => l10n.authSystemError,
                    bio.AuthStatus.authenticated => l10n.authAuthenticated,
                  };
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
              icon: const Icon(Icons.fingerprint),
              label: Text(l10n.authAuthenticate),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => GoRouter.of(context).push('/legal/terms'),
                  child: Text(l10n.legalTermsTitle),
                ),
                TextButton(
                  onPressed: () => GoRouter.of(context).push('/legal/privacy'),
                  child: Text(l10n.legalPrivacyTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
