import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/entities/content.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// 콘텐츠 상세 데이터
class ContentDetailData {
  final Content content;
  final List<Content> similar;
  final double? userRating;

  const ContentDetailData({
    required this.content,
    required this.similar,
    this.userRating,
  });
}

/// 콘텐츠 상세 프로바이더
final contentDetailProvider =
    FutureProvider.family<ContentDetailData, String>((ref, contentId) async {
  final ds = ref.read(contentDataSourceProvider);
  final result = await ds.getContentDetailFull(contentId);
  return ContentDetailData(
    content: result.content,
    similar: result.similar,
    userRating: result.userRating,
  );
});

/// 유저 평점 상태 (낙관적 업데이트용)
final userRatingProvider =
    StateNotifierProvider.family<UserRatingNotifier, double?, String>(
  (ref, contentId) => UserRatingNotifier(ref, contentId),
);

class UserRatingNotifier extends StateNotifier<double?> {
  final Ref _ref;
  final String _contentId;

  UserRatingNotifier(this._ref, this._contentId) : super(null) {
    // 초기값은 contentDetail에서 가져옴
    _ref.listen(contentDetailProvider(_contentId), (_, next) {
      next.whenData((data) {
        if (state == null) state = data.userRating;
      });
    });
  }

  Future<void> rate(double rating) async {
    final prev = state;
    state = rating; // 낙관적 업데이트
    try {
      final ds = _ref.read(contentDataSourceProvider);
      await ds.rateContent(_contentId, rating);
    } catch (_) {
      state = prev; // 롤백
    }
  }
}
