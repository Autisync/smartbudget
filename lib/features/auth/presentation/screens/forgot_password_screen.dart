import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/components/feedback/app_feedback_service.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isError = _message != null && _message == 'Enter a valid email.';
    final emailError =
        _emailTouched ? _emailValidation(_emailController.text) : null;

    return AuthScaffold(
      title: 'Forgot password',
      subtitle: 'Recover account access in a few quick steps.',
      icon: Icons.mark_email_read_rounded,
      cardWidth: 500,
      footer: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackButton(
            label: 'Back to sign in',
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
            label: 'Email',
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
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.40),
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
            child: const Text('Return to sign in'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!_hasValidEmail) {
      setState(() => _message = 'Enter a valid email.');
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });
    await ref.read(sessionControllerProvider.notifier).forgotPassword(email);
    final session = ref.read(sessionControllerProvider);
    final hasError = session.errorMessage != null;
    setState(() {
      _submitting = false;
      _message = session.errorMessage ??
          'If this account exists, reset instructions were sent.';
    });

    if (!mounted) return;

    if (hasError) {
      AppFeedbackService.showError(context, session.errorMessage!);
      return;
    }
    AppFeedbackService.showSuccess(
      context,
      'Password reset email sent. Check your inbox.',
    );
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
            color: colorScheme.primary.withValues(alpha: 0.12),
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
