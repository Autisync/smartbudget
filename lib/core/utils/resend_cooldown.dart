/// Shared client-side cooldown for verification-email resends.
///
/// The backend hard-limits resends to once per hour per user; this mirrors that
/// in the UI so the button disables and shows a countdown instead of letting the
/// user tap into a 400. In-memory (resets on app restart) — the server remains
/// the source of truth, and a 429/400 from the server also (re)starts it.
class ResendCooldown {
  ResendCooldown._();

  static const Duration window = Duration(hours: 1);
  static DateTime? _until;

  /// TEMPORARY kill-switch: the resend limit is disabled until this UTC instant,
  /// after which normal 1-hour throttling auto-resumes with no redeploy/rebuild.
  /// Set 2026-06-17 14:42Z → expires 2026-06-17 16:42Z.
  static final DateTime _disabledUntil = DateTime.utc(2026, 6, 17, 16, 42, 19);

  static bool get _isDisabled =>
      DateTime.now().toUtc().isBefore(_disabledUntil);

  /// Begin a fresh 1-hour cooldown (call after a send is accepted OR rate-limited).
  static void start() {
    if (_isDisabled) return;
    _until = DateTime.now().add(window);
  }

  /// Time left before another resend is allowed. Zero when ready.
  static Duration get remaining {
    if (_isDisabled) return Duration.zero;
    final until = _until;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  static bool get active => remaining > Duration.zero;

  /// Formats the remaining time as `M:SS` (or `MM:SS`) for display.
  static String formatRemaining() {
    final secs = remaining.inSeconds;
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
