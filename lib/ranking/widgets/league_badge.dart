import 'package:flutter/material.dart';
import 'package:gymaipro/ranking/models/league.dart';

/// ویجت نمایش نشان لیگ
class LeagueBadge extends StatelessWidget {
  const LeagueBadge({
    required this.league,
    this.size = 24.0,
    this.showText = false,
    super.key,
  });

  final League league;
  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            league.icon,
            style: TextStyle(fontSize: size),
          ),
          const SizedBox(width: 4),
          Text(
            league.nameFa,
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
              color: Color(league.color),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: Color(league.color).withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Color(league.color),
          width: 2,
        ),
      ),
      child: Text(
        league.icon,
        style: TextStyle(fontSize: size),
      ),
    );
  }
}
