import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

class AppErrorMapper {
  static String from(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is DioException) {
      return fromDio(error, fallback: fallback);
    }
    if (error is SocketException) {
      return 'No internet connection. Check your network and try again.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is FormatException) {
      return 'Unexpected response from server. Please try again.';
    }
    return fallback;
  }

  static String fromDio(
    DioException error, {
    String fallback = 'Something went wrong. Please try again.',
    String unauthorizedMessage = 'Authentication failed. Please sign in again.',
    Map<int, String> statusMessages = const {},
  }) {
    final detail = _extractDetail(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Check your network and try again.';
      case DioExceptionType.cancel:
        return 'Request was canceled.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null && statusMessages.containsKey(statusCode)) {
          return statusMessages[statusCode]!;
        }
        if (detail != null) {
          return detail;
        }
        return switch (statusCode) {
          400 => 'Invalid request. Please review and try again.',
          401 => unauthorizedMessage,
          403 => 'You do not have permission to do that.',
          404 => 'Requested resource was not found.',
          409 => 'A conflict occurred. Please refresh and try again.',
          422 => 'Please check your input and try again.',
          429 => 'Too many attempts. Please try again later.',
          500 ||
          502 ||
          503 ||
          504 =>
            'Service is temporarily unavailable. Please try again shortly.',
          _ => fallback,
        };
      case DioExceptionType.unknown:
        if (detail != null) {
          return detail;
        }
        if (error.error is SocketException) {
          return 'No internet connection. Check your network and try again.';
        }
        return fallback;
    }
  }

  /// M-2 FIX: Only surfaces server-provided error text when it passes a
  /// "safe user message" check. Raw server detail fields can contain stack
  /// traces, internal file paths, SQL fragments, or other implementation
  /// details that expose server internals to users and aid attackers.
  ///
  /// A message is considered user-safe when it is:
  ///   • Short (≤ 200 characters)
  ///   • Free of common server-internal patterns (paths, tracebacks, SQL)
  ///
  /// This deliberately errs conservative: when in doubt, we fall back to
  /// our own predefined message rather than leaking server internals.
  static String? _extractDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      final raw = _firstStringValue(data, const ['detail', 'message']);
      if (raw != null && _isSafeUserMessage(raw)) {
        return raw;
      }
    }
    return null;
  }

  static String? _firstStringValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Returns true only for short, human-readable messages that don't look
  /// like server internals. Add patterns here as new leak vectors are found.
  static bool _isSafeUserMessage(String message) {
    if (message.length > 200) return false;

    // Reject messages that look like server-side implementation details.
    final internalPatterns = <RegExp>[
      RegExp(r'Traceback \(most recent call last\)', caseSensitive: false),
      RegExp(r'Exception in thread', caseSensitive: false),
      RegExp(r'File "[^"]*", line \d+', caseSensitive: false),
      RegExp(r'at [a-zA-Z0-9_.]+\([^)]*\.java:\d+\)'),
      RegExp(r'\bSQLAlchemy\b', caseSensitive: false),
      RegExp(r'\bpsycopg\b', caseSensitive: false),
      RegExp(r'\bSELECT\b.*\bFROM\b', caseSensitive: false),
      RegExp(r'\bINSERT INTO\b', caseSensitive: false),
      RegExp(r'\bUPDATE\b.*\bSET\b', caseSensitive: false),
      RegExp(r'(\/[a-zA-Z0-9._-]+){3,}'),   // Unix-style deep file paths
      RegExp(r'[A-Z]:\\[^\s]+'),             // Windows-style paths
      RegExp(r'<html', caseSensitive: false), // HTML error pages
      RegExp(r'Internal Server Error', caseSensitive: false),
      RegExp(r'\bstacktrace\b', caseSensitive: false),
    ];

    for (final pattern in internalPatterns) {
      if (pattern.hasMatch(message)) return false;
    }
    return true;
  }
}




