import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';


/// 화면 높이에 따라 자동으로 크기를 조정하는 함수
double scaleHeight(double baseHeight) {
  double screenHeight = ScreenUtil().screenHeight;
  return screenHeight * (baseHeight / 800);
}

/// 화면 너비에 따라 자동으로 크기를 조정하는 함수
double scaleWidth(double baseWidth) {
  double screenWidth = ScreenUtil().screenWidth;
  return screenWidth * (baseWidth / 360);
}

/// 화면 크기에 따라 폰트 크기를 조정하는 함수
double scaleFont(double baseFontSize) {
  double screenHeight = ScreenUtil().screenHeight;
  return screenHeight * (baseFontSize / 800);
}

/// 달력 그리드 스케일링을 위한 함수
double scaleCalendar(double baseSize) {
  double screenWidth = ScreenUtil().screenWidth;
  // 너비 기반으로 달력 스케일링
  return screenWidth * (baseSize / 360);
}
double scaleCalendarFont(double baseFontSize) {
  double screenWidth = ScreenUtil().screenWidth;
  // 달력 글자도 너비 기반
  return screenWidth * (baseFontSize / 360);
}

///======================================================
/// 디버그용
void debugPhysicalScreen(BuildContext context) {
  final data = MediaQuery.of(context);
  print('=== Physical Screen Info ===');
  print('Logical Width: ${data.size.width}');
  print('Logical Height: ${data.size.height}');
  print('Device Pixel Ratio: ${data.devicePixelRatio}');
  print('Physical Width: ${data.size.width * data.devicePixelRatio}');
  print('Physical Height: ${data.size.height * data.devicePixelRatio}');

  // 인치당 픽셀 밀도
  final dpi = data.devicePixelRatio * 160;
  print('Approximate DPI: $dpi');

  // 실제 물리적 크기 (cm 단위)
  final widthCm = (data.size.width * data.devicePixelRatio) / dpi * 2.54;
  print('Approximate Physical Width: ${widthCm.toStringAsFixed(1)}cm');
  print('=============================');
}

