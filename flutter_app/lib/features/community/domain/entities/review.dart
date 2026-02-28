class Review {
  final String id;
  final String contentId;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final double rating;
  final String text;
  final bool spoiler;
  final int likeCount;
  final String? contentTitle;
  final String? contentPosterUrl;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.contentId,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.rating,
    required this.text,
    this.spoiler = false,
    this.likeCount = 0,
    this.contentTitle,
    this.contentPosterUrl,
    required this.createdAt,
  });
}
