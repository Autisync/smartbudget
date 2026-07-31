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
        ? _requiredValidation(l10n, form.firstName, l10n.authFirstName)
        : null;
    final lastNameError = _lastNameTouched
        ? _requiredValidation(l10n, form.lastName, l10n.authLastName)
        : null;
    final emailError =
        _emailTouched ? _emailValidation(l10n, form.email) : null;
    final passwordError =
        _passwordTouched ? _passwordValidation(l10n, form.password) : null;
    final confirmError = _confirmTouched
        ? _confirmValidation(l10n, form.password, form.confirmPassword)
        : null;

    return AuthScaffold(
      title: l10n.authCreateAccount,
      subtitle: l10n.authSignupSubtitle,
      icon: Icons.person_add_alt_1_rounded,
      footer: AuthInlinePrompt(
        label: l10n.authAlreadyHaveAccount,
        actionLabel: l10n.authSignIn,
        onPressed: form.submitting ? null : () => context.go('/login'),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.signupHeading,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.signupHeadingSubtitle,
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
              hint: l10n.authEmailHint,
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
                tooltip: _obscurePassword ? l10n.a11yShowPassword : l10n.a11yHidePassword,
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
                tooltip: _obscureConfirmPassword
                    ? l10n.a11yShowPassword
                    : l10n.a11yHidePassword,
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
              label: form.submitting
                  ? l10n.signupCreatingAccount
                  : l10n.authCreateAccount,
              loading: form.submitting,
              enabled: !form.submitting,
              leading: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              onPressed: () => _submit(context),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
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
              l10n.authTermsAgreement,
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

  String? _requiredValidation(AppLocalizations l10n, String value, String field) {
    if (value.trim().isEmpty) return l10n.authFieldRequired(field);
    return null;
  }

  String? _emailValidation(AppLocalizations l10n, String value) {
    if (value.trim().isEmpty) return l10n.authEmailRequired;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    if (!valid) return l10n.authEmailInvalid;
    return null;
  }

  String? _passwordValidation(AppLocalizations l10n, String value) {
    if (value.isEmpty) return l10n.authPasswordRequired;
    if (value.length < 8) return l10n.authPasswordTooShort;
    return null;
  }

  String? _confirmValidation(
    AppLocalizations l10n,
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) return l10n.authConfirmPasswordRequired;
    if (password != confirmPassword) return l10n.authPasswordsDoNotMatch;
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
            ? l10n.signupCompleteFieldsAndLegal
            : hasInvalidFields
                ? l10n.signupCompleteHighlightedFields
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
      formController
          .setError(session.errorMessage ?? l10n.signupUnableToCreateAccount);
      return;
    }
    if (!context.mounted) return;
    // Account created: send the user to the verification prompt so they get a
    // clear "check your inbox" confirmation with a resend option, instead of
    // silently landing on the dashboard.
    context.go('/verify-email');
  }
}
