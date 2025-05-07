import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 화면 높이에 따라 자동으로 크기를 조정하는 함수
/// 800px 기준으로 비율 조정
double scaleHeight(double baseHeight) {
  double screenHeight = ScreenUtil().screenHeight;
  if (screenHeight >= 800) {
    return baseHeight; // 800 이상은 고정
  } else {
    return baseHeight * (screenHeight / 800); // 800 미만은 비율 축소
  }
}

/// 화면 높이에 따라 비율에 맞춰 상단/하단 height를 계산
/// 원하는 base height를 직접 넘긴다
Map<String, double> calculateHeights({
  required double imageBaseHeight,
  required double contentBaseHeight,
  double baseScreenHeight = 800, // 기본 디자인 기준 총 높이 (800)
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
/// 기본 800px 기준으로 비율 조정
double scaleFont(double baseFontSize, double screenHeight) {
  return screenHeight * (baseFontSize / 800);
}