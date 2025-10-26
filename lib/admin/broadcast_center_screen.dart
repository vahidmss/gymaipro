import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BroadcastCenterScreen extends StatefulWidget {
  const BroadcastCenterScreen({super.key});

  @override
  State<BroadcastCenterScreen> createState() => _BroadcastCenterScreenState();
}

class _BroadcastCenterScreenState extends State<BroadcastCenterScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _topicController = TextEditingController(
    text: 'all',
  );
  bool _sending = false;
  String? _result;
  final NotificationService _notificationService = NotificationService();

  Future<void> _sendToTopic() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final ok = await _notificationService.sendDirectToTopic(
        topic: _topicController.text.trim(),
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        data: const {},
      );
      setState(
        () => _result = ok
            ? 'ارسال مستقیم با موفقیت انجام شد'
            : 'ارسال ناموفق بود',
      );
    } catch (e) {
      print('❌ Error in _sendToTopic: $e');
      setState(() => _result = 'خطا: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _sendToInactiveUsers7d() async {
    setState(() => _sending = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('notification_broadcast_requests').insert({
        'created_by': supabase.auth.currentUser?.id,
        'target_type': 'inactive_7d',
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'data': jsonEncode({}),
      });
      await _notificationService.processBroadcastQueue();
      setState(
        () => _result =
            'درخواست ارسال به کاربران غیرفعال ثبت شد و در صف پردازش قرار گرفت',
      );
    } catch (e) {
      setState(() => _result = 'خطا: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مرکز ارسال اعلان')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _titleController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'عنوان'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'متن'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'تاپیک (مثلاً all یا fa)',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendToTopic,
                    child: const Text('ارسال به تاپیک'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendToInactiveUsers7d,
                    child: const Text('ارسال به غیرفعال‌های ۷ روزه'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_result != null)
              Text(_result!, textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            const Text(
              'توجه: اجرای واقعی ارسال باید توسط فانکشن/سرور انجام شود.',
            ),
          ],
        ),
      ),
    );
  }
}
