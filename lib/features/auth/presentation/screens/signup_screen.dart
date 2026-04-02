import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/signup_form_provider.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_shell.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(signupFormProvider);
    final formController = ref.read(signupFormProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthScaffold(
      title: 'Create your account',
      subtitle:
          'Set up a secure SmartSpend account to manage transactions, budgets, subscriptions, and insights in one place.',
      icon: Icons.person_add_alt_1_rounded,
      footer: AuthInlinePrompt(
        label: 'Already have an account?',
        actionLabel: 'Sign in',
        onPressed: form.submitting ? () {} : () => context.go('/login'),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Account details',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete the fields below to create your account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthSectionLabel(text: 'First name'),
                      const SizedBox(height: 8),
                      TextField(
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        decoration: const InputDecoration(
                          labelText: 'First name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        onChanged: formController.setFirstName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthSectionLabel(text: 'Last name'),
                      const SizedBox(height: 8),
                      TextField(
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        onChanged: formController.setLastName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const AuthSectionLabel(text: 'Email address'),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Create a password',
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
            ),
            const SizedBox(height: 12),
            _PasswordRequirement(
              label: 'At least 8 characters',
              met: form.password.length >= 8,
            ),
            const SizedBox(height: 6),
            _PasswordRequirement(
              label: 'Includes uppercase, lowercase, and number',
              met: form.passwordStrong,
            ),
            const SizedBox(height: 16),
            const AuthSectionLabel(text: 'Confirm password'),
            const SizedBox(height: 8),
            TextField(
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              onChanged: formController.setConfirmPassword,
              onSubmitted: (_) async {
                if (!form.isValid || form.submitting) return;
                await _submit(context);
              },
            ),
            if (form.confirmPassword.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PasswordRequirement(
                label: 'Passwords match',
                met: form.password == form.confirmPassword,
              ),
            ],
            if (form.errorMessage != null) ...[
              const SizedBox(height: 16),
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
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                form.submitting ? 'Creating account...' : 'Create account',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'By continuing, you confirm that the information provided is accurate and that you will use this account to manage your own financial workspace.',
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
    final form = ref.read(signupFormProvider);
    final formController = ref.read(signupFormProvider.notifier);

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
      formController.setError(
        session.errorMessage ?? 'Unable to create account.',
      );
      return;
    }
    if (!context.mounted) return;
    context.go('/');
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({
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
