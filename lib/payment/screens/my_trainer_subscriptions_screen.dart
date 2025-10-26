import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/payment/services/trainer_subscription_service.dart';
import 'package:gymaipro/payment/widgets/trainer_subscription_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحه اشتراک‌های مربی کاربر
class MyTrainerSubscriptionsScreen extends StatefulWidget {
  const MyTrainerSubscriptionsScreen({super.key});

  @override
  State<MyTrainerSubscriptionsScreen> createState() =>
      _MyTrainerSubscriptionsScreenState();
}

class _MyTrainerSubscriptionsScreenState
    extends State<MyTrainerSubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TrainerSubscriptionService _subscriptionService =
      TrainerSubscriptionService();

  List<TrainerSubscription> _subscriptions = [];
  bool _isLoading = true;
  final String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final subscriptions = await _subscriptionService.getUserSubscriptions(
          currentUser.id,
        );
        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری اشتراک‌ها: $e',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<TrainerSubscription> get _filteredSubscriptions {
    switch (_selectedFilter) {
      case 'active':
        return _subscriptions.where((s) => s.isActive).toList();
      case 'expired':
        return _subscriptions.where((s) => s.isExpired).toList();
      case 'pending':
        return _subscriptions.where((s) => s.isPending).toList();
      default:
        return _subscriptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'اشتراک‌های مربی من',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: Colors.grey[400],
          tabs: [
            Tab(child: Text('همه', style: GoogleFonts.vazirmatn(fontSize: 12))),
            Tab(
              child: Text('فعال', style: GoogleFonts.vazirmatn(fontSize: 12)),
            ),
            Tab(
              child: Text('منقضی', style: GoogleFonts.vazirmatn(fontSize: 12)),
            ),
            Tab(
              child: Text(
                'در انتظار',
                style: GoogleFonts.vazirmatn(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionsList('all'),
          _buildSubscriptionsList('active'),
          _buildSubscriptionsList('expired'),
          _buildSubscriptionsList('pending'),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList(String filter) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    final filteredSubscriptions = filter == 'all'
        ? _subscriptions
        : _subscriptions.where((s) {
            switch (filter) {
              case 'active':
                return s.isActive;
              case 'expired':
                return s.isExpired;
              case 'pending':
                return s.isPending;
              default:
                return true;
            }
          }).toList();

    if (filteredSubscriptions.isEmpty) {
      return _buildEmptyState(filter);
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredSubscriptions.length,
        itemBuilder: (context, index) {
          final subscription = filteredSubscriptions[index];
          return TrainerSubscriptionCard(
            subscription: subscription,
            onTap: () => _showSubscriptionDetails(subscription),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String message;
    IconData icon;

    switch (filter) {
      case 'active':
        title = 'اشتراک فعالی ندارید';
        message = 'هنوز هیچ اشتراک فعالی خریداری نکرده‌اید';
        icon = LucideIcons.userCheck;
      case 'expired':
        title = 'اشتراک منقضی‌ای ندارید';
        message = 'همه اشتراک‌های شما فعال هستند';
        icon = LucideIcons.clock;
      case 'pending':
        title = 'اشتراک در انتظاری ندارید';
        message = 'همه اشتراک‌های شما پرداخت شده‌اند';
        icon = LucideIcons.creditCard;
      default:
        title = 'اشتراکی ندارید';
        message = 'هنوز هیچ اشتراکی خریداری نکرده‌اید';
        icon = LucideIcons.userX;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.vazirmatn(
              color: Colors.grey[600],
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.vazirmatn(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.search),
            label: Text('جستجوی مربی', style: GoogleFonts.vazirmatn()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDetails(TrainerSubscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'جزئیات اشتراک',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('نوع خدمات', subscription.serviceTypeText),
              _buildDetailRow('وضعیت', subscription.statusText),
              _buildDetailRow('مبلغ', subscription.formattedFinalAmount),
              if (subscription.discountAmount > 0)
                _buildDetailRow('تخفیف', subscription.formattedDiscountAmount),
              _buildDetailRow(
                'تاریخ خرید',
                _formatDate(subscription.purchaseDate),
              ),
              if (subscription.programRegistrationDate != null)
                _buildDetailRow(
                  'ثبت برنامه',
                  _formatDate(subscription.programRegistrationDate!),
                ),
              if (subscription.firstUsageDate != null)
                _buildDetailRow(
                  'اولین استفاده',
                  _formatDate(subscription.firstUsageDate!),
                ),
              _buildDetailRow('انقضا', _formatDate(subscription.expiryDate)),
              if (subscription.hasDelay)
                _buildDetailRow(
                  'تاخیر مربی',
                  '${subscription.trainerDelayDays} روز',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'بستن',
              style: GoogleFonts.vazirmatn(color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.vazirmatn(color: Colors.grey[400], fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.vazirmatn(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
