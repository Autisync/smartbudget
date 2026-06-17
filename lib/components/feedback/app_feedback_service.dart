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

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final effectiveDuration = duration ?? _durationFor(message);

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

    if (replaceCurrent) {
      messenger
        ..hideCurrentSnackBar()
        ..removeCurrentSnackBar();
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: effectiveDuration,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        backgroundColor: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
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
    );
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
