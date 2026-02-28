/// 앱 전체에서 사용하는 Failure 클래스들
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// 네트워크 연결 없음
final class NetworkFailure extends Failure {
  const NetworkFailure([String message = '인터넷 연결을 확인해주세요.']) : super(message);
}

/// API 서버 오류
final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([String message = '서버 오류가 발생했습니다.', this.statusCode])
      : super(message);
}

/// 인증 오류
final class AuthFailure extends Failure {
  const AuthFailure([String message = '로그인이 필요합니다.']) : super(message);
}

/// 리소스 없음
final class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = '요청한 항목을 찾을 수 없습니다.']) : super(message);
}

/// 캐시 오류
final class CacheFailure extends Failure {
  const CacheFailure([String message = '데이터를 불러오는 중 오류가 발생했습니다.']) : super(message);
}

/// 예상치 못한 오류
final class UnknownFailure extends Failure {
  const UnknownFailure([String message = '알 수 없는 오류가 발생했습니다.']) : super(message);
}
