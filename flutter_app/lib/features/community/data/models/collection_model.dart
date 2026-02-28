import '../../domain/entities/collection_summary.dart';

class CollectionModel extends CollectionSummary {
  const CollectionModel({
    required super.id,
    required super.title,
    super.description,
    super.coverPosterUrl,
    super.itemCount,
    super.likeCount,
    required super.creatorNickname,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id:               json['id'] as String,
      title:            json['title'] as String? ?? '',
      description:      json['description'] as String?,
      coverPosterUrl:   json['cover_poster_url'] as String?,
      itemCount:        json['item_count'] as int? ?? 0,
      likeCount:        json['like_count'] as int? ?? 0,
      creatorNickname:  json['creator_nickname'] as String? ?? '익명',
    );
  }
}
