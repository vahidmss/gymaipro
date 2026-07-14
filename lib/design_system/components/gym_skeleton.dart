import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/shimmer.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';

enum GymSkeletonVariant { hero, card, timeline, chatBubble }

/// Skeleton placeholder with shimmer for loading states.
class GymSkeleton extends StatelessWidget {
  const GymSkeleton({
    this.variant = GymSkeletonVariant.card,
    this.width,
    this.height,
    super.key,
  });

  final GymSkeletonVariant variant;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      GymSkeletonVariant.hero => _HeroSkeleton(width: width, height: height),
      GymSkeletonVariant.card => _CardSkeleton(width: width, height: height),
      GymSkeletonVariant.timeline => _TimelineSkeleton(width: width),
      GymSkeletonVariant.chatBubble => _ChatBubbleSkeleton(width: width),
    };
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GymShimmer(
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 140,
        padding: GymSpacing.card,
        decoration: const BoxDecoration(
          color: GymColors.neutral800,
          borderRadius: GymRadius.radiusXxl,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GymShimmerBlock(width: 120, height: 18, radius: GymRadius.sm),
            SizedBox(height: GymSpacing.lg),
            GymShimmerBlock(height: 14, radius: GymRadius.sm),
            SizedBox(height: GymSpacing.sm),
            GymShimmerBlock(width: 200, height: 14, radius: GymRadius.sm),
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GymShimmer(
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 96,
        padding: GymSpacing.paddingLg,
        decoration: const BoxDecoration(
          color: GymColors.neutral800,
          borderRadius: GymRadius.radiusXl,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GymShimmerBlock(width: 80, height: 12, radius: GymRadius.sm),
            SizedBox(height: GymSpacing.md),
            GymShimmerBlock(height: 20, radius: GymRadius.sm),
          ],
        ),
      ),
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton({this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const GymShimmer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GymColors.neutral700,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 10, height: 10),
          ),
        ),
        const SizedBox(width: GymSpacing.md),
        Expanded(
          child: GymShimmer(
            child: Container(
              width: width ?? double.infinity,
              height: 72,
              padding: GymSpacing.paddingMd,
              decoration: const BoxDecoration(
                color: GymColors.neutral800,
                borderRadius: GymRadius.radiusLg,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GymShimmerBlock(width: 100, height: 12),
                  SizedBox(height: GymSpacing.sm),
                  GymShimmerBlock(height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubbleSkeleton extends StatelessWidget {
  const _ChatBubbleSkeleton({this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GymShimmer(
        child: Container(
          width: width ?? 240,
          height: 64,
          padding: GymSpacing.paddingLg,
          decoration: const BoxDecoration(
            color: GymColors.neutral800,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(GymRadius.xl),
              topRight: Radius.circular(GymRadius.xl),
              bottomLeft: Radius.circular(GymRadius.xl),
              bottomRight: Radius.circular(GymRadius.sm),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GymShimmerBlock(height: 12),
              SizedBox(height: GymSpacing.sm),
              GymShimmerBlock(width: 140, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
