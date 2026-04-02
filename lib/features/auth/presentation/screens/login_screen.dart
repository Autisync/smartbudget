import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart' as bio;
import 'package:smartbudget/features/auth/presentation/providers/auth_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/login_form_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    if (session.authenticated && session.localUnlockRequired) {
      return _BiometricUnlockView(
        onUnlock: () async {
          final result =
              await ref.read(authControllerProvider.notifier).authenticate();
          if (result == bio.AuthStatus.authenticated) {
            ref.read(sessionControllerProvider.notifier).markUnlockedLocally();
            if (context.mounted) {
              context.go('/');
            }
            return;
          }

          if (!context.mounted) return;
          final message = switch (result) {
            bio.AuthStatus.notAvailable =>
              'Biometric authentication unavailable on this device.',
            bio.AuthStatus.noBiometricsEnrolled =>
              'No biometrics enrolled. Configure it in device settings.',
            bio.AuthStatus.lockedOut =>
              'Biometric authentication is temporarily locked out.',
            bio.AuthStatus.permanentlyLockedOut =>
              'Biometric authentication is permanently locked.',
            bio.AuthStatus.denied => 'Authentication denied.',
            bio.AuthStatus.error =>
              'Authentication failed due to a system error.',
            bio.AuthStatus.authenticated => 'Authenticated',
          };
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthScaffold(
      title: 'Welcome back',
      subtitle:
          'Sign in to continue with your secure account session and pick up where you left off.',
      icon: Icons.lock_open_rounded,
      footer: AuthInlinePrompt(
        label: 'New to SmartSpend?',
        actionLabel: 'Create account',
        onPressed: form.submitting ? () {} : () => context.push('/signup'),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign in',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the credentials linked to your SmartSpend account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const AuthSectionLabel(text: 'Email address'),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email
              ],
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'name@example.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              onChanged: formController.setEmail,
            ),
            const SizedBox(height: 16),
            const AuthSectionLabel(text: 'Password'),
            const SizedBox(height: 8),
            TextField(
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              onChanged: formController.setPassword,
              onSubmitted: (_) async {
                if (!form.isValid || form.submitting) return;
                await _submit(context);
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: form.submitting
                    ? null
                    : () => context.push('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            if (form.errorMessage != null) ...[
              const SizedBox(height: 8),
              AuthMessageBanner(
                message: form.errorMessage!,
                isError: true,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: (!form.isValid || form.submitting)
                  ? null
                  : () => _submit(context),
              icon: form.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(form.submitting ? 'Signing in...' : 'Sign in'),
            ),
            const SizedBox(height: 12),
            Text(
              'Biometric unlock remains available after your authenticated session is established on this device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final form = ref.read(loginFormProvider);
    final formController = ref.read(loginFormProvider.notifier);

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthScaffold(
      title: 'Unlock your session',
      subtitle:
          'Your account is already authenticated. Confirm with biometrics to regain local access on this device.',
      icon: Icons.fingerprint_rounded,
      cardWidth: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Biometric unlock',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This quick check protects your local session without changing the signed-in account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Use Face ID, fingerprint, or another enrolled biometric method to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => onUnlock(),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Unlock with biometrics'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => onUseDifferentAccount(),
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
