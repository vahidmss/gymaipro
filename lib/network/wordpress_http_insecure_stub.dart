import 'package:http/http.dart' as http;

/// Web / non-IO: no custom TLS; same as a normal client (browser enforces HTTPS).
Future<http.Response> insecureWordpressGet(
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

Future<http.Response> insecureWordpressPost(
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
