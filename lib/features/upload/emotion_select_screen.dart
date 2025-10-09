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
import 'package:frontend/features/upload/ticket_info_screen.dart';

class EmotionSelectScreen extends StatefulWidget {
  const EmotionSelectScreen({Key? key}) : super(key: key);

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
    final recordState = Provider.of<RecordState>(context, listen: false);
    selectedEmotionCode ??= recordState.emotionCode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // 뒤로가기
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => TicketInfoScreen(
                imagePath: recordState.ticketImagePath ?? '',
                skipOcrFailPopup: true,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 뒤로가기 영역
              Container(
                width: double.infinity,
                height: scaleHeight(60),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: scaleWidth(20)),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => TicketInfoScreen(
                          imagePath: recordState.ticketImagePath ?? '',
                          skipOcrFailPopup: true,
                        ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    AppImages.backBlack,
                    width: scaleWidth(24),
                    height: scaleHeight(24),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: scaleHeight(18)),

              Padding(
                padding: EdgeInsets.only(left: scaleWidth(20)),
                child: Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FixedText(
                        '직관 감정 선택',
                        style: AppFonts.suite.title_lg_700(context).copyWith(color: AppColors.gray900),
                      ),
                      SizedBox(height: scaleHeight(4)),
                      FixedText(
                        '이번 직관에 대한 내 생생한 감정을 남겨봐요!',
                        style: AppFonts.suite.body_md_400(context).copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: scaleHeight(37.5)),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth - scaleWidth(40);
                    final horizontalSpacing = availableWidth * (28 / 320);
                    final verticalSpacing = availableWidth * (20 / 320);

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: GridView.builder(
                        itemCount: emotions.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: horizontalSpacing,
                          mainAxisSpacing: verticalSpacing,
                          childAspectRatio: 88 / 120,
                        ),
                        itemBuilder: (context, index) {
                          final emotion = emotions[index];
                          final isSelected = selectedEmotionCode == null || selectedEmotionCode == emotion['code'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedEmotionCode = selectedEmotionCode == emotion['code'] ? null : emotion['code'];
                              });
                            },
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                  SizedBox(height: scaleHeight(8)),
                                  FixedText(
                                    emotion['label'],
                                    textAlign: TextAlign.center,
                                    style: AppFonts.suite.body_md_400(context).copyWith(
                                      color: isSelected ? AppColors.gray900 : AppColors.gray900.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                width: double.infinity,
                height: scaleHeight(88),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.gray20, width: 1)),
                ),
                padding: EdgeInsets.only(
                  top: scaleHeight(24),
                  right: scaleWidth(20),
                  bottom: scaleHeight(10),
                  left: scaleWidth(20),
                ),
                child: ElevatedButton(
                  onPressed: selectedEmotionCode != null
                      ? () {
                    final recordState = Provider.of<RecordState>(context, listen: false);

                    recordState.updateEmotionCode(selectedEmotionCode!);

                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => DetailRecordScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedEmotionCode != null ? AppColors.gray700 : AppColors.gray200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleHeight(16)),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: Center(
                    child: FixedText(
                      '다음',
                      style: AppFonts.suite.body_md_500(context).copyWith(color: AppColors.gray20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}