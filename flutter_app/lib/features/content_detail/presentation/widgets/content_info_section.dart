import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/widgets/star_rating_bar.dart';
import '../../../home/domain/entities/content.dart';

class ContentInfoSection extends StatelessWidget {
  final Content content;
  final double? userRating;
  final ValueChanged<double>? onRatingChanged;

  const ContentInfoSection({
    super.key,
    required this.content,
    this.userRating,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 기본 정보
        Row(
          children: [
            if (content.releaseYear != null)
              _InfoChip(content.releaseYear.toString()),
            if (content.runtime != null) ...[
              const SizedBox(width: 6),
              _InfoChip('${content.runtime}분'),
            ],
            if (content.contentType == 'tv') ...[
              const SizedBox(width: 6),
              const _InfoChip('TV 시리즈'),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // 장르 칩
        if (content.genres.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: content.genres.map((g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface2Dark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(g, style: const TextStyle(
                  color: AppColors.textSecondaryDark, fontSize: 12)),
            )).toList(),
          ),
        const SizedBox(height: 20),

        // 평점 섹션
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('내 평점', style: TextStyle(
                  color: AppColors.textSecondaryDark, fontSize: 13)),
              const SizedBox(height: 8),
              StarRatingBar(
                rating: userRating ?? 0,
                onRatingChanged: onRatingChanged,
                starSize: 36,
                showLabel: true,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 14,
                      color: AppColors.textSecondaryDark),
                  const SizedBox(width: 4),
                  Text(
                    '커뮤니티 평균 ${content.displayRating}',
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 12),
                  ),
                  if (content.totalRatings > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${content.totalRatings}명)',
                      style: const TextStyle(
                          color: AppColors.textSecondaryDark, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 줄거리
        if (content.overview != null && content.overview!.isNotEmpty) ...[
          const Text('줄거리', style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _ExpandableText(text: content.overview!),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface2Dark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(
          color: AppColors.textSecondaryDark, fontSize: 12)),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: const TextStyle(color: AppColors.textSecondaryDark,
              fontSize: 14, height: 1.6),
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 100)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? '접기' : '더보기',
                style: const TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}
