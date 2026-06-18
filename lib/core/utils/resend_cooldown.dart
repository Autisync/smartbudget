/// Client-side cooldown for verification-email resends, mirroring the backend
/// policy: up to [maxPerHour] sends per rolling hour, each followed by a short
/// [gap] (1 minute); after the last allowed send the user is locked out for the
/// remainder of the hour. The server remains the source of truth — a 429/400
/// also (re)starts this — but reflecting it here keeps the button honest.
class ResendCooldown {
  ResendCooldown._();

  static const int maxPerHour = 3;
  static const Duration gap = Duration(minutes: 1);
  static const Duration window = Duration(hours: 1);

  static DateTime? _windowStart;
  static int _attempts = 0;
  static DateTime? _cooldownUntil;

  static void _resetIfWindowElapsed() {
    final start = _windowStart;
    if (start != null && DateTime.now().difference(start) >= window) {
      _windowStart = null;
      _attempts = 0;
      _cooldownUntil = null;
    }
  }

  /// Record a send (accepted or server-rate-limited) and advance the cooldown:
  /// a 1-minute gap between sends, or a lock until the hour ends after the 3rd.
  static void start() {
    _resetIfWindowElapsed();
    final now = DateTime.now();
    _windowStart ??= now;
    _attempts += 1;
    _cooldownUntil = _attempts >= maxPerHour
        ? _windowStart!.add(window)
        : now.add(gap);
  }

  /// How many resends remain in the current hour window.
  static int get attemptsRemaining {
    _resetIfWindowElapsed();
    final left = maxPerHour - _attempts;
    return left < 0 ? 0 : left;
  }

  /// True when the current cooldown is the final hour-long lock (3rd send used).
  static bool get isHourlyLock => attemptsRemaining == 0 && active;

  /// Time left before another resend is allowed. Zero when ready.
  static Duration get remaining {
    _resetIfWindowElapsed();
    final until = _cooldownUntil;
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
