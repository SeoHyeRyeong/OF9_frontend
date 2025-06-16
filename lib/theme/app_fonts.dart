import 'package:flutter/material.dart';
import 'package:frontend/utils/size_utils.dart';

class AppFonts {
  static const String suit = 'SUIT';

  // 사용법 - style: AppFonts.h4_b
  static TextStyle h1_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(28, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.84,
  );

  static TextStyle h3_eb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w800,
    fontSize: scaleFont(24, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.72,
  );

  static TextStyle h3_sb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(24, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.72,
  );

  static TextStyle h4_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(22, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.66,
  );

  static TextStyle h5_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(20, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.6,
  );

  static TextStyle h5_sb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(20, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.6,
  );

  // Body
  static TextStyle b1_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(18, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.54,
  );

  static TextStyle b1_sb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(18, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.54,
  );

  static TextStyle b2_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(16, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.48,
  );

  static TextStyle b2_m(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.48,
  );

  static TextStyle b2_m_long(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(16, MediaQuery.of(context).size.height),
    height: 1.6,
    letterSpacing: -0.48,
  );

  static TextStyle b3_sb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.42,
  );

  static TextStyle b3_sb_long(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(14, MediaQuery.of(context).size.height),
    height: 1.6,
    letterSpacing: -0.42,
  );

  static TextStyle b3_m(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(14, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.42,
  );

  static TextStyle b3_r(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(14, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.42,
  );

  static TextStyle b3_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(14, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.42,
  );

  // Caption
  static TextStyle c1_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(12, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.36,
  );

  static TextStyle c1_r(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w400,
    fontSize: scaleFont(12, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.36,
  );

  static TextStyle c2_b(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w700,
    fontSize: scaleFont(10, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.3,
  );

  static TextStyle c1_sb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(12, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.36,
  );

  static TextStyle c2_sb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(10, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.3,
  );

  static TextStyle c3_sb(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w600,
    fontSize: scaleFont(8, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.3,
  );

  static TextStyle c2_m(BuildContext context) => TextStyle(
    fontFamily: suit,
    fontWeight: FontWeight.w500,
    fontSize: scaleFont(10, MediaQuery.of(context).size.height),
    height: 1.0,
    letterSpacing: -0.3,
  );
}
