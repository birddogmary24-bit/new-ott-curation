import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../models/taste_profile_model.dart';

class ProfileRemoteDataSource {
  final Dio _dio;

  const ProfileRemoteDataSource(this._dio);

  /// 취향 프로필
  Future<TasteProfileModel> getTasteProfile() async {
    final response = await _dio.get('${AppConfig.apiBaseUrl}/api/curations/taste-profile');
    return TasteProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>? ?? {},
    );
  }

  /// 프로필 수정
  Future<void> updateProfile({
    String? nickname,
    String? bio,
    List<String>? preferredGenres,
    List<String>? preferredPlatforms,
  }) async {
    await _dio.put('${AppConfig.apiBaseUrl}/api/users/profile', data: {
      if (nickname != null) 'nickname': nickname,
      if (bio != null) 'bio': bio,
      if (preferredGenres != null) 'preferred_genres': preferredGenres,
      if (preferredPlatforms != null) 'preferred_platforms': preferredPlatforms,
    });
  }

  /// 내 평점 목록
  Future<({List<Map<String, dynamic>> items, bool hasMore})> getMyRatings({
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _dio.get(
      '${AppConfig.apiBaseUrl}/api/users/ratings',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final hasMore = data['has_more'] as bool? ?? false;
    return (items: items, hasMore: hasMore);
  }
}
