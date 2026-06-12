import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/trainer_client.dart';
import 'package:gymaipro/models/trainer_detail.dart';
import 'package:gymaipro/models/trainer_review.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({required this.trainerId, super.key});
  final String trainerId;

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final TrainerService _trainerService = TrainerService();
  bool _isLoading = true;
  UserProfile? _trainer;
  TrainerDetail? _trainerDetail;
  List<TrainerReview> _reviews = [];
  TrainerClient? _relationship;
  double _avgRating = 0;
  final String _currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';
  bool _isCurrentUserClient = false;

  @override
  void initState() {
    super.initState();
    _loadTrainerData();
  }

  Future<void> _loadTrainerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load trainer profile
      final profiles = await _trainerService.getAllTrainers();
      _trainer =
          profiles.firstWhere(
                (profile) => profile.id == widget.trainerId,
                orElse: () => throw Exception('مربی یافت نشد'),
              )
              as UserProfile?;

      // Load trainer details
      _trainerDetail = await _trainerService.getTrainerDetails(
        widget.trainerId,
      );

      // Load trainer reviews
      _reviews = await _trainerService.getTrainerReviews(widget.trainerId);

      // Calculate average rating
      if (_reviews.isNotEmpty) {
        final totalRating = _reviews.fold(
          0,
          (sum, review) => sum + review.rating,
        );
        _avgRating = totalRating / _reviews.length;
      }

      // Check relationship with current user
      if (_currentUserId.isNotEmpty) {
        final relationships = await _trainerService.getClientTrainers(
          _currentUserId,
        );
        try {
          _relationship = relationships.firstWhere(
            (rel) => rel.trainerId == widget.trainerId,
          );
        } catch (e) {
          _relationship = null;
        }

        _isCurrentUserClient = await _trainerService.isClientOfTrainer(
          _currentUserId,
          widget.trainerId,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگیری اطلاعات مربی: $e')),
      );
    }
  }

  Future<void> _requestTrainer() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _trainerService.requestTrainer(
        _currentUserId,
        widget.trainerId,
      );

      setState(() {
        _isLoading = false;
        if (success) {
          _relationship = TrainerClient(
            id: '',
            trainerId: widget.trainerId,
            clientId: _currentUserId,
            status: 'pending',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('درخواست شما با موفقیت ارسال شد')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('خطا در ارسال درخواست')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
    }
  }

  Future<void> _cancelRequest() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _trainerService.endTrainerClientRelationship(
        widget.trainerId,
        _currentUserId,
      );

      setState(() {
        _isLoading = false;
        if (success) {
          _relationship = null;
          _isCurrentUserClient = false;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('درخواست با موفقیت لغو شد')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('خطا در لغو درخواست')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
    }
  }

  Future<void> _showReviewDialog() async {
    int rating = 5;
    String reviewText = '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('نظر شما در مورد این مربی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('امتیاز'),
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'نظر شما (اختیاری)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  reviewText = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop({'rating': rating, 'review': reviewText});
              },
              child: const Text('ثبت نظر'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final review = TrainerReview(
          id: '',
          trainerId: widget.trainerId,
          clientId: _currentUserId,
          rating: result['rating'] as int,
          review: result['review'] as String?,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await _trainerService.saveTrainerReview(review);

        if (success) {
          // Reload reviews
          await _loadTrainerData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('نظر شما با موفقیت ثبت شد')),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('خطا در ثبت نظر')));
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _trainer?.fullName ?? 'پروفایل مربی',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrainerData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trainer == null
          ? const Center(child: Text('مربی یافت نشد'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrainerHeader(),
                  const SizedBox(height: 20),
                  if (_trainerDetail != null) ...[
                    _buildTrainerDetails(),
                    const SizedBox(height: 20),
                  ],
                  _buildReviewsSection(),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildTrainerHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                // Trainer avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(50.r),
                  child:
                      _trainer?.avatarUrl != null &&
                          _trainer!.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _trainer!.avatarUrl!,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 100.w,
                            height: 100.h,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100.w,
                            height: 100.h,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 50),
                          ),
                        )
                      : Container(
                          width: 100.w,
                          height: 100.h,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 50),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _trainer?.fullName ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22.sp,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: _avgRating > 0 ? Colors.amber : Colors.grey,
                            size: 20.sp,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _avgRating > 0
                                ? '${_avgRating.toStringAsFixed(1)} (${_reviews.length})'
                                : 'بدون امتیاز',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: _avgRating > 0
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (_relationship != null) ...[
                        const SizedBox(height: 8),
                        _buildRelationshipBadge(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_trainer?.bio != null && _trainer!.bio!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _trainer!.bio!,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipBadge() {
    final Color color;
    final String text;

    if (_relationship!.isPending) {
      color = Colors.orange;
      text = 'در انتظار تایید';
    } else if (_relationship!.isActive) {
      color = Colors.green;
      text = 'مربی فعال شما';
    } else if (_relationship!.isRejected) {
      color = Colors.red;
      text = 'درخواست رد شده';
    } else {
      color = Colors.grey;
      text = 'پایان یافته';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrainerDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات مربی',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (_trainerDetail?.experienceYears != null) ...[
              _buildDetailRow(
                Icons.history,
                'سابقه',
                '${_trainerDetail!.experienceYears} سال',
              ),
              const SizedBox(height: 12),
            ],
            if (_trainerDetail?.specialties != null &&
                _trainerDetail!.specialties!.isNotEmpty) ...[
              _buildDetailRow(
                Icons.fitness_center,
                'تخصص‌ها',
                _trainerDetail!.specialties!.join('، '),
              ),
              const SizedBox(height: 12),
            ],
            if (_trainerDetail?.certifications != null &&
                _trainerDetail!.certifications!.isNotEmpty) ...[
              _buildDetailRow(
                Icons.badge,
                'گواهینامه‌ها',
                _trainerDetail!.certifications!.join('، '),
              ),
              const SizedBox(height: 12),
            ],
            if (_trainerDetail?.education != null &&
                _trainerDetail!.education!.isNotEmpty) ...[
              _buildDetailRow(
                Icons.school,
                'تحصیلات',
                _trainerDetail!.education!,
              ),
              const SizedBox(height: 12),
            ],
            if (_trainerDetail?.hourlyRate != null) ...[
              _buildDetailRow(
                Icons.attach_money,
                'هزینه ساعتی',
                '${_trainerDetail!.hourlyRate} تومان',
              ),
              const SizedBox(height: 12),
            ],
            if (_trainerDetail?.bioExtended != null &&
                _trainerDetail!.bioExtended!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'درباره مربی',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _trainerDetail!.bioExtended!,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.sp, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'نظرات و امتیازات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (_isCurrentUserClient)
                  TextButton.icon(
                    icon: const Icon(Icons.rate_review),
                    label: const Text('ثبت نظر'),
                    onPressed: _showReviewDialog,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_reviews.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: const Text('هنوز نظری ثبت نشده است'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return _buildReviewItem(review);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(TrainerReview review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 8),
              const Text(
                'کاربر',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16.sp,
                  );
                }),
              ),
            ],
          ),
          if (review.review != null && review.review!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.review!,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800),
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    // Don't show action button for own profile
    if (_currentUserId == widget.trainerId || _currentUserId.isEmpty) {
      return const SizedBox();
    }

    // If relationship exists
    if (_relationship != null) {
      if (_relationship!.isPending || _relationship!.isActive) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cancel),
            label: Text(
              _relationship!.isPending ? 'لغو درخواست' : 'قطع همکاری',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: _cancelRequest,
          ),
        );
      }
    }

    // Default: Show request button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add),
        label: const Text('درخواست مربی'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: _requestTrainer,
      ),
    );
  }
}
