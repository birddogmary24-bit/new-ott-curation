import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../home/domain/entities/content.dart';

class BackdropHeader extends StatelessWidget {
  final Content content;

  const BackdropHeader({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.backgroundDark,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 60),
        title: Text(
          content.titleKo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (content.backdropUrl != null)
              CachedNetworkImage(
                imageUrl: content.backdropUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceDark),
                errorWidget: (_, __, ___) => Container(color: AppColors.surfaceDark),
              )
            else
              Container(color: AppColors.surfaceDark),
            // 하단 그라데이션
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundDark.withValues(alpha: 0.6),
                    AppColors.backgroundDark,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
