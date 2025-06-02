import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/exercise.dart';
import '../models/exercise_comment.dart';
import '../services/exercise_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isVideoInitialized = false;
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  List<ExerciseComment> _comments = [];
  bool _isLoadingComments = false;
  final FocusNode _commentFocusNode = FocusNode();

  // Gold theme colors
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeVideo();
    _loadComments();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.exercise.videoUrl.isNotEmpty) {
        _videoPlayerController =
            VideoPlayerController.network(widget.exercise.videoUrl);
        await _videoPlayerController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: goldColor,
            handleColor: goldColor,
            backgroundColor: Colors.grey[800]!,
            bufferedColor: goldColor.withOpacity(0.3),
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: goldColor,
              ),
            ),
          ),
          autoInitialize: true,
        );

        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments =
          await _exerciseService.getExerciseComments(widget.exercise.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت نظر ابتدا وارد حساب کاربری خود شوید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isPostingComment = true;
    });

    try {
      final comment = await _exerciseService.addExerciseComment(
        widget.exercise.id,
        _commentController.text.trim(),
      );

      if (comment != null) {
        setState(() {
          _comments.insert(0, comment);
          _commentController.clear();
          _isPostingComment = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نظر شما با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ثبت نظر: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  Future<void> _deleteComment(ExerciseComment comment) async {
    try {
      await _exerciseService.deleteComment(comment.id, widget.exercise.id);
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نظر با موفقیت حذف شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در حذف نظر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _tabController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ذخیره تمرین ابتدا وارد حساب کاربری خود شوید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _exerciseService.toggleFavorite(widget.exercise.id);
      setState(() {
        // widget.exercise.isFavorite is already updated in the service
        if (widget.exercise.isFavorite) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین به لیست علاقه‌مندی‌ها اضافه شد'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین از لیست علاقه‌مندی‌ها حذف شد'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای پسندیدن تمرین ابتدا وارد حساب کاربری خود شوید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final wasLiked = widget.exercise.isLikedByUser;
      await _exerciseService.toggleLike(widget.exercise.id);
      setState(() {
        // widget.exercise.isLikedByUser and widget.exercise.likes are already updated in the service
        if (!wasLiked && widget.exercise.isLikedByUser) {
          // Successfully liked
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین را پسندیدید'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Hide keyboard on tap outside
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: _isLoading ? _buildLoadingIndicator() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // App bar
        _buildSliverAppBar(),

        // Video section
        SliverToBoxAdapter(
          child: _buildVideoSection(),
        ),

        // Tab bar
        SliverPersistentHeader(
          delegate: _SliverAppBarDelegate(
            TabBar(
              controller: _tabController,
              indicatorColor: goldColor,
              indicatorWeight: 3,
              labelColor: goldColor,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'توضیحات'),
                Tab(text: 'نکات کلیدی'),
                Tab(text: 'نظرات کاربران'),
              ],
            ),
          ),
          pinned: true,
        ),

        // Tab content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDescriptionTab(),
              _buildTipsTab(),
              _buildCommentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: goldColor,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240.0,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Hero(
          tag:
              'exercise_image_${widget.exercise.id}', // Match the tag from ExerciseListScreen
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                widget.exercise.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    LucideIcons.dumbbell,
                    color: goldColor,
                    size: 80,
                  ),
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Like button
        IconButton(
          icon: Icon(
            widget.exercise.isLikedByUser
                ? Icons.favorite
                : Icons.favorite_border,
            color: widget.exercise.isLikedByUser ? Colors.red : Colors.white,
          ),
          onPressed: _toggleLike,
        ),
        // Bookmark button
        IconButton(
          icon: Icon(
            widget.exercise.isFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: widget.exercise.isFavorite ? goldColor : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        // Add to workout button
        IconButton(
          icon: const Icon(
            LucideIcons.plusSquare,
            color: Colors.white,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تمرین به برنامه افزوده شد'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    if (!_isVideoInitialized || _chewieController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 230,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Chewie(
        controller: _chewieController!,
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise info card
          _buildInfoCard(),
          const SizedBox(height: 20),

          // Main content
          const Text(
            'توضیحات تمرین',
            style: TextStyle(
              color: goldColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.exercise.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 32),

          // Other names section
          if (widget.exercise.otherNames.isNotEmpty) ...[
            const Text(
              'نام‌های دیگر',
              style: TextStyle(
                color: goldColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.exercise.otherNames.map((name) {
                return Chip(
                  label: Text(name),
                  backgroundColor: cardColor,
                  side: BorderSide(color: goldColor.withOpacity(0.3)),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tips list
          if (widget.exercise.tips.isNotEmpty) ...[
            const Text(
              'نکات کلیدی',
              style: TextStyle(
                color: goldColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.exercise.tips.map((tip) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: goldColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.lightbulb,
                      color: goldColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Icon(
                    LucideIcons.info,
                    color: Colors.white38,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'نکات تکمیلی برای این تمرین ثبت نشده است',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // Warning section
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.red,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'همیشه قبل از انجام تمرینات جدید با مربی خود مشورت کنید. انجام حرکات با فرم نادرست می‌تواند منجر به آسیب شود.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    final user = Supabase.instance.client.auth.currentUser;

    return Column(
      children: [
        // Comment input section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نظر خود را بنویسید',
                style: TextStyle(
                  color: goldColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'نظر شما...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: MaterialButton(
                      onPressed: user != null
                          ? (_isPostingComment ? null : _postComment)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'برای ثبت نظر ابتدا وارد حساب کاربری خود شوید'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                      color: goldColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      child: _isPostingComment
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              LucideIcons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (user == null)
                const Text(
                  'برای ثبت نظر ابتدا وارد حساب کاربری خود شوید',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),

        // Comments list
        Expanded(
          child: _isLoadingComments
              ? const Center(
                  child: CircularProgressIndicator(
                    color: goldColor,
                  ),
                )
              : _comments.isEmpty
                  ? _buildEmptyCommentsView()
                  : _buildCommentsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyCommentsView() {
    return const SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.messageSquare,
                color: Colors.white38,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'هنوز نظری برای این تمرین ثبت نشده است',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'اولین نفری باشید که نظر می‌دهد!',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final isMyComment =
            comment.userId == Supabase.instance.client.auth.currentUser?.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Comment header (username and date)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align items to the start
                children: [
                  Expanded(
                    // Wrap the user info Row with Expanded
                    child: Row(
                      children: [
                        // User avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                          child: comment.profileAvatar != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    comment.profileAvatar!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      LucideIcons.user,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.user,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 8),
                        // Username
                        Expanded(
                          // Allow username to wrap
                          child: Text(
                            comment.profileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Prevent long names from breaking layout
                            maxLines: 1,
                          ),
                        ),
                        if (isMyComment) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: goldColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'شما',
                              style: TextStyle(
                                color: goldColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Date and delete button
                  Row(
                    mainAxisSize: MainAxisSize.min, // Take only necessary space
                    children: [
                      // Date
                      Text(
                        '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      // Delete button (only for user's own comments)
                      if (isMyComment) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _deleteComment(comment),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              LucideIcons.trash2,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Comment content
              Text(
                comment.comment,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: goldColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            title: 'عضلات اصلی:',
            content: widget.exercise.mainMuscle,
            icon: LucideIcons.target,
          ),
          const Divider(
            color: Colors.white12,
            height: 24,
          ),
          _buildInfoRow(
            title: 'عضلات فرعی:',
            content: widget.exercise.secondaryMuscles,
            icon: LucideIcons.activity,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: goldColor,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          // Added Expanded here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                // overflow: TextOverflow.ellipsis, // Optional: if you prefer ellipsis for very long content
                // maxLines: 3, // Optional: limit max lines
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF121212),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
