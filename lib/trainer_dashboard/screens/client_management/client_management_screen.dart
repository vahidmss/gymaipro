import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/trainer_client_service.dart';
import '../../services/user_search_service.dart';
import '../../widgets/athlete_request_widget.dart';
import '../../widgets/client_search_widget.dart';
import '../../widgets/relationship_stats_widget.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({Key? key}) : super(key: key);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری اطلاعات: $e')),
        );
      }
    }
  }

  Future<void> _addNewClient(Map<String, dynamic> athlete) async {
    if (_currentUserId == null) return;

    try {
      // بررسی وجود هر نوع رابطه
      final existingRelationship = await _searchService.getAnyRelationship(
        trainerId: _currentUserId!,
        clientId: athlete['id'],
      );

      if (existingRelationship != null) {
        final status = existingRelationship['status'] as String;
        String message;

        switch (status) {
          case 'active':
            message = 'این ورزشکار قبلاً شاگرد فعال شما است';
            break;
          case 'pending':
            message = 'درخواست شما برای این ورزشکار در انتظار تایید است';
            break;
          case 'inactive':
            message = 'این ورزشکار قبلاً شاگرد شما بوده و غیرفعال است';
            break;
          case 'blocked':
            message = 'این ورزشکار مسدود شده است';
            break;
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
        clientId: athlete['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('درخواست برای شاگرد ارسال شد - در انتظار تایید')),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در اضافه کردن شاگرد: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شاگرد با موفقیت حذف شد')),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف شاگرد: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در مسدود کردن شاگرد: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در رفع مسدودیت شاگرد: $e')),
        );
      }
    }
  }

  void _onClientTap(Map<String, dynamic> clientProfile) {
    // TODO: Navigate to client details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('انتقال به صفحه اطلاعات ${_getDisplayName(clientProfile)}'),
        backgroundColor: Colors.green,
      ),
    );

    // بعداً اینجا navigation به صفحه جزئیات شاگرد اضافه می‌شود
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ClientDetailsScreen(clientProfile: clientProfile),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'داشبورد مربی',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.amber),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            )
          : Column(
              children: [
                // آمار
                RelationshipStatsWidget(stats: _relationshipStats),

                // تب‌ها
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.amber,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(LucideIcons.users, size: 20),
                        text: 'شاگردان',
                      ),
                      Tab(
                        icon: Icon(LucideIcons.userPlus, size: 20),
                        text: 'درخواست شاگرد',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // محتوای تب‌ها
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // تب شاگردان
                      Column(
                        children: [
                          ClientSearchWidget(
                            allClients: _clients,
                            onSearchResultsChanged: _onSearchResultsChanged,
                          ),
                          Expanded(
                            child: _buildClientsTab(),
                          ),
                        ],
                      ),

                      // تب درخواست شاگرد
                      AthleteRequestWidget(
                        onAthleteSelected: _addNewClient,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'active':
        chipColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        statusText = 'فعال';
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'pending':
        chipColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        statusText = 'در انتظار تایید';
        statusIcon = LucideIcons.clock;
        break;
      case 'inactive':
        chipColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey;
        statusText = 'غیرفعال';
        statusIcon = LucideIcons.userX;
        break;
      case 'blocked':
        chipColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        statusText = 'مسدود';
        statusIcon = LucideIcons.userMinus;
        break;
      default:
        chipColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey;
        statusText = 'نامشخص';
        statusIcon = LucideIcons.helpCircle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
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

  String _getSafeInitial(String? username) {
    if (username == null || username.isEmpty) {
      return '?';
    }
    return username.substring(0, 1).toUpperCase();
  }

  Widget _buildClientsTab() {
    if (_displayedClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 64,
              color: Colors.amber[300],
            ),
            const SizedBox(height: 16),
            Text(
              'هنوز شاگردی ندارید',
              style: TextStyle(
                color: Colors.amber[200],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'برای افزودن شاگرد جدید،\nبه تب "افزودن شاگرد" بروید',
              style: TextStyle(
                color: Colors.amber[300],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _displayedClients.length,
      itemBuilder: (context, index) {
        final client = _displayedClients[index];
        final clientProfile = client['client'] as Map<String, dynamic>?;

        if (clientProfile == null) return const SizedBox.shrink();

        final status = client['status'] as String? ?? 'pending';
        final isActive = status == 'active';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: Colors.green.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: ListTile(
            onTap: isActive ? () => _onClientTap(clientProfile) : null,
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.amber[700],
              child: Text(
                _getSafeInitial(clientProfile['username'] as String?),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                  ),
                ),
                // نمایش وضعیت رابطه
                const SizedBox(height: 4),
                _buildStatusChip(client['status'] as String? ?? 'pending'),
                if (clientProfile['bio'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    clientProfile['bio'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (clientProfile['height'] != null ||
                    clientProfile['weight'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${clientProfile['height'] ?? 'نامشخص'}cm - ${clientProfile['weight'] ?? 'نامشخص'}kg',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, color: Colors.amber),
              onSelected: (value) {
                switch (value) {
                  case 'remove':
                    _removeClient(clientProfile['id']);
                    break;
                  case 'block':
                    _blockClient(clientProfile['id']);
                    break;
                  case 'unblock':
                    _unblockClient(clientProfile['id']);
                    break;
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
}
