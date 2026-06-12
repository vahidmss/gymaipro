import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/network/wordpress_http_insecure.dart'
    if (dart.library.html) 'wordpress_http_insecure_stub.dart'
    as wp_insecure;
import 'package:http/http.dart' as http;

DateTime? _wordpressHostCooldownUntil;
const Duration _wordpressHostCooldown = Duration(seconds: 90);

bool _hostMatchesConfiguredWordpress(Uri uri) {
  try {
    final configured = Uri.parse(AppConfig.wordpressApiOrigin);
    if (configured.host.isEmpty) return false;
    return uri.host.toLowerCase() == configured.host.toLowerCase();
  } catch (_) {
    return false;
  }
}

bool _looksLikeTlsOrCertFailure(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('handshakeexception') ||
      msg.contains('handshake') ||
      msg.contains('tlsexception') ||
      msg.contains('certificateexception') ||
      msg.contains('certificate_verify_failed') ||
      msg.contains('cert_verify') ||
      msg.contains('bad certificate') ||
      msg.contains('certificate has expired') ||
      (msg.contains('ssl') && msg.contains('error')) ||
      msg.contains('wrong version number');
}

bool _looksLikeDnsOrNetworkFailure(Object error) {
  if (error is TimeoutException) {
    // Slow responses should not globally block this host for all features.
    return false;
  }
  final msg = error.toString().toLowerCase();
  return msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('no address associated with hostname') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('connection closed');
}

bool _isWordpressHostInCooldown(Uri uri) {
  if (!_hostMatchesConfiguredWordpress(uri)) return false;
  if (_wordpressHostCooldownUntil == null) return false;
  return DateTime.now().isBefore(_wordpressHostCooldownUntil!);
}

void _markWordpressHostCooldown(Uri uri, Object error) {
  if (!_hostMatchesConfiguredWordpress(uri)) return;
  if (!_looksLikeDnsOrNetworkFailure(error)) return;
  _wordpressHostCooldownUntil = DateTime.now().add(_wordpressHostCooldown);
  if (kDebugMode) {
    debugPrint(
      'WordpressHttp: host cooldown enabled for ${_wordpressHostCooldown.inSeconds}s (${uri.host})',
    );
  }
}

void _clearWordpressHostCooldown(Uri uri) {
  if (!_hostMatchesConfiguredWordpress(uri)) return;
  _wordpressHostCooldownUntil = null;
}

Future<http.Response> _strictGet(
  Uri uri, {
  Map<String, String>? headers,
  Duration? timeout,
}) async {
  final c = http.Client();
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

Future<http.Response> _strictPost(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Duration? timeout,
}) async {
  final c = http.Client();
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

/// GET to the configured WordPress site: strict TLS first, then insecure retry on cert/TLS failure (VM/IO only).
Future<http.Response> wordpressGet(
  Uri uri, {
  Map<String, String>? headers,
  Duration? timeout,
}) async {
  if (_isWordpressHostInCooldown(uri)) {
    if (kDebugMode) {
      debugPrint(
        'WordpressHttp: host cooldown active, but probing anyway (${uri.host})',
      );
    }
  }
  if (!_hostMatchesConfiguredWordpress(uri)) {
    return _strictGet(uri, headers: headers, timeout: timeout);
  }
  try {
    final response = await _strictGet(uri, headers: headers, timeout: timeout);
    _clearWordpressHostCooldown(uri);
    return response;
  } catch (e) {
    if (kIsWeb || !_looksLikeTlsOrCertFailure(e)) {
      _markWordpressHostCooldown(uri, e);
      rethrow;
    }
    if (!AppConfig.allowInsecureTlsFallback) {
      _markWordpressHostCooldown(uri, e);
      rethrow;
    }
    if (kDebugMode) {
      debugPrint(
        'WordpressHttp: strict TLS failed (${e.runtimeType}), retrying without cert verification for ${uri.host}',
      );
    }
    try {
      final response = await wp_insecure.insecureWordpressGet(
        uri,
        headers: headers,
        timeout: timeout,
      );
      _clearWordpressHostCooldown(uri);
      return response;
    } catch (e2) {
      _markWordpressHostCooldown(uri, e2);
      rethrow;
    }
  }
}

/// POST (e.g. payment proxy on same host): same strict-then-insecure behavior for the WordPress host only.
Future<http.Response> wordpressPost(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Duration? timeout,
}) async {
  if (_isWordpressHostInCooldown(uri)) {
    if (kDebugMode) {
      debugPrint(
        'WordpressHttp: host cooldown active on POST, but probing anyway (${uri.host})',
      );
    }
  }
  if (!_hostMatchesConfiguredWordpress(uri)) {
    return _strictPost(uri, headers: headers, body: body, timeout: timeout);
  }
  try {
    final response = await _strictPost(
      uri,
      headers: headers,
      body: body,
      timeout: timeout,
    );
    _clearWordpressHostCooldown(uri);
    return response;
  } catch (e) {
    if (kIsWeb || !_looksLikeTlsOrCertFailure(e)) {
      _markWordpressHostCooldown(uri, e);
      rethrow;
    }
    if (!AppConfig.allowInsecureTlsFallback) {
      _markWordpressHostCooldown(uri, e);
      rethrow;
    }
    if (kDebugMode) {
      debugPrint(
        'WordpressHttp: strict TLS failed on POST (${e.runtimeType}), retrying without cert verification for ${uri.host}',
      );
    }
    try {
      final response = await wp_insecure.insecureWordpressPost(
        uri,
        headers: headers,
        body: body,
        timeout: timeout,
      );
      _clearWordpressHostCooldown(uri);
      return response;
    } catch (e2) {
      _markWordpressHostCooldown(uri, e2);
      rethrow;
    }
  }
}
