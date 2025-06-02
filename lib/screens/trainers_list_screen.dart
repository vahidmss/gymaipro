import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/trainer_service.dart';
import 'trainer_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TrainersListScreen extends StatefulWidget {
  const TrainersListScreen({Key? key}) : super(key: key);

  @override
  State<TrainersListScreen> createState() => _TrainersListScreenState();
}

class _TrainersListScreenState extends State<TrainersListScreen> {
  final TrainerService _trainerService = TrainerService();
  List<UserProfile> _trainers = [];
  bool _isLoading = true;
  final Map<String, double> _trainerRatings = {}; // Cache for trainer ratings

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trainers = await _trainerService.getAllTrainers();

      // Load ratings for each trainer
      for (final trainer in trainers) {
        if (trainer.id != null) {
          _loadTrainerRating(trainer.id!);
        }
      }

      setState(() {
        _trainers = trainers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگیری لیست مربیان: $e')),
      );
    }
  }

  Future<void> _loadTrainerRating(String trainerId) async {
    try {
      final reviews = await _trainerService.getTrainerReviews(trainerId);
      if (reviews.isNotEmpty) {
        // Calculate average rating
        final totalRating =
            reviews.fold(0, (sum, review) => sum + review.rating);
        final averageRating = totalRating / reviews.length;

        setState(() {
          _trainerRatings[trainerId] = averageRating;
        });
      }
    } catch (e) {
      debugPrint('Error loading trainer rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('مربیان', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrainers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trainers.isEmpty
              ? const Center(
                  child: Text(
                    'مربی‌ای یافت نشد',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trainers.length,
                  itemBuilder: (context, index) {
                    final trainer = _trainers[index];
                    final rating = _trainerRatings[trainer.id] ?? 0.0;

                    return _buildTrainerCard(trainer, rating);
                  },
                ),
    );
  }

  Widget _buildTrainerCard(UserProfile trainer, double rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (trainer.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TrainerProfileScreen(trainerId: trainer.id!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trainer avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    trainer.avatarUrl != null && trainer.avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: trainer.avatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.person, size: 40),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 40),
                          ),
              ),
              const SizedBox(width: 16),
              // Trainer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (trainer.bio != null && trainer.bio!.isNotEmpty)
                      Text(
                        trainer.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: rating > 0 ? Colors.amber : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating > 0
                              ? rating.toStringAsFixed(1)
                              : 'بدون امتیاز',
                          style: TextStyle(
                            fontSize: 14,
                            color: rating > 0 ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow icon
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
