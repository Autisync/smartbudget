import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Enter your account email and we will send password reset instructions.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                            if (!valid) {
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
                          },
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send reset email'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
