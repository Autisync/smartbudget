import 'package:flutter/material.dart';
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

    return AuthScaffold(
      title: 'Recover account access',
      subtitle:
          'Enter the email tied to your account and we will send instructions to reset your password securely.',
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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For security, we always send the same response whether or not the email exists in our system.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const AuthSectionLabel(text: 'Email address'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'name@example.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            onChanged: (_) => setState(() => _message = null),
            onSubmitted: (_) async {
              if (_submitting || !_hasValidEmail) {
                return;
              }
              await _submit();
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(18),
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
            const SizedBox(height: 16),
            AuthMessageBanner(
              message: _message!,
              isError: isError,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (_submitting || !_hasValidEmail) ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _submitting ? 'Sending reset link...' : 'Send reset email',
            ),
          ),
          const SizedBox(height: 10),
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
    setState(() {
      _submitting = false;
      _message = session.errorMessage ??
          'If this account exists, reset instructions were sent.';
    });
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
