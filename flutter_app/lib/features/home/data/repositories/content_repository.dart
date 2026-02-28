import '../../domain/entities/content.dart';
import '../../domain/entities/curation_section.dart';

abstract class ContentRepository {
  Future<List<CurationSection>> getHomeSections();

  Future<({List<Content> items, bool hasMore})> getContents({
    String? platformId,
    String? genre,
    String? contentType,
    String sort,
    int page,
  });

  Future<Content> getContentDetail(String contentId);

  Future<List<Content>> searchContents({
    required String query,
    String? platformId,
    String? genre,
    String? contentType,
    int page,
  });
}
