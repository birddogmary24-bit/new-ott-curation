class CollectionSummary {
  final String id;
  final String title;
  final String? description;
  final String? coverPosterUrl;
  final int itemCount;
  final int likeCount;
  final String creatorNickname;

  const CollectionSummary({
    required this.id,
    required this.title,
    this.description,
    this.coverPosterUrl,
    this.itemCount = 0,
    this.likeCount = 0,
    required this.creatorNickname,
  });
}
