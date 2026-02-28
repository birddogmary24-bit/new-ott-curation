enum AiContentType {
  shortVideo,
  clip,
  trailerRemix,
  highlight,
  fanEdit;

  String get displayName => switch (this) {
    AiContentType.shortVideo    => '숏폼',
    AiContentType.clip          => '클립',
    AiContentType.trailerRemix  => '트레일러 리믹스',
    AiContentType.highlight     => '하이라이트',
    AiContentType.fanEdit       => '팬 에디트',
  };

  static AiContentType fromString(String value) {
    return switch (value) {
      'short_video'   => AiContentType.shortVideo,
      'clip'          => AiContentType.clip,
      'trailer_remix' => AiContentType.trailerRemix,
      'highlight'     => AiContentType.highlight,
      'fan_edit'      => AiContentType.fanEdit,
      _               => AiContentType.shortVideo,
    };
  }
}

class AiContent {
  final String id;
  final String? title;
  final AiContentType contentType;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? aiToolUsed;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isLikedByMe;
  final DateTime createdAt;

  // 작성자 정보
  final String? authorId;
  final String? authorNickname;
  final String? authorAvatarUrl;

  const AiContent({
    required this.id,
    this.title,
    required this.contentType,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    this.aiToolUsed,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.isLikedByMe = false,
    required this.createdAt,
    this.authorId,
    this.authorNickname,
    this.authorAvatarUrl,
  });

  String get formattedDuration {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    if (mins > 0) return '$mins:${secs.toString().padLeft(2, '0')}';
    return '${secs}s';
  }

  AiContent copyWith({bool? isLikedByMe, int? likeCount}) {
    return AiContent(
      id: id,
      title: title,
      contentType: contentType,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      aiToolUsed: aiToolUsed,
      tags: tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      viewCount: viewCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt,
      authorId: authorId,
      authorNickname: authorNickname,
      authorAvatarUrl: authorAvatarUrl,
    );
  }
}
