import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';

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

    final ok = await ref.read(sessionControllerProvider.notifier).verifyEmail(widget.token);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loading) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    const Text('Verifying your email...'),
                  ] else ...[
                    Icon(
                      _success ? Icons.verified_rounded : Icons.error_outline_rounded,
                      size: 56,
                      color: _success ? Colors.green : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(_message ?? ''),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Go to sign in'),
                    ),
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
