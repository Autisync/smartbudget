import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_shell.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _message;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isStrongPassword {
    final value = _passwordController.text;
    return value.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[0-9]').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final tokenMissing = widget.token.isEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSuccess = (_message ?? '').toLowerCase().contains('success');
    final isError = _message != null && !isSuccess;

    return AuthScaffold(
      title: 'Set a new password',
      subtitle:
          'Choose a strong new password for your account and continue back into SmartSpend with a fresh secure credential.',
      icon: Icons.password_rounded,
      cardWidth: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackButton(
            label: 'Back to sign in',
            onPressed: () => popOrGoToLogin(context),
          ),
          Text(
            'Reset password',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tokenMissing
                ? 'The reset link is missing or incomplete. Open the most recent password reset email and use that link again.'
                : 'Enter your new password below. Your old password will stop working after this update.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const AuthSectionLabel(text: 'New password'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !tokenMissing,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Create a new password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: tokenMissing
                    ? null
                    : () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _ResetRequirement(
            label: 'At least 8 characters',
            met: _passwordController.text.length >= 8,
          ),
          const SizedBox(height: 6),
          _ResetRequirement(
            label: 'Includes uppercase, lowercase, and number',
            met: _isStrongPassword,
          ),
          const SizedBox(height: 16),
          const AuthSectionLabel(text: 'Confirm password'),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            enabled: !tokenMissing,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Re-enter the new password',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                onPressed: tokenMissing
                    ? null
                    : () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) async {
              if (tokenMissing || _submitting) return;
              await _submit();
            },
          ),
          if (_confirmPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ResetRequirement(
              label: 'Passwords match',
              met: _passwordController.text == _confirmPasswordController.text,
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            AuthMessageBanner(
              message: _message!,
              isError: isError,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: tokenMissing || _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isSuccess ? Icons.check_rounded : Icons.password_rounded,
                  ),
            label: Text(
              _submitting ? 'Updating password...' : 'Reset password',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go('/login'),
            child: Text(isSuccess ? 'Continue to sign in' : 'Back to sign in'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (!_isStrongPassword) {
      setState(() => _message = 'Use a stronger password.');
      return;
    }
    if (password != confirm) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });
    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .resetPassword(token: widget.token, newPassword: password);
    final session = ref.read(sessionControllerProvider);
    setState(() {
      _submitting = false;
      _message = ok
          ? 'Success. You can now sign in with your new password.'
          : (session.errorMessage ?? 'Could not reset password.');
    });
  }
}

class _ResetRequirement extends StatelessWidget {
  const _ResetRequirement({
    required this.label,
    required this.met,
  });

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met
        ? const Color(0xFF0F9D58)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: met ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
