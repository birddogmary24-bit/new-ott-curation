import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../providers/community_provider.dart';
import '../widgets/collection_card.dart';
import '../widgets/review_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: const Text('커뮤니티',
              style: TextStyle(color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondaryDark,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: '리뷰'),
              Tab(text: '컬렉션'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReviewsTab(),
            _CollectionsTab(),
          ],
        ),
      ),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(popularReviewsProvider);

    return reviewsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('리뷰를 불러오지 못했어요',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(popularReviewsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 48, color: Colors.white38),
                SizedBox(height: 12),
                Text('아직 리뷰가 없어요', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => ReviewCard(
            review: reviews[i],
            onTap: () => context.push(Routes.contentDetail(reviews[i].contentId)),
          ),
        );
      },
    );
  }
}

class _CollectionsTab extends ConsumerWidget {
  const _CollectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(publicCollectionsProvider);

    return collectionsAsync.when(
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
              onPressed: () => ref.invalidate(publicCollectionsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (collections) {
        if (collections.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.collections_bookmark_outlined, size: 48, color: Colors.white38),
                SizedBox(height: 12),
                Text('아직 컬렉션이 없어요', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: collections.length,
          itemBuilder: (_, i) => CollectionCard(
            collection: collections[i],
            onTap: () => context.push(Routes.collectionDetail(collections[i].id)),
          ),
        );
      },
    );
  }
}
