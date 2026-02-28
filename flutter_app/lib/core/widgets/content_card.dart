import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme/app_colors.dart';
import '../../features/home/domain/entities/content.dart';

/// 재사용 가능한 콘텐츠 썸네일 카드
/// 홈 큐레이션 섹션, 검색 결과 등에서 사용
class ContentCard extends StatelessWidget {
  final Content content;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.width  = 120,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final primaryAvail = content.primaryAvailability;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 포스터
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  if (content.posterUrl != null)
                    CachedNetworkImage(
                      imageUrl: content.posterUrl!,
                      width:  width,
                      height: height,
                      fit:    BoxFit.cover,
                      placeholder: (_, __) => _PosterPlaceholder(width: width, height: height),
                      errorWidget: (_, __, ___) => _PosterPlaceholder(width: width, height: height),
                    )
                  else
                    _PosterPlaceholder(width: width, height: height),

                  // OTT 플랫폼 뱃지
                  if (primaryAvail != null)
                    Positioned(
                      top: 6, left: 6,
                      child: _OttBadge(platformId: primaryAvail.platformId),
                    ),

                  // TV 뱃지
                  if (content.isTvShow)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'TV',
                          style: TextStyle(fontSize: 8, color: Colors.white70),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 제목
            Text(
              content.titleKo,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // 평점
            if (content.ourAvgRating != null && content.ourAvgRating! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: AppColors.starActive),
                    const SizedBox(width: 2),
                    Text(
                      content.displayRating,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
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

class _PosterPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  const _PosterPlaceholder({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface2Dark,
      child: const Icon(Icons.movie_outlined, color: AppColors.textSecondaryDark),
    );
  }
}

class _OttBadge extends StatelessWidget {
  final String platformId;
  const _OttBadge({required this.platformId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ottColor(platformId),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _shortName(platformId),
        style: const TextStyle(
          fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white,
        ),
      ),
    );
  }

  String _shortName(String id) => switch (id) {
    'netflix'      => 'N',
    'tving'        => 'T',
    'coupang_play' => 'C',
    'wavve'        => 'W',
    'watcha'       => 'WC',
    _              => id.substring(0, 1).toUpperCase(),
  };
}
