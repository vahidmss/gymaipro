// نوار بالای صفحه (AppBar) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppBarMealPlanBuilder extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onOpenDrawer;
  final VoidCallback onBack;

  const AppBarMealPlanBuilder({
    Key? key,
    required this.isSaving,
    required this.onSave,
    required this.onOpenDrawer,
    required this.onBack,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
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
                // دکمه بازگشت
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
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: 16),
                // عنوان
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'برنامه غذایی',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'طراحی و مدیریت وعده‌های غذایی',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // دکمه منو
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
                    onPressed: onOpenDrawer,
                    tooltip: 'برنامه‌های ذخیره‌شده',
                  ),
                ),
                const SizedBox(width: 12),
                // دکمه ذخیره
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
