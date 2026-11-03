import 'dart:async';

import 'package:flutter/material.dart';

class AppFeedbackToast {
  const AppFeedbackToast._();

  static DateTime? _lastShownAt;
  static String? _lastMessage;
  static OverlayEntry? _loadingEntry;

  static bool shouldSuppressDuplicate(String message, {Duration? window}) {
    final dedupeWindow = window ?? const Duration(milliseconds: 1400);
    final now = DateTime.now();
    if (_lastMessage == message &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < dedupeWindow) {
      return true;
    }
    _lastMessage = message;
    _lastShownAt = now;
    return false;
  }

  /// Reading-time-aware display duration: long enough to comfortably read the
  /// message rather than a fixed 3s that vanished before users finished. ~4s
  /// floor + ~55ms/char, capped at 8s. Callers can still override explicitly.
  static Duration _durationFor(String message) {
    final ms = message.trim().length * 55 + 2600;
    return Duration(milliseconds: ms.clamp(4000, 8000));
  }

  static OverlayEntry? _toastEntry;

  /// Entries already taken out of the overlay. OverlayEntry.remove() asserts
  /// when called twice, and a toast can be removed by its own timer, by the
  /// next toast replacing it, or both in the same frame.
  static final Expando<bool> _removed = Expando<bool>('toastRemoved');

  // Must match AppBottomNavigation's layout in app_router.dart so the toast
  // sits just above the navbar instead of behind it (or mid-screen, which the
  // old floating SnackBar did because its position followed whichever
  // ScaffoldMessenger happened to be nearest).
  static const double _kNavBarHeight = 60.0;
  static const double _kNavBarPaddingBottom = 8.0;

  static void show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration? duration,
    bool replaceCurrent = true,
  }) {
    if (message.trim().isEmpty || shouldSuppressDuplicate(message)) {
      return;
    }

    // Anchor in the root overlay so positioning is independent of the nested
    // Scaffold/messenger the caller lives in.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final effectiveDuration = duration ?? _durationFor(message);

    if (replaceCurrent) {
      _dismissToast();
    }

    // Read the bottom safe-area inset WITHOUT registering an inherited
    // dependency. This method is frequently invoked from async event handlers
    // (e.g. right before a bottom sheet is popped); using MediaQuery.of/paddingOf
    // there would attach a late dependency to a subtree that is about to be torn
    // down, tripping the framework's "InheritedElement.debugDeactivated:
    // _dependents.isEmpty" assertion. getInheritedWidgetOfExactType reads the
    // value without subscribing, so it is safe in any lifecycle state.
    final bottomInset =
        context.getInheritedWidgetOfExactType<MediaQuery>()?.data.padding.bottom ??
            0.0;
    final bottomOffset =
        bottomInset + _kNavBarPaddingBottom + _kNavBarHeight + 12;

    // The toast removes itself when its time is up. The timer lives in the
    // toast's own State, not here, so it is cancelled whenever the toast
    // leaves the screen for any other reason (replaced by the next toast, the
    // app's widget tree torn down). A static timer outlived the overlay: in
    // widget tests that is the "A Timer is still pending even after the
    // widget tree was disposed" failure.
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: bottomOffset,
        child: _ToastCard(
          message: message,
          backgroundColor: backgroundColor,
          icon: icon,
          duration: effectiveDuration,
          onExpired: () => _removeEntry(entry),
        ),
      ),
    );
    _toastEntry = entry;
    overlay.insert(entry);
  }

  static void _dismissToast() {
    final current = _toastEntry;
    if (current != null) _removeEntry(current);
  }

  static void _removeEntry(OverlayEntry entry) {
    if (identical(_toastEntry, entry)) _toastEntry = null;
    if (_removed[entry] == true) return;
    _removed[entry] = true;
    entry.remove();
  }

  static void showLoadingOverlay(BuildContext context,
      {required String message}) {
    dismissLoadingOverlay();

    if (message.trim().isEmpty) {
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _loadingEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Material(
                  color: const Color(0xFF2446C7),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_loadingEntry!);
  }

  static void dismissLoadingOverlay() {
    _loadingEntry?.remove();
    _loadingEntry = null;
  }
}

/// Animated toast pill rendered in the root overlay, anchored just above the
/// navbar. Fades + slides up on entry; the controller in [AppFeedbackToast]
/// removes the entry after the display duration.
class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.duration,
    required this.onExpired,
  });

  final String message;
  final Color backgroundColor;
  final IconData icon;

  /// How long the toast stays on screen before [onExpired] removes it.
  final Duration duration;
  final VoidCallback onExpired;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  Timer? _expiry;

  @override
  void initState() {
    super.initState();
    _expiry = Timer(widget.duration, widget.onExpired);
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(_curve),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity( 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppFeedbackService {
  const AppFeedbackService._();

  static void showSuccess(BuildContext context, String message) {
    AppFeedbackToast.show(
      context,
      message: message,
      backgroundColor: const Color(0xFF0F9D58),
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    AppFeedbackToast.show(
      context,
      message: message,
      backgroundColor: const Color(0xFFE25563),
      icon: Icons.error_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    AppFeedbackToast.show(
      context,
      message: message,
      backgroundColor: const Color(0xFFC47A1B),
      icon: Icons.warning_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    AppFeedbackToast.show(
      context,
      message: message,
      backgroundColor: const Color(0xFF5B55E7),
      icon: Icons.info_rounded,
    );
  }

  static void showLoading(BuildContext context, String message) {
    if (AppFeedbackToast.shouldSuppressDuplicate(message)) {
      return;
    }
    AppFeedbackToast.showLoadingOverlay(context, message: message);
  }

  static void dismissLoading() {
    AppFeedbackToast.dismissLoadingOverlay();
  }
}
