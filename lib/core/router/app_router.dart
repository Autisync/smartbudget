import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
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
import 'package:smartbudget/features/accounts/presentation/screens/accounts_screen.dart';
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
import 'package:smartbudget/core/providers/quick_add_provider.dart';
import 'package:smartbudget/core/widgets/logo_loading_indicator.dart';
import 'package:smartbudget/core/widgets/app_tour_overlay.dart';
import 'package:smartbudget/core/widgets/nav_action_panel.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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
            path: '/accounts',
            builder: (context, state) => const AccountsScreen(),
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

/// Which expandable bottom-nav panel is currently open.
enum _NavPanel { none, add, more }

// Nav-bar layout constants (must match AppBottomNavigation in fintech_components).
const _kNavBarHeight = 60.0;
const _kNavBarPaddingBottom = 8.0;
// The panel's bottom edge sits at the × button's centre minus a small overlap
// so the round button "pokes out" at the panel's lower-right corner.
// × centre from screen bottom = safeArea + paddingBottom + barHeight/2
// = safeArea + 8 + 30 = safeArea + 38; subtract 10dp overlap → safeArea + 28.
double _panelBottom(double safeAreaBottom) =>
    safeAreaBottom + _kNavBarPaddingBottom + _kNavBarHeight / 2 - 10;

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  _NavPanel _panel = _NavPanel.none;

  void _closePanel() {
    if (_panel != _NavPanel.none) setState(() => _panel = _NavPanel.none);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    // PopScope wraps BOTH layouts so the Android back button closes any open
    // panel before navigating away, regardless of screen width.
    return PopScope(
      canPop: _panel == _NavPanel.none,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closePanel();
      },
      child: AppTourOverlay(
        child: useRail ? _buildRailScaffold(l10n) : _buildMobileScaffold(),
      ),
    );
  }

  Widget _buildRailScaffold(AppLocalizations l10n) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            selectedIndex: _calculateRailSelectedIndex(context),
            onDestinationSelected: _onRailItemTapped,
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
          Expanded(child: _wrapWithPanel(widget.child)),
        ],
      ),
    );
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      // Let the page content flow behind the floating nav capsule so there is
      // no opaque strip behind it — it reads as truly floating over the screen.
      extendBody: true,
      body: _wrapWithPanel(widget.child),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _calculateBottomIndex(context),
        moreActive: _panel == _NavPanel.more,
        actionIsClose: _panel != _NavPanel.none,
        capsuleVisible: _panel == _NavPanel.none,
        onTabSelected: _onBottomTabSelected,
        onActionButtonTapped: _onActionButtonTapped,
      ),
    );
  }

  /// Overlays the active expandable panel (and a tap-to-dismiss scrim).
  ///
  /// The panel aligns with the capsule's footprint — its right edge stops where
  /// the capsule ended (16 margin + 60 button + 10 gap = 86) so the round "×"
  /// sits at the bottom-right *beside* the panel, not underneath it. Its bottom
  /// is anchored near the button's centre so the "×" pokes out at the corner,
  /// matching the reference.
  Widget _wrapWithPanel(Widget body) {
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final isOpen = _panel != _NavPanel.none;

    return Stack(
      children: [
        Positioned.fill(child: body),
        // Scrim — always Positioned.fill so it covers the full body area;
        // fades in/out with the panel. IgnorePointer keeps it non-interactive
        // when the panel is closed so the body receives all gestures normally.
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: isOpen ? 1.0 : 0.0,
            duration: UiTokens.motionMedium,
            curve: UiTokens.motionCurve,
            child: IgnorePointer(
              ignoring: !isOpen,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closePanel,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.30),
                ),
              ),
            ),
          ),
        ),
        // Panel — slides + fades in from bottom-right; reverses on close.
        Positioned(
          left: 16,
          right: 86,
          bottom: _panelBottom(safeAreaBottom),
          child: AnimatedSwitcher(
            duration: UiTokens.motionMedium,
            switchInCurve: UiTokens.motionCurve,
            switchOutCurve: UiTokens.motionCurve.flipped,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                alignment: Alignment.bottomRight,
                child: child,
              ),
            ),
            child: isOpen
                ? (_panel == _NavPanel.add
                    ? NavActionPanel(
                        key: const ValueKey(_NavPanel.add),
                        items: _buildAddItems(),
                        crossAxisCount: 4,
                      )
                    : NavActionPanel(
                        key: const ValueKey(_NavPanel.more),
                        items: _buildMoreItems(),
                        crossAxisCount: 3,
                      ))
                : const SizedBox.shrink(key: ValueKey(_NavPanel.none)),
          ),
        ),
      ],
    );
  }

  void _onActionButtonTapped() {
    // The detached round button: "×" closes any open panel, "+" opens add.
    HapticFeedback.lightImpact();
    setState(() {
      _panel = _panel != _NavPanel.none ? _NavPanel.none : _NavPanel.add;
    });
  }

  // -- Quick-add menu ---------------------------------------------------------

  List<NavActionItem> _buildAddItems() {
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context);

    void pushTo(String route) {
      _closePanel();
      router.push(route);
    }

    void openModalAdd(QuickAddTarget target, String route) {
      _closePanel();
      // Raise the in-screen add form via a pending request the destination
      // screen consumes, then navigate there.
      container.read(pendingQuickAddProvider.notifier).state = target;
      router.go(route);
    }

    return [
      NavActionItem(
        icon: AppIcons.transactionsFilled,
        label: 'Transaction',
        onTap: () => pushTo('/transactions/add'),
      ),
      NavActionItem(
        icon: AppIcons.subscriptionsFilled,
        label: 'Subscription',
        onTap: () => pushTo('/subscriptions/add'),
      ),
      NavActionItem(
        icon: AppIcons.savingsFilled,
        label: 'Savings',
        onTap: () => openModalAdd(QuickAddTarget.savings, '/savings'),
      ),
      NavActionItem(
        icon: AppIcons.budgetsFilled,
        label: 'Budget',
        onTap: () => openModalAdd(QuickAddTarget.budget, '/budgets'),
      ),
    ];
  }

  // -- More menu --------------------------------------------------------------

  List<NavActionItem> _buildMoreItems() {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context);
    // Read brightness from the live theme rather than provider snapshot so the
    // label ("Dark mode" / "Light mode") is always current when the panel opens.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void goTo(String route) {
      _closePanel();
      router.go(route);
    }

    void pushTo(String route) {
      _closePanel();
      router.push(route);
    }

    Future<void> openHelpWebsite() async {
      _closePanel();
      final websiteUri = Uri.parse('https://www.smaartspend.com');
      final launched = await launchUrl(
        websiteUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open website right now.')),
        );
      }
    }

    void toggleTheme() {
      container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
      _closePanel();
    }

    return [
      NavActionItem(
        icon: AppIcons.settingsFilled,
        label: l10n.settings,
        onTap: () => pushTo('/settings'),
      ),
      NavActionItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Accounts',
        onTap: () => pushTo('/accounts'),
      ),
      NavActionItem(
        icon: AppIcons.subscriptionsFilled,
        label: 'Subscriptions',
        onTap: () => goTo('/subscriptions'),
      ),
      NavActionItem(
        icon: AppIcons.reportsFilled,
        label: 'Reports',
        onTap: () => goTo('/reports'),
      ),
      NavActionItem(
        icon: AppIcons.exchangeRates,
        label: 'Exchange Rates',
        onTap: () => goTo('/exchange-rates'),
      ),
      NavActionItem(
        icon: AppIcons.insightsFilled,
        label: 'AI Insights',
        onTap: () => goTo('/insights'),
      ),
      NavActionItem(
        icon: Icons.science_rounded,
        label: 'Scenario Lab',
        onTap: () => goTo('/scenario-lab'),
      ),
      NavActionItem(
        icon: Icons.lock_outline_rounded,
        label: 'Security',
        onTap: () => goTo('/security'),
      ),
      NavActionItem(
        icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        label: isDark ? 'Light mode' : 'Dark mode',
        onTap: toggleTheme,
      ),
      NavActionItem(
        icon: Icons.help_outline_rounded,
        label: 'Help',
        onTap: openHelpWebsite,
      ),
      NavActionItem(
        icon: Icons.gavel_rounded,
        label: l10n.legalCenterTitle,
        onTap: () => pushTo('/legal'),
      ),
    ];
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
        location.startsWith('/balance-sheet') ||
        location.startsWith('/accounts') ||
        location.startsWith('/scenario-lab')) {
      return 4;
    }
    return 2;
  }

  int _calculateRailSelectedIndex(BuildContext context) {
    // Mirror _calculateBottomIndex so rail + mobile highlight consistently.
    return _calculateBottomIndex(context);
  }

  void _onRailItemTapped(int index) => _onBottomTabSelected(index);

  void _onBottomTabSelected(int index) {
    // The "More" item (4) toggles its expandable panel; the rest navigate and
    // dismiss any open panel.
    if (index == 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _panel = _panel == _NavPanel.more ? _NavPanel.none : _NavPanel.more;
      });
      return;
    }
    _closePanel();
    const routes = {0: '/transactions', 1: '/budgets', 2: '/', 3: '/savings'};
    GoRouter.of(context).go(routes[index]!);
  }
}
