import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomInfoBar extends StatelessWidget {
  final int exerciseCount;
  final DateTime updatedAt;

  const BottomInfoBar({
    Key? key,
    required this.exerciseCount,
    required this.updatedAt,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return 'چند دقیقه پیش';
      }
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    } else {
      return '${(difference.inDays / 365).floor()} سال پیش';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.amber[700]!.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.clipboardList,
                        color: Colors.amber[300], size: 16),
                    const SizedBox(width: 3),
                    Text(
                      'تعداد حرکات: ',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      exerciseCount.toString(),
                      style: TextStyle(
                        color: Colors.amber[100],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.clock, color: Colors.amber[300], size: 16),
                    const SizedBox(width: 3),
                    Text(
                      'آخرین ویرایش: ',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      exerciseCount > 0 ? _formatDate(updatedAt) : '-',
                      style: TextStyle(
                        color: Colors.amber[100],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
