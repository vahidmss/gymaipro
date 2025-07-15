import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';

class TrainersChatSection extends StatefulWidget {
  const TrainersChatSection({Key? key}) : super(key: key);

  @override
  State<TrainersChatSection> createState() => _TrainersChatSectionState();
}

class _TrainersChatSectionState extends State<TrainersChatSection> {
  List<UserProfile> _trainers = [];
  bool _isLoading = true;
  late SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get all trainers (users with role = 'trainer')
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('role', 'trainer')
          .limit(5);

      final trainers =
          response.map((json) => UserProfile.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _trainers = trainers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor),
        ),
      );
    }

    if (_trainers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.users,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'مربیان قابل چت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_trainers.length}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Trainers List
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              itemCount: _trainers.length,
              itemBuilder: (context, index) {
                final trainer = _trainers[index];
                return _buildTrainerCard(trainer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(UserProfile trainer) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/chat', arguments: {
          'otherUserId': trainer.id,
          'otherUserName': trainer.firstName ?? 'مربی',
        });
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.purple.withValues(alpha: 0.2),
              child: const Icon(
                LucideIcons.user,
                color: Colors.purple,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trainer.firstName ?? 'مربی',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'چت',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
