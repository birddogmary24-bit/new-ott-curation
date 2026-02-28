/// 앱 사용자 도메인 엔티티
class AppUser {
  final String id;              // DB profiles.id (UUID)
  final String firebaseUid;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final List<String> preferredGenres;
  final List<String> preferredPlatforms;
  final bool onboardingCompleted;
  final int totalRatings;
  final int totalReviews;

  const AppUser({
    required this.id,
    required this.firebaseUid,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    required this.preferredGenres,
    required this.preferredPlatforms,
    required this.onboardingCompleted,
    this.totalRatings = 0,
    this.totalReviews = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:                   json['id'] as String,
      firebaseUid:          json['firebase_uid'] as String,
      nickname:             json['nickname'] as String? ?? '익명',
      avatarUrl:            json['avatar_url'] as String?,
      bio:                  json['bio'] as String?,
      preferredGenres:      List<String>.from(json['preferred_genres'] as List? ?? []),
      preferredPlatforms:   List<String>.from(json['preferred_platforms'] as List? ?? []),
      onboardingCompleted:  json['onboarding_completed'] as bool? ?? false,
      totalRatings:         json['total_ratings'] as int? ?? 0,
      totalReviews:         json['total_reviews'] as int? ?? 0,
    );
  }

  AppUser copyWith({
    String? nickname,
    String? avatarUrl,
    String? bio,
    List<String>? preferredGenres,
    List<String>? preferredPlatforms,
    bool? onboardingCompleted,
    int? totalRatings,
    int? totalReviews,
  }) {
    return AppUser(
      id:                   id,
      firebaseUid:          firebaseUid,
      nickname:             nickname ?? this.nickname,
      avatarUrl:            avatarUrl ?? this.avatarUrl,
      bio:                  bio ?? this.bio,
      preferredGenres:      preferredGenres ?? this.preferredGenres,
      preferredPlatforms:   preferredPlatforms ?? this.preferredPlatforms,
      onboardingCompleted:  onboardingCompleted ?? this.onboardingCompleted,
      totalRatings:         totalRatings ?? this.totalRatings,
      totalReviews:         totalReviews ?? this.totalReviews,
    );
  }
}
