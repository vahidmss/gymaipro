import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/user_search_service.dart';

class AthleteRequestWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onAthleteSelected;

  const AthleteRequestWidget({
    Key? key,
    required this.onAthleteSelected,
  }) : super(key: key);

  @override
  State<AthleteRequestWidget> createState() => _AthleteRequestWidgetState();
}

class _AthleteRequestWidgetState extends State<AthleteRequestWidget> {
  final UserSearchService _searchService = UserSearchService();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _foundAthlete;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'لطفاً یوزرنیم را وارد کنید';
        _foundAthlete = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundAthlete = null;
    });

    try {
      final athlete =
          await _searchService.getUserProfile(_usernameController.text.trim());

      if (athlete != null && athlete['role'] == 'athlete') {
        setState(() {
          _foundAthlete = athlete;
        });
      } else {
        setState(() {
          _errorMessage = 'یوزرنیم یافت نشد یا ورزشکار نیست';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در بررسی یوزرنیم: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'یوزرنیم ورزشکار را وارد کنید',
                      hintStyle: TextStyle(color: Colors.amber),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendRequest(),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.amber,
                          ),
                        )
                      : const Icon(LucideIcons.send, color: Colors.amber),
                  onPressed: _isLoading ? null : _sendRequest,
                ),
              ],
            ),
          ),

          // پیام خطا
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // نتیجه جستجو
          if (_foundAthlete != null) ...[
            Text(
              'ورزشکار یافت شد - درخواست ارسال کنید:',
              style: TextStyle(
                color: Colors.green[300],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAthleteCard(_foundAthlete!),
          ],

          const SizedBox(height: 20),

          // راهنمای پایین
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.lightbulb,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'نکات مهم:',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• یوزرنیم ورزشکاری که می‌شناسید را وارد کنید\n• درخواست برای ورزشکار ارسال می‌شود\n• ورزشکار درخواست را تایید یا رد می‌کند',
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> athlete) {
    final firstName = athlete['first_name'] as String?;
    final lastName = athlete['last_name'] as String?;

    if (firstName != null && firstName.isNotEmpty) {
      if (lastName != null && lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName;
    }

    return athlete['username'] as String;
  }

  String _getSafeInitial(String? username) {
    if (username == null || username.isEmpty) {
      return 'U';
    }
    return username.substring(0, 1).toUpperCase();
  }

  Widget _buildAthleteCard(Map<String, dynamic> athlete) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.green[700],
          child: Text(
            _getSafeInitial(athlete['username'] as String?),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _getDisplayName(athlete),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${athlete['username']}',
              style: TextStyle(
                color: Colors.green[300],
                fontSize: 12,
              ),
            ),
            if (athlete['bio'] != null) ...[
              const SizedBox(height: 4),
              Text(
                athlete['bio'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => widget.onAthleteSelected(athlete),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('ارسال درخواست'),
        ),
      ),
    );
  }
}
