import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

enum OttPlatform {
  netflix,
  tving,
  coupangPlay,
  wavve,
  watcha;

  String get id => switch (this) {
    OttPlatform.netflix     => 'netflix',
    OttPlatform.tving       => 'tving',
    OttPlatform.coupangPlay => 'coupang_play',
    OttPlatform.wavve       => 'wavve',
    OttPlatform.watcha      => 'watcha',
  };

  String get nameKo => switch (this) {
    OttPlatform.netflix     => '넷플릭스',
    OttPlatform.tving       => '티빙',
    OttPlatform.coupangPlay => '쿠팡플레이',
    OttPlatform.wavve       => '웨이브',
    OttPlatform.watcha      => '왓챠',
  };

  Color get color => switch (this) {
    OttPlatform.netflix     => AppColors.netflix,
    OttPlatform.tving       => AppColors.tving,
    OttPlatform.coupangPlay => AppColors.coupangPlay,
    OttPlatform.wavve       => AppColors.wavve,
    OttPlatform.watcha      => AppColors.watcha,
  };

  String get logoAsset => 'assets/images/ott_logos/${id}.png';

  static OttPlatform? fromId(String id) {
    return OttPlatform.values.where((p) => p.id == id).firstOrNull;
  }

  static List<OttPlatform> get all => OttPlatform.values;
}
