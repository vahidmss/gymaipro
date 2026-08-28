import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCrashReportsScreen extends StatefulWidget {
  const AdminCrashReportsScreen({super.key});

  @override
  State<AdminCrashReportsScreen> createState() =>
      _AdminCrashReportsScreenState();
}

class _AdminCrashReportsScreenState extends State<AdminCrashReportsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('client_crash_reports')
          .select()
          .order('created_at', ascending: false)
          .limit(80);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'جدول کرش پیدا نشد یا دسترسی ندارید. اسکریپت sql/create_client_crash_reports.sql را روی سوپابیس اجرا کنید.\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
              FilledButton(
                onPressed: () {
                  unawaited(_load());
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.onGoldColor,
                ),
                child: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return Center(
        child: Text(
          'هنوز کرشی گزارش نشده',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.goldColor,
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final row = _rows[index];
          final message = '${row['error_message'] ?? ''}';
          final version =
              '${row['app_version'] ?? '?'}+${row['build_number'] ?? '?'}';
          final platform = '${row['platform'] ?? ''}';
          final errorType = '${row['error_type'] ?? 'UnknownError'}';
          final occurrenceCount =
              (row['occurrence_count'] as num?)?.toInt() ?? 1;
          final isFatal = row['is_fatal'] != false;
          final createdAt = '${row['created_at'] ?? ''}';
          final stackTrace = '${row['stack_trace'] ?? ''}'.trim();
          return Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 16.sp,
                      color: AppTheme.goldColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '$version · $platform · ${isFatal ? 'Fatal' : 'Error'}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '$errorType - تکرار: $occurrenceCount',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    color: context.textColor,
                    height: 1.4,
                  ),
                ),
                if (createdAt.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    createdAt,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
                if (stackTrace.isNotEmpty)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      'جزئیات فنی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          stackTrace,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.sp,
                            color: context.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
