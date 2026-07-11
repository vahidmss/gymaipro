import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createOpenAiHttpClient() {
  final io = HttpClient()
    ..connectionTimeout = const Duration(seconds: 45)
    ..idleTimeout = const Duration(seconds: 90);
  return IOClient(io);
}
