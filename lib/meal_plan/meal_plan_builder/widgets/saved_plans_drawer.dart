import 'package:flutter/material.dart';
import '../../../models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SavedPlansDrawerMealPlanBuilder extends StatelessWidget {
  final List<MealPlan> savedPlans;
  final void Function(MealPlan) onSelect;
  final void Function(String) onDelete;
  final VoidCallback onNewPlan;
  final VoidCallback onClose;
  const SavedPlansDrawerMealPlanBuilder({
    Key? key,
    required this.savedPlans,
    required this.onSelect,
    required this.onDelete,
    required this.onNewPlan,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
          ),
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(24)),
          border: Border.all(
            color: Colors.amber[700]!.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(-6, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'برنامه‌های ذخیره‌شده',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: savedPlans.isEmpty
                    ? Center(
                        child: Text(
                          'برنامه‌ای ذخیره نشده',
                          style: TextStyle(
                            color: Colors.amber[300],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: savedPlans.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, idx) {
                          final plan = savedPlans[idx];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber[700]!.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                plan.planName,
                                style: TextStyle(
                                  color: Colors.amber[100],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'تاریخ: ${plan.createdAt.toString().substring(0, 10)}',
                                style: TextStyle(
                                  color: Colors.amber[300],
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => onSelect(plan),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[100]?.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red[300],
                                    size: 18,
                                  ),
                                  onPressed: () => onDelete(plan.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber[600]!,
                        Colors.amber[700]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber[700]!.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      LucideIcons.plus,
                      color: Color(0xFF1A1A1A),
                    ),
                    label: const Text(
                      'برنامه جدید',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onNewPlan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
