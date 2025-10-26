import 'package:flutter/material.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/dashboard/widgets/section_nav_carousel.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AcademyPreviewSection extends StatefulWidget {
  const AcademyPreviewSection({super.key});

  @override
  State<AcademyPreviewSection> createState() => _AcademyPreviewSectionState();
}

class _AcademyPreviewSectionState extends State<AcademyPreviewSection> {
  List<Article> _articles = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ArticleService.fetchArticles(perPage: 10);
      if (mounted) setState(() => _articles = data.take(6).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _articles
        .map(
          (a) => SectionCardItem(
            title: a.title,
            subtitle: a.excerpt,
            icon: LucideIcons.bookOpen,
            onTap: () =>
                Navigator.pushNamed(context, '/article-detail', arguments: a),
            gradientColors: [
              AppTheme.cardColor,
              AppTheme.goldColor.withValues(alpha: 0.3),
            ],
            imageUrl: a.featuredImageUrl,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionNavCarousel(
          title: 'آکادمی',
          items: _loading && items.isEmpty
              ? [
                  SectionCardItem(
                    title: 'در حال بارگیری...',
                    subtitle: 'لطفاً صبر کنید',
                    icon: Icons.hourglass_bottom,
                    onTap: () {},
                    gradientColors: [
                      AppTheme.cardColor,
                      AppTheme.goldColor.withValues(alpha: 0.3),
                    ],
                  ),
                ]
              : items,
          onHeaderAction: () => Navigator.pushNamed(context, '/articles'),
        ),
      ],
    );
  }
}
