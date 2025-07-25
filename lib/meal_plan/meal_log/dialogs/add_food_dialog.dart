// دیالوگ افزودن غذا (AddFoodDialog) مخصوص meal log
import 'package:flutter/material.dart';
import '../../../models/food.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddFoodDialog extends StatefulWidget {
  final List<Food> foods;
  const AddFoodDialog({required this.foods, Key? key}) : super(key: key);

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  Food? _selectedFood;
  String? _selectedUnit;
  double? _amount;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered =
        widget.foods.where((f) => f.title.contains(_query)).toList();
    final nutrition = _selectedFood?.nutrition;
    final factor = (_amount ?? 0) / 100.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 450),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.utensils,
                        color: Colors.amber[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('افزودن غذا',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'جستجو...',
                    hintStyle:
                        TextStyle(color: Colors.amber[200]?.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  style: TextStyle(color: Colors.amber[200]),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  width: 300,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final food = filtered[idx];
                      return ListTile(
                        leading: food.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(food.imageUrl,
                                    width: 40, height: 40, fit: BoxFit.cover),
                              )
                            : const Icon(LucideIcons.image),
                        title: Text(food.title),
                        onTap: () {
                          setState(() {
                            _selectedFood = food;
                            _selectedUnit = 'گرم';
                            _amount = null;
                          });
                        },
                        selected: _selectedFood?.id == food.id,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedFood != null) ...[
                  Row(
                    children: [
                      if (_selectedFood!.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(_selectedFood!.imageUrl,
                              width: 48, height: 48, fit: BoxFit.cover),
                        )
                      else
                        const Icon(LucideIcons.image, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_selectedFood!.title,
                            style: theme.textTheme.titleMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'مقدار',
                            labelStyle: TextStyle(color: Colors.amber[300]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => _amount = double.tryParse(v)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedUnit,
                        items: ['گرم', 'عدد', 'لیوان']
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v),
                      ),
                    ],
                  ),
                  if (_amount != null && _amount! > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                            'کالری: ${(double.tryParse(nutrition?.calories ?? '0') ?? 0 * factor).toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall!
                                .copyWith(color: Colors.grey[400])),
                        const SizedBox(width: 12),
                        Text(
                            'پروتئین: ${(double.tryParse(nutrition?.protein ?? '0') ?? 0 * factor).toStringAsFixed(1)}g',
                            style: theme.textTheme.bodySmall!
                                .copyWith(color: Colors.grey[400])),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(LucideIcons.check),
                          label: const Text('تایید'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _selectedFood != null &&
                                  _amount != null &&
                                  _amount! > 0
                              ? () {
                                  Navigator.of(context).pop({
                                    'food': _selectedFood!,
                                    'amount': _amount!,
                                    'unit': _selectedUnit,
                                  });
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber[200],
                            side: BorderSide(color: Colors.amber[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('انصراف'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
