import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../models/collection_model.dart';
import '../models/review_model.dart';

class CommunityRemoteDataSource {
  final Dio _dio;

  const CommunityRemoteDataSource(this._dio);

  /// 인기 리뷰 목록
  Future<List<ReviewModel>> getPopularReviews({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      '${AppConfig.apiBaseUrl}/api/community/reviews',
      queryParameters: {'page': page, 'limit': limit, 'sort': 'popular'},
    );
    final items = response.data['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList();
  }

  /// 콘텐츠별 리뷰
  Future<List<ReviewModel>> getContentReviews(String contentId, {int page = 1}) async {
    final response = await _dio.get(
      '${AppConfig.apiBaseUrl}/api/community/reviews/$contentId',
      queryParameters: {'page': page},
    );
    final items = response.data['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList();
  }

  /// 공개 컬렉션 목록
  Future<List<CollectionModel>> getCollections({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      '${AppConfig.apiBaseUrl}/api/community/collections',
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = response.data['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CollectionModel.fromJson)
        .toList();
  }

  /// 컬렉션 상세 (콘텐츠 목록 포함)
  Future<Map<String, dynamic>> getCollectionDetail(String collectionId) async {
    final response = await _dio.get(
      '${AppConfig.apiBaseUrl}/api/community/collections/$collectionId',
    );
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }
}
