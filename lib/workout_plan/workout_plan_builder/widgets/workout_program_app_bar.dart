import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutProgramAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? programId;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onMenuPressed;

  const WorkoutProgramAppBar({
    Key? key,
    this.programId,
    required this.isSaving,
    required this.onSave,
    required this.onMenuPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF3D2317),
            Color(0xFF4A2C1A),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Row(
            children: [
              // Save button (rightmost)
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber[700]!.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber[700]!,
                            ),
                          ),
                        )
                      : Icon(
                          LucideIcons.save,
                          color: Colors.amber[700],
                          size: 20,
                        ),
                  onPressed: isSaving ? null : onSave,
                  tooltip: 'ذخیره',
                ),
              ),
              const SizedBox(width: 12),
              // Menu button
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber[700]!.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.menu,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  onPressed: onMenuPressed,
                  tooltip: 'برنامه‌های ذخیره‌شده',
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          programId != null
                              ? 'ویرایش برنامه تمرینی'
                              : 'ایجاد برنامه تمرینی',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'طراحی و مدیریت جلسات تمرینی',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Back button (leftmost)
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber[700]!.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
