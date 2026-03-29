import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/features/auth/presentation/providers/auth_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/security_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _isAppBarScrolled = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(securitySettingProvider);
    final logsAsync = ref.watch(authLogsProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
          child: const Text('Security Settings'),
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
                      key: const ValueKey('security-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('security-appbar-blur-off')),
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
                        'Authentication & access',
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
                            title: const Text('Biometric authentication'),
                            subtitle: const Text(
                              'Use Face ID / Touch ID to unlock SmartBudget.',
                            ),
                            value: settings.biometricEnabled,
                            onChanged: (value) async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .enableBiometric(value);
                              await ref
                                  .read(securityServiceProvider)
                                  .updateBiometricEnabled(value);
                              ref.invalidate(securitySettingProvider);
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
                            title: const Text('Session timeout'),
                            subtitle: Text(
                              '${(settings.sessionTimeout / 60).round()} minutes before re-authentication',
                            ),
                            trailing: DropdownButton<int>(
                              value: settings.sessionTimeout,
                              items: const [300, 600, 900, 1800]
                                  .map(
                                    (seconds) => DropdownMenuItem(
                                      value: seconds,
                                      child: Text('${seconds ~/ 60} min'),
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
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Theme.of(context).dividerColor,
                          ),
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: const Text('Lockout threshold'),
                            subtitle: Text(
                              'Lock account after ${settings.maxFailedAttempts} failed attempts',
                            ),
                            trailing: DropdownButton<int>(
                              value: settings.maxFailedAttempts,
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
                        'Recent authentication attempts',
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
                                'No attempts recorded yet.',
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
                      error: (err, st) => Text('Error loading logs: $err'),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) =>
              Center(child: Text('Error loading security settings: $err')),
        ),
      ),
    );
  }
}
