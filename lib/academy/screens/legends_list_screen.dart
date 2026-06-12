import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/fitness_legend.dart';
import 'package:gymaipro/academy/services/fitness_legend_service.dart';
import 'package:gymaipro/academy/widgets/legend_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';

class LegendsListScreen extends StatefulWidget {
  const LegendsListScreen({super.key});

  @override
  State<LegendsListScreen> createState() => _LegendsListScreenState();
}

class _LegendsListScreenState extends State<LegendsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<FitnessLegend> _legends = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadPage();
      }
    });
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (refresh) {
        _currentPage = 1;
        _legends.clear();
        _hasMore = true;
      }
      final newItems = await FitnessLegendService.fetchLegends(
        page: _currentPage,
        forceRefresh: refresh,
      );

      WidgetSafetyUtils.safeSetState(this, () {
        _legends.addAll(newItems);
        _currentPage++;
        if (newItems.isEmpty || newItems.length < 20) _hasMore = false;
      });
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگیری اساطیر: $e',
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(refresh: true),
        child: ColoredBox(
          color: context.backgroundColor,
          child: Column(
            children: [
              // Legends List
              Expanded(
                child: _legends.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 64.sp,
                              color: context.textSecondary,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'اسطوره‌ای یافت نشد',
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
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _legends.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _legends.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.goldColor,
                                ),
                              ),
                            );
                          }
                          final legend = _legends[index];
                          return LegendCard(legend: legend);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
