import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../../domain/constants/genre_constants.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/genre_chip.dart';
import '../widgets/onboarding_progress_bar.dart';

class OnboardingGenreScreen extends ConsumerWidget {
  const OnboardingGenreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingProgressBar(currentStep: 1),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '좋아하는 장르를\n선택해주세요',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '3개 이상 선택해주세요 (${state.selectedGenres.length}개 선택됨)',
                    style: TextStyle(
                      color: state.canProceedGenre
                          ? AppColors.success
                          : AppColors.textSecondaryDark,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.95,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: GenreConstants.all.length,
                itemBuilder: (_, i) {
                  final genre = GenreConstants.all[i];
                  return GenreChip(
                    emoji: genre.emoji,
                    label: genre.nameKo,
                    isSelected: state.selectedGenres.contains(genre.id),
                    onTap: () => ref.read(onboardingProvider.notifier).toggleGenre(genre.id),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.canProceedGenre
                      ? () => context.push(Routes.onboardingOtt)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.surface2Dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '다음',
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
