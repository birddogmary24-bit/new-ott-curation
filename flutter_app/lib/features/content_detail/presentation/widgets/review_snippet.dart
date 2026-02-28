import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';

/// 콘텐츠 상세 화면 하단의 리뷰 스니펫 (1~2개 미리보기)
class ReviewSnippet extends StatelessWidget {
  final String contentId;

  const ReviewSnippet({super.key, required this.contentId});

  @override
  Widget build(BuildContext context) {
    // 실제 리뷰 로드는 커뮤니티 API 연동 후
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('리뷰', style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () {}, // TODO: 리뷰 전체 보기
              child: const Text('더보기', style: TextStyle(
                  color: AppColors.primary, fontSize: 13)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '아직 리뷰가 없어요. 첫 번째 리뷰를 남겨보세요!',
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
