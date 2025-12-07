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
import 'package:frontend/api/record_api.dart';

class EmotionSelectScreen extends StatefulWidget {
  final bool isEditMode;
  final int? recordId;

  const EmotionSelectScreen({
    Key? key,
    this.isEditMode = false,
    this.recordId,
  }) : super(key: key);

  @override
  State<EmotionSelectScreen> createState() => _EmotionSelectScreenState();
}

class _EmotionSelectScreenState extends State<EmotionSelectScreen> {
  String selectedFilter = '전체';
  int? selectedEmotionCode;
  List<Map<String, dynamic>> displayedEmotions = [];
  bool isLoading = false;

  // emotion code에 따른 이미지 매핑
  final Map<int, String> emotionImages = {
    1: AppImages.emotion_1,
    2: AppImages.emotion_2,
    3: AppImages.emotion_3,
    4: AppImages.emotion_4,
    5: AppImages.emotion_5,
    6: AppImages.emotion_6,
    7: AppImages.emotion_7,
    8: AppImages.emotion_8,
    9: AppImages.emotion_9,
    10: AppImages.emotion_10,
    11: AppImages.emotion_11,
    12: AppImages.emotion_12,
    13: AppImages.emotion_13,
    14: AppImages.emotion_14,
    15: AppImages.emotion_15,
    16: AppImages.emotion_16,
  };

  @override
  void initState() {
    super.initState();
    final recordState = Provider.of<RecordState>(context, listen: false);
    selectedEmotionCode = recordState.emotionCode;
    _loadEmotions();
  }

  Future<void> _loadEmotions() async {
    try {
      final emotions = await RecordApi.getEmotionsByCategory(
        category: selectedFilter,
      );

      setState(() {
        displayedEmotions = emotions;
        isLoading = false;
      });

      print('✅ 로드된 감정 개수: ${displayedEmotions.length}');
    } catch (e) {
      print('❌ 감정 목록 로드 실패: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordState = Provider.of<RecordState>(context, listen: false);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          if (selectedEmotionCode != null) {
            recordState.updateEmotionCode(selectedEmotionCode!);
          }
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
                    if (selectedEmotionCode != null) {
                      recordState.updateEmotionCode(selectedEmotionCode!);
                    }
                    Navigator.pop(context);
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
                        style: AppFonts.pretendard.title_lg_600(context).copyWith(color: AppColors.gray900),
                      ),
                      SizedBox(height: scaleHeight(4)),
                      FixedText(
                        '이번 직관에 대한 내 생생한 감정을 남겨봐요!',
                        style: AppFonts.pretendard.body_md_400(context).copyWith(color: AppColors.gray300),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: scaleHeight(23)),

              // 필터 버튼 (왼쪽 정렬)
              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(left: scaleWidth(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: ['전체', '승리', '무승부', '패배'].map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: scaleWidth(8)),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter = filter;
                            });
                            _loadEmotions();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: scaleWidth(14),
                              vertical: scaleHeight(4),
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.gray30 : AppColors.gray20,
                              borderRadius: BorderRadius.circular(scaleHeight(8)),
                            ),
                            child: FixedText(
                              filter,
                              style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                color: isSelected ? AppColors.gray600 : AppColors.gray300,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              SizedBox(height: scaleHeight(20)),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = scaleWidth(40);
                    final availableWidth = constraints.maxWidth - horizontalPadding;
                    final itemWidth = scaleWidth(72);
                    final totalItemsWidth = itemWidth * 4;
                    final remainingSpace = availableWidth - totalItemsWidth;
                    final spacing = remainingSpace / 3;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: GridView.builder(
                        key: ValueKey(selectedFilter),
                        itemCount: displayedEmotions.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: spacing > 0 ? spacing : scaleWidth(8),
                          mainAxisSpacing: scaleHeight(20),
                          childAspectRatio: 72 / 84,
                        ),
                        itemBuilder: (context, index) {
                          final emotion = displayedEmotions[index];
                          final emotionCode = emotion['code'] as int;
                          final emotionLabel = emotion['label'] as String;
                          final isSelected = selectedEmotionCode == null || selectedEmotionCode == emotionCode;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedEmotionCode = selectedEmotionCode == emotionCode ? null : emotionCode;
                              });
                            },
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.3,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: scaleWidth(55),
                                    height: scaleHeight(55),
                                    child: emotionImages.containsKey(emotionCode)
                                        ? SvgPicture.asset(
                                      emotionImages[emotionCode]!,
                                      width: scaleWidth(55),
                                      height: scaleHeight(55),
                                    )
                                        : Container(
                                      width: scaleWidth(55),
                                      height: scaleHeight(55),
                                      decoration: BoxDecoration(
                                        color: AppColors.gray100,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: scaleHeight(8)),
                                  FixedText(
                                    emotionLabel,
                                    textAlign: TextAlign.center,
                                    style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                      color: AppColors.gray900,
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
                    recordState.updateEmotionCode(selectedEmotionCode!);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => DetailRecordScreen(
                          isEditMode: widget.isEditMode,
                          recordId: widget.recordId,
                        ),
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
                      style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray20),
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
