import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/app_theme.dart';

class ShimmerLoader extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: AppTheme.cardBg,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.of(context).surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class PostShimmer extends StatelessWidget {
  const PostShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const ShimmerLoader(height: 40, width: 40, borderRadius: 20),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerLoader(height: 14, width: MediaQuery.sizeOf(context).width * 0.3),
              const SizedBox(height: 6),
              ShimmerLoader(height: 12, width: MediaQuery.sizeOf(context).width * 0.2),
            ]),
          ]),
          const SizedBox(height: 12),
          const ShimmerLoader(height: 16),
          const SizedBox(height: 8),
          ShimmerLoader(height: 14, width: MediaQuery.sizeOf(context).width * 0.7),
          const SizedBox(height: 16),
          const ShimmerLoader(height: 1),
        ],
      ),
    );
  }
}
