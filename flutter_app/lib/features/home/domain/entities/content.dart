import '../../../../core/constants/ott_platforms.dart';

class Content {
  final String id;
  final String? tmdbId;
  final String contentType; // 'movie' | 'tv'
  final String titleKo;
  final String? titleEn;
  final String? titleOriginal;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final String? releaseDate;
  final int? runtime;
  final List<String> genres;
  final List<String> moodTags;
  final double? tmdbRating;
  final double? ourAvgRating;
  final int totalRatings;
  final List<OttAvailability> availability;
  final double? userRating; // 현재 유저의 평점 (옵션)

  const Content({
    required this.id,
    this.tmdbId,
    required this.contentType,
    required this.titleKo,
    this.titleEn,
    this.titleOriginal,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.releaseDate,
    this.runtime,
    this.genres = const [],
    this.moodTags = const [],
    this.tmdbRating,
    this.ourAvgRating,
    this.totalRatings = 0,
    this.availability = const [],
    this.userRating,
  });

  /// 대표 OTT 플랫폼 (flatrate 우선)
  OttAvailability? get primaryAvailability {
    final flatrate = availability.where((a) => a.type == 'flatrate').toList();
    if (flatrate.isNotEmpty) return flatrate.first;
    if (availability.isNotEmpty) return availability.first;
    return null;
  }

  bool get isMovie => contentType == 'movie';
  bool get isTvShow => contentType == 'tv';

  String get displayRating {
    if (ourAvgRating != null && ourAvgRating! > 0) {
      return ourAvgRating!.toStringAsFixed(1);
    }
    if (tmdbRating != null) return tmdbRating!.toStringAsFixed(1);
    return '-';
  }

  int? get releaseYear {
    if (releaseDate == null) return null;
    return int.tryParse(releaseDate!.split('-').first);
  }
}

class OttAvailability {
  final String platformId;
  final String type; // flatrate, rent, buy, free, ads
  final double? price;
  final String? quality;
  final String? deepLinkUrl;

  const OttAvailability({
    required this.platformId,
    required this.type,
    this.price,
    this.quality,
    this.deepLinkUrl,
  });

  OttPlatform? get platform => OttPlatform.fromId(platformId);

  bool get isFlatrate => type == 'flatrate';
  bool get isFree => type == 'free' || type == 'ads';
}
