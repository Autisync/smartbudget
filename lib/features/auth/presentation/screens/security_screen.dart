import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/features/auth/presentation/providers/auth_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/security_provider.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(securitySettingProvider);
    final logsAsync = ref.watch(authLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Authentication & access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
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
              const SizedBox(height: 12),
              ListTile(
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
              const SizedBox(height: 12),
              ListTile(
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
              const SizedBox(height: 24),
              const Text(
                'Recent authentication attempts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Text('No attempts recorded yet.');
                  }
                  return Column(
                    children: logs.map((log) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            log.authType.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${log.status.name.toUpperCase()} · ${log.timestamp.toLocal()}',
                          ),
                          trailing: Text(
                            log.deviceId,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Error loading logs: $err'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            Center(child: Text('Error loading security settings: $err')),
      ),
    );
  }
}
