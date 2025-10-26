import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:gymaipro/trainer_dashboard/services/user_search_service.dart';
import 'package:gymaipro/trainer_dashboard/widgets/athlete_request_widget.dart';
import 'package:gymaipro/trainer_dashboard/widgets/client_search_widget.dart';
import 'package:gymaipro/trainer_dashboard/widgets/relationship_stats_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen>
    with SingleTickerProviderStateMixin {
  final TrainerClientService _clientService = TrainerClientService();
  final UserSearchService _searchService = UserSearchService();

  late TabController _tabController;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _displayedClients = [];
  Map<String, int> _relationshipStats = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _currentUserId = user.id;

        // دریافت لیست شاگردان
        final clients = await _clientService.getTrainerClients(user.id);

        // دریافت آمار
        final stats = await _clientService.getRelationshipStats(user.id);

        if (mounted) {
          setState(() {
            _clients = clients;
            _displayedClients = clients;
            _relationshipStats = stats;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در بارگذاری اطلاعات: $e')));
      }
    }
  }

  Future<void> _addNewClient(Map<String, dynamic> athlete) async {
    if (_currentUserId == null) return;

    try {
      // بررسی وجود هر نوع رابطه
      final existingRelationship = await _searchService.getAnyRelationship(
        trainerId: _currentUserId!,
        clientId: athlete['id'] as String,
      );

      if (existingRelationship != null) {
        final status = existingRelationship['status'] as String;
        String message;

        switch (status) {
          case 'active':
            message = 'این ورزشکار قبلاً شاگرد فعال شما است';
          case 'pending':
            message = 'درخواست شما برای این ورزشکار در انتظار تایید است';
          case 'inactive':
            message = 'این ورزشکار قبلاً شاگرد شما بوده و غیرفعال است';
          case 'blocked':
            message = 'این ورزشکار مسدود شده است';
          default:
            message = 'رابطه‌ای با این ورزشکار وجود دارد';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: status == 'pending' ? Colors.orange : Colors.red,
            ),
          );
        }
        return;
      }

      // ایجاد رابطه جدید
      await _clientService.createTrainerClientRelationship(
        trainerId: _currentUserId!,
        clientId: athlete['id'] as String,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درخواست برای شاگرد ارسال شد - در انتظار تایید'),
          ),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در اضافه کردن شاگرد: $e')));
      }
    }
  }

  void _onSearchResultsChanged(List<Map<String, dynamic>> filteredClients) {
    setState(() {
      _displayedClients = filteredClients;
    });
  }

  Future<void> _removeClient(String clientId) async {
    if (_currentUserId == null) return;

    try {
      await _clientService.endRelationship(
        trainerId: _currentUserId!,
        clientId: clientId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('شاگرد با موفقیت حذف شد')));
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در حذف شاگرد: $e')));
      }
    }
  }

  Future<void> _blockClient(String clientId) async {
    if (_currentUserId == null) return;

    try {
      await _clientService.updateRelationshipStatus(
        trainerId: _currentUserId!,
        clientId: clientId,
        status: 'blocked',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شاگرد مسدود شد'),
            backgroundColor: Colors.red,
          ),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در مسدود کردن شاگرد: $e')));
      }
    }
  }

  Future<void> _unblockClient(String clientId) async {
    if (_currentUserId == null) return;

    try {
      await _clientService.updateRelationshipStatus(
        trainerId: _currentUserId!,
        clientId: clientId,
        status: 'active',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مسدودیت شاگرد رفع شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در رفع مسدودیت شاگرد: $e')));
      }
    }
  }

  void _onClientTap(Map<String, dynamic> clientProfile) {
    final String? userId = clientProfile['id'] as String?;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('شناسه کاربر نامعتبر است')));
      return;
    }
    Navigator.pushNamed(context, '/trainer-profile', arguments: userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          child: Column(
            children: [
              ClientSearchWidget(
                allClients: _clients,
                onSearchResultsChanged: _onSearchResultsChanged,
              ),
              const SizedBox(height: 8),
              RelationshipStatsWidget(stats: _relationshipStats),
              const SizedBox(height: 12),
              Expanded(child: _buildClientsTab()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color baseColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'active':
        baseColor = Colors.green;
        statusText = 'فعال';
        statusIcon = LucideIcons.checkCircle2;
      case 'pending':
        baseColor = Colors.amber;
        statusText = 'در انتظار';
        statusIcon = LucideIcons.clock4;
      case 'inactive':
        baseColor = Colors.grey;
        statusText = 'غیرفعال';
        statusIcon = LucideIcons.userX;
      case 'blocked':
        baseColor = Colors.red;
        statusText = 'مسدود';
        statusIcon = LucideIcons.shieldAlert;
      default:
        baseColor = Colors.grey;
        statusText = 'نامشخص';
        statusIcon = LucideIcons.helpCircle;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.1),
            baseColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: baseColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 12.sp, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: baseColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> profile) {
    final firstName = profile['first_name'] as String?;
    final lastName = profile['last_name'] as String?;

    if (firstName != null && firstName.isNotEmpty) {
      if (lastName != null && lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName;
    }

    return profile['username'] as String;
  }

  // removed: replaced by _ClientAvatar initials logic

  Widget _buildClientsTab() {
    if (_displayedClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 64.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'هنوز شاگردی ندارید',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.1),
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 220.w,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('افزودن شاگرد جدید'),
                onPressed: _openAddClientSheet,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _displayedClients.length + 1,
      itemBuilder: (context, index) {
        if (index == _displayedClients.length) {
          // Minimal add button as the last item
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _openAddClientSheet,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                ),
                foregroundColor: AppTheme.goldColor,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: const Text('افزودن شاگرد جدید'),
            ),
          );
        }

        final client = _displayedClients[index];
        final clientProfile = client['client'] as Map<String, dynamic>?;

        if (clientProfile == null) return const SizedBox.shrink();

        final status = client['status'] as String? ?? 'pending';
        final isActive = status == 'active';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? const [
                      Color(0xFF143D26),
                      Color(0xFF112F1E),
                      Color(0xFF0F2719),
                    ]
                  : [
                      const Color(0xFF262A33),
                      const Color(0xFF20252E),
                      const Color(0xFF1B2028),
                    ],
            ),
            border: Border.all(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.white10,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x44000000),
                blurRadius: 12.r,
                offset: Offset(0.w, 6.h),
              ),
            ],
          ),
          child: ListTile(
            onTap: isActive ? () => _onClientTap(clientProfile) : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            leading: _ClientAvatar(profile: clientProfile),
            title: Text(
              _getDisplayName(clientProfile),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${clientProfile['username']}',
                  style: TextStyle(color: AppTheme.goldColor, fontSize: 12.sp),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(client['status'] as String? ?? 'pending'),
                if (clientProfile['bio'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    clientProfile['bio'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (clientProfile['height'] != null ||
                    clientProfile['weight'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${clientProfile['height'] ?? 'نامشخص'}cm - ${clientProfile['weight'] ?? 'نامشخص'}kg',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(
                LucideIcons.moreVertical,
                color: AppTheme.goldColor,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'remove':
                    _removeClient(clientProfile['id'] as String);
                  case 'block':
                    _blockClient(clientProfile['id'] as String);
                  case 'unblock':
                    _unblockClient(clientProfile['id'] as String);
                }
              },
              itemBuilder: (context) {
                final status = client['status'] as String? ?? 'pending';
                final items = <PopupMenuItem<String>>[];

                if (status == 'blocked') {
                  items.add(
                    const PopupMenuItem(
                      value: 'unblock',
                      child: Row(
                        children: [
                          Icon(LucideIcons.userCheck, color: Colors.green),
                          SizedBox(width: 8),
                          Text('رفع مسدودیت'),
                        ],
                      ),
                    ),
                  );
                } else {
                  items.add(
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(LucideIcons.userMinus, color: Colors.red),
                          SizedBox(width: 8),
                          Text('مسدود کردن'),
                        ],
                      ),
                    ),
                  );
                }

                items.add(
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف شاگرد'),
                      ],
                    ),
                  ),
                );

                return items;
              },
            ),
          ),
        );
      },
    );
  }

  void _openAddClientSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: AthleteRequestWidget(
                onAthleteSelected: (athlete) {
                  Navigator.pop(context);
                  _addNewClient(athlete);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl =
        (profile['avatar_url'] ??
                profile['avatarUrl'] ??
                profile['profile_image_url'])
            as String?;
    final String initials = _initialsFromProfile(profile);

    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: ClipOval(
        child: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(initials: initials),
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Center(
                        child: SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
              )
            : _Initials(initials: initials),
      ),
    );
  }

  String _initialsFromProfile(Map<String, dynamic> p) {
    final first = (p['first_name'] as String?)?.trim() ?? '';
    final last = (p['last_name'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined.characters.first;
    final username = (p['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) {
      return username.characters.first;
    }
    return '?';
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
