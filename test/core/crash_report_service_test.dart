import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/core/crash_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sanitizes secrets and phone numbers before queueing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await CrashReportService.instance.record(
      Exception(
        'Authorization: Bearer abc123 token=secret-value phone=09121234567',
      ),
      StackTrace.fromString('password=my-password'),
    );

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('client_crash_report_queue_v1');
    expect(raw, isNotNull);

    final rows = (jsonDecode(raw!) as List).cast<Map<String, dynamic>>();
    final row = rows.single;
    final serialized = jsonEncode(row);
    expect(serialized, isNot(contains('abc123')));
    expect(serialized, isNot(contains('secret-value')));
    expect(serialized, isNot(contains('my-password')));
    expect(serialized, isNot(contains('09121234567')));
    expect(row['occurrence_count'], 1);
  });

  test(
    'sanitizes nested context and aggregates duplicate fingerprints',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final error = Exception('database failure');
      final stack = StackTrace.fromString('frame one\nframe two');
      final context = <String, Object?>{
        'request': <String, Object?>{
          'token': 'nested-secret',
          'phone': '09121234567',
        },
        'values': <Object?>['password=another-secret'],
      };

      await CrashReportService.instance.record(error, stack, context: context);
      await CrashReportService.instance.record(error, stack, context: context);

      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('client_crash_report_queue_v1');
      final rows = (jsonDecode(raw!) as List).cast<Map<String, dynamic>>();
      final row = rows.single;
      final serialized = jsonEncode(row);
      expect(row['occurrence_count'], 2);
      expect(serialized, isNot(contains('nested-secret')));
      expect(serialized, isNot(contains('another-secret')));
      expect(serialized, isNot(contains('09121234567')));
      expect(row['fingerprint'], hasLength(64));
    },
  );
}
