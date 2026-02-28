import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/entities/review.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback? onTap;

  const ReviewCard({super.key, required this.review, this.onTap});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _spoilerRevealed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 프로필 + 별점
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surface2Dark,
                  backgroundImage: r.avatarUrl != null
                      ? CachedNetworkImageProvider(r.avatarUrl!)
                      : null,
                  child: r.avatarUrl == null
                      ? Text(r.nickname.isNotEmpty ? r.nickname[0] : '?',
                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.nickname, style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                // 별점
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.starActive),
                    const SizedBox(width: 2),
                    Text(r.rating.toStringAsFixed(1), style: const TextStyle(
                        color: AppColors.starActive, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 콘텐츠 정보
            if (r.contentTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    if (r.contentPosterUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: r.contentPosterUrl!,
                          width: 24, height: 34, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(r.contentTitle!, style: const TextStyle(
                          color: AppColors.textSecondaryDark, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // 리뷰 텍스트
            if (r.spoiler && !_spoilerRevealed)
              GestureDetector(
                onTap: () => setState(() => _spoilerRevealed = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_off, size: 14, color: AppColors.textSecondaryDark),
                      SizedBox(width: 6),
                      Text('스포일러 포함 - 탭하여 보기',
                          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              Text(r.text, style: const TextStyle(
                  color: AppColors.textPrimaryDark, fontSize: 13, height: 1.5),
                maxLines: 4, overflow: TextOverflow.ellipsis),

            const SizedBox(height: 8),

            // 하단 정보
            Row(
              children: [
                if (r.likeCount > 0) ...[
                  const Icon(Icons.thumb_up_outlined, size: 12, color: AppColors.textSecondaryDark),
                  const SizedBox(width: 4),
                  Text('${r.likeCount}', style: const TextStyle(
                      color: AppColors.textSecondaryDark, fontSize: 11)),
                  const SizedBox(width: 12),
                ],
                Text(_timeAgo(r.createdAt), style: const TextStyle(
                    color: AppColors.textSecondaryDark, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${dt.month}/${dt.day}';
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    return '방금 전';
  }
}
