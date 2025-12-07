import 'package:flutter/material.dart';
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
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.trans700.withOpacity(0.7),
    builder: (_) {
      String? selected = initial;
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Container(
            height: scaleHeight(537),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(scaleHeight(20)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // 헤더 영역
                  Container(
                    height: scaleHeight(60),
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: Stack(
                      children: [
                        // 뒤로가기 버튼
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SvgPicture.asset(
                              AppImages.backBlack,
                              width: scaleWidth(24),
                              height: scaleHeight(24),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // 타이틀
                        Center(
                          child: FixedText(
                            title,
                            style: AppFonts.pretendard.head_sm_600(context).copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 구장 리스트 영역
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.only(
                        top: scaleHeight(12),
                        right: scaleWidth(20),
                        bottom: scaleHeight(12),
                        left: scaleWidth(20),
                      ),
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
                          child: Stack(
                            children: [
                              // 카드
                              Container(
                                width: double.infinity,
                                height: scaleHeight(64),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  border: Border.all(
                                    color: isSel ? AppColors.pri700 : Colors.transparent,
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
                                          width: scaleHeight(40),
                                          height: scaleHeight(40),
                                          fit: BoxFit.contain,
                                        )
                                      else
                                        Row(
                                          children: [
                                            for (int i = 0; i < images.length; i++) ...[
                                              Image.asset(
                                                images[i],
                                                width: scaleHeight(40),
                                                height: scaleHeight(40),
                                                fit: BoxFit.contain,
                                              ),
                                              if (i < images.length - 1) SizedBox(width: scaleWidth(2)),
                                            ],
                                          ],
                                        ),
                                      SizedBox(width: scaleWidth(8)),
                                    ],
                                    // 구장명 텍스트
                                    Expanded(
                                      child: FixedText(
                                        stadium,
                                        style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                    ),
                                    // 체크 아이콘
                                    if (isSel)
                                      Container(
                                        width: scaleWidth(24),
                                        height: scaleWidth(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.pri700,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: SvgPicture.asset(
                                            AppImages.check,
                                            width: scaleWidth(13),
                                            height: scaleHeight(11),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // 흐림 처리
                              if (selected != null && stadium != selected)
                                Container(
                                  width: double.infinity,
                                  height: scaleHeight(64),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray50.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 완료 버튼 영역
                  Container(
                    width: double.infinity,
                    height: scaleHeight(88),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.gray20,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: scaleHeight(24),
                      right: scaleWidth(20),
                      bottom: scaleHeight(10),
                      left: scaleWidth(20),
                    ),
                    child: ElevatedButton(
                      onPressed: selected != null ? () => Navigator.pop(context, selected) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected != null
                            ? AppColors.gray700
                            : AppColors.gray200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(scaleHeight(16)),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: Center(
                        child: FixedText(
                          '완료',
                          style: AppFonts.pretendard.body_md_500(context).copyWith(
                            color: AppColors.gray20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}