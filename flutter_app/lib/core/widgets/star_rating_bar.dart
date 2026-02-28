import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

/// 0.5단위 인터랙티브 별점 위젯
/// 온보딩, 콘텐츠 상세, 내 평점에서 공통 사용
class StarRatingBar extends StatelessWidget {
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final double starSize;
  final double spacing;
  final bool showLabel;

  const StarRatingBar({
    super.key,
    this.rating = 0,
    this.onRatingChanged,
    this.starSize = 32,
    this.spacing = 4,
    this.showLabel = false,
  });

  bool get _interactive => onRatingChanged != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++) ...[
          if (i > 1) SizedBox(width: spacing),
          _buildStar(i),
        ],
        if (showLabel && rating > 0) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.starActive,
              fontSize: starSize * 0.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int index) {
    final double fill = (rating - (index - 1)).clamp(0.0, 1.0);

    Widget star;
    if (fill >= 1.0) {
      star = Icon(Icons.star_rounded, size: starSize, color: AppColors.starActive);
    } else if (fill >= 0.5) {
      star = Icon(Icons.star_half_rounded, size: starSize, color: AppColors.starActive);
    } else {
      star = Icon(Icons.star_outline_rounded, size: starSize, color: AppColors.starInactive);
    }

    if (!_interactive) return star;

    return GestureDetector(
      onTapDown: (details) {
        final dx = details.localPosition.dx;
        final half = dx < starSize / 2;
        final newRating = half ? index - 0.5 : index.toDouble();
        onRatingChanged!(newRating == rating ? 0 : newRating);
      },
      child: star,
    );
  }
}
