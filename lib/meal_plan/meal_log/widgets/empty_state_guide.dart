import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyStateGuide extends StatelessWidget {
  const EmptyStateGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF3D2317),
            Color(0xFF4A2C1A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber[700]!.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber[700]?.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LucideIcons.utensils,
              color: Colors.amber[700],
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'شروع ثبت تغذیه روزانه',
            style: TextStyle(
              color: Colors.amber[200],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            'برای شروع، روی دکمه + کلیک کنید و وعده غذایی یا مکمل اضافه کنید',
            style: TextStyle(
              color: Colors.amber[300],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[700]?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber[700]!.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      color: Colors.amber[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نکات مهم:',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• می‌توانید وعده‌های مختلف (صبحانه، ناهار، شام، میان‌وعده) اضافه کنید\n• برای دقت بیشتر، مقدار دقیق غذاها را ثبت کنید\n• مکمل‌ها و داروها را جداگانه ثبت کنید',
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
