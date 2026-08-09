import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_detail_screen.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:gymaipro/trainer_ranking/widgets/shimmer.dart';
import 'package:gymaipro/trainer_ranking/widgets/trainer_card_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _TrainerSort {
  recommended,
  students,
  reviews,
  score,
}

/// لیست کشف مربیان — امتیاز فقط ترتیب پیش‌فرض است، نه لیگ رقابت.
class TrainerRankingScreen extends StatefulWidget {
  const TrainerRankingScreen({super.key});

  @override
  State<TrainerRankingScreen> createState() => _TrainerRankingScreenState();
}

class _TrainerRankingScreenState extends State<TrainerRankingScreen> {
  final TrainerRankingService _service = TrainerRankingService();
  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _trainers = [];
  List<UserProfile> _visible = [];
  bool _isLoading = true;
  bool _isSearching = false;

  _TrainerSort _sort = _TrainerSort.recommended;
  bool _onlineOnly = false;
  String? _specialty;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_recomputeVisible);
    unawaited(_loadTrainers());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_recomputeVisible)
      ..dispose();
    super.dispose();
  }

  List<String> get _availableSpecialties {
    final set = <String>{};
    for (final t in _trainers) {
      for (final s in t.specializations ?? const <String>[]) {
        final v = s.trim();
        if (v.isNotEmpty) set.add(v);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  void _recomputeVisible() {
    final query = _searchController.text.toLowerCase().trim();
    var list = List<UserProfile>.from(_trainers);

    if (_onlineOnly) {
      list = list.where((t) => t.isEffectivelyOnline).toList();
    }
    if (_specialty != null && _specialty!.isNotEmpty) {
      list = list.where((t) {
        final specs = t.specializations ?? const <String>[];
        return specs.any((s) => s.trim() == _specialty);
      }).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((t) {
        final name =
            (t.fullName.isNotEmpty ? t.fullName : t.username).toLowerCase();
        final specs = (t.specializations ?? []).join(' ').toLowerCase();
        return name.contains(query) || specs.contains(query);
      }).toList();
    }

    _sortList(list);

    if (!mounted) return;
    setState(() => _visible = list);
  }

  void _sortList(List<UserProfile> list) {
    int cmpDesc(int a, int b) => b.compareTo(a);

    if (_sort == _TrainerSort.students) {
      list.sort((a, b) {
        final c = cmpDesc(a.studentCount ?? 0, b.studentCount ?? 0);
        if (c != 0) return c;
        return cmpDesc(a.trainerScore ?? 0, b.trainerScore ?? 0);
      });
      return;
    }
    if (_sort == _TrainerSort.reviews) {
      list.sort((a, b) {
        final c = cmpDesc(a.reviewCount ?? 0, b.reviewCount ?? 0);
        if (c != 0) return c;
        final ratingCmp = (b.rating ?? 0).compareTo(a.rating ?? 0);
        if (ratingCmp != 0) return ratingCmp;
        return cmpDesc(a.trainerScore ?? 0, b.trainerScore ?? 0);
      });
      return;
    }
    // recommended / score
    list.sort((a, b) {
      final c = cmpDesc(a.trainerScore ?? 0, b.trainerScore ?? 0);
      if (c != 0) return c;
      return cmpDesc(a.reviewCount ?? 0, b.reviewCount ?? 0);
    });
  }

  Future<void> _loadTrainers({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (!forceRefresh && _trainers.isNotEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final trainers = await _service.getTrainerRankings(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      _trainers = trainers;
      _isLoading = false;
      _recomputeVisible();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در بارگذاری مربیان',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          backgroundColor: AppTheme.errorColor.withValues(alpha: 0.18),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onTrainerTap(UserProfile trainer) {
    unawaited(
      Navigator.of(context).push(_buildDetailRoute(trainer)).then((_) {
        if (mounted) unawaited(_loadTrainers(forceRefresh: true));
      }),
    );
  }

  PageRoute<void> _buildDetailRoute(UserProfile trainer) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => TrainerDetailScreen(trainer: trainer),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
    _recomputeVisible();
  }

  void _setSort(_TrainerSort sort) {
    if (_sort == sort) return;
    setState(() => _sort = sort);
    _recomputeVisible();
  }

  void _toggleOnline() {
    setState(() => _onlineOnly = !_onlineOnly);
    _recomputeVisible();
  }

  void _setSpecialty(String? value) {
    setState(() => _specialty = value);
    _recomputeVisible();
  }

  String get _sortHint {
    switch (_sort) {
      case _TrainerSort.recommended:
        return 'مرتب‌سازی: پیشنهادی';
      case _TrainerSort.students:
        return 'مرتب‌سازی: بیشترین شاگرد';
      case _TrainerSort.reviews:
        return 'مرتب‌سازی: بیشترین نظر';
      case _TrainerSort.score:
        return 'مرتب‌سازی: امتیاز کیفیت';
    }
  }

  bool get _hasActiveFilters =>
      _onlineOnly || (_specialty != null && _specialty!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final specialties = _availableSpecialties;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'لیست مربیان',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 17.sp,
            color: context.textColor,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(
            LucideIcons.arrowRight,
            color: context.textColor,
            size: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearching ? LucideIcons.x : LucideIcons.search,
              color: AppTheme.goldColor,
              size: 20.sp,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isLoading && _trainers.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
              child: _IntroBanner(
                total: _trainers.length,
                showing: _visible.length,
                hint: _sortHint,
                filtered: _hasActiveFilters ||
                    _searchController.text.trim().isNotEmpty,
              ),
            ),
          if (!_isLoading && _trainers.isNotEmpty) ...[
            _SortChips(selected: _sort, onSelect: _setSort),
            SizedBox(height: 6.h),
            _FilterChips(
              onlineOnly: _onlineOnly,
              onToggleOnline: _toggleOnline,
              specialties: specialties,
              selectedSpecialty: _specialty,
              onSpecialty: _setSpecialty,
            ),
            SizedBox(height: 4.h),
          ],
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.goldColor,
              onRefresh: () => _loadTrainers(forceRefresh: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (_isSearching)
                    SliverToBoxAdapter(
                      child: _SearchField(controller: _searchController),
                    ),
                  if (_isLoading)
                    SliverPadding(
                      padding: EdgeInsets.all(16.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Shimmer(
                                  width: 40.w,
                                  height: 40.w,
                                  borderRadius: BorderRadius.circular(11.r),
                                ),
                                SizedBox(width: 10.w),
                                Shimmer(
                                  width: 52.w,
                                  height: 52.w,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Shimmer(width: 140.w, height: 14.h),
                                      SizedBox(height: 8.h),
                                      Shimmer(width: 100.w, height: 12.h),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          childCount: 6,
                        ),
                      ),
                    )
                  else if (_visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        searching: _searchController.text.trim().isNotEmpty ||
                            _hasActiveFilters,
                        onClearFilters: _hasActiveFilters
                            ? () {
                                setState(() {
                                  _onlineOnly = false;
                                  _specialty = null;
                                });
                                _recomputeVisible();
                              }
                            : null,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final trainer = _visible[index];
                            return TrainerCardWidget(
                              trainer: trainer,
                              position: index + 1,
                              discoveryMode: true,
                              emphasizeRecommended:
                                  _sort == _TrainerSort.recommended &&
                                      index < 3,
                              onTap: () => _onTrainerTap(trainer),
                            );
                          },
                          childCount: _visible.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({
    required this.total,
    required this.showing,
    required this.hint,
    required this.filtered,
  });

  final int total;
  final int showing;
  final String hint;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final countText = filtered
        ? '${FormatUtils.toPersianDigits('$showing')} از ${FormatUtils.toPersianDigits('$total')} مربی'
        : '${FormatUtils.toPersianDigits('$total')} مربی';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(LucideIcons.users, color: AppTheme.goldColor, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انتخاب مربی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$countText · $hint',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({
    required this.selected,
    required this.onSelect,
  });

  final _TrainerSort selected;
  final ValueChanged<_TrainerSort> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(_TrainerSort, String)>[
      (_TrainerSort.recommended, 'پیشنهادی'),
      (_TrainerSort.students, 'شاگرد'),
      (_TrainerSort.reviews, 'نظرات'),
      (_TrainerSort.score, 'امتیاز'),
    ];

    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, i) {
          final (sort, label) = items[i];
          final active = sort == selected;
          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppTheme.onGoldColor : context.textColor,
              ),
            ),
            selected: active,
            onSelected: (_) => onSelect(sort),
            selectedColor: AppTheme.goldColor,
            backgroundColor: context.cardColor,
            side: BorderSide(
              color: active
                  ? AppTheme.goldColor
                  : context.separatorColor,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.onlineOnly,
    required this.onToggleOnline,
    required this.specialties,
    required this.selectedSpecialty,
    required this.onSpecialty,
  });

  final bool onlineOnly;
  final VoidCallback onToggleOnline;
  final List<String> specialties;
  final String? selectedSpecialty;
  final ValueChanged<String?> onSpecialty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            avatar: Icon(
              LucideIcons.wifi,
              size: 14.sp,
              color: onlineOnly ? AppTheme.onGoldColor : context.textSecondary,
            ),
            label: Text(
              'آنلاین',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: onlineOnly ? AppTheme.onGoldColor : context.textColor,
              ),
            ),
            selected: onlineOnly,
            onSelected: (_) => onToggleOnline(),
            selectedColor: AppTheme.goldColor,
            backgroundColor: context.cardColor,
            side: BorderSide(
              color: onlineOnly ? AppTheme.goldColor : context.separatorColor,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (specialties.isNotEmpty) ...[
            SizedBox(width: 8.w),
            FilterChip(
              label: Text(
                selectedSpecialty == null ? 'همه تخصص‌ها' : selectedSpecialty!,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: selectedSpecialty != null
                      ? AppTheme.onGoldColor
                      : context.textColor,
                ),
              ),
              selected: selectedSpecialty != null,
              onSelected: (_) => _openSpecialtySheet(context),
              selectedColor: AppTheme.goldColor,
              backgroundColor: context.cardColor,
              side: BorderSide(
                color: selectedSpecialty != null
                    ? AppTheme.goldColor
                    : context.separatorColor,
              ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSpecialtySheet(BuildContext context) async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                child: Text(
                  'تخصص مربی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                    color: ctx.textColor,
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  'همه تخصص‌ها',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: ctx.textColor,
                  ),
                ),
                trailing: selectedSpecialty == null
                    ? const Icon(LucideIcons.check, color: AppTheme.goldColor)
                    : null,
                onTap: () => Navigator.pop(ctx, '__clear__'),
              ),
              for (final s in specialties)
                ListTile(
                  title: Text(
                    s,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: ctx.textColor,
                    ),
                  ),
                  trailing: selectedSpecialty == s
                      ? const Icon(LucideIcons.check, color: AppTheme.goldColor)
                      : null,
                  onTap: () => Navigator.pop(ctx, s),
                ),
            ],
          ),
        );
      },
    );

    if (picked == null) return; // dismissed
    if (picked == '__clear__') {
      onSpecialty(null);
      return;
    }
    onSpecialty(picked as String);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: TextField(
        controller: controller,
        autofocus: true,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.sp,
          color: context.textColor,
        ),
        decoration: InputDecoration(
          hintText: 'جستجو نام یا تخصص...',
          hintStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
            color: context.textSecondary,
          ),
          filled: true,
          fillColor: context.cardColor,
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 18.sp,
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: context.separatorColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: context.separatorColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppTheme.goldColor, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.searching,
    this.onClearFilters,
  });

  final bool searching;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searching ? LucideIcons.searchX : LucideIcons.users,
            size: 44.sp,
            color: AppTheme.goldColor,
          ),
          SizedBox(height: 14.h),
          Text(
            searching ? 'مربی‌ای با این شرایط نیست' : 'هنوز مربی‌ای ثبت نشده',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            searching
                ? 'فیلتر یا عبارت جستجو را عوض کن.'
                : 'به‌زودی مربیان GymAI اینجا دیده می‌شوند.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
          if (onClearFilters != null) ...[
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onClearFilters,
              child: Text(
                'پاک کردن فیلترها',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
