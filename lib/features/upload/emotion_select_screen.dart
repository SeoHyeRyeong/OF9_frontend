import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/features/upload/detail_record_screen.dart';
import 'package:frontend/features/upload/ticket_info_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔙 뒤로가기
            Padding(
              padding: EdgeInsets.only(top: 36.h, left: 20.w),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SvgPicture.asset(
                  AppImages.backBlack,
                  width: 24.w,
                  height: 24.w,
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // 🧾 제목
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: FixedText(
                '직관 감정 선택',
                style: AppFonts.h1_b(context).copyWith(color: Colors.black),
              ),
            ),

            SizedBox(height: 17.h),

            // 📄 설명
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: FixedText(
                '이번 직관에 대한 내 생생한 감정을 남겨봐요!',
                style: AppFonts.b2_m(context).copyWith(color: AppColors.gray300),
              ),
            ),

            SizedBox(height: 40.h),

            // 😊 이모지 그리드
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: GridView.builder(
                  itemCount: emotions.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 24.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 88 / 120,
                  ),
                  itemBuilder: (context, index) {
                    final emotion = emotions[index];
                    final isSelected = selectedEmotionCode == null ||
                        selectedEmotionCode == emotion['code'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmotionCode = selectedEmotionCode == emotion['code']
                              ? null
                              : emotion['code'];
                        });
                      },
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.5,
                        child: Column(
                          children: [
                            Container(
                              width: 88.w,
                              height: 88.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: const Color(0x0D000000),
                                    blurRadius: 7,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                    : [],
                              ),
                              child: SvgPicture.asset(
                                emotion['image'],
                                width: 88.w,
                                height: 88.h,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            FixedText(
                              emotion['label'],
                              style: AppFonts.b2_m_long(context).copyWith(
                                color: isSelected
                                    ? AppColors.gray800
                                    : AppColors.trans700.withOpacity(0.7),
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: 88.h,
          margin: EdgeInsets.only(bottom: 25.h),
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.gray20, width: 1),
            ),
          ),
          child: SizedBox(
            width: 320.w,
            height: 54.h,
            child: ElevatedButton(
              onPressed: selectedEmotionCode != null
                  ? () {
                final requestBody = {
                  'userId': widget.userId,
                  'gameId': widget.gameId,
                  'seatInfo': widget.seatInfo,
                  'emotionCode': selectedEmotionCode,
                  'stadium': widget.stadium,
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailRecordScreen(
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
                backgroundColor: selectedEmotionCode != null
                    ? AppColors.gray700
                    : AppColors.gray200,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                elevation: 0,
              ),
              child: FixedText(
                '다음',
                style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}