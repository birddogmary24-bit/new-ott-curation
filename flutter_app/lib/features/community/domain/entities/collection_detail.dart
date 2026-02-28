import '../../../home/domain/entities/content.dart';

class CollectionDetail {
  final String id;
  final String title;
  final String? description;
  final String creatorNickname;
  final String? creatorAvatarUrl;
  final int likeCount;
  final List<Content> items;
  final DateTime createdAt;

  const CollectionDetail({
    required this.id,
    required this.title,
    this.description,
    required this.creatorNickname,
    this.creatorAvatarUrl,
    this.likeCount = 0,
    required this.items,
    required this.createdAt,
  });
}
