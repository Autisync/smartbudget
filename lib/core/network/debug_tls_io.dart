import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// C-4 FIX: cert bypass is now scoped exclusively to local dev hosts.
/// It will NEVER fire for profile/TestFlight/ad-hoc builds targeting the
/// production domain — those builds must pass real TLS validation.
const _localHosts = {'localhost', '127.0.0.1', '10.0.2.2', '::1'};

void configureDebugTlsAdapter(Dio dio, String baseUrl) {
  if (kReleaseMode) return;

  final uri = Uri.tryParse(baseUrl);
  if (uri == null) return;

  // Only bypass cert validation for local emulator / simulator addresses.
  if (!_localHosts.contains(uri.host)) return;

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      return client;
    },
  );
}
