/// 앱 전체 설정값
/// GCP setup.sh 실행 후 API_BASE_URL을 실제 Cloud Run URL로 변경하세요
class AppConfig {
  AppConfig._();

  // Cloud Run API URL (setup.sh 실행 후 자동으로 출력됨)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',  // 로컬 개발 시
  );

  // 앱 정보
  static const String appName = 'OTT 큐레이션';
  static const String appVersion = '1.0.0';

  // API 엔드포인트
  static const String contentsEndpoint  = '/api/contents';
  static const String curationsEndpoint = '/api/curations';
  static const String aiHallEndpoint    = '/api/ai-hall';
  static const String communityEndpoint = '/api/community';
  static const String usersEndpoint     = '/api/users';

  // 전체 URL (데이터소스에서 사용)
  static String get contentsUrl       => '$apiBaseUrl$contentsEndpoint';
  static String get contentSearchUrl  => '$apiBaseUrl$contentsEndpoint/search';
  static String get curationsHomeUrl  => '$apiBaseUrl$curationsEndpoint/home';
  static String get curationsChatUrl  => '$apiBaseUrl$curationsEndpoint/chat';
  static String get aiHallFeedUrl     => '$apiBaseUrl$aiHallEndpoint/feed';
  static String get aiHallUploadUrl   => '$apiBaseUrl$aiHallEndpoint/upload';

  // 페이지네이션 기본값
  static const int defaultPageLimit = 20;
  static const int aiHallPageLimit  = 20;
  static const int pageSize         = 20;

  // 캐시 만료 시간
  static const Duration contentCacheDuration   = Duration(hours: 6);
  static const Duration curationCacheDuration  = Duration(hours: 1);
  static const Duration profileCacheDuration   = Duration(minutes: 30);

  // 영상 업로드 제한
  static const int maxVideoDurationSeconds = 60;
  static const int maxVideoSizeMb          = 500;   // 업로드 전 압축
  static const int targetVideoSizeMb       = 50;    // 압축 후 목표
}
