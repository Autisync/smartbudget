import 'package:flutter/material.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_shell.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

enum _VerifyPhase { verifying, success, failed, pending }

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late _VerifyPhase _phase;
  String? _message;
  bool _resending = false;

  bool get _hasToken => widget.token.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // With a token we attempt verification immediately; without one (the
    // post-signup "check your inbox" destination) we show a pending state with
    // a resend option.
    _phase = _hasToken ? _VerifyPhase.verifying : _VerifyPhase.pending;
    if (_hasToken) {
      Future.microtask(_runVerification);
    } else {
      _message =
          "We've emailed you a verification link. Open it on this device to "
          'finish verifying, or resend it below.';
    }
  }

  Future<void> _runVerification() async {
    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .verifyEmail(widget.token);
    final session = ref.read(sessionControllerProvider);
    if (!mounted) return;
    setState(() {
      _phase = ok ? _VerifyPhase.success : _VerifyPhase.failed;
      _message = ok
          ? 'Email successfully verified. You can continue using your account.'
          : (session.errorMessage ?? 'Email verification failed.');
    });
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() {
      _resending = true;
      _message = null;
    });
    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .resendVerificationEmail();
    final session = ref.read(sessionControllerProvider);
    if (!mounted) return;
    setState(() {
      _resending = false;
      _message = ok
          ? 'A new verification link is on its way. Check your inbox (and spam).'
          : (session.errorMessage ??
              'Could not send a verification email right now.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVerifying = _phase == _VerifyPhase.verifying;
    final isSuccess = _phase == _VerifyPhase.success;
    final statusColor = switch (_phase) {
      _VerifyPhase.success => const Color(0xFF0F9D58),
      _VerifyPhase.failed => colorScheme.error,
      _ => colorScheme.primary,
    };
    // Resend only makes sense while still unverified and not mid-verification.
    final canResend = !isSuccess && !isVerifying;

    return AuthScaffold(
      title: l10n.authConfirmEmail,
      subtitle:
          'Secure your account by confirming the email you signed up with.',
      icon: Icons.verified_user_rounded,
      cardWidth: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackButton(
            label: l10n.authBackToSignIn,
            onPressed: () => popOrGoToLogin(context),
          ),
          Text(
            'Verify email',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isVerifying
                ? 'This usually takes a moment. Keep this screen open while we validate your link.'
                : 'Verification status for your email address is shown below.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity( 0.08),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity( 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (isVerifying) ...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verifying your email...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else ...[
                  Icon(
                    switch (_phase) {
                      _VerifyPhase.success => Icons.verified_rounded,
                      _VerifyPhase.failed => Icons.error_outline_rounded,
                      _ => Icons.mark_email_unread_rounded,
                    },
                    size: 56,
                    color: statusColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    switch (_phase) {
                      _VerifyPhase.success => 'Verification complete',
                      _VerifyPhase.failed => 'Verification failed',
                      _ => 'Check your inbox',
                    },
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isVerifying ? null : () => context.go('/'),
            icon: Icon(isSuccess ? Icons.check_rounded : Icons.home_rounded),
            label: Text(isSuccess ? 'Continue to app' : 'Go to the app'),
          ),
          if (canResend) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _resending ? null : _resend,
              icon: _resending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label:
                  Text(_resending ? 'Sending…' : 'Resend verification email'),
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.authBackToSignIn),
          ),
        ],
      ),
    );
  }
}
