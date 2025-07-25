import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MealTypeSelectorOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final Function(String) onMealTypeSelected;

  const MealTypeSelectorOverlay({
    Key? key,
    required this.onClose,
    required this.onMealTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.amber[700]!.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]?.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          LucideIcons.utensils,
                          color: Colors.amber[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'انتخاب نوع وعده',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                          icon: Icon(
                            LucideIcons.x,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Meal type cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildMealTypeCard(
                          'صبحانه', LucideIcons.sunrise, Colors.orange[400]!),
                      _buildMealTypeCard(
                          'ناهار', LucideIcons.sun, Colors.yellow[400]!),
                      _buildMealTypeCard(
                          'شام', LucideIcons.moon, Colors.indigo[400]!),
                      _buildMealTypeCard(
                          'میان‌وعده', LucideIcons.coffee, Colors.green[400]!),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => onMealTypeSelected(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber[100],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
