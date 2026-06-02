import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/core/services/locale_service.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/balance_sheet/presentation/screens/recurring_balance_sheet_screen.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/features/insights/presentation/providers/insight_provider.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isAppBarScrolled = false;

  Future<void> _sendSupportFeedbackEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@autisync.com',
      queryParameters: {
        'subject': 'SmartSpend Feedback (Tech & General)',
        'body':
            'Hi Autisync team,%0A%0AI would like to share feedback:%0A%0A- Technical feedback:%0A- General feedback:%0A%0AThanks!',
      },
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        AppFeedbackService.showWarning(
          context,
          'Could not open email app on this device.',
        );
      }
    } on MissingPluginException {
      if (!mounted) return;
      AppFeedbackService.showWarning(
        context,
        'Email plugin not ready yet. Please fully restart the app and try again.',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.showError(
        context,
        'Unable to open email app right now.',
      );
    }
  }

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  Future<void> _handleCurrencyChange(String nextCurrency) async {
    final currentCurrency = ref.read(appCurrencyControllerProvider);
    final normalizedNextCurrency = nextCurrency.toUpperCase();
    if (currentCurrency == normalizedNextCurrency) return;

    AppFeedbackService.showLoading(
      context,
      'Syncing data and converting currency...',
    );
    try {
      await ref.read(currencyMigrationServiceProvider).migrateAllData(
            fromCurrency: currentCurrency,
            toCurrency: normalizedNextCurrency,
          );
      await ref
          .read(appCurrencyControllerProvider.notifier)
          .setCurrencyCode(normalizedNextCurrency);

      ref.invalidate(transactionRepositoryProvider);
      ref.invalidate(budgetRepositoryProvider);
      ref.invalidate(savingsGoalRepositoryProvider);
      ref.invalidate(subscriptionRepositoryProvider);

      ref.invalidate(transactionListProvider());
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(spendingProfileProvider);
      ref.invalidate(cashflowPredictionProvider);
      ref.invalidate(budgetListProvider);
      ref.invalidate(budgetAlertsProvider);
      ref.invalidate(savingsGoalListProvider);
      ref.invalidate(savingsNudgesProvider);
      ref.invalidate(subscriptionListProvider);
      ref.invalidate(dueSubscriptionsProvider);
      ref.invalidate(financialHealthProvider);
      ref.invalidate(insightResultsProvider);
      ref.invalidate(recurringBalanceSheetProvider);

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          'Currency updated to $normalizedNextCurrency.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.showError(
        context,
        'Unable to convert currency: $error',
      );
    } finally {
      AppFeedbackService.dismissLoading();
    }
  }

  Future<void> _openControlCenterSheet({
    required AppLocalizations l10n,
    required ThemeMode themeMode,
    required String appCurrency,
    required Locale appLocale,
    required List<(String, String)> languageOptions,
    required String displayName,
    required String userEmail,
    required bool isActive,
    required bool isVerified,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;

    await AppFormSheet.show<void>(
      context,
      builder: (sheetContext) {
        return AppFormSheet(
          maxHeightFactor: 0.86,
          bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          body: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.14),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName.characters.first.toUpperCase()
                            : 'U',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isVerified
                                ? Colors.green
                                : colorScheme.onSurfaceVariant)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isVerified ? 'Verified' : 'Unverified',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: isVerified
                                      ? Colors.green.shade700
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MoreActionTile(
                  icon: Icons.badge_outlined,
                  title: 'Account info',
                  subtitle: 'View your account details',
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Account info'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AccountInfoRow(
                                  label: 'Name', value: displayName),
                              _AccountInfoRow(label: 'Email', value: userEmail),
                              _AccountInfoRow(
                                label: 'Email status',
                                value: isVerified ? 'Verified' : 'Unverified',
                              ),
                              _AccountInfoRow(
                                label: 'Account status',
                                value: isActive ? 'Active' : 'Inactive',
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                _MoreActionTile(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsAppearance,
                  subtitle: switch (themeMode) {
                    ThemeMode.system => l10n.themeSystem,
                    ThemeMode.light => l10n.themeLight,
                    ThemeMode.dark => l10n.themeDark,
                  },
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final selected = await showDialog<ThemeMode>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text(l10n.settingsAppearance),
                        children: [
                          RadioGroup<ThemeMode>(
                            groupValue: themeMode,
                            onChanged: (value) =>
                                Navigator.of(context).pop(value),
                            child: Column(
                              children: [
                                RadioListTile<ThemeMode>(
                                  value: ThemeMode.system,
                                  title: Text(l10n.themeSystem),
                                ),
                                RadioListTile<ThemeMode>(
                                  value: ThemeMode.light,
                                  title: Text(l10n.themeLight),
                                ),
                                RadioListTile<ThemeMode>(
                                  value: ThemeMode.dark,
                                  title: Text(l10n.themeDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    if (selected == null) return;
                    await ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(selected);
                    if (!mounted) return;
                    AppFeedbackService.showSuccess(
                      context,
                      'Appearance updated.',
                    );
                  },
                ),
                _MoreActionTile(
                  icon: Icons.language_rounded,
                  title: l10n.language,
                  subtitle: languageOptions
                      .firstWhere(
                        (option) => option.$1 == appLocale.languageCode,
                        orElse: () => languageOptions.first,
                      )
                      .$2,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text(l10n.language),
                        children: [
                          RadioGroup<String>(
                            groupValue: appLocale.languageCode,
                            onChanged: (value) =>
                                Navigator.of(context).pop(value),
                            child: Column(
                              children: [
                                for (final option in languageOptions)
                                  RadioListTile<String>(
                                    value: option.$1,
                                    title: Text(option.$2),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    if (selected == null) return;
                    await ref
                        .read(appLocaleControllerProvider.notifier)
                        .setLanguageCode(selected);
                    if (!mounted) return;
                    AppFeedbackService.showSuccess(
                      context,
                      'Language updated.',
                    );
                  },
                ),
                _MoreActionTile(
                  icon: Icons.currency_exchange_rounded,
                  title: l10n.currency,
                  subtitle: appCurrency,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text(l10n.currency),
                        children: [
                          RadioGroup<String>(
                            groupValue: appCurrency,
                            onChanged: (value) =>
                                Navigator.of(context).pop(value),
                            child: Column(
                              children: [
                                for (final code
                                    in CurrencyService.supportedCurrencyCodes)
                                  RadioListTile<String>(
                                    value: code,
                                    title: Text(code),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    if (selected == null) return;
                    await _handleCurrencyChange(selected);
                  },
                ),
                _MoreActionTile(
                  icon: Icons.lock_outline,
                  title: l10n.settingsAuthenticationSettings,
                  subtitle: l10n.settingsAuthenticationSettingsSubtitle,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    GoRouter.of(context).push('/security');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeControllerProvider);
    final notificationPrefs =
        ref.watch(notificationPreferencesControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final onboardingStatus = ref.watch(onboardingStatusProvider).valueOrNull;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final appLocale = ref.watch(appLocaleControllerProvider);
    final transactionsCount =
        ref.watch(transactionListProvider()).valueOrNull?.length ?? 0;
    final itemsCount =
        (ref.watch(budgetListProvider).valueOrNull?.length ?? 0) +
            (ref.watch(savingsGoalListProvider).valueOrNull?.length ?? 0) +
            (ref.watch(subscriptionListProvider).valueOrNull?.length ?? 0);
    final colorScheme = Theme.of(context).colorScheme;
    const languageOptions = [
      ('en', 'English'),
      ('pt', 'Português'),
      ('es', 'Español'),
    ];
    final activeThemeLabel = switch (themeMode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
    final activeLanguageLabel = languageOptions
        .firstWhere(
          (option) => option.$1 == appLocale.languageCode,
          orElse: () => (LocaleService.defaultLanguageCode, 'English'),
        )
        .$2;
    final notificationsLabel = notificationPrefs.enabled
        ? l10n.settingsNotificationsEnabled
        : l10n.settingsNotificationsPaused;
    final userEmail = session.user?.email ?? 'Not signed in';
    final isActive = session.user?.isActive ?? false;
    final displayName = [
      session.user?.firstName ?? '',
      session.user?.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final userDisplayName =
        displayName.isEmpty ? 'SmartSpend User' : displayName;
    final isVerified = session.user?.isVerified ?? false;
    final legalReviewedAt = onboardingStatus?.legalReviewedAt;
    final legalReviewedAtLabel = legalReviewedAt == null
        ? 'No timestamp recorded yet.'
        : DateFormat.yMMMd(appLocale.languageCode)
            .add_jm()
            .format(legalReviewedAt.toLocal());

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.settings,
          isScrolled: _isAppBarScrolled,
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface
            .withValues(alpha: _isAppBarScrolled ? 0.88 : 0.0),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'settings-appbar-blur-on',
          offKey: 'settings-appbar-blur-off',
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openControlCenterSheet(
                  l10n: l10n,
                  themeMode: themeMode,
                  appCurrency: appCurrency,
                  appLocale: appLocale,
                  languageOptions: languageOptions,
                  displayName: userDisplayName,
                  userEmail: userEmail,
                  isActive: isActive,
                  isVerified: isVerified,
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppSurfaces.elevated(context, radius: 18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.14),
                        child: Text(
                          userDisplayName.characters.first.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: AppSurfaces.elevated(context, radius: 18),
              child: Row(
                children: [
                  Expanded(
                    child: _StatsTile(
                      icon: Icons.receipt_long_rounded,
                      value: '$transactionsCount',
                      label: 'Transactions',
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: VerticalDivider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.28),
                      thickness: 1,
                    ),
                  ),
                  Expanded(
                    child: _StatsTile(
                      icon: Icons.inventory_2_outlined,
                      value: '$itemsCount',
                      label: 'Items',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _SectionDivider(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppSurfaces.elevated(context, radius: 18),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Main Features',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Essential tools to manage spending, plan ahead, and improve financial health.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's included",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        const _IncludedItem(
                            label: 'Transactions and recurring entries'),
                        const _IncludedItem(
                            label: 'Budgets, savings goals, and subscriptions'),
                        const _IncludedItem(
                            label: 'Insights, forecasts, and anomaly alerts'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _SectionDivider(),
            const SizedBox(height: 22),
            Text(
              'Explore features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.82,
                    child: _FeatureCard(
                      icon: Icons.description_outlined,
                      title: 'Fin Simulator',
                      subtitle:
                          'Run what-if financial scenarios with projected outcomes.',
                      tag: 'Coming soon',
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.82,
                    child: _FeatureCard(
                      icon: Icons.auto_awesome_mosaic_rounded,
                      title: 'AI Budget Coach',
                      subtitle:
                          'Get weekly personalized spending and savings guidance.',
                      tag: 'Coming soon',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionDivider(),
            const SizedBox(height: 26),
            Text(
              'Others',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: AppSurfaces.elevated(context, radius: 16),
              child: Column(
                children: [
                  _MoreActionTile(
                    icon: Icons.people_alt_outlined,
                    title: 'Tell a friend',
                    tileVerticalPadding: 12,
                    onTap: () {
                      AppFeedbackService.showInfo(
                        context,
                        'Referral sharing coming soon.',
                      );
                    },
                  ),
                  _MoreActionTile(
                    icon: Icons.mail_outline,
                    title: 'Send feedback',
                    subtitle: 'Email tech and general feedback',
                    tileVerticalPadding: 12,
                    showChevron: true,
                    onTap: _sendSupportFeedbackEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _SectionDivider(),
            const SizedBox(height: 26),
            Text(
              l10n.settings,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _ModernSettingsGroup(
              title: 'Preferences',
              children: [
                _MoreActionTile(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsAppearance,
                  subtitle: activeThemeLabel,
                  showLeading: false,
                  showChevron: false,
                  trailing: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tileVerticalPadding: 10,
                  onTap: () async {
                    final selected = await showDialog<ThemeMode>(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(l10n.settingsAppearance),
                          children: [
                            RadioGroup<ThemeMode>(
                              groupValue: themeMode,
                              onChanged: (value) =>
                                  Navigator.of(context).pop(value),
                              child: Column(
                                children: [
                                  RadioListTile<ThemeMode>(
                                    value: ThemeMode.system,
                                    title: Text(l10n.themeSystem),
                                  ),
                                  RadioListTile<ThemeMode>(
                                    value: ThemeMode.light,
                                    title: Text(l10n.themeLight),
                                  ),
                                  RadioListTile<ThemeMode>(
                                    value: ThemeMode.dark,
                                    title: Text(l10n.themeDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    if (selected == null) return;
                    await ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(selected);
                  },
                ),
                _MoreActionTile(
                  icon: Icons.language_rounded,
                  title: l10n.language,
                  subtitle: activeLanguageLabel,
                  showLeading: false,
                  showChevron: false,
                  trailing: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tileVerticalPadding: 10,
                  onTap: () async {
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(l10n.language),
                          children: [
                            RadioGroup<String>(
                              groupValue: appLocale.languageCode,
                              onChanged: (value) =>
                                  Navigator.of(context).pop(value),
                              child: Column(
                                children: [
                                  for (final option in languageOptions)
                                    RadioListTile<String>(
                                      value: option.$1,
                                      title: Text(option.$2),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    if (selected == null) return;
                    await ref
                        .read(appLocaleControllerProvider.notifier)
                        .setLanguageCode(selected);
                  },
                ),
                _MoreActionTile(
                  icon: Icons.currency_exchange_rounded,
                  title: l10n.currency,
                  subtitle: appCurrency,
                  showLeading: false,
                  showChevron: false,
                  trailing: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tileVerticalPadding: 10,
                  onTap: () async {
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(l10n.currency),
                          children: [
                            RadioGroup<String>(
                              groupValue: appCurrency,
                              onChanged: (value) =>
                                  Navigator.of(context).pop(value),
                              child: Column(
                                children: [
                                  for (final code
                                      in CurrencyService.supportedCurrencyCodes)
                                    RadioListTile<String>(
                                      value: code,
                                      title: Text(code),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    if (selected == null) return;
                    await _handleCurrencyChange(selected);
                  },
                ),
                _MoreActionTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.settingsNotifications,
                  subtitle: notificationsLabel,
                  showLeading: false,
                  showChevron: false,
                  tileVerticalPadding: 10,
                  onTap: () async {
                    await ref
                        .read(
                            notificationPreferencesControllerProvider.notifier)
                        .setEnabled(!notificationPrefs.enabled);
                    if (!mounted) return;
                    AppFeedbackService.showSuccess(
                      this.context,
                      notificationPrefs.enabled
                          ? 'Notifications disabled.'
                          : 'Notifications enabled.',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ModernSettingsGroup(
              title: 'Legal & Onboarding',
              children: [
                _MoreActionTile(
                  icon: Icons.gavel_rounded,
                  title: l10n.legalAllDocuments,
                  subtitle: l10n.legalAllDocumentsSubtitle,
                  showLeading: false,
                  showChevron: true,
                  tileVerticalPadding: 10,
                  onTap: () => GoRouter.of(context).push('/legal'),
                ),
                _MoreActionTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Legal review confirmation',
                  subtitle: legalReviewedAtLabel,
                  showLeading: false,
                  showChevron: false,
                  tileVerticalPadding: 10,
                ),
                _MoreActionTile(
                  icon: Icons.refresh_rounded,
                  title: l10n.restartOnboarding,
                  subtitle: l10n.restartOnboardingSubtitle,
                  showLeading: false,
                  showChevron: true,
                  tileVerticalPadding: 10,
                  onTap: () async {
                    final router = GoRouter.of(context);
                    await ref.read(onboardingServiceProvider).resetOnboarding();
                    ref.invalidate(onboardingStatusProvider);
                    if (!mounted) return;
                    AppFeedbackService.showSuccess(
                      this.context,
                      'Onboarding restarted.',
                    );
                    router.go('/onboarding');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ModernSettingsGroup(
              title: 'Security',
              children: [
                _MoreActionTile(
                  icon: Icons.lock_outline,
                  title: l10n.settingsAuthenticationSettings,
                  subtitle: l10n.settingsAuthenticationSettingsSubtitle,
                  showLeading: false,
                  showChevron: true,
                  tileVerticalPadding: 10,
                  onTap: () => GoRouter.of(context).push('/security'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      await ref
                          .read(sessionControllerProvider.notifier)
                          .logout();
                      if (!mounted) return;
                      router.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSettingsGroup extends StatelessWidget {
  const _ModernSettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
        ),
        Container(
          decoration: AppSurfaces.elevated(context, radius: 16),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.22),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _IncludedItem extends StatelessWidget {
  const _IncludedItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check, size: 22, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tag,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppSurfaces.elevated(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 28),
              ),
              if (tag != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.brown.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoreActionTile extends StatelessWidget {
  const _MoreActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showLeading = true,
    this.showChevron = true,
    this.tileVerticalPadding = 2,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showLeading;
  final bool showChevron;
  final double tileVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: tileVerticalPadding,
      ),
      leading: showLeading
          ? CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
              child: Icon(
                icon,
                color: colorScheme.primary,
              ),
            )
          : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
      trailing: trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                )
              : null),
      onTap: onTap,
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
