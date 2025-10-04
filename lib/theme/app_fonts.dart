import 'package:flutter/material.dart';
import 'package:frontend/utils/size_utils.dart';

class AppFonts {
  static const String suiteFontFamily = 'SUITE';
  static const String pretendardFontFamily = 'Pretendard';

  // SUITE 폰트
  static final suite = _SuiteFonts();
  // Pretendard 폰트
  static final pretendard = _PretendardFonts();
}

class _SuiteFonts {
  static const String _fontFamily = AppFonts.suiteFontFamily;

  // Headers
  TextStyle h1_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(28),
    height: 1.0,
    letterSpacing: -0.84,
  );

  TextStyle h3_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(24),
    height: 1.0,
    letterSpacing: -0.72,
  );


  TextStyle h3_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(24),
    height: 1.0,
    letterSpacing: -0.72,
  );

  TextStyle h4_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(22),
    height: 1.0,
    letterSpacing: -0.66,
  );

  TextStyle h5_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(20),
    height: 1.0,
    letterSpacing: -0.6,
  );

  TextStyle h5_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(20),
    height: 1.0,
    letterSpacing: -0.6,
  );

  // Body
  TextStyle b1_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(18),
    height: 1.0,
    letterSpacing: -0.54,
  );

  TextStyle b1_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(18),
    height: 1.0,
    letterSpacing: -0.54,
  );

  TextStyle b2_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(16),
    height: 1.0,
    letterSpacing: -0.48,
  );

  TextStyle b2_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 1.0,
    letterSpacing: -0.48,
  );

  TextStyle b2_m_long(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 1.6,
    letterSpacing: -0.48,
  );

  TextStyle b3_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  TextStyle b3_sb_long(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14),
    height: 1.6,
    letterSpacing: -0.42,
  );

  TextStyle b3_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  TextStyle b3_r(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  TextStyle b3_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  TextStyle b3_r_long(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14),
    height: 1.45,
    letterSpacing: -0.42,
  );

  // Caption
  TextStyle c1_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c1_r(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c1_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c1_m_narrow(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(12),
    height: 1.45,
    letterSpacing: -0.36,
  );

  TextStyle c2_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  TextStyle c1_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c2_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  TextStyle c3_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(8),
    height: 1.0,
    letterSpacing: -0.3,
  );

  TextStyle c2_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  // ========== 변경된 디자인 시스템 ==========
  TextStyle title_lg_700(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(26),
    height: 38 / 26,
    letterSpacing: -0.52,
  );

  TextStyle title_md_700(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(24),
    height: 36 / 24,
    letterSpacing: -0.48,
  );

  TextStyle title_sm_700(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(22),
    height: 36 / 22,
    letterSpacing: -0.44,
  );

  TextStyle head_md_700(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(20),
    height: 30 / 20,
    letterSpacing: -0.40,
  );

  TextStyle head_sm_700(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(18),
    height: 28 / 18,
    letterSpacing: -0.36,
  );

  TextStyle body_md_500(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 24 / 16,
    letterSpacing: -0.32,
  );

  TextStyle body_md_400(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(16),
    height: 24 / 16,
    letterSpacing: -0.32,
  );

  TextStyle body_sm_500(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(14),
    height: 20 / 14,
    letterSpacing: -0.28,
  );

  TextStyle body_re_400(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14),
    height: 20 / 14,
    letterSpacing: -0.28,
  );

  TextStyle caption_md_500(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(12),
    height: 18 / 12,
    letterSpacing: -0.24,
  );

  TextStyle caption_re_400(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(12),
    height: 18 / 12,
    letterSpacing: -0.24,
  );

  TextStyle caption_re_500(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(10),
    height: 18 / 10,
    letterSpacing: -0.24,
  );

  TextStyle caption_md_400(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(10),
    height: 18 / 10,
    letterSpacing: -0.24,
  );
}

/// =======================================================
/// 프리텐다드 class
/// =======================================================
class _PretendardFonts {
  static const String _fontFamily = AppFonts.pretendardFontFamily;

  // Headers
  TextStyle h1_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(28),
    height: 1.0,
    letterSpacing: -0.84,
  );

  TextStyle h3_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: scaleFont(24),
    height: 1.0,
    letterSpacing: -0.72,
  );

  TextStyle h3_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(24),
    height: 1.0,
    letterSpacing: -0.72,
  );

  TextStyle h4_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(22),
    height: 1.0,
    letterSpacing: -0.66,
  );

  TextStyle h5_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(20),
    height: 1.0,
    letterSpacing: -0.6,
  );

  TextStyle h5_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(20),
    height: 1.0,
    letterSpacing: -0.6,
  );

  // Body
  TextStyle b1_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(18),
    height: 1.0,
    letterSpacing: -0.54,
  );

  TextStyle b1_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(18),
    height: 1.0,
    letterSpacing: -0.54,
  );

  TextStyle b2_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(16),
    height: 1.0,
    letterSpacing: -0.48,
  );

  TextStyle b2_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 1.0,
    letterSpacing: -0.48,
  );

  TextStyle b2_m_long(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 1.6,
    letterSpacing: -0.48,
  );

  TextStyle b3_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );


  TextStyle b3_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  TextStyle b3_sb_long(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14),
    height: 1.6,
    letterSpacing: -0.42,
  );

  TextStyle b3_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  TextStyle b3_r(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  TextStyle b3_r_long(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14),
    height: 1.45,
    letterSpacing: -0.42,
  );

  // Caption
  TextStyle c1_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c1_r(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c2_b(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  TextStyle c2_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  TextStyle c2_sb_long(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  TextStyle c3_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(8),
    height: 1.0,
    letterSpacing: -0.3,
  );

  TextStyle c1_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c1_sb(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  TextStyle c1_m_narrow(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(12),
    height: 1.45,
    letterSpacing: -0.36,
  );

  TextStyle c2_m(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );


// ========== 변경된 디자인 시스템 ==========
  TextStyle title_lg_600(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(26),
    height: 38 / 26,
    letterSpacing: -0.52,
  );

  TextStyle title_md_600(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(24),
    height: 36 / 24,
    letterSpacing: -0.48,
  );

  TextStyle title_sm_600(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(22),
    height: 36 / 22,
    letterSpacing: -0.44,
  );

  TextStyle head_md_600(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(20),
    height: 30 / 20,
    letterSpacing: -0.40,
  );

  TextStyle head_sm_600(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(18),
    height: 28 / 18,
    letterSpacing: -0.36,
  );

  TextStyle body_md_500(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 24 / 16,
    letterSpacing: -0.32,
  );

  TextStyle body_md_400(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(16),
    height: 24 / 16,
    letterSpacing: -0.32,
  );

  TextStyle body_sm_500(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(14),
    height: 20 / 14,
    letterSpacing: -0.28,
  );

  TextStyle body_sm_400(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14),
    height: 20 / 14,
    letterSpacing: -0.28,
  );

  TextStyle caption_md_500(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(12),
    height: 18 / 12,
    letterSpacing: -0.24,
  );

  TextStyle caption_md_400(BuildContext context) => TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(12),
    height: 18 / 12,
    letterSpacing: -0.24,
  );

}