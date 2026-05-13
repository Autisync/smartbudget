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

  static String? _extractDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
