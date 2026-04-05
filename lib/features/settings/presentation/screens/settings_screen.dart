import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/core/services/locale_service.dart';
import 'package:smartbudget/core/services/notification_preferences_service.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Currency updated to $normalizedNextCurrency.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to convert currency: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeControllerProvider);
    final rolloverPolicy = ref.watch(rolloverPolicyControllerProvider);
    final notificationPrefs =
        ref.watch(notificationPreferencesControllerProvider);
    final budgetNextEligible =
        ref.watch(notificationDispatchStatusProvider('budgetAlerts'));
    final savingsNextEligible =
        ref.watch(notificationDispatchStatusProvider('savingsNudges'));
    final healthNextEligible =
        ref.watch(notificationDispatchStatusProvider('healthInsights'));
    final onboardingStatus = ref.watch(onboardingStatusProvider).valueOrNull;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final appLocale = ref.watch(appLocaleControllerProvider);
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
    final legalReviewedAt = onboardingStatus?.legalReviewedAt;
    final legalReviewedAtLabel = legalReviewedAt == null
        ? 'No timestamp recorded yet.'
        : DateFormat.yMMMd(appLocale.languageCode)
            .add_jm()
            .format(legalReviewedAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(l10n.settings),
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isAppBarScrolled
                  ? ClipRect(
                      key: const ValueKey('settings-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('settings-appbar-blur-off')),
            ),
          ],
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppSurfaces.elevated(
                context,
                radius: 22,
                color: colorScheme.surfaceContainerHigh,
                opacity: 0.06,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.settingsControlCenterTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.settingsControlCenterSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: UiTokens.sectionGapSm),
                  Wrap(
                    spacing: UiTokens.chipSpacing,
                    runSpacing: UiTokens.chipRunSpacing,
                    children: [
                      _SettingsPill(
                        icon: Icons.palette_outlined,
                        label: l10n.settingsTheme,
                        value: activeThemeLabel,
                      ),
                      _SettingsPill(
                        icon: Icons.notifications_active_outlined,
                        label: l10n.settingsAlerts,
                        value: notificationsLabel,
                      ),
                      _SettingsPill(
                        icon: Icons.language_rounded,
                        label: l10n.language,
                        value: activeLanguageLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: UiTokens.sectionGapXl),
            _SettingsSection(
              title: l10n.settingsAppearance,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.darkMode),
                  subtitle: Text(l10n.settingsAppearanceSubtitle),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(l10n.themeSystem),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(l10n.themeLight),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(l10n.themeDark),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      await ref
                          .read(themeModeControllerProvider.notifier)
                          .setThemeMode(value);
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.language),
                  subtitle: Text(l10n.settingsLanguageSubtitle),
                  trailing: DropdownButton<String>(
                    value: appLocale.languageCode,
                    items: languageOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.$1,
                            child: Text(option.$2),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await ref
                          .read(appLocaleControllerProvider.notifier)
                          .setLanguageCode(value);
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.currency),
                  subtitle: Text(l10n.settingsCurrencySubtitle),
                  trailing: DropdownButton<String>(
                    value: appCurrency,
                    items: CurrencyService.supportedCurrencyCodes
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await _handleCurrencyChange(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: UiTokens.sectionGapXl),
            _SettingsSection(
              title: l10n.settingsBudgetRollover,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsAutoRolloverBudgets),
                  subtitle: Text(l10n.settingsAutoRolloverBudgetsSubtitle),
                  value: rolloverPolicy.autoRolloverEnabled,
                  onChanged: (value) async {
                    await ref
                        .read(rolloverPolicyControllerProvider.notifier)
                        .setAutoRollover(value);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsRolloverDay),
                  subtitle: Text(l10n.settingsRolloverDaySubtitle),
                  trailing: DropdownButton<int>(
                    value: rolloverPolicy.rolloverDay,
                    items: List.generate(
                      31,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: rolloverPolicy.autoRolloverEnabled
                        ? (value) async {
                            if (value == null) return;
                            await ref
                                .read(rolloverPolicyControllerProvider.notifier)
                                .setRolloverDay(value);
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UiTokens.sectionGapXl),
            _SettingsSection(
              title: l10n.settingsNotifications,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsEnableNotifications),
                  subtitle: Text(l10n.settingsEnableNotificationsSubtitle),
                  value: notificationPrefs.enabled,
                  onChanged: (value) async {
                    await ref
                        .read(
                            notificationPreferencesControllerProvider.notifier)
                        .setEnabled(value);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsNudgeFrequency),
                  trailing: DropdownButton<NotificationFrequency>(
                    value: notificationPrefs.frequency,
                    items: [
                      DropdownMenuItem(
                        value: NotificationFrequency.immediate,
                        child: Text(l10n.frequencyImmediate),
                      ),
                      DropdownMenuItem(
                        value: NotificationFrequency.daily,
                        child: Text(l10n.frequencyDaily),
                      ),
                      DropdownMenuItem(
                        value: NotificationFrequency.weekly,
                        child: Text(l10n.frequencyWeekly),
                      ),
                    ],
                    onChanged: notificationPrefs.enabled
                        ? (value) async {
                            if (value == null) return;
                            await ref
                                .read(notificationPreferencesControllerProvider
                                    .notifier)
                                .setFrequency(value);
                          }
                        : null,
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsQuietHours),
                  subtitle: Text(
                    '${notificationPrefs.quietHoursStart.toString().padLeft(2, '0')}:00 - ${notificationPrefs.quietHoursEnd.toString().padLeft(2, '0')}:00',
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<int>(
                          value: notificationPrefs.quietHoursStart,
                          items: List.generate(
                            24,
                            (i) => DropdownMenuItem(
                                value: i,
                                child:
                                    Text('${i.toString().padLeft(2, '0')}h')),
                          ),
                          onChanged: notificationPrefs.enabled
                              ? (value) async {
                                  if (value == null) return;
                                  await ref
                                      .read(
                                          notificationPreferencesControllerProvider
                                              .notifier)
                                      .setQuietHours(
                                        start: value,
                                        end: notificationPrefs.quietHoursEnd,
                                      );
                                }
                              : null,
                        ),
                        const SizedBox(width: 6),
                        DropdownButton<int>(
                          value: notificationPrefs.quietHoursEnd,
                          items: List.generate(
                            24,
                            (i) => DropdownMenuItem(
                                value: i,
                                child:
                                    Text('${i.toString().padLeft(2, '0')}h')),
                          ),
                          onChanged: notificationPrefs.enabled
                              ? (value) async {
                                  if (value == null) return;
                                  await ref
                                      .read(
                                          notificationPreferencesControllerProvider
                                              .notifier)
                                      .setQuietHours(
                                        start:
                                            notificationPrefs.quietHoursStart,
                                        end: value,
                                      );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor,
                ),
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsBudgetAlerts),
                  value: notificationPrefs.categories['budgetAlerts'] ?? true,
                  onChanged: notificationPrefs.enabled
                      ? (value) async {
                          await ref
                              .read(notificationPreferencesControllerProvider
                                  .notifier)
                              .setCategoryEnabled('budgetAlerts', value);
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsSavingsNudges),
                  value: notificationPrefs.categories['savingsNudges'] ?? true,
                  onChanged: notificationPrefs.enabled
                      ? (value) async {
                          await ref
                              .read(notificationPreferencesControllerProvider
                                  .notifier)
                              .setCategoryEnabled('savingsNudges', value);
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.settingsHealthInsights),
                  value: notificationPrefs.categories['healthInsights'] ?? true,
                  onChanged: notificationPrefs.enabled
                      ? (value) async {
                          await ref
                              .read(notificationPreferencesControllerProvider
                                  .notifier)
                              .setCategoryEnabled('healthInsights', value);
                        }
                      : null,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: Text(
                    l10n.settingsNextEligibleSendTime,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _NextEligibleTile(
                  title: l10n.settingsBudgetAlerts,
                  dateAsync: budgetNextEligible,
                ),
                _NextEligibleTile(
                  title: l10n.settingsSavingsNudges,
                  dateAsync: savingsNextEligible,
                ),
                _NextEligibleTile(
                  title: l10n.settingsHealthInsights,
                  dateAsync: healthNextEligible,
                ),
              ],
            ),
            const SizedBox(height: UiTokens.sectionGapLg),
            Text(
              l10n.settingsSecurity,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(l10n.settingsAuthenticationSettings),
              subtitle: Text(l10n.settingsAuthenticationSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => GoRouter.of(context).push('/security'),
            ),
            ListTile(
              title: const Text('Sign out'),
              subtitle:
                  const Text('End server session and remove local tokens.'),
              trailing: const Icon(Icons.logout),
              onTap: () async {
                final router = GoRouter.of(context);
                await ref.read(sessionControllerProvider.notifier).logout();
                if (!mounted) return;
                router.go('/login');
              },
            ),
            const SizedBox(height: UiTokens.sectionGapLg),
            Text(
              l10n.legalAndOnboarding,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(l10n.legalAllDocuments),
              subtitle: Text(l10n.legalAllDocumentsSubtitle),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => GoRouter.of(context).push('/legal'),
            ),
            ListTile(
              title: const Text('Legal review confirmation'),
              subtitle: Text(legalReviewedAtLabel),
              trailing: const Icon(Icons.verified_user_outlined),
            ),
            ListTile(
              title: Text(l10n.reviewTerms),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => GoRouter.of(context).push('/legal/terms'),
            ),
            ListTile(
              title: Text(l10n.reviewPrivacy),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => GoRouter.of(context).push('/legal/privacy'),
            ),
            ListTile(
              title: Text(l10n.restartOnboarding),
              subtitle: Text(l10n.restartOnboardingSubtitle),
              trailing: const Icon(Icons.refresh),
              onTap: () async {
                final router = GoRouter.of(context);
                await ref.read(onboardingServiceProvider).resetOnboarding();
                ref.invalidate(onboardingStatusProvider);
                router.go('/onboarding');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
        ),
        Container(
          decoration: AppSurfaces.elevated(context, radius: 20),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _NextEligibleTile extends StatelessWidget {
  const _NextEligibleTile({
    required this.title,
    required this.dateAsync,
  });

  final String title;
  final AsyncValue<NotificationDispatchStatus> dateAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final subtitle = dateAsync.when(
      data: (status) {
        final lineStyle = Theme.of(context).textTheme.bodySmall;
        final reasonColor = _reasonColor(context, status.blockReason);
        final reasonIcon = _reasonIcon(status.blockReason);

        if (status.nextEligibleAt == null) {
          final reason = status.blockReason ==
                  NotificationDispatchBlockReason.notificationsDisabled
              ? l10n.settingsBlockedNotificationsDisabled
              : l10n.settingsBlockedCategoryDisabled;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.settingsNotEligibleRightNow, style: lineStyle),
              Row(
                children: [
                  Icon(reasonIcon, size: 14, color: reasonColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reason,
                      style: lineStyle?.copyWith(color: reasonColor),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        final formatter = DateFormat('EEE, MMM d • HH:mm',
            Localizations.localeOf(context).toLanguageTag());
        final when = formatter.format(status.nextEligibleAt!);
        final remaining = status.nextEligibleAt!.difference(now);
        final countdown = _formatCountdown(remaining, l10n);

        String detail;
        switch (status.blockReason) {
          case NotificationDispatchBlockReason.quietHours:
            detail = l10n.settingsBlockedByQuietHoursUntil(when, countdown);
            break;
          case NotificationDispatchBlockReason.frequencyCooldown:
            detail = l10n.settingsBlockedByFrequencyCooldownUntil(
              when,
              countdown,
            );
            break;
          case NotificationDispatchBlockReason.notificationsDisabled:
            detail = l10n.settingsNotificationsAreDisabled;
            break;
          case NotificationDispatchBlockReason.categoryDisabled:
            detail = l10n.settingsThisCategoryIsDisabled;
            break;
          case null:
            detail = l10n.settingsReadyToSendNow;
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.settingsNextEligible(when), style: lineStyle),
            Row(
              children: [
                Icon(reasonIcon, size: 14, color: reasonColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    detail,
                    style: lineStyle?.copyWith(color: reasonColor),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Text(
        l10n.settingsCalculating,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      error: (_, __) => Text(
        l10n.settingsUnavailable,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title),
      subtitle: subtitle,
      dense: true,
    );
  }

  String _formatCountdown(Duration duration, AppLocalizations l10n) {
    final d = duration;
    if (d.inSeconds <= 0) {
      return l10n.commonNow;
    }

    final totalMinutes = d.inMinutes;
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final minutes = totalMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _reasonColor(
    BuildContext context,
    NotificationDispatchBlockReason? reason,
  ) {
    return switch (reason) {
      NotificationDispatchBlockReason.quietHours => Colors.orange,
      NotificationDispatchBlockReason.frequencyCooldown => Colors.blue,
      NotificationDispatchBlockReason.notificationsDisabled =>
        Theme.of(context).colorScheme.error,
      NotificationDispatchBlockReason.categoryDisabled =>
        Theme.of(context).colorScheme.onSurfaceVariant,
      null => Colors.green,
    };
  }

  IconData _reasonIcon(NotificationDispatchBlockReason? reason) {
    return switch (reason) {
      NotificationDispatchBlockReason.quietHours => Icons.nights_stay_outlined,
      NotificationDispatchBlockReason.frequencyCooldown =>
        Icons.schedule_outlined,
      NotificationDispatchBlockReason.notificationsDisabled =>
        Icons.notifications_off_outlined,
      NotificationDispatchBlockReason.categoryDisabled =>
        Icons.visibility_off_outlined,
      null => Icons.check_circle_outline,
    };
  }
}

class _SettingsPill extends StatelessWidget {
  const _SettingsPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
