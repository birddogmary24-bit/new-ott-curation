import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.contentId,
    required super.userId,
    required super.nickname,
    super.avatarUrl,
    required super.rating,
    required super.text,
    super.spoiler,
    super.likeCount,
    super.contentTitle,
    super.contentPosterUrl,
    required super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id:               json['id'] as String,
      contentId:        json['content_id'] as String? ?? '',
      userId:           json['user_id'] as String? ?? '',
      nickname:         json['nickname'] as String? ?? '익명',
      avatarUrl:        json['avatar_url'] as String?,
      rating:           (json['rating'] as num?)?.toDouble() ?? 0,
      text:             json['text'] as String? ?? '',
      spoiler:          json['spoiler'] as bool? ?? false,
      likeCount:        json['like_count'] as int? ?? 0,
      contentTitle:     json['content_title'] as String?,
      contentPosterUrl: json['content_poster_url'] as String?,
      createdAt:        DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
