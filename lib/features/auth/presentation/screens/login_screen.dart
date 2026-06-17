import 'package:flutter/material.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:smartbudget/components/feedback/app_feedback_service.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart' as bio;
import 'package:smartbudget/core/widgets/app_feedback.dart';
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
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _socialSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    final biometricUi = ref.watch(biometricAuthUiProvider);

    if (session.authenticated && session.localUnlockRequired) {
      return _BiometricUnlockView(
        state: biometricUi,
        onUnlock: () async {
          final result = await ref
              .read(biometricAuthUiProvider.notifier)
              .authenticateForUnlock();
          if (result == bio.AuthStatus.authenticated) {
            ref.read(sessionControllerProvider.notifier).markUnlockedLocally();
            if (context.mounted) {
              context.go('/');
            }
            return;
          }
        },
        onUseDifferentAccount: () async {
          ref.read(biometricAuthUiProvider.notifier).switchToPasswordFallback();
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
    final emailError = _emailTouched ? _emailValidation(form.email) : null;
    final passwordError =
        _passwordTouched ? _passwordValidation(form.password) : null;

    return AuthScaffold(
      title: l10n.authWelcomeBack,
      subtitle: l10n.authLoginSubtitle,
      icon: Icons.lock_open_rounded,
      footer: AuthInlinePrompt(
        label: l10n.authNewHere,
        actionLabel: l10n.authCreateAccount,
        onPressed: form.submitting ? () {} : () => context.push('/signup'),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign In',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use your account credentials to continue.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: l10n.authEmail,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email
              ],
              autocorrect: false,
              enableSuggestions: false,
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 19),
              errorText: emailError,
              onChanged: (value) {
                if (!_emailTouched) {
                  setState(() => _emailTouched = true);
                }
                formController.setEmail(value);
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: l10n.authPassword,
              hint: l10n.authEnterPassword,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              errorText: passwordError,
              suffix: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
              onChanged: (value) {
                if (!_passwordTouched) {
                  setState(() => _passwordTouched = true);
                }
                formController.setPassword(value);
              },
              onSubmitted: (_) async {
                if (form.submitting) return;
                await _submit(context);
              },
            ),
            const SizedBox(height: 4),
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
              const SizedBox(height: 6),
              AuthMessageBanner(
                message: form.errorMessage!,
                isError: true,
              ),
            ],
            const SizedBox(height: 12),
            AuthButton(
              label: form.submitting ? 'Signing in...' : 'Sign in',
              loading: form.submitting,
              leading: const Icon(Icons.login_rounded, size: 18),
              enabled: !form.submitting,
              onPressed: () => _submit(context),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Divider(color: colorScheme.outlineVariant),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'or',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: colorScheme.outlineVariant),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SocialButton(
              icon: Icons.apple,
              label: l10n.authContinueApple,
              onPressed: (_socialSubmitting || form.submitting)
                  ? () {}
                  : () => _signInWithApple(context),
            ),
            const SizedBox(height: 10),
            SocialButton(
              icon: Icons.g_mobiledata_rounded,
              label: l10n.authContinueGoogle,
              onPressed: (_socialSubmitting || form.submitting)
                  ? () {}
                  : () => _signInWithGoogle(context),
            ),
            if (_socialSubmitting) ...[
              const SizedBox(height: 8),
              const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Face ID / biometrics remain available after first sign in.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 0,
              children: [
                TextButton(
                  onPressed: () => context.push('/legal/terms'),
                  child: const Text('Terms'),
                ),
                Text(
                  '•',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/legal/privacy'),
                  child: const Text('Privacy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _emailValidation(String email) {
    if (email.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _passwordValidation(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final sessionController = ref.read(sessionControllerProvider.notifier);
    setState(() => _socialSubmitting = true);
    try {
      final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _showError('Google sign-in did not return an ID token.');
        return;
      }

      final nameParts =
          (account.displayName ?? '').trim().split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty
          ? nameParts.first
          : null;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

      final ok = await sessionController.socialLogin(
        provider: 'google',
        idToken: idToken,
        email: account.email,
        firstName: firstName,
        lastName: lastName,
      );

      if (!mounted) return;

      if (ok && context.mounted) {
        AppFeedbackService.showSuccess(context, 'Signed in successfully.');
        context.go('/');
        return;
      }
      final session = ref.read(sessionControllerProvider);
      _showError(session.errorMessage ?? 'Google sign-in failed.');
    } catch (_) {
      _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _socialSubmitting = false);
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    final sessionController = ref.read(sessionControllerProvider.notifier);
    setState(() => _socialSubmitting = true);
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        _showError('Apple sign-in is not available on this device.');
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        _showError('Apple sign-in did not return an ID token.');
        return;
      }

      final ok = await sessionController.socialLogin(
        provider: 'apple',
        idToken: idToken,
        email: credential.email,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );

      if (!mounted) return;

      if (ok && context.mounted) {
        AppFeedbackService.showSuccess(context, 'Signed in successfully.');
        context.go('/');
        return;
      }
      final session = ref.read(sessionControllerProvider);
      _showError(session.errorMessage ?? 'Apple sign-in failed.');
    } catch (_) {
      _showError('Apple sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _socialSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      message: message,
      type: AppFeedbackType.error,
    );
  }

  Future<void> _submit(BuildContext context) async {
    final form = ref.read(loginFormProvider);
    final formController = ref.read(loginFormProvider.notifier);
    final sessionController = ref.read(sessionControllerProvider.notifier);

    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
    });

    if (!form.isValid) {
      AppFeedbackService.showWarning(
        context,
        'Enter a valid email and password to continue.',
      );
      formController.setError(
        'Enter a valid email and password to sign in.',
      );
      return;
    }

    formController.setSubmitting(true);
    final ok = await sessionController.login(
      email: form.email,
      password: form.password,
    );

    formController.setSubmitting(false);

    if (!mounted) return;

    final sessionAfter = ref.read(sessionControllerProvider);
    if (!ok) {
      final message = sessionAfter.errorMessage ?? 'Login failed.';
      if (message.toLowerCase().contains('sign in again')) {
        AppFeedbackService.showWarning(
          this.context,
          'Your session has expired. Please sign in again.',
        );
      } else {
        AppFeedbackService.showError(this.context, message);
      }
      formController.setError(message);
      return;
    }

    AppFeedbackService.showSuccess(this.context, 'Signed in successfully.');
    if (!context.mounted) return;
    context.go('/');
  }
}

class _BiometricUnlockView extends StatelessWidget {
  const _BiometricUnlockView({
    required this.state,
    required this.onUnlock,
    required this.onUseDifferentAccount,
  });

  final BiometricAuthUiState state;
  final Future<void> Function() onUnlock;
  final Future<void> Function() onUseDifferentAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AuthScaffold(
      title: l10n.authUnlockSession,
      subtitle: l10n.authUnlockSubtitle,
      icon: Icons.fingerprint_rounded,
      cardWidth: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Biometric unlock',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Face ID or fingerprint to restore local access.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                AppLottieView(
                  assetPath: 'assets/animations/biometric_auth.json',
                  width: 108,
                  height: 108,
                  repeat: state.isBusy,
                  animate: true,
                  semanticLabel: 'Biometric authentication animation',
                  fallbackIcon: Icons.fingerprint_rounded,
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
          const SizedBox(height: 16),
          if (state.message != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _messageTone(colorScheme).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _messageTone(colorScheme).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _messageIcon(),
                    size: 16,
                    color: _messageTone(colorScheme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.message!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _messageTone(colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          AuthButton(
            label: state.isBusy ? 'Verifying...' : 'Unlock with biometrics',
            leading: state.isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open_rounded, size: 18),
            onPressed: state.isBusy ? null : () => onUnlock(),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: state.isBusy ? null : () => onUseDifferentAccount(),
            child: Text(
              state.phase == BiometricUiPhase.fallback
                  ? 'Use password instead'
                  : 'Use a different account',
            ),
          ),
        ],
      ),
    );
  }

  Color _messageTone(ColorScheme scheme) {
    switch (state.phase) {
      case BiometricUiPhase.success:
        return const Color(0xFF2E7D32);
      case BiometricUiPhase.failed:
      case BiometricUiPhase.cancelled:
      case BiometricUiPhase.fallback:
        return scheme.error;
      case BiometricUiPhase.openingPrompt:
      case BiometricUiPhase.authenticating:
      case BiometricUiPhase.idle:
        return scheme.primary;
    }
  }

  IconData _messageIcon() {
    switch (state.phase) {
      case BiometricUiPhase.success:
        return Icons.verified_rounded;
      case BiometricUiPhase.failed:
      case BiometricUiPhase.fallback:
        return Icons.error_outline_rounded;
      case BiometricUiPhase.cancelled:
        return Icons.info_outline_rounded;
      case BiometricUiPhase.openingPrompt:
      case BiometricUiPhase.authenticating:
        return Icons.fingerprint_rounded;
      case BiometricUiPhase.idle:
        return Icons.lock_outline_rounded;
    }
  }
}
