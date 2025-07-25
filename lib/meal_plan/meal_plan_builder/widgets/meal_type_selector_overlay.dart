import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'meal_type_card.dart';

class MealTypeSelectorOverlayMealPlanBuilder extends StatelessWidget {
  final void Function(String) onSelectType;
  final VoidCallback onClose;
  const MealTypeSelectorOverlayMealPlanBuilder({
    Key? key,
    required this.onSelectType,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: 220,
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2C1810),
                    Color(0xFF3D2317),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amber[700]!.withOpacity(0.18),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]?.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.utensils,
                          color: Colors.amber[700],
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'نوع وعده غذایی را انتخاب کنید',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.amber[700]?.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: Colors.amber[700],
                            size: 12,
                          ),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    width: 200,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.75,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MealTypeCardMealPlanBuilder(
                          title: 'صبحانه',
                          icon: LucideIcons.sunrise,
                          color: Colors.orange[400]!,
                          onTap: () => onSelectType('صبحانه'),
                        ),
                        MealTypeCardMealPlanBuilder(
                          title: 'ناهار',
                          icon: LucideIcons.sun,
                          color: Colors.green[400]!,
                          onTap: () => onSelectType('ناهار'),
                        ),
                        MealTypeCardMealPlanBuilder(
                          title: 'شام',
                          icon: LucideIcons.moon,
                          color: Colors.blue[400]!,
                          onTap: () => onSelectType('شام'),
                        ),
                        MealTypeCardMealPlanBuilder(
                          title: 'میان وعده',
                          icon: LucideIcons.coffee,
                          color: Colors.purple[400]!,
                          onTap: () => onSelectType('میان وعده'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
