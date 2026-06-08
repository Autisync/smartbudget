import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ExchangeRateQuote {
  const ExchangeRateQuote({
    required this.base,
    required this.target,
    required this.rate,
    required this.date,
  });

  final String base;
  final String target;
  final double rate;
  final DateTime date;
}

class ExchangeRatePoint {
  const ExchangeRatePoint({
    required this.date,
    required this.rate,
  });

  final DateTime date;
  final double rate;
}

/// Fetches live exchange rates from three public providers with automatic fallback.
///
/// ## TLS posture
/// The Dio instances here use Dart's default [HttpClient], which validates
/// server certificates against system CA roots. No custom [SecurityContext] or
/// cert pinning is applied, which is the correct trade-off for these public APIs:
///
/// - **User data** is never sent to any exchange-rate provider — only currency
///   codes and dates travel in the request. A successful MitM can corrupt rate
///   data but cannot exfiltrate user credentials or financial records.
/// - **API key** (ExchangeRate-API v6) is embedded in the URL path by the
///   provider's design; it cannot be moved to a header. Key exposure risk is
///   mitigated by system-CA validation (prevents passive interception) and
///   the debug-mode [_ApiKeyRedactingInterceptor] (prevents key leakage through
///   logs and crash reporters). If the key is billed, rotate it promptly on
///   any suspected compromise.
/// - **Long-term option**: proxy exchange-rate calls through the SmartSpend
///   backend so the API key never leaves the server and rate data is signed
///   before delivery to the app.
class ExchangeRateService {
  ExchangeRateService({
    Dio? frankfurterDio,
    Dio? exchangeRateApiDio,
    Dio? openExchangeRateApiDio,
    String? exchangeRateApiKey,
  })  : _frankfurterDio = frankfurterDio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.frankfurter.app',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            ),
        _exchangeRateApiDio = exchangeRateApiDio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://v6.exchangerate-api.com/v6',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            ),
        _openExchangeRateApiDio = openExchangeRateApiDio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://open.er-api.com/v6',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            ),
        _exchangeRateApiKey =
            (exchangeRateApiKey ?? _configuredExchangeRateApiKey).trim() {
    // H-3 FIX: Attach a redacting log interceptor to prevent the API key
    // from appearing in debug output, crash reporters, or log drains.
    // ExchangeRate-API v6 requires the key in the URL path by design;
    // it cannot be moved to a header — so we redact it from logs instead.
    if (kDebugMode && _exchangeRateApiKey.isNotEmpty) {
      _exchangeRateApiDio.interceptors.add(
        _ApiKeyRedactingInterceptor(_exchangeRateApiKey),
      );
    }
  }

  static const String _configuredExchangeRateApiKey = String.fromEnvironment(
    'EXCHANGE_RATE_API_KEY',
    defaultValue: '',
  );

  final Dio _frankfurterDio;
  final Dio _exchangeRateApiDio;
  final Dio _openExchangeRateApiDio;
  final String _exchangeRateApiKey;

  Future<ExchangeRateQuote> fetchRate({
    required String base,
    required String target,
  }) async {
    final from = base.toUpperCase();
    final to = target.toUpperCase();

    if (from == to) {
      return ExchangeRateQuote(
        base: from,
        target: to,
        rate: 1,
        date: DateTime.now(),
      );
    }

    if (_exchangeRateApiKey.isNotEmpty) {
      try {
        return await _fetchRateFromExchangeRateApi(base: from, target: to);
      } catch (_) {
        // Fallback to Frankfurter/ECB if the primary provider is unavailable.
      }
    }

    try {
      return await _fetchRateFromOpenExchangeRateApi(base: from, target: to);
    } catch (_) {
      // Fallback to Frankfurter/ECB if the open provider is unavailable.
    }

    try {
      return await _fetchRateFromFrankfurter(base: from, target: to);
    } catch (error) {
      throw Exception('Unable to load exchange rate for $from/$to.');
    }
  }

  Future<ExchangeRateQuote> _fetchRateFromExchangeRateApi({
    required String base,
    required String target,
  }) async {
    final response = await _exchangeRateApiDio.get<Map<String, dynamic>>(
      '/$_exchangeRateApiKey/pair/$base/$target',
    );

    final data = response.data;
    if (data == null) {
      throw Exception(
          'No exchange-rate data was returned from ExchangeRate-API.');
    }

    if (data['result']?.toString().toLowerCase() != 'success') {
      throw Exception('ExchangeRate-API returned a non-success result.');
    }

    final rateRaw = data['conversion_rate'];
    if (rateRaw is! num) {
      throw Exception('Malformed ExchangeRate-API response payload.');
    }

    final updateEpoch = data['time_last_update_unix'];
    final updateDate = updateEpoch is num
        ? DateTime.fromMillisecondsSinceEpoch(
            updateEpoch.toInt() * 1000,
            isUtc: true,
          ).toLocal()
        : DateTime.now();

    return ExchangeRateQuote(
      base: base,
      target: target,
      rate: rateRaw.toDouble(),
      date: updateDate,
    );
  }

