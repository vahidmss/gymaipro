import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/widgets/academy_story_card.dart';

class AcademyStoriesSection extends StatelessWidget {
  const AcademyStoriesSection({required this.articles, super.key});

  final List<Article> articles;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120.h,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        scrollDirection: Axis.horizontal,
        itemCount: articles.length.clamp(0, 8),
        itemBuilder: (context, index) {
          final article = articles[index];
          return AcademyStoryCard(article: article);
        },
      ),
    );
  }
}
