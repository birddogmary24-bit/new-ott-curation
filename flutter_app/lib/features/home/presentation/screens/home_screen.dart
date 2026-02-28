import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../routing/app_router.dart';
import '../../domain/entities/curation_section.dart';
import '../providers/home_provider.dart';
import '../widgets/curation_section_widget.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/platform_filter_chips.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(homeSectionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 앱바 ──
            SliverAppBar(
              backgroundColor: AppColors.backgroundDark,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 16,
              title: Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'OTT 큐레이션',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textPrimaryDark),
                  onPressed: () => context.push(Routes.search),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimaryDark),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ── OTT 플랫폼 필터 ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: PlatformFilterChips(),
              ),
            ),

            // ── 섹션 콘텐츠 ──
            sectionsAsync.when(
              loading: () => const SliverToBoxAdapter(child: _HomeSkeleton()),
              error: (err, _) => SliverToBoxAdapter(
                child: _HomeError(onRetry: () => ref.read(homeSectionsProvider.notifier).refresh()),
              ),
              data: (sections) => _HomeSections(sections: sections),
            ),

            // ── 하단 여백 ──
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 섹션 목록
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _HomeSections extends ConsumerWidget {
  final List<CurationSection> sections;

  const _HomeSections({required this.sections});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlatform = ref.watch(selectedPlatformProvider);

    // 플랫폼 필터 적용
    List<CurationSection> filtered = sections;
    if (selectedPlatform != null) {
      filtered = sections.map((section) {
        final filteredContents = section.contents
            .where((c) => c.availability.any((a) => a.platformId == selectedPlatform))
            .toList();
        return CurationSection(
          id: section.id,
          sectionType: section.sectionType,
          titleKo: section.titleKo,
          aiReason: section.aiReason,
          contents: filteredContents,
          isPersonalized: section.isPersonalized,
          expiresAt: section.expiresAt,
        );
      }).where((s) => s.hasContents).toList();
    }

    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final section = filtered[index];

          // 첫 번째 trending 섹션은 히어로 캐러셀로 표시
          if (index == 0 && section.sectionType == SectionType.trending) {
            return HeroCarousel(section: section);
          }

          return CurationSectionWidget(section: section);
        },
        childCount: filtered.length,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 스켈레톤 로딩
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 히어로 영역 스켈레톤
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ShimmerBox(
            width: double.infinity,
            height: 220,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // 섹션 스켈레톤 3개
        const SectionShimmer(),
        const SectionShimmer(),
        const SectionShimmer(),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 에러 상태
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _HomeError extends StatelessWidget {
  final VoidCallback onRetry;

  const _HomeError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textSecondaryDark),
          const SizedBox(height: 16),
          Text(
            '콘텐츠를 불러오지 못했어요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '네트워크 연결을 확인하고 다시 시도해주세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 빈 상태 (플랫폼 필터 결과 없음)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined, size: 64, color: AppColors.textSecondaryDark),
          SizedBox(height: 16),
          Text(
            '해당 플랫폼에 콘텐츠가 없어요',
            style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
