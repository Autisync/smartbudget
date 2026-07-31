// Unit cover for P3.2: AppErrorMapper is the single seam every screen must
// route exceptions through before displaying them, so raw exception text
// (stack frames, SQL, file paths, connection details) never reaches a user.
// No test file existed for it prior to this change even though several
// screens already depended on its behavior.
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';

void main() {
  group('AppErrorMapper.from', () {
    test('an unmapped generic exception falls back to the safe default', () {
      final message = AppErrorMapper.from(
        StateError('connection refused to db.internal:5432'),
      );
      expect(message, AppErrorMapper.defaultFallbackMessage);
      expect(message, isNot(contains('db.internal')));
      expect(message, isNot(contains('5432')));
    });

    test('a custom fallback overrides the default for unmapped errors', () {
      final message = AppErrorMapper.from(
        Exception('boom'),
        fallback: 'Custom fallback.',
      );
      expect(message, 'Custom fallback.');
    });

    test('SocketException maps to a network message, never the raw text', () {
      final message = AppErrorMapper.from(
        const SocketException('Failed host lookup: api.smaartspend.com'),
      );
      expect(message, contains('internet connection'));
      expect(message, isNot(contains('api.smaartspend.com')));
    });

    test('TimeoutException maps to a timeout message', () {
      final message = AppErrorMapper.from(TimeoutException('slow query'));
      expect(message, contains('timed out'));
    });

    test('FormatException maps to a generic parsing message', () {
      final message = AppErrorMapper.from(
        const FormatException('Unexpected character at offset 42'),
      );
      expect(message, isNot(contains('offset 42')));
      expect(message, contains('Unexpected response'));
    });
  });

  group('AppErrorMapper.fromDio', () {
    RequestOptions options() => RequestOptions(path: '/auth/login');

    test('connection timeout maps to a timeout message', () {
      final message = AppErrorMapper.fromDio(
        DioException(requestOptions: options(), type: DioExceptionType.connectionTimeout),
      );
      expect(message, contains('timed out'));
    });

    test('connectionError maps to a network message', () {
      final message = AppErrorMapper.fromDio(
        DioException(requestOptions: options(), type: DioExceptionType.connectionError),
      );
      expect(message, contains('internet connection'));
    });

    test('badCertificate maps to a secure-connection message', () {
      final message = AppErrorMapper.fromDio(
        DioException(requestOptions: options(), type: DioExceptionType.badCertificate),
      );
      expect(message, contains('Secure connection'));
    });

    test('a 500 response with no safe detail maps to a generic service message', () {
      final message = AppErrorMapper.fromDio(
        DioException(
          requestOptions: options(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options(), statusCode: 500),
        ),
      );
      expect(message, contains('temporarily unavailable'));
    });

    test('a 401 maps to the unauthorized message by default', () {
      final message = AppErrorMapper.fromDio(
        DioException(
          requestOptions: options(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options(), statusCode: 401),
        ),
      );
      expect(message, contains('sign in again'));
    });

    test('statusMessages overrides the default text for a given status code', () {
      final message = AppErrorMapper.fromDio(
        DioException(
          requestOptions: options(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options(), statusCode: 409),
        ),
        statusMessages: const {409: 'That email is already registered.'},
      );
      expect(message, 'That email is already registered.');
    });

    // M-2: server-provided detail text is only surfaced when it passes the
    // "safe user message" denylist — otherwise it could leak stack traces,
    // SQL fragments, or internal file paths straight to the user.
    test('a safe server-provided detail is surfaced verbatim', () {
      final message = AppErrorMapper.fromDio(
        DioException(
          requestOptions: options(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options(),
            statusCode: 400,
            data: {'detail': 'Email is already registered.'},
          ),
        ),
      );
      expect(message, 'Email is already registered.');
    });

    for (final entry in <String, String>{
      'a Python traceback': 'Traceback (most recent call last):\n  File "app.py", line 1',
      'a SQL statement': 'duplicate key value violates unique constraint: SELECT * FROM users',
      'a Unix file path': 'Error writing to /var/lib/postgres/data/base/16384/12345',
      'an HTML error page': '<html><body>500 Internal Server Error</body></html>',
      'a message over 200 chars': 'x' * 201,
    }.entries) {
      test('${entry.key} in server detail is rejected, falls back to the generic message', () {
        final message = AppErrorMapper.fromDio(
          DioException(
            requestOptions: options(),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options(),
              statusCode: 400,
              data: {'detail': entry.value},
            ),
          ),
        );
        expect(message, 'Invalid request. Please review and try again.');
      });
    }

    test('cancel maps to a canceled-request message', () {
      final message = AppErrorMapper.fromDio(
        DioException(requestOptions: options(), type: DioExceptionType.cancel),
      );
      expect(message, contains('canceled'));
    });

    test('unknown type with an underlying SocketException maps to a network message', () {
      final message = AppErrorMapper.fromDio(
        DioException(
          requestOptions: options(),
          type: DioExceptionType.unknown,
          error: const SocketException('Connection refused'),
        ),
      );
      expect(message, contains('internet connection'));
    });
  });
}
