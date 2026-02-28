import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../providers/profile_provider.dart';

class MyRatingsScreen extends ConsumerWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRatingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text('내 평점 (${state.items.length})',
            style: const TextStyle(color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700)),
        leading: const BackButton(color: AppColors.textPrimaryDark),
      ),
      body: state.items.isEmpty && state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline, size: 48, color: Colors.white38),
                      SizedBox(height: 12),
                      Text('아직 평점을 남긴 콘텐츠가 없어요',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent * 0.8) {
                      ref.read(myRatingsProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      if (i >= state.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      }
                      return _RatingListTile(
                        item: state.items[i],
                        onTap: () => context.push(
                            Routes.contentDetail(state.items[i].contentId)),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RatingListTile extends StatelessWidget {
  final UserRatingItem item;
  final VoidCallback onTap;

  const _RatingListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // 포스터
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.posterUrl!,
                      width: 44, height: 64, fit: BoxFit.cover,
                    )
                  : Container(
                      width: 44, height: 64, color: AppColors.surface2Dark,
                      child: const Icon(Icons.movie_outlined,
                          size: 16, color: AppColors.textSecondaryDark),
                    ),
            ),
            const SizedBox(width: 12),

            // 제목 + 날짜
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titleKo, style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt),
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 11),
                  ),
                ],
              ),
            ),

            // 내 평점
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 16,
                        color: AppColors.starActive),
                    const SizedBox(width: 2),
                    Text(item.rating.toStringAsFixed(1), style: const TextStyle(
                        color: AppColors.starActive,
                        fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (item.ourAvgRating != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '평균 ${item.ourAvgRating!.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}
