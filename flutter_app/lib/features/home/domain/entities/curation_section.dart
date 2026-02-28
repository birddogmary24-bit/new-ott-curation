import 'content.dart';

enum SectionType {
  trending,
  newArrivals,
  personalizedRecommendations,
  genre,
  platform,
  mood,
  topRated,
  custom;

  String get displayName {
    switch (this) {
      case SectionType.trending:        return '지금 뜨는 콘텐츠';
      case SectionType.newArrivals:     return '새로 올라왔어요';
      case SectionType.personalizedRecommendations: return '회원님을 위한 추천';
      case SectionType.genre:           return '장르별 추천';
      case SectionType.platform:        return 'OTT별 콘텐츠';
      case SectionType.mood:            return '무드별 추천';
      case SectionType.topRated:        return '평점 높은 작품';
      case SectionType.custom:          return '큐레이션';
    }
  }

  static SectionType fromString(String value) {
    return SectionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SectionType.custom,
    );
  }
}

class CurationSection {
  final String id;
  final SectionType sectionType;
  final String titleKo;
  final String? aiReason;
  final List<Content> contents;
  final bool isPersonalized;
  final DateTime? expiresAt;

  const CurationSection({
    required this.id,
    required this.sectionType,
    required this.titleKo,
    this.aiReason,
    required this.contents,
    this.isPersonalized = false,
    this.expiresAt,
  });

  bool get hasContents => contents.isNotEmpty;
  bool get isHeroSection => sectionType == SectionType.trending;
}
