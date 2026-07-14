import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

enum GymAvatarSize { sm, md, lg }

/// Circular avatar with optional image, icon, or initials.
class GymAvatar extends StatelessWidget {
  const GymAvatar({
    this.imageUrl,
    this.initials,
    this.icon,
    this.size = GymAvatarSize.md,
    this.showOnline = false,
    super.key,
  });

  final String? imageUrl;
  final String? initials;
  final IconData? icon;
  final GymAvatarSize size;
  final bool showOnline;

  double get _dimension => switch (size) {
    GymAvatarSize.sm => 32,
    GymAvatarSize.md => 48,
    GymAvatarSize.lg => 64,
  };

  @override
  Widget build(BuildContext context) {
    final dimension = _dimension;
    Widget content;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = ClipOval(
        child: Image.network(
          imageUrl!,
          width: dimension,
          height: dimension,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(dimension),
        ),
      );
    } else {
      content = _fallback(dimension);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        content,
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dimension * 0.28,
              height: dimension * 0.28,
              decoration: BoxDecoration(
                color: GymColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: GymColors.background, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(double dimension) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[GymColors.primary, GymColors.primaryDark],
        ),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: GymColors.onPrimary, size: dimension * 0.45)
          : Text(
              initials ?? '?',
              style: GymTypography.title.copyWith(
                color: GymColors.onPrimary,
                fontSize: dimension * 0.34,
              ),
            ),
    );
  }
}
