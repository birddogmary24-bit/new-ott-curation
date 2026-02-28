import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OnboardingState {
  final Set<String> selectedGenres;
  final Set<String> selectedPlatforms;
  final Map<String, double> ratings; // contentId -> rating
  final bool isSubmitting;
  final String? error;

  const OnboardingState({
    this.selectedGenres = const {},
    this.selectedPlatforms = const {},
    this.ratings = const {},
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    Set<String>? selectedGenres,
    Set<String>? selectedPlatforms,
    Map<String, double>? ratings,
    bool? isSubmitting,
    String? error,
  }) {
    return OnboardingState(
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
      ratings: ratings ?? this.ratings,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }

  bool get canProceedGenre => selectedGenres.length >= 3;
  bool get canProceedOtt => selectedPlatforms.isNotEmpty;
  bool get canSubmit => ratings.length >= 3;
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref),
);

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState());

  void toggleGenre(String genreId) {
    final genres = Set<String>.from(state.selectedGenres);
    if (genres.contains(genreId)) {
      genres.remove(genreId);
    } else {
      genres.add(genreId);
    }
    state = state.copyWith(selectedGenres: genres);
  }

  void togglePlatform(String platformId) {
    final platforms = Set<String>.from(state.selectedPlatforms);
    if (platforms.contains(platformId)) {
      platforms.remove(platformId);
    } else {
      platforms.add(platformId);
    }
    state = state.copyWith(selectedPlatforms: platforms);
  }

  void setRating(String contentId, double rating) {
    final ratings = Map<String, double>.from(state.ratings);
    if (rating == 0) {
      ratings.remove(contentId);
    } else {
      ratings[contentId] = rating;
    }
    state = state.copyWith(ratings: ratings);
  }

  Future<bool> submitOnboarding() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final ratingsList = state.ratings.entries
          .map((e) => {'content_id': e.key, 'rating': e.value})
          .toList();

      await _ref.read(authNotifierProvider.notifier).completeOnboarding(
        genres: state.selectedGenres.toList(),
        platforms: state.selectedPlatforms.toList(),
        ratings: ratingsList,
      );

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: '온보딩 완료 중 오류가 발생했어요.',
      );
      return false;
    }
  }
}
