import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart' as bio;
import 'package:smartbudget/features/auth/presentation/providers/auth_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/login_form_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    if (session.authenticated && session.localUnlockRequired) {
      return _BiometricUnlockView(
        onUnlock: () async {
          final result = await ref.read(authControllerProvider.notifier).authenticate();
          if (result == bio.AuthStatus.authenticated) {
            ref.read(sessionControllerProvider.notifier).markUnlockedLocally();
            if (context.mounted) {
              context.go('/');
            }
            return;
          }

          if (!context.mounted) return;
          final message = switch (result) {
            bio.AuthStatus.notAvailable => 'Biometric authentication unavailable on this device.',
            bio.AuthStatus.noBiometricsEnrolled => 'No biometrics enrolled. Configure it in device settings.',
            bio.AuthStatus.lockedOut => 'Biometric authentication is temporarily locked out.',
            bio.AuthStatus.permanentlyLockedOut => 'Biometric authentication is permanently locked.',
            bio.AuthStatus.denied => 'Authentication denied.',
            bio.AuthStatus.error => 'Authentication failed due to a system error.',
            bio.AuthStatus.authenticated => 'Authenticated',
          };
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        },
        onUseDifferentAccount: () async {
          await ref.read(sessionControllerProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
      );
    }

    final form = ref.watch(loginFormProvider);
    final formController = ref.read(loginFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue with your secure account session.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: formController.setEmail,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onChanged: formController.setPassword,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (form.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      form.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (!form.isValid || form.submitting)
                        ? null
                        : () async {
                            formController.setSubmitting(true);
                            final ok = await ref.read(sessionControllerProvider.notifier).login(
                                  email: form.email,
                                  password: form.password,
                                );
                            formController.setSubmitting(false);

                            final sessionAfter = ref.read(sessionControllerProvider);
                            if (!ok) {
                              formController.setError(sessionAfter.errorMessage ?? 'Login failed.');
                              return;
                            }

                            if (!context.mounted) return;
                            context.go('/');
                          },
                    child: form.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: form.submitting ? null : () => context.push('/signup'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricUnlockView extends StatelessWidget {
  const _BiometricUnlockView({
    required this.onUnlock,
    required this.onUseDifferentAccount,
  });

  final Future<void> Function() onUnlock;
  final Future<void> Function() onUseDifferentAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint, size: 70),
                const SizedBox(height: 20),
                Text(
                  'Unlock SmartSpend',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Use biometrics to unlock local access for this device session.'),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: () => onUnlock(),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unlock with biometrics'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => onUseDifferentAccount(),
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
