import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/features/upload/detail_record_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/upload/providers/record_state.dart';
import 'package:frontend/utils/size_utils.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return Column(
              children: [
                // 뒤로가기 영역
                SizedBox(
                  height: screenHeight * 0.075,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.0225),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: SvgPicture.asset(
                              AppImages.backBlack,
                              width: scaleHeight(24),
                              height: scaleHeight(24),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 콘텐츠 영역 - 나머지 92.5%
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(flex: 32),

                          // 제목
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: FixedText(
                              '직관 감정 선택',
                              style: AppFonts.pretendard.h1_b(context).copyWith(color: Colors.black),
                            ),
                          ),

                          const Spacer(flex: 20),

                          // 서브타이틀
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: FixedText(
                              '이번 직관에 대한 내 생생한 감정을 남겨봐요!',
                              style: AppFonts.pretendard.b2_m(context).copyWith(color: AppColors.gray300),
                            ),
                          ),

                          const Spacer(flex: 35),

                          // 이모션 그리드 영역
                          Expanded(
                            flex: 520,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                              child: GridView.builder(
                                padding: EdgeInsets.only(
                                  top: screenHeight * 0.01,
                                  bottom: screenHeight * 0.01,
                                ),
                                itemCount: emotions.length,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: scaleWidth(24),
                                  mainAxisSpacing: screenHeight * 0.015,
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
                                            width: scaleWidth(88),
                                            height: scaleHeight(88),
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
                                              width: scaleWidth(88),
                                              height: scaleHeight(88),
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.0085),
                                          FixedText(
                                            emotion['label'],
                                            style: AppFonts.suite.b2_m_long(context).copyWith(
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

                          const Spacer(flex: 24),

                          // 완료 버튼
                          Center(
                            child: SizedBox(
                              width: scaleWidth(320),
                              height: scaleHeight(54),
                              child: ElevatedButton(
                                onPressed: selectedEmotionCode != null
                                    ? () {
                                  // 상태에 기본 정보 저장
                                  final recordState = Provider.of<RecordState>(context, listen: false);
                                  recordState.setBasicInfo(
                                    userId: widget.userId,
                                    gameId: widget.gameId,
                                    seatInfo: widget.seatInfo,
                                    emotionCode: selectedEmotionCode!,
                                    stadium: widget.stadium,
                                  );

                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation1, animation2) => DetailRecordScreen(
                                        imagePath: widget.imagePath,
                                        gameDate: widget.gameDate,
                                        homeTeam: widget.homeTeam,
                                        awayTeam: widget.awayTeam,
                                        stadium: widget.stadium,
                                      ),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
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
                                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(18)),
                                ),
                                child: FixedText(
                                  '다음',
                                  style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 33),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
