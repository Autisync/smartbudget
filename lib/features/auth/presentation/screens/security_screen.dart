import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart' as bio;
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/widgets/app_feedback.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/auth/presentation/providers/auth_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/security_provider.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _isAppBarScrolled = false;
  bool _isTogglingBiometric = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(securitySettingProvider);
    final logsAsync = ref.watch(authLogsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.securitySettingsTitle,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'security-appbar-blur-on',
          offKey: 'security-appbar-blur-off',
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: settingsAsync.when(
          data: (settings) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 12),
                      child: Text(
                        l10n.securityAuthenticationAccess,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                      ),
                    ),
                    Container(
                      decoration: AppSurfaces.elevated(context, radius: 20),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(l10n.securityBiometricAuth),
                            subtitle: Text(l10n.securityBiometricAuthSubtitle),
                            value: settings.biometricEnabled,
                            onChanged: _isTogglingBiometric
                                ? null
                                : (value) async {
                                    setState(() => _isTogglingBiometric = true);
                                    try {
                                      final result = await ref
                                          .read(authControllerProvider.notifier)
                                          .enableBiometric(value);

                                      if (!context.mounted) return;

                                      if (value &&
                                          result !=
                                              bio.AuthStatus.authenticated) {
                                        final message = switch (result) {
                                          bio.AuthStatus.notAvailable =>
                                            'Biometric authentication is not available on this device.',
                                          bio.AuthStatus.noBiometricsEnrolled =>
                                            'No biometrics are enrolled on this device.',
                                          bio.AuthStatus.lockedOut =>
                                            'Biometric authentication is temporarily locked.',
                                          bio.AuthStatus.permanentlyLockedOut =>
                                            'Biometric authentication is locked. Unlock with device passcode first.',
                                          bio.AuthStatus.denied =>
                                            'Biometric setup was not confirmed.',
                                          bio.AuthStatus.error =>
                                            'Could not enable biometric authentication.',
                                          bio.AuthStatus.authenticated =>
                                            'Biometric authentication enabled.',
                                        };
                                        AppFeedback.show(
                                          context,
                                          message: message,
                                          type: result ==
                                                  bio.AuthStatus.authenticated
                                              ? AppFeedbackType.success
                                              : AppFeedbackType.warning,
                                        );
                                      }

                                      ref.invalidate(securitySettingProvider);
                                    } finally {
                                      if (mounted) {
                                        setState(
                                            () => _isTogglingBiometric = false);
                                      }
                                    }
                                  },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Theme.of(context).dividerColor,
                          ),
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(l10n.securitySessionTimeout),
                            subtitle: Text(
                              l10n.securitySessionTimeoutSubtitle(
                                (settings.sessionTimeout / 60).round(),
                              ),
                            ),
                            trailing: SizedBox(
                              width: 148,
                              child: AppDropdown<int>(
                                value: settings.sessionTimeout,
                                label: l10n.securityTimeout,
                                items: const [300, 600, 900, 1800]
                                    .map(
                                      (seconds) => DropdownMenuItem(
                                        value: seconds,
                                        child: Text(
                                          l10n.securityMinutesShort(
                                              seconds ~/ 60),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  if (value == null) return;
                                  await ref
                                      .read(securityServiceProvider)
                                      .updateSessionTimeout(value);
                                  ref.invalidate(securitySettingProvider);
                                },
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Theme.of(context).dividerColor,
                          ),
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(l10n.securityLockoutThreshold),
                            subtitle: Text(
                              l10n.securityLockoutThresholdSubtitle(
                                settings.maxFailedAttempts,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 110,
                              child: AppDropdown<int>(
                                value: settings.maxFailedAttempts,
                                label: l10n.securityAttempts,
                                items: const [3, 5, 7, 10]
                                    .map(
                                      (attempts) => DropdownMenuItem(
                                        value: attempts,
                                        child: Text('$attempts'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  if (value == null) return;
                                  await ref
                                      .read(securityServiceProvider)
                                      .updateMaxFailedAttempts(value);
                                  ref.invalidate(securitySettingProvider);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 12),
                      child: Text(
                        l10n.securityRecentAttempts,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                      ),
                    ),
                    logsAsync.when(
                      data: (logs) {
                        if (logs.isEmpty) {
                          return Container(
                            decoration:
                                AppSurfaces.elevated(context, radius: 20),
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                l10n.securityNoAttempts,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          );
                        }
                        return Container(
                          decoration: AppSurfaces.elevated(context, radius: 20),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              for (int i = 0; i < logs.length; i++)
                                Column(
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16),
                                      title: Text(
                                        logs[i].authType.name.toUpperCase(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${logs[i].status.name.toUpperCase()} · ${logs[i].timestamp.toLocal()}',
                                      ),
                                      trailing: Text(
                                        logs[i].deviceId,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    if (i < logs.length - 1)
                                      Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                        color: Theme.of(context).dividerColor,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) =>
                          Text(l10n.securityErrorLoadingLogs(err.toString())),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Text(
              l10n.securityErrorLoadingSettings(err.toString()),
            ),
          ),
        ),
      ),
    );
  }
}
