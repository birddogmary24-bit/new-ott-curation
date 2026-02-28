class TasteProfile {
  final Map<String, double> genreDistribution; // genre -> ratio (0~1)
  final int totalRatings;
  final int totalReviews;
  final int totalCollections;
  final double avgRating;
  final String? topGenre;

  const TasteProfile({
    required this.genreDistribution,
    this.totalRatings = 0,
    this.totalReviews = 0,
    this.totalCollections = 0,
    this.avgRating = 0,
    this.topGenre,
  });
}