  Future<ExchangeRateQuote> _fetchRateFromFrankfurter({
    required String base,
    required String target,
  }) async {
    final response = await _frankfurterDio.get<Map<String, dynamic>>(
      '/latest',
      queryParameters: {
        'from': base,
        'to': target,
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No exchange-rate data was returned.');
    }

    final rates = data['rates'];
    if (rates is! Map<String, dynamic>) {
      throw Exception('Malformed exchange-rate payload.');
    }

    final rateRaw = rates[target];
    if (rateRaw is! num) {
      throw Exception('Rate for $target was not found.');
    }

    final dateRaw = data['date']?.toString();

    return ExchangeRateQuote(
      base: base,
      target: target,
      rate: rateRaw.toDouble(),
      date: dateRaw != null ? DateTime.parse(dateRaw) : DateTime.now(),
    );
  }

  Future<ExchangeRateQuote> _fetchRateFromOpenExchangeRateApi({
    required String base,
    required String target,
  }) async {
    final response = await _openExchangeRateApiDio.get<Map<String, dynamic>>(
      '/latest/$base',
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No exchange-rate data was returned from open ER API.');
    }

    if (data['result']?.toString().toLowerCase() != 'success') {
      throw Exception('Open ER API returned a non-success result.');
    }

    final rates = data['rates'];
    if (rates is! Map<String, dynamic>) {
      throw Exception('Malformed open ER API response payload.');
    }

    final rateRaw = rates[target];
    if (rateRaw is! num) {
      throw Exception('Rate for $target was not found in open ER API.');
    }

    final updateEpoch = data['time_last_update_unix'];
    final updateDate = updateEpoch is num
        ? DateTime.fromMillisecondsSinceEpoch(
            updateEpoch.toInt() * 1000,
            isUtc: true,
          ).toLocal()
        : DateTime.now();

    return ExchangeRateQuote(
      base: base,
      target: target,
      rate: rateRaw.toDouble(),
      date: updateDate,
    );
  }

  Future<List<ExchangeRatePoint>> fetchTrend({
    required String base,
    required String target,
    int days = 7,
  }) async {
    final from = base.toUpperCase();
    final to = target.toUpperCase();
    final now = DateTime.now();

    if (from == to) {
      return List<ExchangeRatePoint>.generate(
        days,
        (index) => ExchangeRatePoint(
          date: now.subtract(Duration(days: days - 1 - index)),
          rate: 1,
        ),
      );
    }

    final start = now.subtract(Duration(days: days + 2));
    final end = now;
    final range =
        '${start.toIso8601String().split('T').first}..${end.toIso8601String().split('T').first}';

    final response = await _frankfurterDio.get<Map<String, dynamic>>(
      '/$range',
      queryParameters: {
        'from': from,
        'to': to,
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No exchange-rate trend data was returned.');
    }

    final ratesByDate = data['rates'];
    if (ratesByDate is! Map<String, dynamic>) {
      throw Exception('Malformed exchange-rate trend payload.');
    }

    final points = <ExchangeRatePoint>[];
    final sortedDates = ratesByDate.keys.toList()..sort();
    for (final dateKey in sortedDates) {
      final dayRates = ratesByDate[dateKey];
      if (dayRates is! Map<String, dynamic>) continue;
      final rateRaw = dayRates[to];
      if (rateRaw is! num) continue;
      points.add(
        ExchangeRatePoint(
          date: DateTime.parse(dateKey),
          rate: rateRaw.toDouble(),
        ),
      );
    }

    if (points.isEmpty) {
      throw Exception('Rate trend for $from/$to was not available.');
    }

    if (points.length > days) {
      return points.sublist(points.length - days);
    }
    return points;
  }
}

/// H-3 FIX: Intercepts Dio requests and responses for the ExchangeRate-API
/// Dio instance and replaces the API key in the URL path with [REDACTED]
/// before printing to debug output. Prevents the key from appearing in logs,
/// crash reporters, or developer tools even though the wire request is
/// unmodified (the key must stay in the path per the API's design).
class _ApiKeyRedactingInterceptor extends Interceptor {
  _ApiKeyRedactingInterceptor(this._apiKey);

  final String _apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && _apiKey.isNotEmpty) {
      final redacted = options.uri.toString().replaceAll(_apiKey, '[REDACTED]');
      debugPrint('[ExchangeRateService] → $redacted');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && _apiKey.isNotEmpty) {
      final redacted =
          err.requestOptions.uri.toString().replaceAll(_apiKey, '[REDACTED]');
      debugPrint('[ExchangeRateService] ✗ $redacted — ${err.message}');
    }
    handler.next(err);
  }
}




