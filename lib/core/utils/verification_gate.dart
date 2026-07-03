import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/components/feedback/app_feedback_service.dart';
import 'package:smartbudget/core/utils/resend_cooldown.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';

/// Soft-blocks write operations for unverified users.
///
/// Usage at any write entry point (button tap, FAB, quick-add menu item):
/// ```dart
/// if (!await VerificationGate.allow(context, container)) return;
/// // proceed with the write operation
/// ```
abstract final class VerificationGate {
  VerificationGate._();

  /// Returns `true` when the signed-in user is verified and the caller may
  /// proceed. Returns `false` and shows a verification prompt when the user
  /// has not yet confirmed their email — the caller must abort the operation.
  ///
  /// [container] is obtained via `ProviderScope.containerOf(context)` in
  /// widget contexts that are not `ConsumerWidget`s, or `ref.read` otherwise.
  static Future<bool> allow(
    BuildContext context,
    ProviderContainer container,
  ) async {
    final session = container.read(sessionControllerProvider);
    final isVerified = session.user?.isVerified ?? false;

    if (isVerified) return true;

    if (!context.mounted) return false;

    await _showVerificationPrompt(context, container);
    return false;
  }

  static Future<void> _showVerificationPrompt(
    BuildContext context,
    ProviderContainer container,
  ) async {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _VerificationSheet(container: container),
    );
  }
}

class _VerificationSheet extends StatefulWidget {
  const _VerificationSheet({required this.container});
  final ProviderContainer container;

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
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

  /// Rebuild once per second while a cooldown is counting down, then stop.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !ResendCooldown.active) {
        t.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = const BorderRadius.vertical(top: Radius.circular(28));

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Icon badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                color: Color(0xFFF97316),
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Verify your email first',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adding data requires a verified email address. '
              'Please check your inbox and follow the link we sent you. '
              'Didn\'t receive it?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Resend button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    (_sending || ResendCooldown.active) ? null : _resend,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFF97316).withOpacity( 0.4),
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        ResendCooldown.active
                            ? 'Resend available in ${ResendCooldown.formatRemaining()}'
                            : 'Resend verification email',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                ResendCooldown.isHourlyLock
                    ? 'Hourly limit reached. Try again later.'
                    : 'You can resend up to 3 times per hour.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Dismiss
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity( 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'I\'ll verify later',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resend() async {
    if (_sending) return;
    setState(() => _sending = true);
    final ok = await widget.container
        .read(sessionControllerProvider.notifier)
        .resendVerificationEmail();
    if (!mounted) return;
    setState(() => _sending = false);
    final errorMsg = widget.container.read(sessionControllerProvider).errorMessage
        ?? 'Could not send email. Please try again.';
    final lowerMsg = errorMsg.toLowerCase();
    final rateLimited = !ok &&
        (lowerMsg.contains('too many') || lowerMsg.contains('please wait'));
    // Start the 1-hour cooldown when the email was sent, or when the server
    // says we've already hit the hourly limit.
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
    // Keep the sheet open on success now so the user sees the cooldown state.
    // (Auto-dismiss removed — they can tap "I'll verify later".)
  }
}
