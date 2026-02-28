import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/widgets/content_card.dart';
import '../../../../routing/app_router.dart';
import '../providers/content_detail_provider.dart';
import '../widgets/backdrop_header.dart';
import '../widgets/content_info_section.dart';
import '../widgets/ott_availability_section.dart';
import '../widgets/review_snippet.dart';

class ContentDetailScreen extends ConsumerWidget {
  final String contentId;

  const ContentDetailScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(contentDetailProvider(contentId));
    final userRating = ref.watch(userRatingProvider(contentId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white38),
              const SizedBox(height: 12),
              const Text('콘텐츠를 불러오지 못했어요',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(contentDetailProvider(contentId)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (data) => CustomScrollView(
          slivers: [
            BackdropHeader(content: data.content),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기본 정보 + 평점
                    ContentInfoSection(
                      content: data.content,
                      userRating: userRating ?? data.userRating,
                      onRatingChanged: (rating) =>
                          ref.read(userRatingProvider(contentId).notifier).rate(rating),
                    ),
                    const SizedBox(height: 24),

                    // OTT 가용성
                    OttAvailabilitySection(availability: data.content.availability),
                    const SizedBox(height: 24),

                    // 비슷한 콘텐츠
                    if (data.similar.isNotEmpty) ...[
                      const Text('비슷한 콘텐츠', style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: data.similar.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final item = data.similar[i];
                            return ContentCard(
                              content: item,
                              onTap: () => context.push(Routes.contentDetail(item.id)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 리뷰
                    ReviewSnippet(contentId: contentId),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
