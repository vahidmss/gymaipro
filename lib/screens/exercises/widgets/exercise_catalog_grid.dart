import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_catalog_card.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_empty_view.dart';

class ExerciseCatalogGrid extends StatelessWidget {
  const ExerciseCatalogGrid({
    required this.exercises,
    required this.onRefresh,
    required this.onExerciseTap,
    required this.onFavorite,
    required this.onLike,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    super.key,
  });

  final List<Exercise> exercises;
  final Future<void> Function() onRefresh;
  final void Function(Exercise exercise) onExerciseTap;
  final void Function(Exercise exercise) onFavorite;
  final void Function(Exercise exercise) onLike;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          cacheExtent: 480,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ExerciseEmptyView(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        cacheExtent: 480,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exercise = exercises[index];
                  return ExerciseCatalogCard(
                    key: ValueKey(exercise.id),
                    exercise: exercise,
                    onTap: () => onExerciseTap(exercise),
                    onFavorite: () => onFavorite(exercise),
                    onLike: () => onLike(exercise),
                  );
                },
                childCount: exercises.length,
                addAutomaticKeepAlives: false,
                findChildIndexCallback: (Key key) {
                  if (key is! ValueKey<Object?>) return null;
                  final id = key.value;
                  for (var i = 0; i < exercises.length; i++) {
                    if (exercises[i].id == id) return i;
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
