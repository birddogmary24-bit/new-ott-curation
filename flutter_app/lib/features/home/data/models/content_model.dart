import '../../domain/entities/content.dart';

class OttAvailabilityModel extends OttAvailability {
  const OttAvailabilityModel({
    required super.platformId,
    required super.type,
    super.price,
    super.quality,
    super.deepLinkUrl,
  });

  factory OttAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return OttAvailabilityModel(
      platformId: json['platform_id'] as String? ?? '',
      type: json['type'] as String? ?? 'flatrate',
      price: (json['price'] as num?)?.toDouble(),
      quality: json['quality'] as String?,
      deepLinkUrl: json['deep_link_url'] as String?,
    );
  }
}

class ContentModel extends Content {
  const ContentModel({
    required super.id,
    super.tmdbId,
    required super.contentType,
    required super.titleKo,
    super.titleEn,
    super.titleOriginal,
    super.overview,
    super.posterUrl,
    super.backdropUrl,
    super.releaseDate,
    super.runtime,
    super.genres,
    super.moodTags,
    super.tmdbRating,
    super.ourAvgRating,
    super.totalRatings,
    super.availability,
    super.userRating,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    // availability 파싱: JSON aggregate 또는 배열
    List<OttAvailabilityModel> availList = [];
    final rawAvail = json['availability'];
    if (rawAvail is List) {
      availList = rawAvail
          .whereType<Map<String, dynamic>>()
          .map(OttAvailabilityModel.fromJson)
          .toList();
    }

    // genres: String[] 또는 JSON array
    List<String> parseStringList(dynamic value) {
      if (value is List) return value.cast<String>();
      if (value is String && value.startsWith('{')) {
        // PostgreSQL array literal "{a,b,c}"
        return value
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    return ContentModel(
      id: json['id'] as String,
      tmdbId: json['tmdb_id']?.toString(),
      contentType: json['content_type'] as String? ?? 'movie',
      titleKo: json['title_ko'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      titleOriginal: json['title_original'] as String?,
      overview: json['overview'] as String?,
      posterUrl: json['poster_url'] as String?,
      backdropUrl: json['backdrop_url'] as String?,
      releaseDate: json['release_date'] as String?,
      runtime: json['runtime'] as int?,
      genres: parseStringList(json['genres']),
      moodTags: parseStringList(json['mood_tags']),
      tmdbRating: (json['tmdb_rating'] as num?)?.toDouble(),
      ourAvgRating: (json['our_avg_rating'] as num?)?.toDouble(),
      totalRatings: json['total_ratings'] as int? ?? 0,
      availability: availList,
      userRating: (json['user_rating'] as num?)?.toDouble(),
    );
  }
}
