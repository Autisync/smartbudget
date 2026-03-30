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
    final width = MediaQuery.of(context).size.width;
    final useRail = width >= 900;
    final useCompactNav = !useRail && width < 700;

    return Scaffold(
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _calculateSelectedIndex(context),
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Transactions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('Budgets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.savings_outlined),
                      selectedIcon: Icon(Icons.savings),
                      label: Text('Savings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.subscriptions_outlined),
                      selectedIcon: Icon(Icons.subscriptions),
                      label: Text('Subscriptions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.description_outlined),
                      selectedIcon: Icon(Icons.description),
                      label: Text('Reports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights),
                      label: Text('Insights'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
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
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: 'Transactions',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: 'Budgets',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.savings_outlined),
                      selectedIcon: Icon(Icons.savings),
                      label: 'Savings',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.subscriptions_outlined),
                      selectedIcon: Icon(Icons.subscriptions),
                      label: 'Subscriptions',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.description_outlined),
                      selectedIcon: Icon(Icons.description),
                      label: 'Reports',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights),
                      label: 'Insights',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
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
                label: 'Txns',
                index: 0,
              ),
              navItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
                label: 'Budgets',
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
                label: 'Savings',
                index: 3,
              ),
              navItem(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view,
                label: 'More',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreSheet(BuildContext context) async {
    final router = GoRouter.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.subscriptions_outlined),
                title: const Text('Subscriptions'),
                onTap: () {
                  Navigator.of(context).pop();
                  router.go('/subscriptions');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.of(context).pop();
                  router.go('/reports');
                },
              ),
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Insights'),
                onTap: () {
                  Navigator.of(context).pop();
                  router.go('/insights');
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_rounded),
                title: const Text('Balance Sheet'),
                onTap: () {
                  Navigator.of(context).pop();
                  router.go('/balance-sheet');
                },
              ),
              ListTile(
                leading: const Icon(Icons.currency_exchange_rounded),
                title: const Text('Exchange Rates'),
                onTap: () {
                  Navigator.of(context).pop();
                  router.go('/exchange-rates');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  router.go('/settings');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFF6366F1)),
            const SizedBox(height: 32),
            const Text(
              'SmartBudget',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Secure Financial Management',
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
                      'Biometric authentication is not available on this Mac. Verify Touch ID is enabled in System Settings.',
                    bio.AuthStatus.noBiometricsEnrolled =>
                      'No biometrics enrolled. Add Touch ID in System Settings and try again.',
                    bio.AuthStatus.lockedOut =>
                      'Biometric authentication is temporarily locked. Try again later.',
                    bio.AuthStatus.permanentlyLockedOut =>
                      'Biometric authentication is locked. Unlock with your device passcode first.',
                    bio.AuthStatus.denied =>
                      'Authentication was canceled or denied. Please try again.',
                    bio.AuthStatus.error =>
                      'Authentication failed due to a system error. Please try again.',
                    bio.AuthStatus.authenticated => 'Authenticated',
                  };
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('Authenticate'),
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
                  child: const Text('Terms & Conditions'),
                ),
                TextButton(
                  onPressed: () => GoRouter.of(context).push('/legal/privacy'),
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
