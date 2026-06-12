import 'package:flutter/material.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/screens/exercises/exercise_catalog_logic.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_catalog_grid.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_empty_view.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_shimmer_grid.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseTrainerPane extends StatefulWidget {
  const ExerciseTrainerPane({
    required this.filters,
    required this.onExerciseTap,
    required this.onFavorite,
    required this.onLike,
    required this.refreshToken,
    super.key,
  });

  final ExerciseCatalogFilters filters;
  final void Function(Exercise exercise) onExerciseTap;
  final void Function(Exercise exercise) onFavorite;
  final void Function(Exercise exercise) onLike;
  final int refreshToken;

  @override
  State<ExerciseTrainerPane> createState() => _ExerciseTrainerPaneState();
}

class _ExerciseTrainerPaneState extends State<ExerciseTrainerPane> {
  final _customService = CustomExerciseService();
  final _trainerService = TrainerService();

  late Future<_TrainerPaneData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(ExerciseTrainerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _load();
    }
  }

  Future<_TrainerPaneData> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const _TrainerPaneData(kind: _TrainerKind.noUser);
    }

    final role = await _getUserRole();
    if (role == 'trainer') {
      final custom = await _customService.getMyExercises();
      final exercises =
          await _customService.customExercisesToExercises(custom);
      return _TrainerPaneData(
        kind: _TrainerKind.trainerOwn,
        exercises: exercises,
      );
    }

    final trainers =
        await _trainerService.getClientTrainersWithProfiles(user.id);
    final active =
        trainers.where((t) => t['status'] == 'active').toList();
    if (active.isEmpty) {
      return const _TrainerPaneData(kind: _TrainerKind.noTrainer);
    }

    final exercises = await _loadClientExercises(user.id);
    return _TrainerPaneData(
      kind: _TrainerKind.client,
      exercises: exercises,
    );
  }

  Future<List<Exercise>> _loadClientExercises(String clientId) async {
    final exercises = <Exercise>[];
    try {
      final custom =
          await _customService.getTrainerExercisesForClient(clientId);
      exercises.addAll(
        await _customService.customExercisesToExercises(custom),
      );
    } catch (_) {}

    try {
      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'role',
      );
      if (profile?['role'] == 'trainer') {
        final myCustom = await _customService.getMyExercises();
        final mine =
            await _customService.customExercisesToExercises(myCustom);
        final ids = exercises.map((e) => e.id).toSet();
        for (final e in mine) {
          if (!ids.contains(e.id)) exercises.add(e);
        }
      }
    } catch (_) {}

    return exercises;
  }

  Future<String?> _getUserRole() async {
    try {
      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'role',
      );
      return profile?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TrainerPaneData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ExerciseShimmerGrid();
        }

        final data = snapshot.data;
        if (data == null) {
          return const ExerciseShimmerGrid();
        }

        switch (data.kind) {
          case _TrainerKind.noUser:
            return const ExerciseEmptyView(
              icon: LucideIcons.userX,
              title: 'وارد حساب کاربری شوید',
              subtitle: 'برای دیدن تمرینات مربی باید وارد شوید.',
            );
          case _TrainerKind.noTrainer:
            return ExerciseEmptyView(
              icon: LucideIcons.userPlus,
              title: 'شما هنوز مربی ندارید',
              subtitle:
                  'با داشتن مربی به تمرینات و برنامه‌های اختصاصی دسترسی دارید.',
              actionLabel: 'جستجوی مربی',
              onAction: () => Navigator.pushNamed(context, '/trainer-ranking'),
            );
          case _TrainerKind.trainerOwn:
          case _TrainerKind.client:
            final visible = ExerciseCatalogLogic.apply(
              data.exercises,
              widget.filters,
            );
            if (data.exercises.isEmpty) {
              return ExerciseEmptyView(
                icon: LucideIcons.dumbbell,
                title: 'تمرین اختصاصی ثبت نشده',
                subtitle: data.kind == _TrainerKind.trainerOwn
                    ? 'با دکمه + تمرین اختصاصی خود را بسازید.'
                    : 'مربی شما هنوز تمرین اختصاصی ایجاد نکرده است.',
              );
            }
            return ExerciseCatalogGrid(
              exercises: visible,
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              onExerciseTap: widget.onExerciseTap,
              onFavorite: widget.onFavorite,
              onLike: widget.onLike,
              emptyTitle: 'نتیجه‌ای یافت نشد',
              emptySubtitle: 'عبارت جستجو یا فیلتر را تغییر دهید.',
              emptyIcon: LucideIcons.searchX,
            );
        }
      },
    );
  }
}

enum _TrainerKind { noUser, noTrainer, trainerOwn, client }

class _TrainerPaneData {
  const _TrainerPaneData({
    required this.kind,
    this.exercises = const [],
  });

  final _TrainerKind kind;
  final List<Exercise> exercises;
}
