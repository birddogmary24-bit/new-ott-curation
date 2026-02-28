import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/widgets/content_card.dart';
import '../../../../routing/app_router.dart';
import '../providers/collection_detail_provider.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final String collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(collectionDetailProvider(collectionId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: detailAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('컬렉션을 불러오지 못했어요',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(collectionDetailProvider(collectionId)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (detail) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.backgroundDark,
              leading: const BackButton(color: AppColors.textPrimaryDark),
              title: Text(detail.title, style: const TextStyle(
                  color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 작성자 정보
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surface2Dark,
                          child: Text(
                            detail.creatorNickname.isNotEmpty
                                ? detail.creatorNickname[0]
                                : '?',
                            style: const TextStyle(
                                color: AppColors.textSecondaryDark, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(detail.creatorNickname, style: const TextStyle(
                            color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.favorite, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text('${detail.likeCount}', style: const TextStyle(
                            color: AppColors.textSecondaryDark, fontSize: 12)),
                      ],
                    ),
                    if (detail.description != null) ...[
                      const SizedBox(height: 12),
                      Text(detail.description!,
                          style: const TextStyle(color: AppColors.textSecondaryDark,
                              fontSize: 13, height: 1.5)),
                    ],
                    const SizedBox(height: 8),
                    Text('${detail.items.length}개 콘텐츠',
                        style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.52,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final item = detail.items[i];
                    return ContentCard(
                      content: item,
                      width: double.infinity,
                      height: 160,
                      onTap: () => context.push(Routes.contentDetail(item.id)),
                    );
                  },
                  childCount: detail.items.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
