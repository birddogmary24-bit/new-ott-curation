import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../../domain/entities/content.dart';
import '../../domain/entities/curation_section.dart';

class HeroCarousel extends StatefulWidget {
  final CurationSection section;

  const HeroCarousel({super.key, required this.section});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.section.contents.take(5).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            widget.section.titleKo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (context, index) {
              return _HeroCard(
                content: items[index],
                isActive: index == _currentIndex,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 페이지 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == _currentIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: index == _currentIndex
                    ? AppColors.primary
                    : AppColors.textSecondaryDark.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Content content;
  final bool isActive;

  const _HeroCard({required this.content, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () => context.push(Routes.contentDetail(content.id)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surfaceDark,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경 이미지 (backdrop or poster)
              if (content.backdropUrl != null || content.posterUrl != null)
                CachedNetworkImage(
                  imageUrl: content.backdropUrl ?? content.posterUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceDark),
                  errorWidget: (_, __, ___) => Container(color: AppColors.surfaceDark),
                )
              else
                Container(color: AppColors.surfaceDark),

              // 그라데이션 오버레이
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // 콘텐츠 정보
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // OTT 뱃지들
                    if (content.availability.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: content.availability
                            .where((a) => a.isFlatrate)
                            .take(3)
                            .map((a) => _OttChip(platformId: a.platformId))
                            .toList(),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      content.titleKo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (content.releaseYear != null) ...[
                          Text(
                            '${content.releaseYear}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (content.genres.isNotEmpty)
                          Text(
                            content.genres.take(2).join(' · '),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        const Spacer(),
                        if (content.ourAvgRating != null && content.ourAvgRating! > 0)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.starColor, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                content.displayRating,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OttChip extends StatelessWidget {
  final String platformId;

  const _OttChip({required this.platformId});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ottColor(platformId);
    final name = switch (platformId) {
      'netflix'      => 'N',
      'tving'        => 'T',
      'coupang_play' => 'C',
      'wavve'        => 'W',
      'watcha'       => 'W',
      _              => platformId.substring(0, 1).toUpperCase(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
