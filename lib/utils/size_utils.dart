import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// 플랫폼별 기준 사이즈
double get _baseWidth => Platform.isIOS ? 375 : 360;
double get _baseHeight => Platform.isIOS ? 812 : 800;

/// 화면 높이에 따라 자동으로 크기를 조정하는 함수
double scaleHeight(double baseHeight) {
  double screenHeight = ScreenUtil().screenHeight;
  double ratio = screenHeight / _baseHeight;

  // pro max 높이만 최대값 제한 (오버플로우 방지)
  if (ratio > 1.08) ratio = 1.08;

  return baseHeight * ratio;
}

/// 화면 너비에 따라 자동으로 크기를 조정하는 함수
double scaleWidth(double baseWidth) {
  double screenWidth = ScreenUtil().screenWidth;
  return screenWidth * (baseWidth / _baseWidth);
}

/// 화면 크기에 따라 폰트 크기를 조정하는 함수
double scaleFont(double baseFontSize) {
  double screenHeight = ScreenUtil().screenHeight;
  double ratio = screenHeight / _baseHeight;

  if (ratio > 1.08) ratio = 1.08;

  return baseFontSize * ratio;
}

/// 달력 그리드 스케일링을 위한 함수
double scaleCalendar(double baseSize) {
  double screenWidth = ScreenUtil().screenWidth;
  return screenWidth * (baseSize / _baseWidth);
}

double scaleCalendarFont(double baseFontSize) {
  double screenWidth = ScreenUtil().screenWidth;
  return screenWidth * (baseFontSize / _baseWidth);
}

///======================================================
/// 디버그용
void debugPhysicalScreen(BuildContext context) {
  final data = MediaQuery.of(context);
  print('=== Physical Screen Info ===');
  print('Platform: ${Platform.isIOS ? "iOS" : "Android"}');
  print('Logical Width: ${data.size.width}');
  print('Logical Height: ${data.size.height}');
  print('Device Pixel Ratio: ${data.devicePixelRatio}');
  print('Physical Width: ${data.size.width * data.devicePixelRatio}');
  print('Physical Height: ${data.size.height * data.devicePixelRatio}');

  final dpi = data.devicePixelRatio * 160;
  print('Approximate DPI: $dpi');

  final widthCm = (data.size.width * data.devicePixelRatio) / dpi * 2.54;
  print('Approximate Physical Width: ${widthCm.toStringAsFixed(1)}cm');
  print('=============================');
}