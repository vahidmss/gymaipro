import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutEmptyStateGuide extends StatelessWidget {
  const WorkoutEmptyStateGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C1810),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amber[700]!.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.dumbbell,
                  color: Colors.amber[700],
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'شروع ثبت تمرین روزانه',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Description
              Text(
                'برای شروع، یک برنامه تمرینی انتخاب کنید و جلسه مورد نظر را برگزینید',
                style: TextStyle(
                  color: Colors.amber[300],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber[700]!.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.lightbulb,
                          color: Colors.amber[600],
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'نکات مهم:',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• ابتدا یک برنامه تمرینی از لیست انتخاب کنید\n• سپس جلسه مورد نظر را برگزینید\n• برای هر ست، تعداد تکرار و وزنه را ثبت کنید\n• تمرین‌های مختلف را به ترتیب انجام دهید',
                      style: TextStyle(
                        color: Colors.amber[300],
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
