import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';
import 'exercise_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen>
    with TickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  List<String> _muscleGroups = [];
  String _selectedMuscleGroup = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearching = false;

  // Gold theme colors
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFFFD700); // Gold accent

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _exerciseService.init();
      final exercises = await _exerciseService.getExercises();
      final muscleGroups = await _exerciseService.getMuscleGroups();

      setState(() {
        _exercises = exercises;
        _filteredExercises = exercises;
        _muscleGroups = muscleGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری تمرینات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterExercises() {
    final filteredByMuscle = _selectedMuscleGroup.isEmpty
        ? _exercises
        : _exercises.where((exercise) {
            return exercise.mainMuscle.contains(_selectedMuscleGroup) ||
                exercise.secondaryMuscles.contains(_selectedMuscleGroup);
          }).toList();

    final filtered = _searchQuery.isEmpty
        ? filteredByMuscle
        : filteredByMuscle.where((exercise) {
            final query = _searchQuery.toLowerCase();
            return exercise.name.toLowerCase().contains(query) ||
                exercise.mainMuscle.toLowerCase().contains(query) ||
                exercise.secondaryMuscles.toLowerCase().contains(query) ||
                exercise.otherNames
                    .any((name) => name.toLowerCase().contains(query));
          }).toList();

    setState(() {
      _filteredExercises = filtered;
    });
  }

  void _toggleFavorite(Exercise exercise) async {
    try {
      await _exerciseService.toggleFavorite(exercise.id);
      setState(() {
        // exercise.isFavorite is already updated in the service
        if (exercise.isFavorite) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین به لیست علاقه‌مندی‌ها اضافه شد'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین از لیست علاقه‌مندی‌ها حذف شد'),
              backgroundColor: Colors.blue,
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

  void _toggleLike(Exercise exercise) async {
    try {
      final wasLiked = exercise.isLikedByUser;
      await _exerciseService.toggleLike(exercise.id);
      setState(() {
        // exercise.isLikedByUser and exercise.likes are already updated in the service
        if (!wasLiked && exercise.isLikedByUser) {
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
    return Theme(
      data: AppTheme.darkTheme,
      child: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // Hide keyboard on tap outside
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: _isSearching
                ? _buildSearchField()
                : const Text(
                    'آموزش تمرینات',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 20, // Slightly larger
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5, // Added letter spacing
                    ),
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? LucideIcons.x : LucideIcons.search,
                  color: goldColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchQuery = '';
                      _filterExercises();
                      // Hide keyboard when exiting search mode
                      FocusScope.of(context).unfocus();
                    } else {
                      // Focus on search field when entering search mode
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(FocusNode());
                      });
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.filter,
                  color: goldColor,
                  size: 22,
                ),
                onPressed: _showFilterDialog,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: goldColor,
              indicatorWeight: 2,
              labelColor: goldColor,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'همه تمرینات'),
                Tab(text: 'محبوب‌ترین'),
                Tab(text: 'مورد علاقه‌ها'),
              ],
            ),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () {
                _exerciseService.clearCache();
                return _loadData();
              },
              color: goldColor,
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExercisesList(_filteredExercises),
                        FutureBuilder<List<Exercise>>(
                          future: _exerciseService.getPopularExercises(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingIndicator();
                            }
                            return _buildExercisesList(snapshot.data ?? []);
                          },
                        ),
                        FutureBuilder<List<Exercise>>(
                          future: _exerciseService.getFavoriteExercises(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingIndicator();
                            }
                            return _buildExercisesList(snapshot.data ?? []);
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      decoration: const InputDecoration(
        hintText: 'جستجوی تمرین...',
        hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _filterExercises();
        });
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.filter, color: goldColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'فیلتر بر اساس گروه عضلانی',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // All button
                      FilterChip(
                        label: const Text('همه'),
                        selected: _selectedMuscleGroup.isEmpty,
                        selectedColor: goldColor.withOpacity(0.3),
                        checkmarkColor: goldColor,
                        backgroundColor: cardColor,
                        labelStyle: TextStyle(
                          color: _selectedMuscleGroup.isEmpty
                              ? goldColor
                              : Colors.white70,
                        ),
                        side: BorderSide(
                          color: _selectedMuscleGroup.isEmpty
                              ? goldColor
                              : Colors.white24,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedMuscleGroup = '';
                          });
                          setState(() {
                            _selectedMuscleGroup = '';
                            _filterExercises();
                          });
                        },
                      ),

                      // Muscle group chips
                      ..._muscleGroups.map((group) {
                        final isSelected = group == _selectedMuscleGroup;
                        return FilterChip(
                          label: Text(group),
                          selected: isSelected,
                          selectedColor: goldColor.withOpacity(0.3),
                          checkmarkColor: goldColor,
                          backgroundColor: cardColor,
                          labelStyle: TextStyle(
                            color: isSelected ? goldColor : Colors.white70,
                          ),
                          side: BorderSide(
                            color: isSelected ? goldColor : Colors.white24,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedMuscleGroup = selected ? group : '';
                            });
                            setState(() {
                              _selectedMuscleGroup = selected ? group : '';
                              _filterExercises();
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(LucideIcons.check, size: 18),
                      label: const Text('تایید'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: goldColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68, // Match the actual list
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6, // Show a few shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: cardColor,
          highlightColor: Colors.grey[800]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // This will be covered by shimmer
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10.5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.white),
                        const SizedBox(height: 4),
                        Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: 14,
                            color: Colors.white),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                width: 50, height: 12, color: Colors.white),
                            Container(
                                width: 60, height: 12, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercisesList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 2
                  ? LucideIcons.heartOff
                  : (_tabController.index == 1
                      ? LucideIcons.trendingDown
                      : LucideIcons.searchX),
              color: Colors.white38,
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              _tabController.index == 2
                  ? 'هنوز تمرینی را به علاقه‌مندی‌ها اضافه نکرده‌اید'
                  : (_tabController.index == 1
                      ? 'موردی برای نمایش در محبوب‌ترین‌ها یافت نشد'
                      : 'هیچ تمرینی با این مشخصات یافت نشد!'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _tabController.index > 0
                ? TextButton.icon(
                    onPressed: () {
                      _tabController.animateTo(0);
                    },
                    icon: const Icon(LucideIcons.listChecks,
                        size: 18, color: goldColor),
                    label: const Text('مشاهده همه تمرینات',
                        style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: goldColor.withOpacity(0.9),
                    ),
                  )
                : Text(
                    _searchQuery.isNotEmpty || _selectedMuscleGroup.isNotEmpty
                        ? 'جستجو یا فیلتر خود را تغییر دهید.'
                        : 'لیست تمرینات خالی است.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68, // Adjusted for new card design
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withOpacity(0.25), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: goldColor.withOpacity(0.03),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            ).then((_) {
              // Refresh state when returning from details screen to reflect changes
              _loadData();
            });
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: goldColor.withOpacity(0.1),
          highlightColor: goldColor.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              AspectRatio(
                aspectRatio: 16 / 10.5, // Adjusted for slightly more image
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'exercise_image_${exercise.id}',
                      child: CachedNetworkImage(
                        imageUrl: exercise.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900]?.withOpacity(0.5),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                  color: goldColor.withOpacity(0.7),
                                  strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900]?.withOpacity(0.5),
                          child: Icon(LucideIcons.imageOff,
                              color: goldColor.withOpacity(0.5), size: 40),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.8)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withOpacity(0.45),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _toggleFavorite(exercise),
                          splashColor: goldColor.withOpacity(0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Icon(
                              exercise.isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: exercise.isFavorite
                                  ? accentColor
                                  : Colors.white.withOpacity(0.85),
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (exercise.mainMuscle.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            exercise.mainMuscle,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Text and Action Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Use spaceBetween
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _toggleLike(exercise),
                              borderRadius: BorderRadius.circular(8),
                              splashColor: goldColor.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 5.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      exercise.isLikedByUser
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: exercise.isLikedByUser
                                          ? Colors.redAccent
                                          : Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      exercise.likes.toString(),
                                      style: TextStyle(
                                        color: exercise.isLikedByUser
                                            ? Colors.redAccent
                                            : Colors.white70,
                                        fontSize: 12.5,
                                        fontWeight: exercise.isLikedByUser
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronLeft,
                            color: goldColor.withOpacity(0.7),
                            size: 18,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
