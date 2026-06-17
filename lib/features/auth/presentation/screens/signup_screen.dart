import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/auth/presentation/providers/signup_form_provider.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_shell.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedLegal = false;
  bool _firstNameTouched = false;
  bool _lastNameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(signupFormProvider);
    final formController = ref.read(signupFormProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firstNameError = _firstNameTouched
        ? _requiredValidation(form.firstName, 'First name')
        : null;
    final lastNameError = _lastNameTouched
        ? _requiredValidation(form.lastName, 'Last name')
        : null;
    final emailError = _emailTouched ? _emailValidation(form.email) : null;
    final passwordError =
        _passwordTouched ? _passwordValidation(form.password) : null;
    final confirmError = _confirmTouched
        ? _confirmValidation(form.password, form.confirmPassword)
        : null;

    return AuthScaffold(
      title: l10n.authCreateAccount,
      subtitle: l10n.authSignupSubtitle,
      icon: Icons.person_add_alt_1_rounded,
      footer: AuthInlinePrompt(
        label: l10n.authAlreadyHaveAccount,
        actionLabel: l10n.authSignIn,
        onPressed: form.submitting ? () {} : () => context.go('/login'),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign Up',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your secure SmartSpend account.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    label: l10n.authFirstName,
                    hint: l10n.authFirstNameHint,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.givenName],
                    prefixIcon: const Icon(Icons.badge_outlined, size: 19),
                    errorText: firstNameError,
                    onChanged: (value) {
                      if (!_firstNameTouched) {
                        setState(() => _firstNameTouched = true);
                      }
                      formController.setFirstName(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuthTextField(
                    label: l10n.authLastName,
                    hint: l10n.authLastNameHint,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.familyName],
                    prefixIcon:
                        const Icon(Icons.person_outline_rounded, size: 19),
                    errorText: lastNameError,
                    onChanged: (value) {
                      if (!_lastNameTouched) {
                        setState(() => _lastNameTouched = true);
                      }
                      formController.setLastName(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AuthTextField(
              label: l10n.authEmail,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
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
            const SizedBox(height: 12),
            AuthTextField(
              label: l10n.authPassword,
              hint: l10n.authCreatePassword,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
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
            ),
            const SizedBox(height: 10),
            PasswordStrengthIndicator(
              password: form.password,
              confirmPassword: form.confirmPassword,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              label: l10n.authConfirmPassword,
              hint: l10n.authRepeatPassword,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: const Icon(Icons.verified_user_outlined, size: 19),
              errorText: confirmError,
              suffix: IconButton(
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
              onChanged: (value) {
                if (!_confirmTouched) {
                  setState(() => _confirmTouched = true);
                }
                formController.setConfirmPassword(value);
              },
              onSubmitted: (_) async {
                if (form.submitting) return;
                await _submit(context);
              },
            ),
            if (form.errorMessage != null) ...[
              const SizedBox(height: 8),
              AuthMessageBanner(
                message: form.errorMessage!,
                isError: true,
              ),
            ],
            const SizedBox(height: 14),
            AuthButton(
              label: form.submitting ? 'Creating account...' : 'Create account',
              loading: form.submitting,
              enabled: !form.submitting,
              leading: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              onPressed: () => _submit(context),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 0.92,
                    child: Checkbox(
                      value: _acceptedLegal,
                      visualDensity: VisualDensity.compact,
                      onChanged: form.submitting
                          ? null
                          : (value) {
                              setState(() => _acceptedLegal = value ?? false);
                              if (value == true && form.errorMessage != null) {
                                formController.setError(null);
                              }
                            },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        l10n.onboardingAcceptLegal,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'By continuing, you agree to our Terms and Privacy Policy.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => context.push('/legal/terms'),
                  child: Text(l10n.legalTermsTitle),
                ),
                Text(
                  '•',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/legal/privacy'),
                  child: Text(l10n.legalPrivacyTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidation(String value, String field) {
    if (value.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _emailValidation(String value) {
    if (value.trim().isEmpty) return 'Email is required';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    if (!valid) return 'Enter a valid email';
    return null;
  }

  String? _passwordValidation(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  String? _confirmValidation(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(signupFormProvider);
    final formController = ref.read(signupFormProvider.notifier);
    final sessionController = ref.read(sessionControllerProvider.notifier);

    setState(() {
      _firstNameTouched = true;
      _lastNameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
      _confirmTouched = true;
    });

    final hasInvalidFields = !form.isValid;
    if (hasInvalidFields || !_acceptedLegal) {
      // Single inline message (no duplicate snackbar).
      formController.setError(
        hasInvalidFields && !_acceptedLegal
            ? 'Complete the required fields and accept the legal terms.'
            : hasInvalidFields
                ? 'Complete the highlighted fields to create your account.'
                : l10n.onboardingAcceptLegalError,
      );
      return;
    }

    formController.setSubmitting(true);
    final ok = await sessionController.signup(
      email: form.email,
      password: form.password,
      firstName: form.firstName,
      lastName: form.lastName,
    );

    if (!mounted) return;
    formController.setSubmitting(false);

    final session = ref.read(sessionControllerProvider);
    if (!ok) {
      // Surfaces backend messages such as "Account already exists" inline.
      formController.setError(session.errorMessage ?? 'Unable to create account.');
      return;
    }
    if (!context.mounted) return;
    // Account created: send the user to the verification prompt so they get a
    // clear "check your inbox" confirmation with a resend option, instead of
    // silently landing on the dashboard.
    context.go('/verify-email');
  }
}
