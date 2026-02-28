import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/entities/collection_summary.dart';

class CollectionCard extends StatelessWidget {
  final CollectionSummary collection;
  final VoidCallback? onTap;

  const CollectionCard({super.key, required this.collection, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 커버 이미지
            AspectRatio(
              aspectRatio: 16 / 9,
              child: collection.coverPosterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: collection.coverPosterUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surface2Dark),
                      errorWidget: (_, __, ___) => _CoverPlaceholder(),
                    )
                  : _CoverPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        collection.creatorNickname,
                        style: const TextStyle(
                            color: AppColors.textSecondaryDark, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        '${collection.itemCount}개',
                        style: const TextStyle(
                            color: AppColors.textSecondaryDark, fontSize: 11),
                      ),
                      if (collection.likeCount > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite, size: 11,
                            color: AppColors.textSecondaryDark),
                        const SizedBox(width: 2),
                        Text(
                          '${collection.likeCount}',
                          style: const TextStyle(
                              color: AppColors.textSecondaryDark, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface2Dark,
      child: const Center(
        child: Icon(Icons.collections_bookmark_outlined,
            size: 32, color: AppColors.textSecondaryDark),
      ),
    );
  }
}
