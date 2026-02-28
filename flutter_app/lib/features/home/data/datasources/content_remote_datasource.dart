import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../models/content_model.dart';
import '../models/curation_section_model.dart';

class ContentRemoteDataSource {
  final Dio _dio;

  const ContentRemoteDataSource(this._dio);

  /// 홈 큐레이션 섹션 목록 가져오기
  Future<List<CurationSectionModel>> getHomeSections() async {
    try {
      final response = await _dio.get(AppConfig.curationsHomeUrl);
      final List<dynamic> sections = response.data['data'] as List<dynamic>? ?? [];
      return sections
          .whereType<Map<String, dynamic>>()
          .map(CurationSectionModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 콘텐츠 목록 (필터링)
  Future<({List<ContentModel> items, bool hasMore})> getContents({
    String? platformId,
    String? genre,
    String? contentType,
    String sort = 'rating',
    int page = 1,
    int limit = AppConfig.pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'sort': sort,
        'page': page,
        'limit': limit,
        if (platformId != null) 'platform': platformId,
        if (genre != null) 'genre': genre,
        if (contentType != null) 'type': contentType,
      };

      final response = await _dio.get(
        AppConfig.contentsUrl,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      final List<dynamic> items = data?['items'] as List<dynamic>? ?? [];
      final hasMore = data?['has_more'] as bool? ?? false;

      return (
        items: items
            .whereType<Map<String, dynamic>>()
            .map(ContentModel.fromJson)
            .toList(),
        hasMore: hasMore,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 콘텐츠 상세
  Future<ContentModel> getContentDetail(String contentId) async {
    try {
      final response = await _dio.get('${AppConfig.contentsUrl}/$contentId');
      return ContentModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 검색
  Future<List<ContentModel>> searchContents({
    required String query,
    String? platformId,
    String? genre,
    String? contentType,
    int page = 1,
    int limit = AppConfig.pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
        if (platformId != null) 'platform': platformId,
        if (genre != null) 'genre': genre,
        if (contentType != null) 'type': contentType,
      };

      final response = await _dio.get(
        AppConfig.contentSearchUrl,
        queryParameters: queryParams,
      );

      final List<dynamic> items = response.data['data'] as List<dynamic>? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ContentModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure('연결 시간이 초과됐어요. 네트워크를 확인해주세요.');
    }
    if (e.response?.statusCode == 401) {
      return const AuthFailure('로그인이 필요해요.');
    }
    if (e.response?.statusCode == 404) {
      return const NotFoundFailure('콘텐츠를 찾을 수 없어요.');
    }
    if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
      return const ServerFailure('서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.');
    }
    return NetworkFailure(e.message ?? '알 수 없는 오류가 발생했어요.');
  }
}
