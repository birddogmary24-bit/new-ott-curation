import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/widgets/star_rating_bar.dart';
import '../../../home/domain/entities/content.dart';

class RatingContentTile extends StatelessWidget {
  final Content content;
  final double? currentRating;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onSkip;

  const RatingContentTile({
    super.key,
    required this.content,
    this.currentRating,
    required this.onRatingChanged,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: currentRating != null && currentRating! > 0
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // 포스터
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: content.posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: content.posterUrl!,
                    width: 56,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56, height: 80, color: AppColors.surface2Dark,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56, height: 80, color: AppColors.surface2Dark,
                      child: const Icon(Icons.movie_outlined,
                          color: AppColors.textSecondaryDark, size: 20),
                    ),
                  )
                : Container(
                    width: 56, height: 80, color: AppColors.surface2Dark,
                    child: const Icon(Icons.movie_outlined,
                        color: AppColors.textSecondaryDark, size: 20),
                  ),
          ),
          const SizedBox(width: 12),

          // 제목 + 별점
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.titleKo,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (content.releaseYear != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${content.releaseYear}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                StarRatingBar(
                  rating: currentRating ?? 0,
                  onRatingChanged: onRatingChanged,
                  starSize: 26,
                  spacing: 2,
                ),
              ],
            ),
          ),

          // 안 봤어요
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              '안 봤어요',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
