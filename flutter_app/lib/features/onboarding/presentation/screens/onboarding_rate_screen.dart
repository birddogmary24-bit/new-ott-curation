import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../../../home/domain/entities/content.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/rating_content_tile.dart';

/// 온보딩용 트렌딩 콘텐츠 프로바이더
final onboardingContentsProvider = FutureProvider<List<Content>>((ref) async {
  final repo = ref.read(contentRepositoryProvider);
  final result = await repo.getContents(sort: 'trending', page: 1);
  return result.items;
});

class OnboardingRateScreen extends ConsumerWidget {
  const OnboardingRateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final contentsAsync = ref.watch(onboardingContentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingProgressBar(currentStep: 3),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '본 작품에\n별점을 매겨주세요',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '3개 이상 평가해주세요 (${state.ratings.length}개 완료)',
                    style: TextStyle(
                      color: state.canSubmit
                          ? AppColors.success
                          : AppColors.textSecondaryDark,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: contentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('콘텐츠를 불러오지 못했어요',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(onboardingContentsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
                data: (contents) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: contents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final content = contents[i];
                    return RatingContentTile(
                      content: content,
                      currentRating: state.ratings[content.id],
                      onRatingChanged: (rating) =>
                          ref.read(onboardingProvider.notifier).setRating(content.id, rating),
                      onSkip: () =>
                          ref.read(onboardingProvider.notifier).setRating(content.id, 0),
                    );
                  },
                ),
              ),
            ),

            // 에러 메시지
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(state.error!, style: const TextStyle(color: AppColors.error)),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.canSubmit && !state.isSubmitting
                      ? () async {
                          final success =
                              await ref.read(onboardingProvider.notifier).submitOnboarding();
                          if (success && context.mounted) {
                            context.go(Routes.home);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.surface2Dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          '시작하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
