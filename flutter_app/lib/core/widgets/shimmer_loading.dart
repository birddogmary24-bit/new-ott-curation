import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/app_colors.dart';

/// 범용 shimmer 박스
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface2Dark,
      highlightColor: AppColors.surfaceDark,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface2Dark,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// 콘텐츠 카드 로딩 shimmer
class ContentCardShimmer extends StatelessWidget {
  final double width;
  final double height;
  const ContentCardShimmer({super.key, this.width = 120, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:  AppColors.surface2Dark,
      highlightColor: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width, height: height,
            decoration: BoxDecoration(
              color: AppColors.surface2Dark,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 6),
          Container(width: width * 0.8, height: 12, color: AppColors.surface2Dark),
          const SizedBox(height: 4),
          Container(width: width * 0.5, height: 10, color: AppColors.surface2Dark),
        ],
      ),
    );
  }
}

/// 가로 스크롤 섹션 로딩 shimmer
class SectionShimmer extends StatelessWidget {
  const SectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.surface2Dark,
          highlightColor: AppColors.surfaceDark,
          child: Container(width: 150, height: 20, color: AppColors.surface2Dark),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => const ContentCardShimmer(),
          ),
        ),
      ],
    );
  }
}
