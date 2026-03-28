import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeControllerProvider);

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
