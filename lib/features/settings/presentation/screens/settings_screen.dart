import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/notification_preferences_service.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(l10n.darkMode),
            subtitle: const Text('Choose how SmartBudget should look.'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
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
          const SizedBox(height: 24),
          Text(
            'Budget Rollover',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-rollover budgets'),
            subtitle: const Text(
                'Automatically start a new cycle when a budget period ends.'),
            value: rolloverPolicy.autoRolloverEnabled,
            onChanged: (value) async {
              await ref
                  .read(rolloverPolicyControllerProvider.notifier)
                  .setAutoRollover(value);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rollover day'),
            subtitle:
                const Text('Used for monthly/yearly budget cycle boundaries.'),
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
          const SizedBox(height: 24),
          Text(
            'Notifications',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable notifications'),
            subtitle:
                const Text('Master switch for all budget/savings alerts.'),
            value: notificationPrefs.enabled,
            onChanged: (value) async {
              await ref
                  .read(notificationPreferencesControllerProvider.notifier)
                  .setEnabled(value);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nudge frequency'),
            trailing: DropdownButton<NotificationFrequency>(
              value: notificationPrefs.frequency,
              items: const [
                DropdownMenuItem(
                  value: NotificationFrequency.immediate,
                  child: Text('Immediate'),
                ),
                DropdownMenuItem(
                  value: NotificationFrequency.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: NotificationFrequency.weekly,
                  child: Text('Weekly'),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Quiet hours'),
            subtitle: Text(
              '${notificationPrefs.quietHoursStart.toString().padLeft(2, '0')}:00 - ${notificationPrefs.quietHoursEnd.toString().padLeft(2, '0')}:00',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: notificationPrefs.quietHoursStart,
                  items: List.generate(
                    24,
                    (i) => DropdownMenuItem(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}h')),
                  ),
                  onChanged: notificationPrefs.enabled
                      ? (value) async {
                          if (value == null) return;
                          await ref
                              .read(notificationPreferencesControllerProvider
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
                        child: Text('${i.toString().padLeft(2, '0')}h')),
                  ),
                  onChanged: notificationPrefs.enabled
                      ? (value) async {
                          if (value == null) return;
                          await ref
                              .read(notificationPreferencesControllerProvider
                                  .notifier)
                              .setQuietHours(
                                start: notificationPrefs.quietHoursStart,
                                end: value,
                              );
                        }
                      : null,
                ),
              ],
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Budget alerts'),
            value: notificationPrefs.categories['budgetAlerts'] ?? true,
            onChanged: notificationPrefs.enabled
                ? (value) async {
                    await ref
                        .read(
                            notificationPreferencesControllerProvider.notifier)
                        .setCategoryEnabled('budgetAlerts', value);
                  }
                : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Savings nudges'),
            value: notificationPrefs.categories['savingsNudges'] ?? true,
            onChanged: notificationPrefs.enabled
                ? (value) async {
                    await ref
                        .read(
                            notificationPreferencesControllerProvider.notifier)
                        .setCategoryEnabled('savingsNudges', value);
                  }
                : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Health insights'),
            value: notificationPrefs.categories['healthInsights'] ?? true,
            onChanged: notificationPrefs.enabled
                ? (value) async {
                    await ref
                        .read(
                            notificationPreferencesControllerProvider.notifier)
                        .setCategoryEnabled('healthInsights', value);
                  }
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Next eligible send time',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          _NextEligibleTile(
            title: 'Budget alerts',
            dateAsync: budgetNextEligible,
          ),
          _NextEligibleTile(
            title: 'Savings nudges',
            dateAsync: savingsNextEligible,
          ),
          _NextEligibleTile(
            title: 'Health insights',
            dateAsync: healthNextEligible,
          ),
          const SizedBox(height: 24),
          Text(
            'Security',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Authentication settings'),
            subtitle:
                const Text('Biometrics, session timeout, lockout controls'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push('/security'),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.legalAndOnboarding,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
    final now = DateTime.now();
    final subtitle = dateAsync.when(
      data: (status) {
        final lineStyle = Theme.of(context).textTheme.bodySmall;
        final reasonColor = _reasonColor(context, status.blockReason);
        final reasonIcon = _reasonIcon(status.blockReason);

        if (status.nextEligibleAt == null) {
          final reason = status.blockReason ==
                  NotificationDispatchBlockReason.notificationsDisabled
              ? 'Blocked because notifications are disabled.'
              : 'Blocked because this category is disabled.';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Not eligible right now', style: lineStyle),
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

        final formatter = DateFormat('EEE, MMM d • HH:mm');
        final when = formatter.format(status.nextEligibleAt!);
        final remaining = status.nextEligibleAt!.difference(now);
        final countdown = _formatCountdown(remaining);

        String detail;
        switch (status.blockReason) {
          case NotificationDispatchBlockReason.quietHours:
            detail = 'Blocked by quiet hours until $when ($countdown).';
            break;
          case NotificationDispatchBlockReason.frequencyCooldown:
            detail = 'Blocked by frequency cooldown until $when ($countdown).';
            break;
          case NotificationDispatchBlockReason.notificationsDisabled:
            detail = 'Notifications are disabled.';
            break;
          case NotificationDispatchBlockReason.categoryDisabled:
            detail = 'This category is disabled.';
            break;
          case null:
            detail = 'Ready to send now.';
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Next eligible: $when', style: lineStyle),
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
        'Calculating... ',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      error: (_, __) => Text(
        'Unavailable',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle,
      dense: true,
    );
  }

  String _formatCountdown(Duration duration) {
    if (duration.inSeconds <= 0) {
      return 'now';
    }

    final totalMinutes = duration.inMinutes;
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
