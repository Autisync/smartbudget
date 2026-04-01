import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/signup_form_provider.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(signupFormProvider);
    final formController = ref.read(signupFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'First name'),
                    onChanged: formController.setFirstName,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Last name'),
                    onChanged: formController.setLastName,
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 6),
                  Text(
                    'Use at least 8 characters, including upper, lower, and number.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password'),
                    onChanged: formController.setConfirmPassword,
                  ),
                  if (form.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      form.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (!form.isValid || form.submitting)
                        ? null
                        : () async {
                            formController.setSubmitting(true);
                            final ok = await ref.read(sessionControllerProvider.notifier).signup(
                                  email: form.email,
                                  password: form.password,
                                  firstName: form.firstName,
                                  lastName: form.lastName,
                                );
                            formController.setSubmitting(false);

                            final session = ref.read(sessionControllerProvider);
                            if (!ok) {
                              formController.setError(session.errorMessage ?? 'Unable to create account.');
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
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: form.submitting ? null : () => context.go('/login'),
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
