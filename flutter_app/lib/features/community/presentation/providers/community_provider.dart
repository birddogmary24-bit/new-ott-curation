import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../domain/entities/collection_summary.dart';
import '../../domain/entities/review.dart';

final communityDataSourceProvider = Provider<CommunityRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CommunityRemoteDataSource(dio);
});

/// 인기 리뷰
final popularReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final ds = ref.read(communityDataSourceProvider);
  return ds.getPopularReviews();
});

/// 공개 컬렉션
final publicCollectionsProvider = FutureProvider<List<CollectionSummary>>((ref) async {
  final ds = ref.read(communityDataSourceProvider);
  return ds.getCollections();
});
