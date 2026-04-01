import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _message;
  bool _submitting = false;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tokenMissing
                        ? 'Reset token is missing. Open the latest email link again.'
                        : 'Create a new password for your account.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    enabled: !tokenMissing,
                    decoration: const InputDecoration(labelText: 'New password'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    enabled: !tokenMissing,
                    decoration: const InputDecoration(labelText: 'Confirm new password'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use at least 8 characters, including upper, lower, and number.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (_message != null)
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.toLowerCase().contains('success')
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: tokenMissing || _submitting
                        ? null
                        : () async {
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
                          },
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reset password'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to sign in'),
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
