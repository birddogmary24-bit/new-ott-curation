import '../../domain/entities/ai_content.dart';

class AiContentModel extends AiContent {
  const AiContentModel({
    required super.id,
    super.title,
    required super.contentType,
    required super.videoUrl,
    super.thumbnailUrl,
    required super.durationSeconds,
    super.aiToolUsed,
    super.tags,
    super.likeCount,
    super.commentCount,
    super.viewCount,
    super.isLikedByMe,
    required super.createdAt,
    super.authorId,
    super.authorNickname,
    super.authorAvatarUrl,
  });

  factory AiContentModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value is List) return value.cast<String>();
      if (value is String && value.startsWith('{')) {
        return value.replaceAll('{', '').replaceAll('}', '')
            .split(',').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return AiContentModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      contentType: AiContentType.fromString(json['content_type'] as String? ?? 'short_video'),
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 30,
      aiToolUsed: json['ai_tool_used'] as String?,
      tags: parseStringList(json['tags']),
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      authorId: json['author_id'] as String?,
      authorNickname: json['author_nickname'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
    );
  }
}
