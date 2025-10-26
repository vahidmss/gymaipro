import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ArticleImage extends StatelessWidget {
  const ArticleImage({
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    super.key,
  });

  final String imageUrl;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const ColoredBox(
          color: Colors.black12,
          child: Center(
            child: Icon(LucideIcons.imageOff, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
