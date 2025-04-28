import 'package:flutter/material.dart';
import 'package:frontend/utils/size_utils.dart'; // scaleFont 함수 import

// 사용법 - style: AppFonts.h4_b
class AppFonts {
  static const String suit = 'SUIT';

  // Head
  static TextStyle h1_b = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(28),
    height: 1.0,
    letterSpacing: -0.84,
  );

  static TextStyle h3_eb = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w800,
    fontSize: scaleFont(24),
    height: 1.0,
    letterSpacing: -0.72,
  );

  static TextStyle h3_sb = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(24),
    height: 1.0,
    letterSpacing: -0.72,
  );

  static TextStyle h4_b = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(22),
    height: 1.0,
    letterSpacing: -0.66,
  );

  static TextStyle h5_b = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(20),
    height: 1.0,
    letterSpacing: -0.6,
  );

  static TextStyle h5_sb = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(20),
    height: 1.0,
    letterSpacing: -0.6,
  );

  // Body
  static TextStyle b1_b = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(18),
    height: 1.0,
    letterSpacing: -0.54,
  );

  static TextStyle b1_sb = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(18),
    height: 1.0,
    letterSpacing: -0.54,
  );

  static TextStyle b2_b = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(16),
    height: 1.0,
    letterSpacing: -0.48,
  );

  static TextStyle b2_m = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 1.0,
    letterSpacing: -0.48,
  );

  static TextStyle b2_m_long = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16),
    height: 1.6,
    letterSpacing: -0.48,
  );

  static TextStyle b3_sb = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  static TextStyle b3_sb_long = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14),
    height: 1.6,
    letterSpacing: -0.42,
  );

  static TextStyle b3_m = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  static TextStyle b3_r = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14),
    height: 1.0,
    letterSpacing: -0.42,
  );

  // Caption
  static TextStyle c1_b = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  static TextStyle c1_2 = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(12),
    height: 1.0,
    letterSpacing: -0.36,
  );

  static TextStyle c2_b = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  static TextStyle c2_sb = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(10),
    height: 1.0,
    letterSpacing: -0.3,
  );

  static TextStyle c3_sb = TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(8),
    height: 1.0,
    letterSpacing: -0.3,
  );
}