import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/components/feedback/app_feedback_service.dart';
import 'package:smartbudget/core/utils/resend_cooldown.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';

/// A dismissible in-app banner that reminds unverified users to check their
/// inbox and provides a one-tap Resend action.
///
/// Renders as [SizedBox.shrink] when:
///   • the signed-in user is already verified, or
///   • the user has dismissed it this session.
///
/// Placement: top of the main navigation scaffold (before page content).
/// Per the design system: orange = warning, no border on the container itself.
class AppEmailVerificationBanner extends ConsumerStatefulWidget {
  const AppEmailVerificationBanner({super.key});

  @override
  ConsumerState<AppEmailVerificationBanner> createState() =>
      _AppEmailVerificationBannerState();
}

class _AppEmailVerificationBannerState
    extends ConsumerState<AppEmailVerificationBanner> {
  bool _dismissed = false;
  bool _sending = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (ResendCooldown.active) _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !ResendCooldown.active) {
        t.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  static const _orange = Color(0xFFF97316); // semantic warning
  static const _orangeBg = Color(0xFFFFF7ED); // orange-50
  static const _orangeDark = Color(0xFF9A3412); // orange-900 for headline
  static const _orangeMid = Color(0xFF92400E); // amber-800 for body text

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isVerified = session.user?.isVerified ?? true;

    if (isVerified || _dismissed) return const SizedBox.shrink();

    return Material(
      color: _orangeBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 20,
                color: _orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Verify your email',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _orangeDark,
                          ),
                    ),
                    Text(
                      'Check your inbox or tap Resend.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _orangeMid,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Resend CTA
              if (_sending)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_orange),
                  ),
                )
              else if (ResendCooldown.active)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Resend in ${ResendCooldown.formatRemaining()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _orangeMid,
                        ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _resend,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Resend',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _orange,
                                decoration: TextDecoration.underline,
                                decorationColor: _orange,
                              ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Dismiss
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _orangeMid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resend() async {
    if (_sending) return;
    setState(() => _sending = true);
    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .resendVerificationEmail();
    if (!mounted) return;
    setState(() => _sending = false);
    // Use the specific error from the session state (e.g. "No internet
    // connection") rather than a generic fallback, so the user knows whether
    // to check their network or try again later.
    final errorMsg = ref.read(sessionControllerProvider).errorMessage
        ?? 'Could not send email. Please try again.';
    final rateLimited = !ok && errorMsg.toLowerCase().contains('too many');
    if (ok || rateLimited) {
      ResendCooldown.start();
      _startTicker();
    }
    AppFeedbackToast.show(
      context,
      message: ok ? 'Verification email sent — check your inbox.' : errorMsg,
      backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      icon: ok ? Icons.check_circle_outline : Icons.error_outline,
    );
  }
}
