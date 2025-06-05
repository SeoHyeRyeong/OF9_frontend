import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/features/upload/detail_record_screen.dart';

class EmotionSelectScreen extends StatefulWidget {
  final String gameId;
  final String seatInfo;
  final String stadium;
  final int userId;
  final String? imagePath;
  final String? homeTeam;
  final String? awayTeam;
  final String? gameDate;

  const EmotionSelectScreen({
    Key? key,
    required this.userId,
    required this.gameId,
    required this.seatInfo,
    required this.stadium,
    this.imagePath,
    this.homeTeam,
    this.awayTeam,
    this.gameDate,
  }) : super(key: key);

  @override
  State<EmotionSelectScreen> createState() => _EmotionSelectScreenState();
}

class _EmotionSelectScreenState extends State<EmotionSelectScreen> {
  int? selectedEmotionCode;

  final List<Map<String, dynamic>> emotions = [
    {'code': 1, 'label': '짜릿해요', 'image': AppImages.emotion_1},
    {'code': 2, 'label': '만족해요', 'image': AppImages.emotion_2},
    {'code': 3, 'label': '감동이에요', 'image': AppImages.emotion_3},
    {'code': 4, 'label': '놀랐어요', 'image': AppImages.emotion_4},
    {'code': 5, 'label': '행복해요', 'image': AppImages.emotion_5},
    {'code': 6, 'label': '답답해요', 'image': AppImages.emotion_6},
    {'code': 7, 'label': '아쉬워요', 'image': AppImages.emotion_7},
    {'code': 8, 'label': '화났어요', 'image': AppImages.emotion_8},
    {'code': 9, 'label': '지쳤어요', 'image': AppImages.emotion_9},
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const baseScreenHeight = 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 뒤로가기
            Positioned(
              top: (screenHeight * (46 / baseScreenHeight)),
              left: 20.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SvgPicture.asset(
                  AppImages.backBlack,
                  width: 24.h,
                  height: 24.h,
                ),
              ),
            ),

            // 제목
            Positioned(
              top: (screenHeight * (130 / baseScreenHeight)),
              left: 20.w,
              child: FixedText(
                '직관 감정 선택',
                style: AppFonts.h1_b(context).copyWith(color: Colors.black),
              ),
            ),

            // 설명
            Positioned(
              top: (screenHeight * (174 / baseScreenHeight)),
              left: 20.w,
              child: FixedText(
                '이번 직관에 대한 내 생생한 감정을 남겨봐요!',
                style: AppFonts.b2_m(
                  context,
                ).copyWith(color: AppColors.gray300),
              ),
            ),

            // 감정 이모지 그리드
            Positioned(
              top: (screenHeight * (212 / baseScreenHeight)),
              left: 0,
              right: 0,
              bottom:
                  (screenHeight * (88 / baseScreenHeight)) +
                  (screenHeight * (24 / baseScreenHeight)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: GridView.builder(
                  itemCount: emotions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: screenHeight * (16 / baseScreenHeight),
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final emotion = emotions[index];
                    final isSelected =
                        selectedEmotionCode == null ||
                        selectedEmotionCode == emotion['code'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmotionCode =
                              selectedEmotionCode == emotion['code']
                                  ? null
                                  : emotion['code'];
                        });
                      },
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 88.h,
                              height: 88.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: const Color(0x0D000000),
                                            blurRadius: 7,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(6.h),
                                child: SvgPicture.asset(
                                  emotion['image'],
                                  width: 88.h,
                                  height: 88.h,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            FixedText(
                              emotion['label'],
                              style: AppFonts.b2_m_long(context).copyWith(
                                color:
                                    isSelected
                                        ? AppColors.gray800
                                        : AppColors.trans700,
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

            // 다음 버튼
            Positioned(
              top: (screenHeight * (688 / baseScreenHeight)) - statusBarHeight,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                width: 360.w,
                height: screenHeight * (88 / baseScreenHeight),
                padding: EdgeInsets.only(
                  top: screenHeight * (24 / baseScreenHeight),
                  left: 20.w,
                  right: 20.w,
                  bottom: screenHeight * (10 / baseScreenHeight),
                ),
                child: Center(
                  child: SizedBox(
                    width: 320.w,
                    height: screenHeight * (54 / baseScreenHeight),
                    child: ElevatedButton(
                      onPressed:
                          selectedEmotionCode != null
                              ? () {
                                final requestBody = {
                                  'userId': widget.userId,
                                  'gameId': widget.gameId,
                                  'seatInfo': widget.seatInfo,
                                  'emotionCode': selectedEmotionCode,
                                  'stadium': widget.stadium,
                                };

                                // 로그 출력
                                print('😊 1차 저장된 감정 선택 바디: ${requestBody}');

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => DetailRecordScreen(
                                          imagePath: widget.imagePath,
                                          gameDate: widget.gameDate,
                                          homeTeam: widget.homeTeam,
                                          awayTeam: widget.awayTeam,
                                          stadium: widget.stadium,
                                        ),
                                  ),
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedEmotionCode != null
                                ? AppColors.gray700
                                : AppColors.gray200,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: FixedText(
                        '다음',
                        style: AppFonts.b2_b(
                          context,
                        ).copyWith(color: AppColors.gray20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
