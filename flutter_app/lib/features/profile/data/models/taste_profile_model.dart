import '../../domain/entities/taste_profile.dart';

class TasteProfileModel extends TasteProfile {
  const TasteProfileModel({
    required super.genreDistribution,
    super.totalRatings,
    super.totalReviews,
    super.totalCollections,
    super.avgRating,
    super.topGenre,
  });

  factory TasteProfileModel.fromJson(Map<String, dynamic> json) {
    final genreRaw = json['genre_distribution'] as Map<String, dynamic>? ?? {};
    final genreDistribution = genreRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return TasteProfileModel(
      genreDistribution: genreDistribution,
      totalRatings:     json['total_ratings'] as int? ?? 0,
      totalReviews:     json['total_reviews'] as int? ?? 0,
      totalCollections: json['total_collections'] as int? ?? 0,
      avgRating:        (json['avg_rating'] as num?)?.toDouble() ?? 0,
      topGenre:         json['top_genre'] as String?,
    );
  }
}
