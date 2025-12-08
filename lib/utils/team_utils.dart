import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';

class TeamUtils {
  /// 팀 전체 이름을 짧은 이름으로 변환
  static String getShortTeamName(String fullTeamName) {
    if (fullTeamName.contains('두산')) return '두산';
    if (fullTeamName.contains('롯데')) return '롯데';
    if (fullTeamName.contains('삼성')) return '삼성';
    if (fullTeamName.contains('키움')) return '키움';
    if (fullTeamName.contains('한화')) return '한화';
    if (fullTeamName.contains('KIA')) return 'KIA';
    if (fullTeamName.contains('KT')) return 'KT';
    if (fullTeamName.contains('LG')) return 'LG';
    if (fullTeamName.contains('NC')) return 'NC';
    if (fullTeamName.contains('SSG')) return 'SSG';
    return fullTeamName;
  }

  /// 팀별 텍스트 색상 반환
  static Color getTeamTextColor(String teamName) {
    final shortName = getShortTeamName(teamName);

    switch (shortName) {
      case '두산':
        return AppColors.doosan1;
      case '롯데':
        return AppColors.lotte1;
      case '삼성':
        return AppColors.samsung1;
      case '키움':
        return AppColors.kiwoom1;
      case '한화':
        return AppColors.hamwha1;
      case 'KIA':
        return AppColors.kia1;
      case 'KT':
        return AppColors.kt1;
      case 'LG':
        return AppColors.lg1;
      case 'NC':
        return AppColors.nc1;
      case 'SSG':
        return AppColors.ssg1;
      default:
        return AppColors.gray800;
    }
  }

  /// 팀별 배경 색상 반환
  static Color getTeamBackgroundColor(String teamName) {
    final shortName = getShortTeamName(teamName);

    switch (shortName) {
      case '두산':
        return AppColors.doosan2;
      case '롯데':
        return AppColors.lotte2;
      case '삼성':
        return AppColors.samsung2;
      case '키움':
        return AppColors.kiwoom2;
      case '한화':
        return AppColors.hamwha2;
      case 'KIA':
        return AppColors.kia2;
      case 'KT':
        return AppColors.kt2;
      case 'LG':
        return AppColors.lg2;
      case 'NC':
        return AppColors.nc2;
      case 'SSG':
        return AppColors.ssg2;
      default:
        return AppColors.gray30;
    }
  }

  /// 팀 배지 위젯 생성 (짧은 이름 + 팀 텍스트 + 색상 적용)
  static Widget buildTeamBadge({
    required BuildContext context,
    required String teamName,
    required TextStyle textStyle,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? height,
    String suffix = '팬',
  }) {
    final shortName = getShortTeamName(teamName);
    final displayText = '$shortName$suffix';

    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 7, vertical: 0),
      decoration: BoxDecoration(
        color: getTeamBackgroundColor(teamName),
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: textStyle.copyWith(
          color: getTeamTextColor(teamName),
        ),
      ),
    );
  }
}
