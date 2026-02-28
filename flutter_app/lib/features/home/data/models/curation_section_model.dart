import '../../domain/entities/curation_section.dart';
import 'content_model.dart';

class CurationSectionModel extends CurationSection {
  const CurationSectionModel({
    required super.id,
    required super.sectionType,
    required super.titleKo,
    super.aiReason,
    required super.contents,
    super.isPersonalized,
    super.expiresAt,
  });

  factory CurationSectionModel.fromJson(Map<String, dynamic> json) {
    final contentsJson = json['contents'] as List<dynamic>? ?? [];
    final contents = contentsJson
        .whereType<Map<String, dynamic>>()
        .map(ContentModel.fromJson)
        .toList();

    return CurationSectionModel(
      id: json['id'] as String? ?? '',
      sectionType: SectionType.fromString(json['section_type'] as String? ?? 'custom'),
      titleKo: json['title_ko'] as String? ?? '',
      aiReason: json['ai_reason'] as String?,
      contents: contents,
      isPersonalized: json['target_user_id'] != null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }
}
