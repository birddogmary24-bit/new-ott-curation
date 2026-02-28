import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/data/models/content_model.dart';
import '../../domain/entities/collection_detail.dart';
import 'community_provider.dart';

final collectionDetailProvider =
    FutureProvider.family<CollectionDetail, String>((ref, collectionId) async {
  final ds = ref.read(communityDataSourceProvider);
  final data = await ds.getCollectionDetail(collectionId);

  final itemsJson = data['items'] as List<dynamic>? ?? [];
  final items = itemsJson
      .whereType<Map<String, dynamic>>()
      .map(ContentModel.fromJson)
      .toList();

  return CollectionDetail(
    id: data['id'] as String? ?? collectionId,
    title: data['title'] as String? ?? '',
    description: data['description'] as String?,
    creatorNickname: data['creator_nickname'] as String? ?? '익명',
    creatorAvatarUrl: data['creator_avatar_url'] as String?,
    likeCount: data['like_count'] as int? ?? 0,
    items: items,
    createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
  );
});
