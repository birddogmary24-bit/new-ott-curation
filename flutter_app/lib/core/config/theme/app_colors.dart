import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 브랜드 컬러
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color primary       = Color(0xFF6C63FF);  // 보라색 (메인)
  static const Color primaryDark   = Color(0xFF5147D9);
  static const Color primaryLight  = Color(0xFF8F88FF);
  static const Color accent        = Color(0xFFFF6584);  // 핑크 (AI Hall 강조)

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 배경
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color backgroundDark  = Color(0xFF0A0A0F);  // 거의 검정
  static const Color surfaceDark     = Color(0xFF141419);  // 카드 배경
  static const Color surface2Dark    = Color(0xFF1E1E27);  // 레이어 2
  static const Color backgroundLight = Color(0xFFF5F5F8);
  static const Color surfaceLight    = Color(0xFFFFFFFF);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 텍스트
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color textPrimaryDark   = Color(0xFFEEEEF5);
  static const Color textSecondaryDark = Color(0xFF9898B0);
  static const Color textPrimaryLight  = Color(0xFF1A1A2E);
  static const Color textSecondaryLight= Color(0xFF6B6B8A);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // OTT 플랫폼 브랜드 컬러
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color netflix      = Color(0xFFE50914);
  static const Color tving        = Color(0xFFFF153C);
  static const Color coupangPlay  = Color(0xFFC00C3F);
  static const Color wavve        = Color(0xFF1155CC);
  static const Color watcha       = Color(0xFFFF0558);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 별점
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color starActive   = Color(0xFFFFD700);
  static const Color starColor    = Color(0xFFFFD700);  // starActive alias
  static const Color starInactive = Color(0xFF404055);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 상태
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color success  = Color(0xFF4CAF50);
  static const Color error    = Color(0xFFEF5350);
  static const Color warning  = Color(0xFFFFB300);
  static const Color info     = Color(0xFF42A5F5);

  // 구분선
  static const Color dividerDark  = Color(0xFF2A2A38);
  static const Color dividerLight = Color(0xFFE0E0EA);

  static Color ottColor(String platformId) {
    return switch (platformId) {
      'netflix'      => netflix,
      'tving'        => tving,
      'coupang_play' => coupangPlay,
      'wavve'        => wavve,
      'watcha'       => watcha,
      _              => primary,
    };
  }
}
