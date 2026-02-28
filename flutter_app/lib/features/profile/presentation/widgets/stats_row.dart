import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';

class StatsRow extends StatelessWidget {
  final int ratingsCount;
  final int reviewsCount;
  final int collectionsCount;

  const StatsRow({
    super.key,
    required this.ratingsCount,
    required this.reviewsCount,
    required this.collectionsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(label: '평점', count: ratingsCount),
          _Divider(),
          _StatItem(label: '리뷰', count: reviewsCount),
          _Divider(),
          _StatItem(label: '컬렉션', count: collectionsCount),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;

  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
            color: AppColors.textSecondaryDark, fontSize: 12)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.dividerDark,
    );
  }
}
