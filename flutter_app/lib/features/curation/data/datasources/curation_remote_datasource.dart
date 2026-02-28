import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/data/models/content_model.dart';

class CurationChatResponse {
  final String message;
  final List<ContentModel> contents;
  final String? curatingReason;

  const CurationChatResponse({
    required this.message,
    required this.contents,
    this.curatingReason,
  });
}

class CurationRemoteDataSource {
  final Dio _dio;

  const CurationRemoteDataSource(this._dio);

  /// 자연어 큐레이션 요청
  Future<CurationChatResponse> chat(String query) async {
    try {
      final response = await _dio.post(
        AppConfig.curationsChatUrl,
        data: {'query': query},
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final contentsJson = data['contents'] as List<dynamic>? ?? [];

      final contents = contentsJson
          .whereType<Map<String, dynamic>>()
          .map(ContentModel.fromJson)
          .toList();

      return CurationChatResponse(
        message: data['message'] as String? ?? '',
        contents: contents,
        curatingReason: data['curating_reason'] as String?,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkFailure('응답 시간이 초과됐어요. 다시 시도해주세요.');
      }
      if (e.response?.statusCode == 401) throw const AuthFailure('로그인이 필요해요.');
      throw const ServerFailure('AI 큐레이션 서비스에 일시적인 오류가 있어요. 잠시 후 다시 시도해주세요.');
    }
  }

  /// 취향 프로필 조회
  Future<Map<String, dynamic>> getTasteProfile() async {
    try {
      final response = await _dio.get('${AppConfig.apiBaseUrl}/api/curations/taste-profile');
      return response.data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const AuthFailure('로그인이 필요해요.');
      throw const ServerFailure('취향 프로필을 불러오지 못했어요.');
    }
  }
}
