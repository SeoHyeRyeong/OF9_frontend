import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';

/// 홈/원정 구단 선택용 BottomSheet
Future<String?> showTeamPicker({
  required BuildContext context,
  required String title,      // "홈 구단" 또는 "원정 구단"
  required List<Map<String, String>> teams,
  String? initial,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  const baseH = 800;
  final sheetHeight = screenHeight * (537 / baseH);

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.trans700.withOpacity(0.7),
    builder: (_) {
      String? selected = initial;
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Container(
            height: sheetHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.r),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: screenHeight * (60 / baseH),
                  child: Stack(
                    children: [
                      Positioned(
                        top: screenHeight * (18 / baseH),
                        left: 20.w,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset(
                            AppImages.backBlack,
                            width: 24.w,
                            height: screenHeight * (24 / baseH),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: screenHeight * (22 / baseH),
                        left: 158.w,
                        child: FixedText(
                          title,
                          style: AppFonts.b2_b(context).copyWith(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: screenHeight * (60 / baseH),
                  left: 0,
                  right: 0,
                  height: screenHeight * (414 / baseH),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(0, 12.h, 0, 49.h),
                      itemCount: teams.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, idx) {
                        final team = teams[idx]['name']!;
                        final image = teams[idx]['image']!;
                        final isSel = team == selected;

                        return GestureDetector(
                          onTap: () => setState(() {
                            selected = selected == team ? null : team;
                          }),
                          child: Align(
                            alignment: Alignment.center,
                            child: Stack(
                              children: [
                                // 카드 자체에 테두리 포함
                                Container(
                                  width: 320.w,
                                  height: screenHeight * (64 / baseH),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray50,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: isSel ? AppColors.pri300 : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        image,
                                        width: 35.h,
                                        height: 35.h,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: FixedText(
                                          team,
                                          style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 체크 아이콘
                                if (isSel)
                                  Positioned(
                                    top: (screenHeight * (64 / baseH) - 24.w) / 2,
                                    right: 16.w,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.pri300,
                                      size: 24.w,
                                    ),
                                  ),
                                // 흐림 처리
                                if (selected != null && team != selected)
                                  Positioned.fill(
                                    child: Container(
                                      width: 320.w,
                                      height: screenHeight * (64 / baseH),
                                      decoration: BoxDecoration(
                                        color: AppColors.gray50.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 완료 버튼 영역
                Positioned(
                  top: screenHeight * (425 / baseH),
                  left: 0,
                  right: 0,
                  height: 88.h,
                  child: Container(
                    width: 360.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.gray20,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 10.h),
                    child: SizedBox(
                      width: 320.w,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, selected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected != null ? AppColors.gray700 : AppColors.gray200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.all(10.w),
                          elevation: 0,
                        ),
                        child: FixedText(
                          '완료',
                          style: AppFonts.b2_b(context).copyWith(
                            color: AppColors.gray20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
