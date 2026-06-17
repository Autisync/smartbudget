import 'package:flutter/material.dart';
import 'package:smartbudget/components/feedback/app_feedback_service.dart';

enum AppFeedbackType { success, error, warning, info }

class AppFeedback {
  static void show(
    BuildContext context, {
    required String message,
    AppFeedbackType type = AppFeedbackType.info,
    bool replaceCurrent = true,
    // Null => the toast picks a reading-time-aware duration (longer messages
    // stay longer). Pass an explicit value only to override.
    Duration? duration,
  }) {
    if (message.trim().isEmpty) {
      return;
    }
    final shouldSuppress = !replaceCurrent &&
        AppFeedbackToast.shouldSuppressDuplicate(
          message,
          window: duration,
        );
    if (shouldSuppress) {
      return;
    }

    switch (type) {
      case AppFeedbackType.success:
        AppFeedbackToast.show(
          context,
          message: message,
          duration: duration,
          replaceCurrent: replaceCurrent,
          backgroundColor: _backgroundColor(type),
          icon: _icon(type),
        );
        break;
      case AppFeedbackType.error:
        AppFeedbackToast.show(
          context,
          message: message,
          duration: duration,
          replaceCurrent: replaceCurrent,
          backgroundColor: _backgroundColor(type),
          icon: _icon(type),
        );
        break;
      case AppFeedbackType.warning:
        AppFeedbackToast.show(
          context,
          message: message,
          duration: duration,
          replaceCurrent: replaceCurrent,
          backgroundColor: _backgroundColor(type),
          icon: _icon(type),
        );
        break;
      case AppFeedbackType.info:
        AppFeedbackToast.show(
          context,
          message: message,
          duration: duration,
          replaceCurrent: replaceCurrent,
          backgroundColor: _backgroundColor(type),
          icon: _icon(type),
        );
        break;
    }
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
