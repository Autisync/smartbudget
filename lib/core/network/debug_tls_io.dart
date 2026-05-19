import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

void configureDebugTlsAdapter(Dio dio, String baseUrl) {
  if (kReleaseMode || !baseUrl.startsWith('https://')) {
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      return client;
    },
  );
}
