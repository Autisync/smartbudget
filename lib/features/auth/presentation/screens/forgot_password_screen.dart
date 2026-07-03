import 'package:flutter/material.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _message;
  bool _isError = false;
  bool _emailTouched = false;

  bool get _hasValidEmail => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
      .hasMatch(_emailController.text.trim());

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isError = _isError;
    final emailError =
        _emailTouched ? _emailValidation(_emailController.text) : null;

    return AuthScaffold(
      title: l10n.authForgotPassword,
      subtitle: l10n.authForgotSubtitle,
      icon: Icons.mark_email_read_rounded,
      cardWidth: 500,
      footer: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackButton(
            label: l10n.authBackToSignIn,
            onPressed: () => popOrGoToLogin(context),
          ),
          Text(
            'Forgot password',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your email and we will send a secure reset link.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: l10n.authEmail,
            hint: 'name@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 19),
            errorText: emailError,
            onChanged: (_) {
              setState(() {
                _message = null;
                _emailTouched = true;
              });
            },
            onSubmitted: (_) async {
              if (_submitting || !_hasValidEmail) {
                return;
              }
              await _submit();
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withOpacity( 0.40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RecoveryStep(
                    index: '1',
                    text: 'Enter the email linked to your account.'),
                SizedBox(height: 10),
                _RecoveryStep(
                    index: '2',
                    text: 'Check your inbox for the password reset link.'),
                SizedBox(height: 10),
                _RecoveryStep(
                    index: '3',
                    text: 'Choose a new password and sign back in.'),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            AuthMessageBanner(
              message: _message!,
              isError: isError,
            ),
          ],
          const SizedBox(height: 14),
          AuthButton(
            label: _submitting ? 'Sending reset link...' : 'Send reset email',
            loading: _submitting,
            enabled: _hasValidEmail,
            leading: const Icon(Icons.send_rounded, size: 18),
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting ? null : () => context.go('/login'),
            child: Text(l10n.authBackToSignIn),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!_hasValidEmail) {
      setState(() {
        _message = 'Enter a valid email.';
        _isError = true;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
      _isError = false;
    });
    await ref.read(sessionControllerProvider.notifier).forgotPassword(email);
    if (!mounted) return;
    final session = ref.read(sessionControllerProvider);
    // Single inline message — no duplicate snackbar. The success copy is
    // intentionally generic so it never reveals whether the account exists.
    setState(() {
      _submitting = false;
      _isError = session.errorMessage != null;
      _message = session.errorMessage ??
          'If an account exists for this email, a reset link has been sent. '
              'Check your inbox and spam folder.';
    });
  }

  String? _emailValidation(String email) {
    if (email.trim().isEmpty) return 'Email is required';
    if (!_hasValidEmail) return 'Enter a valid email';
    return null;
  }
}

class _RecoveryStep extends StatelessWidget {
  const _RecoveryStep({
    required this.index,
    required this.text,
  });

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity( 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
