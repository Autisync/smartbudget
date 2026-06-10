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
  bool _passwordTouched = false;
  bool _confirmTouched = false;

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
    final passwordError =
        _passwordTouched ? _passwordValidation(_passwordController.text) : null;
    final confirmError = _confirmTouched
        ? _confirmValidation(
            _passwordController.text, _confirmPasswordController.text)
        : null;

    return AuthScaffold(
      title: 'Set a new password',
      subtitle: 'Protect your account with a strong replacement password.',
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
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tokenMissing
                ? 'The reset link is missing or incomplete. Open the most recent password reset email and use that link again.'
                : 'Enter your new password below. Your old password will stop working after this update.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'New password',
            hint: 'Create a new password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !tokenMissing,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
            errorText: passwordError,
            suffix: IconButton(
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
            onChanged: (_) {
              setState(() {
                _passwordTouched = true;
              });
            },
          ),
          const SizedBox(height: 10),
          PasswordStrengthIndicator(
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            label: 'Confirm password',
            hint: 'Re-enter the password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            enabled: !tokenMissing,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: const Icon(Icons.verified_user_outlined, size: 19),
            errorText: confirmError,
            suffix: IconButton(
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
            onChanged: (_) {
              setState(() {
                _confirmTouched = true;
              });
            },
            onSubmitted: (_) async {
              if (tokenMissing || _submitting) return;
              await _submit();
            },
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
            label: _submitting ? 'Updating password...' : 'Reset password',
            loading: _submitting,
            enabled: !tokenMissing,
            leading: Icon(
              isSuccess ? Icons.check_rounded : Icons.password_rounded,
              size: 18,
            ),
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
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
    if (!mounted) return;
    final session = ref.read(sessionControllerProvider);
    // Single inline message; the banner styles itself from the success keyword.
    setState(() {
      _submitting = false;
      _message = ok
          ? 'Success. You can now sign in with your new password.'
          : (session.errorMessage ?? 'Could not reset password.');
    });
  }

  String? _passwordValidation(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  String? _confirmValidation(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }
}
