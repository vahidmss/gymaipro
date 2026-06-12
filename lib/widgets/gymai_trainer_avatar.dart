import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// آواتار مربی GymAI: اول شبکه، در صورت نبود/خطا از `images/GymAI.jpg`.
class GymaiTrainerAvatar extends StatelessWidget {
  const GymaiTrainerAvatar({
    required this.size, super.key,
    this.avatarUrl,
    this.userId,
    this.username,
    this.fit = BoxFit.cover,
    this.fallback,
    this.clipOval = true,
  });

  final String? avatarUrl;
  final String? userId;
  final String? username;
  final double size;
  final BoxFit fit;
  final Widget? fallback;
  final bool clipOval;

  bool get _isGymai =>
      AITrainerService.isGymaiTrainer(userId: userId, username: username);

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final hasNetwork = url != null && url.isNotEmpty;

    Widget child;
    if (_isGymai) {
      child = hasNetwork
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: fit,
              errorWidget: (_, __, ___) => _assetImage(),
            )
          : _assetImage();
    } else if (hasNetwork) {
      child = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: fit,
        errorWidget: (_, __, ___) =>
            fallback ?? Icon(LucideIcons.user, size: size * 0.45),
      );
    } else {
      child = fallback ??
          Icon(LucideIcons.user, size: size * 0.45);
    }

    if (!clipOval) return SizedBox(width: size, height: size, child: child);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: child),
    );
  }

  Widget _assetImage() {
    return Image.asset(
      AITrainerService.avatarAssetPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          fallback ?? Icon(LucideIcons.bot, size: size * 0.45),
    );
  }
}
