import 'package:flutter/material.dart';

enum AppFeedbackType { success, error, warning, info }

class AppFeedback {
  static void show(
    BuildContext context, {
    required String message,
    AppFeedbackType type = AppFeedbackType.info,
    bool replaceCurrent = true,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null || message.trim().isEmpty) {
      return;
    }

    if (replaceCurrent) {
      messenger
        ..hideCurrentSnackBar()
        ..removeCurrentSnackBar();
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        backgroundColor: _backgroundColor(type),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        content: Row(
          children: [
            Icon(_icon(type), color: Colors.white, size: 18),
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

  static Color _backgroundColor(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => const Color(0xFF0F9D58),
      AppFeedbackType.error => const Color(0xFFE25563),
      AppFeedbackType.warning => const Color(0xFFC47A1B),
      AppFeedbackType.info => const Color(0xFF5B55E7),
    };
  }

  static IconData _icon(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => Icons.check_circle_rounded,
      AppFeedbackType.error => Icons.error_rounded,
      AppFeedbackType.warning => Icons.warning_rounded,
      AppFeedbackType.info => Icons.info_rounded,
    };
  }
}




