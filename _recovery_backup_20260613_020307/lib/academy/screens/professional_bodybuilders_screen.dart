import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/professional_bodybuilder.dart';
import 'package:gymaipro/academy/services/professional_bodybuilder_service.dart';
import 'package:gymaipro/academy/widgets/bodybuilder_card.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ProfessionalBodybuildersScreen extends StatefulWidget {
  const ProfessionalBodybuildersScreen({super.key});

  @override
  State<ProfessionalBodybuildersScreen> createState() =>
      _ProfessionalBodybuildersScreenState();
}

class _ProfessionalBodybuildersScreenState
    extends State<ProfessionalBodybuildersScreen> {
  List<ProfessionalBodybuilder> _bodybuilders = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'همه',
    'classic',
    'bodybuilding',
    'physique',
    'wellness',
  ];

  @override
  void initState() {
    super.initState();
    _loadBodybuilders();
  }

  Future<void> _loadBodybuilders({bool refresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final bodybuilders = await ProfessionalBodybuilderService.fetchBodybuilders(
        category: _selectedCategory == 'همه' ? null : _selectedCategory,
        forceRefresh: refresh,
      );
      if (mounted) {
        setState(() {
          _bodybuilders = bodybuilders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگیری بدنسازان: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: RefreshIndicator(
        onRefresh: () => _loadBodybuilders(refresh: true),
        child: Column(
          children: [
            // Category Filter
            SizedBox(
              height: 50.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category ||
                      (_selectedCategory == null && category == 'همه');
                  return Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: FilterChip(
                      label:
                          Text(category == 'همه' ? 'همه' : _getCategoryLabel(category)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                        _loadBodybuilders(refresh: true);
                      },
                      selectedColor: AppTheme.goldColor.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.goldColor,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.goldColor : null,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bodybuilders List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.goldColor),
                    )
                  : _bodybuilders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 64.sp,
                                color: context.textSecondary,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'بدنسازی یافت نشد',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 14.sp,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _bodybuilders.length,
                          itemBuilder: (context, index) {
                            return BodybuilderCard(
                              bodybuilder: _bodybuilders[index],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'classic':
        return 'کلاسیک';
      case 'bodybuilding':
        return 'بدنسازی';
      case 'physique':
        return 'فیزیک';
      case 'wellness':
        return 'ولنس';
      default:
        return category;
    }
  }
}

