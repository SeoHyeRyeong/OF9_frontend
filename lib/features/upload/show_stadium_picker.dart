import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';

/// 구장 선택용 BottomSheet
Future<String?> showStadiumPicker({
  required BuildContext context,
  required String title,      // "구장"
  required List<Map<String, dynamic>> stadiums,
  String? initial,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final sheetHeight = screenHeight * 0.7;

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
                top: Radius.circular(scaleHeight(20)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sheetHeight = constraints.maxHeight;

                  return Column(
                    children: [
                      // 헤더 영역
                      SizedBox(
                        height: scaleHeight(60),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                          child: Row(
                            children: [
                              // 뒤로가기 버튼
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: SvgPicture.asset(
                                  AppImages.backBlack,
                                  width: scaleWidth(24),
                                  height: scaleHeight(24),
                                  fit: BoxFit.contain,
                                ),
                              ),

                              Expanded(
                                child: Center(
                                  child: FixedText(
                                    title,
                                    style: AppFonts.pretendard.b2_b(context).copyWith(color: Colors.black),
                                  ),
                                ),
                              ),

                              SizedBox(width: scaleWidth(24)),
                            ],
                          ),
                        ),
                      ),

                      // 콘텐츠 영역
                      Expanded(
                        child: SafeArea(
                          top: false,
                          child: LayoutBuilder(
                            builder: (context, contentConstraints) {
                              return Column(
                                children: [
                                  // 리스트 영역
                                  Expanded(
                                    flex: 470,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                                      child: ListView.separated(
                                        padding: EdgeInsets.only(top: scaleHeight(5)),
                                        itemCount: stadiums.length,
                                        separatorBuilder: (_, __) => SizedBox(height: scaleHeight(8)),
                                        itemBuilder: (context, idx) {
                                          final stadium = stadiums[idx]['name']! as String;
                                          final imagesData = stadiums[idx]['images'];
                                          final images = imagesData != null ? List<String>.from(imagesData) : <String>[];
                                          final isSel = stadium == selected;
                                          final hasImages = images.isNotEmpty;

                                          return GestureDetector(
                                            onTap: () => setState(() {
                                              selected = selected == stadium ? null : stadium;
                                            }),
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Stack(
                                                children: [
                                                  // 카드
                                                  Container(
                                                    width: scaleWidth(320),
                                                    height: scaleHeight(64),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.gray50,
                                                      borderRadius: BorderRadius.circular(scaleHeight(8)),
                                                      border: Border.all(
                                                        color: isSel ? AppColors.pri300 : Colors.transparent,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        // 이미지 표시
                                                        if (hasImages) ...[
                                                          if (images.length == 1)
                                                            Image.asset(
                                                              images[0],
                                                              width: scaleHeight(35),
                                                              height: scaleHeight(35),
                                                              fit: BoxFit.contain,
                                                            )
                                                          else
                                                            Row(
                                                              children: [
                                                                for (int i = 0; i < images.length; i++) ...[
                                                                  Image.asset(
                                                                    images[i],
                                                                    width: scaleHeight(30),
                                                                    height: scaleHeight(30),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  if (i < images.length - 1) SizedBox(width: scaleWidth(5)),
                                                                ],
                                                              ],
                                                            ),
                                                          SizedBox(width: scaleWidth(8)),
                                                        ],

                                                        // 구장명 텍스트
                                                        Expanded(
                                                          child: FixedText(
                                                            stadium,
                                                            style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray900),
                                                          ),
                                                        ),

                                                        // 체크 아이콘
                                                        if (isSel)
                                                          Icon(
                                                            Icons.check_circle,
                                                            color: AppColors.pri300,
                                                            size: scaleWidth(24),
                                                          ),
                                                      ],
                                                    ),
                                                  ),

                                                  // 흐림 처리 (선택되지 않은 항목)
                                                  if (selected != null && stadium != selected)
                                                    Container(
                                                      width: scaleWidth(320),
                                                      height: scaleHeight(64),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.gray50.withOpacity(0.5),
                                                        borderRadius: BorderRadius.circular(scaleHeight(8)),
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

                                  // 완료 버튼
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                        top: BorderSide(
                                          color: AppColors.gray20,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      scaleWidth(20),
                                      scaleHeight(24),
                                      scaleWidth(20),
                                      scaleHeight(10),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: scaleWidth(320),
                                        height: scaleHeight(54),
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context, selected),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: selected != null
                                                ? AppColors.gray700
                                                : AppColors.gray200,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(scaleHeight(16)),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(18)),
                                            elevation: 0,
                                          ),
                                          child: FixedText(
                                            '완료',
                                            style: AppFonts.suite.b2_b(context).copyWith(
                                              color: AppColors.gray20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const Spacer(flex: 26),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}
