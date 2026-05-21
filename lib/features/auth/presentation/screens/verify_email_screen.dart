import 'package:flutter/material.dart';
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

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _loading = true;
  bool _success = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runVerification);
  }

  Future<void> _runVerification() async {
    if (widget.token.isEmpty) {
      setState(() {
        _loading = false;
        _success = false;
        _message = 'Verification token is missing.';
      });
      return;
    }

    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .verifyEmail(widget.token);
    final session = ref.read(sessionControllerProvider);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _success = ok;
      _message = ok
          ? 'Email successfully verified. You can continue using your account.'
          : (session.errorMessage ?? 'Email verification failed.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _success ? const Color(0xFF0F9D58) : colorScheme.error;

    return AuthScaffold(
      title: 'Confirm your email',
      subtitle:
          'We are validating your email verification link so your account can continue through the secure sign-in flow.',
      icon: Icons.verified_user_rounded,
      cardWidth: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackButton(
            label: 'Back to sign in',
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
            _loading
                ? 'This usually takes a moment. Keep this screen open while we validate your token.'
                : 'Verification status for your email address is shown below.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_loading) ...[
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
                    _success
                        ? Icons.verified_rounded
                        : Icons.error_outline_rounded,
                    size: 56,
                    color: statusColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _success ? 'Verification complete' : 'Verification failed',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _message ?? 'Preparing verification status...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loading ? null : () => context.go('/login'),
            icon: Icon(
              _success ? Icons.login_rounded : Icons.arrow_back_rounded,
            ),
            label: Text(_success ? 'Continue to sign in' : 'Go to sign in'),
          ),
          if (!_loading && !_success) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _message = null;
                });
                Future.microtask(_runVerification);
              },
              child: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}




