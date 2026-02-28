import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/stats_row.dart';
import '../widgets/taste_radar_chart.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final tasteAsync = ref.watch(tasteProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('프로필',
            style: TextStyle(color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondaryDark),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(
            child: Text('프로필을 불러오지 못했어요',
                style: TextStyle(color: Colors.white70))),
        data: (user) {
          if (user == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('로그인'),
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(
                  user: user,
                  onEdit: () => context.push(Routes.editProfile),
                ),

                // 통계
                tasteAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (taste) => StatsRow(
                    ratingsCount: taste.totalRatings,
                    reviewsCount: taste.totalReviews,
                    collectionsCount: taste.totalCollections,
                  ),
                ),
                const SizedBox(height: 20),

                // 취향 레이더 차트
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: tasteAsync.when(
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (taste) => TasteRadarChart(
                        genreDistribution: taste.genreDistribution),
                  ),
                ),
                const SizedBox(height: 24),

                // 바로가기
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _MenuTile(
                        icon: Icons.star_outline,
                        title: '내 평점',
                        subtitle: '${user.totalRatings}개',
                        onTap: () => context.push(Routes.myRatings),
                      ),
                      _MenuTile(
                        icon: Icons.collections_bookmark_outlined,
                        title: '내 컬렉션',
                        onTap: () => context.push(Routes.myCollections),
                      ),
                      _MenuTile(
                        icon: Icons.settings_outlined,
                        title: '설정',
                        onTap: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondaryDark),
      title: Text(title, style: const TextStyle(
          color: AppColors.textPrimaryDark, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(subtitle!, style: const TextStyle(
                  color: AppColors.textSecondaryDark, fontSize: 13)),
            ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
