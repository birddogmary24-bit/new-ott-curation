/// DB seed의 17개 장르 (genres 테이블과 동기화)
class GenreConstants {
  GenreConstants._();

  static const List<({String id, String nameKo, String emoji})> all = [
    (id: 'action',      nameKo: '액션',       emoji: '💥'),
    (id: 'adventure',   nameKo: '모험',       emoji: '🗺️'),
    (id: 'animation',   nameKo: '애니메이션', emoji: '🎨'),
    (id: 'comedy',      nameKo: '코미디',     emoji: '😂'),
    (id: 'crime',       nameKo: '범죄',       emoji: '🔍'),
    (id: 'documentary', nameKo: '다큐멘터리', emoji: '📹'),
    (id: 'drama',       nameKo: '드라마',     emoji: '🎭'),
    (id: 'family',      nameKo: '가족',       emoji: '👨‍👩‍👧‍👦'),
    (id: 'fantasy',     nameKo: '판타지',     emoji: '🧙'),
    (id: 'history',     nameKo: '역사',       emoji: '📜'),
    (id: 'horror',      nameKo: '공포',       emoji: '👻'),
    (id: 'music',       nameKo: '음악',       emoji: '🎵'),
    (id: 'mystery',     nameKo: '미스터리',   emoji: '🕵️'),
    (id: 'romance',     nameKo: '로맨스',     emoji: '💕'),
    (id: 'sf',          nameKo: 'SF',         emoji: '🚀'),
    (id: 'thriller',    nameKo: '스릴러',     emoji: '😱'),
    (id: 'war',         nameKo: '전쟁',       emoji: '⚔️'),
  ];
}
