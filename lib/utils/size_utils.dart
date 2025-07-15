import 'package:flutter_screenutil/flutter_screenutil.dart';

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

/// 화면 높이에 따라 비율에 맞춰 상단/하단 height를 계산
/// 원하는 base height를 직접 넘긴다
Map<String, double> calculateHeights({
  required double imageBaseHeight,
  required double contentBaseHeight,
  double baseScreenHeight = 800, 
}) {
  double screenHeight = ScreenUtil().screenHeight;

  double imageRatio = imageBaseHeight / baseScreenHeight;
  double contentRatio = contentBaseHeight / baseScreenHeight;

  double imageHeight = screenHeight * imageRatio;
  double contentHeight = screenHeight * contentRatio;

  return {
    'imageHeight': imageHeight,
    'contentHeight': contentHeight,
  };
}

/// 화면 크기에 따라 폰트 크기를 조정하는 함수
double scaleFont(double baseFontSize) {
  double screenHeight = ScreenUtil().screenHeight;
  return screenHeight * (baseFontSize / 800);
}
