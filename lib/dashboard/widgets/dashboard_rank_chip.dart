import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// چیپ فشرده امتیاز / لیگ / رتبه روی داشبورد.
class DashboardRankChip extends StatefulWidget {
  const DashboardRankChip({super.key});

  @override
  State<DashboardRankChip> createState() => _DashboardRankChipState();
}

class _DashboardRankChipState extends State<DashboardRankChip> {
  UserRanking? _ranking;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    try {
      final ranking = await RankingService().getCurrentUserRanking();
      if (!mounted) return;
      setState(() {
        _ranking = ranking;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  void _openLeaderboard() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const LeaderboardScreen()),
    );
  }

  League _leagueById(String id) {
    return League.all.firstWhere(
      (l) => l.id == id,
      orElse: () => League.bronze,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreService = context.watch<ScoreService>();
    final score = scoreService.rankingScore > 0
        ? scoreService.rankingScore
        : (_ranking?.totalScore ?? 0);
    final league = _leagueById(_ranking?.currentLeague ?? 'bronze');
    final rank = _ranking?.globalRank;

    if (!_loaded && score <= 0) {
      return const SizedBox.shrink();
    }

    final parts = <String>[
      FormatUtils.toPersianDigits('$score'),
      GamificationLabels.points,
      '·',
      'لیگ ${league.nameFa}',
      if (rank != null && rank > 0) ...[
        '·',
        'رتبه ${FormatUtils.toPersianDigits('$rank')}',
      ],
    ];

    return GestureDetector(
      onTap: _openLeaderboard,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            GamificationLabels.rankingIcon,
            size: 13.sp,
            color: context.textSecondary,
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              parts.join(' '),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
                color: context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(width: 2.w),
          Icon(
            LucideIcons.chevronLeft,
            size: 12.sp,
            color: context.textSecondary.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}
