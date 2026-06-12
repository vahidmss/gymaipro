import 'dart:io';

import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/network/gymaipro_insecure_tls_hosts.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// IO-only: accept any server certificate (used only after a strict TLS attempt failed).
Future<http.Response> insecureWordpressGet(
  Uri uri, {
  Map<String, String>? headers,
  Duration? timeout,
}) async {
  if (!AppConfig.allowInsecureTlsFallback ||
      !GymaiproInsecureTlsHosts.allowInsecureConnectionTo(uri.host)) {
    throw const HandshakeException(
      'Insecure TLS fallback is disabled for this host.',
    );
  }
  final io = HttpClient()..badCertificateCallback = (_, __, ___) => true;
  final c = IOClient(io);
  try {
    final future = c.get(uri, headers: headers);
    if (timeout != null) {
      return await future.timeout(timeout);
    }
    return await future;
  } finally {
    c.close();
  }
}

Future<http.Response> insecureWordpressPost(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Duration? timeout,
}) async {
  if (!AppConfig.allowInsecureTlsFallback ||
      !GymaiproInsecureTlsHosts.allowInsecureConnectionTo(uri.host)) {
    throw const HandshakeException(
      'Insecure TLS fallback is disabled for this host.',
    );
  }
  final io = HttpClient()..badCertificateCallback = (_, __, ___) => true;
  final c = IOClient(io);
  try {
    final future = c.post(uri, headers: headers, body: body);
    if (timeout != null) {
      return await future.timeout(timeout);
    }
    return await future;
  } finally {
    c.close();
  }
}
