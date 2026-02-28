import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../models/ai_content_model.dart';

class AiHallRemoteDataSource {
  final Dio _dio;

  const AiHallRemoteDataSource(this._dio);

  /// AI 콘텐츠 피드 (커서 기반 페이지네이션)
  Future<({List<AiContentModel> items, String? nextCursor})> getFeed({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        AppConfig.aiHallFeedUrl,
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final itemsJson = data['items'] as List<dynamic>? ?? [];
      final items = itemsJson
          .whereType<Map<String, dynamic>>()
          .map(AiContentModel.fromJson)
          .toList();

      return (
        items: items,
        nextCursor: data['next_cursor'] as String?,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// 좋아요 토글
  Future<({bool isLiked, int likeCount})> toggleLike(String contentId) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/api/ai-hall/$contentId/like',
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return (
        isLiked: data['liked'] as bool? ?? false,
        likeCount: data['like_count'] as int? ?? 0,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// 업로드 준비 (signed URL 발급)
  Future<({String contentId, String videoUploadUrl, String? thumbnailUploadUrl})>
      prepareUpload({
    required String title,
    required String contentType,
    required int durationSeconds,
    required List<String> tags,
    String? aiToolUsed,
  }) async {
    try {
      final response = await _dio.post(
        AppConfig.aiHallUploadUrl,
        data: {
          'title': title,
          'content_type': contentType,
          'duration_seconds': durationSeconds,
          'tags': tags,
          if (aiToolUsed != null) 'ai_tool_used': aiToolUsed,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return (
        contentId: data['content_id'] as String,
        videoUploadUrl: data['video_upload_url'] as String,
        thumbnailUploadUrl: data['thumbnail_upload_url'] as String?,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// 업로드 완료 알림
  Future<void> completeUpload(String contentId) async {
    try {
      await _dio.post(
        '${AppConfig.apiBaseUrl}/api/ai-hall/$contentId/upload-complete',
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  void _handleError(DioException e) {
    if (e.response?.statusCode == 401) throw const AuthFailure('로그인이 필요해요.');
    if (e.response?.statusCode == 403) throw const AuthFailure('권한이 없어요.');
    if (e.response?.statusCode == 413) throw const ServerFailure('파일 크기가 너무 커요 (최대 500MB).');
    throw const ServerFailure('AI 콘텐츠 서비스 오류가 발생했어요.');
  }
}
