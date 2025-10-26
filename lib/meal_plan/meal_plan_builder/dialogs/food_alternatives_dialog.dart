import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FoodAlternativesDialog extends StatefulWidget {
  const FoodAlternativesDialog({
    required this.foods,
    required this.selectedFood,
    required this.selectedAlternatives,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });
  final List<Food> foods;
  final Food selectedFood;
  final Map<int, double> selectedAlternatives;
  final void Function(Map<int, double>) onConfirm;
  final VoidCallback onCancel;

  @override
  State<FoodAlternativesDialog> createState() => _FoodAlternativesDialogState();
}

class _FoodAlternativesDialogState extends State<FoodAlternativesDialog> {
  late Map<int, double> selectedWithAmounts;
  String query = '';

  @override
  void initState() {
    super.initState();
    selectedWithAmounts = Map<int, double>.from(widget.selectedAlternatives);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.foods
        .where((f) => f.id != widget.selectedFood.id && f.title.contains(query))
        .toList();
    final foodName = widget.selectedFood.title;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(20.w),
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), Color(0xFF3D2317), Color(0xFF4A2C1A)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.amber[700]!.withValues(alpha: 0.1),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20.r,
                offset: Offset(0.w, 8.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.refreshCw,
                      color: Colors.amber[700],
                      size: 24.sp,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'انتخاب جایگزین برای $foodName',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'جستجو...',
                    hintStyle: TextStyle(
                      color: Colors.amber[200]?.withValues(alpha: 0.1),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                  style: const TextStyle(color: Colors.amber),
                  onChanged: (v) => setState(() => query = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300.h,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final alt = filtered[idx];
                      final isSelected = selectedWithAmounts.containsKey(
                        alt.id,
                      );
                      final amount = selectedWithAmounts[alt.id] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amber[700]?.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber[700]!.withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          leading: alt.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    alt.imageUrl,
                                    width: 36.w,
                                    height: 36.h,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  LucideIcons.image,
                                  color: Colors.amber[200],
                                ),
                          title: Text(
                            alt.title,
                            style: const TextStyle(color: Colors.amber),
                          ),
                          subtitle: isSelected
                              ? Text(
                                  'مقدار: ${amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 12.sp,
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                SizedBox(
                                  width: 60.w,
                                  child: TextField(
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12.sp,
                                    ),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'مقدار',
                                      hintStyle: TextStyle(
                                        color: Colors.amber[200]?.withValues(
                                          alpha: 0.1,
                                        ),
                                        fontSize: 10.sp,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.amber[700]!.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.amber[700]!.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      final newAmount =
                                          double.tryParse(value) ?? 0;
                                      setState(() {
                                        selectedWithAmounts[alt.id] = newAmount;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  LucideIcons.check,
                                  color: Colors.greenAccent,
                                  size: 20.sp,
                                ),
                              ] else
                                Icon(
                                  LucideIcons.plus,
                                  color: Colors.amber[200],
                                  size: 20.sp,
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedWithAmounts.remove(alt.id);
                              } else {
                                selectedWithAmounts[alt.id] = 0;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
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
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => widget.onConfirm(selectedWithAmounts),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[200],
                          side: BorderSide(color: Colors.amber[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: widget.onCancel,
                        child: const Text('انصراف'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
