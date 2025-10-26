import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileWeightControlsWidget extends StatelessWidget {
  const ProfileWeightControlsWidget({
    required this.onAddWeightPressed,
    required this.onWeightHistoryPressed,
    super.key,
  });
  final VoidCallback onAddWeightPressed;
  final VoidCallback onWeightHistoryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAddWeightPressed,
              icon: const Icon(LucideIcons.plus),
              label: Text('ثبت وزن جدید', style: GoogleFonts.vazirmatn()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onWeightHistoryPressed,
              icon: const Icon(LucideIcons.history),
              label: Text('تاریخچه وزن', style: GoogleFonts.vazirmatn()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                foregroundColor: AppTheme.goldColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
