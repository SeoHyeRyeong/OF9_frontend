import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';
import 'package:frontend/features/feed/feed_screen.dart';
import 'package:frontend/components/custom_popup_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:frontend/features/upload/providers/record_state.dart';
import 'package:frontend/api/record_api.dart';


class DetailRecordScreen extends StatefulWidget {
  final String? imagePath;
  final String? gameDate;
  final String? homeTeam;
  final String? awayTeam;
  final String? stadium;

  const DetailRecordScreen({
    Key? key,
    this.imagePath,
    this.gameDate,
    this.homeTeam,
    this.awayTeam,
    this.stadium,
  }) : super(key: key);

  @override
  State<DetailRecordScreen> createState() => _DetailRecordScreenState();
}

class _DetailRecordScreenState extends State<DetailRecordScreen> {
  final ImagePicker _picker = ImagePicker();
  List<String> selectedImages = [];
  final int maxImages = 20;
  final ScrollController _scrollController = ScrollController();

  /// 날짜 포맷팅 함수 (2025 - 04 - 15 (수) 14시 00분 → 2025.04.15(수))
  String? formatDisplayDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // "2025 - 04 - 15 (수) 14시 00분" 같은 형태에서 날짜 부분만 추출
      final dateMatch = RegExp(r'(\d{4})\s*-\s*(\d{2})\s*-\s*(\d{2})\s*\(([^)]+)\)').firstMatch(dateStr);
      if (dateMatch != null) {
        final year = dateMatch.group(1);
        final month = dateMatch.group(2);
        final day = dateMatch.group(3);
        final weekday = dateMatch.group(4);
        return '$year.$month.$day($weekday)';
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  /// 갤러리 이미지 선택, 삭제 관련 함수
  /// 갤러리에서 이미지 선택
  Future<void> _pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 ${maxImages}개까지만 선택할 수 있습니다.')),
      );
      return;
    }

    try {
      // 남은 선택 가능한 개수 계산
      final remainingCount = maxImages - selectedImages.length;
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        // 선택한 파일이 제한을 초과하는 경우 처리
        final filesToAdd = pickedFiles.take(remainingCount).toList();

        if (pickedFiles.length > remainingCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${remainingCount}개만 추가되었습니다. (최대 ${maxImages}개)'),
            ),
          );
        }

        // 이미지 경로 추가
        for (final file in filesToAdd) {
          selectedImages.add(file.path);
        }
        print('✔️추가 후 서버로 전송할 이미지 경로: $selectedImages');
        setState(() {});

        // Provider에 이미지 경로 저장
        Provider.of<RecordState>(context, listen: false)
            .updateImagePaths(selectedImages);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.')),
      );
    }
  }

  /// 이미지 삭제
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });

    print('🗑️삭제 후 서버로 전송할 이미지 경로: $selectedImages');

    // Provider에 업데이트된 이미지 경로 저장
    Provider.of<RecordState>(context, listen: false)
        .updateImagePaths(selectedImages);
  }

  /// 갤러리 위젯 빌드
  /// 사진과 영상을 추가해 주세요 기능 구현 + 뷰 디자인
  Widget _buildGallerySection() {
    final screenHeight = MediaQuery.of(context).size.height;

    if (selectedImages.isEmpty) {
      // 기본 상태
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: 320.13.w,
          height: screenHeight * (202 / 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Color(0x08000000),
                offset: Offset(0, 0),
                blurRadius: 5,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppImages.gallery_detail,
                width: 44.w,
                height: 37.h,
              ),
              SizedBox(height: 10.h),
              FixedText(
                '사진과 영상을 추가해 주세요',
                style: AppFonts.b2_b(context).copyWith(color: AppColors.gray800),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              FixedText(
                '첫 번째 사진이 대표 사진으로 지정됩니다!',
                style: AppFonts.c1_r(context).copyWith(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              SvgPicture.asset(
                AppImages.plus,
                width: 42.w,
                height: 42.h,
              ),
            ],
          ),
        ),
      );
    }

    // 이미지가 선택된 상태 - 가로 스크롤 갤러리
    return Container(
      width: 320.13.w,
      height: 152.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 선택된 이미지들
            ...selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imagePath = entry.value;

              return Container(
                margin: EdgeInsets.only(right: 10.w),
                child: Stack(
                  children: [
                    // 이미지
                    Container(
                      width: 112.w,
                      height: 152.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: 112.w,
                          height: 152.h,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 112.w,
                              height: 152.h,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                size: 32.w,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 대표 배지 (첫 번째 이미지에만 표시)
                    if (index == 0)
                      Positioned(
                        top: 8.h,
                        left: 7.w,
                        child: Container(
                          width: 40.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: AppColors.pri600,
                            borderRadius: BorderRadius.circular(11.16.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppImages.maincheck,
                                width: 10.w,
                                height: 10.h,
                              ),
                              SizedBox(width: 2.w),
                              FixedText(
                                '대표',
                                style: AppFonts.c2_sb(context).copyWith(color: AppColors.gray20),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 삭제 버튼
                    Positioned(
                      top: 8.h,
                      right: 7.w,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 14.w,
                          height: 14.h,
                          decoration: BoxDecoration(
                            color: AppColors.gray400,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 10.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // 추가 버튼 (20개 미만일 때만 표시)
            if (selectedImages.length < maxImages) ...[
              SizedBox(width: 20.w),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 42.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppImages.plus,
                    width: 24.w,
                    height: 24.h,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseScreenHeight = 800;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // 뒤로가기 버튼 (원래 위치에 고정)
            Positioned(
              top: (screenHeight * 46 / baseScreenHeight) - statusBarHeight,
              left: 0,
              child: SizedBox(
                width: 360.w,
                height: screenHeight * (60 / baseScreenHeight),
                child: Stack(
                  children: [
                    Positioned(
                      top: screenHeight * (18 / baseScreenHeight),
                      left: 20.w,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TicketOcrScreen(),
                            ),
                          );
                        },
                        child: SvgPicture.asset(
                          AppImages.backBlack,
                          width: 24.w,
                          height: 24.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 메인 콘텐츠 영역 (스크롤)
            Positioned(
              top: screenHeight * (75 / baseScreenHeight),
              left: 0,
              right: 0,
              bottom: screenHeight * ((800 - 688) / baseScreenHeight) - statusBarHeight,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // 티켓 사진 카드
                    Container(
                      width: 360.w,
                      height: screenHeight * (110 / baseScreenHeight),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x08000000),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 10.h, left: 14.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 티켓 이미지
                            Container(
                              width: 60.17.w,
                              height: screenHeight * (88 / baseScreenHeight),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                color: Colors.grey[200],
                                image: widget.imagePath != null
                                    ? DecorationImage(
                                  image: FileImage(File(widget.imagePath!)),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: widget.imagePath == null
                                  ? const Center(child: FixedText('이미지X'))
                                  : null,
                            ),

                            SizedBox(width: 15.w),

                            // 티켓 정보
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 10.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 일시
                                    FixedText(
                                      formatDisplayDate(widget.gameDate) ?? widget.gameDate ?? '',
                                      style: AppFonts.c1_b(context).copyWith(
                                        color: AppColors.gray800,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    // 홈팀 VS 원정팀
                                    FixedText(
                                      '${widget.homeTeam ?? ''} VS ${widget.awayTeam ?? ''}',
                                      style: AppFonts.b2_b(context).copyWith(
                                        color: AppColors.gray800,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    // 구장
                                    FixedText(
                                      widget.stadium ?? '',
                                      style: AppFonts.c1_b(context).copyWith(
                                        color: AppColors.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 회색 배경 영역
                    Container(
                      width: double.infinity,
                      color: AppColors.gray20,
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * (24 / baseScreenHeight)),

                          // 사진과 영상을 추가해 주세요
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.75.w),
                            child: _buildGallerySection(),
                          ),

                          SizedBox(height: screenHeight * (24 / baseScreenHeight)),

                          // 직관 한 마디
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.75.w),
                            child: Container(
                              width: 320.13.w,
                              height: screenHeight * (150 / baseScreenHeight),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    offset: Offset(0, 0),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 18.h,
                                  right: 16.w,
                                  bottom: 16.h,
                                  left: 16.w,
                                ),
                                child: OneWordSectionContent(
                                  scrollController: _scrollController,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * (24 / baseScreenHeight)),

                          // 야구 일기
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.75.w),
                            child: Container(
                              width: 320.13.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    offset: Offset(0, 0),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 18.h,
                                  right: 16.w,
                                  bottom: 16.h,
                                  left: 16.w,
                                ),
                                child: DiaryNoteSectionContent(
                                  scrollController: _scrollController,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * (24 / baseScreenHeight)),

                          // 베스트플레이어
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.75.w),
                            child: Container(
                              width: 320.13.w,
                              height: screenHeight * (134 / baseScreenHeight),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    offset: Offset(0, 0),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 18.h,
                                  right: 16.w,
                                  bottom: 16.h,
                                  left: 16.w,
                                ),
                                child: BestPlayerSectionContent(
                                  scrollController: _scrollController,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * (24 / baseScreenHeight)),

                          // 함께 직관한 친구
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.75.w),
                            child: Container(
                              width: 320.13.w,
                              height: screenHeight * (134 / baseScreenHeight),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    offset: Offset(0, 0),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 18.h,
                                  right: 16.w,
                                  bottom: 16.h,
                                  left: 16.w,
                                ),
                                child: CheerFriendSectionContent(
                                  scrollController: _scrollController,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * (24 / baseScreenHeight)),

                          // 먹거리 태그
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.75.w),
                            child: Container(
                              width: 320.13.w,
                              height: screenHeight * (128 / baseScreenHeight),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    offset: Offset(0, 0),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 18.h,
                                  right: 16.w,
                                  bottom: 16.h,
                                  left: 16.w,
                                ),
                                child: FoodTagSectionContent(
                                  scrollController: _scrollController,
                                ),
                              ),
                            ),
                          ),

                          // 하단 여백
                          SizedBox(height: screenHeight * (55 / baseScreenHeight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 완료 버튼
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
                      onPressed: () async {
                        try {
                          final recordState = Provider.of<RecordState>(context, listen: false);

                          // 기본 정보가 완전한지 확인
                          if (!recordState.isBasicInfoComplete) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('기본 정보가 누락되었습니다.')),
                            );
                            return;
                          }

                          // API 호출
                          final result = await RecordApi.createCompleteRecord(
                            userId: recordState.userId!,
                            gameId: recordState.gameId!,
                            seatInfo: recordState.seatInfo!,
                            emotionCode: recordState.emotionCode!,
                            stadium: recordState.stadium!,
                            comment: recordState.comment,
                            longContent: recordState.longContent,
                            bestPlayer: recordState.bestPlayer,
                            companions: recordState.companions,
                            foodTags: recordState.foodTags,
                            imagePaths: recordState.imagePaths,
                          );

                          print('✅ 기록 저장 성공: $result');

                          // 성공 시 상태 초기화
                          recordState.reset();

                          // 성공 메시지 및 화면 이동
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FeedScreen(showCompletionPopup: true),
                            ),
                          );

                        } catch (e) {
                          print('❌ 기록 저장 실패: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('기록 저장에 실패했습니다: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gray700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                      ),
                      child: FixedText(
                        '작성 완료',
                        style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20),
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

/// OneWordSectionContent 위젯 클래스
/// 직관 한 마디 글자수 count + 뷰 디자인
class OneWordSectionContent extends StatefulWidget {
  final ScrollController scrollController;

  const OneWordSectionContent({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<OneWordSectionContent> createState() => _OneWordSectionContentState();
}

class _OneWordSectionContentState extends State<OneWordSectionContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _currentLength = 0;
  final int _maxLength = 30;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateCharacterCount);
    _focusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCharacterCount);
    _focusNode.removeListener(_updateFocusState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _currentLength = _controller.text.length;
    });

    // Provider에 데이터 저장
    Provider.of<RecordState>(context, listen: false)
        .updateComment(_controller.text);
  }

  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          200.0, // 직관 한 마디 섹션 위치 근처
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updateFocusState() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // 포커스될 때마다 해당 위치로 스크롤 (재포커스 시에도 적용)
    if (_isFocused) {
      _scrollToTextField();
    }
  }

  // 텍스트 필드가 활성 상태인지 확인 (글자가 1개 이상일 때)
  bool get _isActive => _controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘과 제목/설명 부분
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘
            SvgPicture.asset(
              AppImages.oneword,
              width: 48.w,
              height: 48.h,
            ),

            SizedBox(width: 12.w),

            // 텍스트 부분
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  FixedText(
                    '직관 한 마디',
                    style: AppFonts.b2_b(context).copyWith(
                      color: AppColors.gray800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // 설명
                  FixedText(
                    '이번 경기의 한 줄 평을 남겨주세요!',
                    style: AppFonts.c1_r(context).copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 텍스트 필드와 글자수 카운터
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 텍스트 필드
            Container(
              width: 288.w,
              height: 40.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gray30,
                borderRadius: BorderRadius.circular(6.r),
                border: _isActive
                    ? Border.all(color: AppColors.pri100, width: 1.0)
                    : null,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: _maxLength,
                onTap: () => _scrollToTextField(), // 터치할 때마다 스크롤
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return null;
                },
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.only(left: 16.w),
                  hintText: '직접 작성해 주세요',
                  hintStyle: AppFonts.c1_r(context).copyWith(
                    color: AppColors.gray200,
                    height: 1.0,
                  ),
                  border: InputBorder.none,
                ),
                textAlignVertical: TextAlignVertical.center,
                style: AppFonts.c1_r(context).copyWith(
                  color: _isActive ? AppColors.gray950 : AppColors.gray200,
                  height: 1.0,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // 글자수 카운터
            Container(
              width: 288.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FixedText(
                    '$_currentLength/$_maxLength',
                    style: AppFonts.c2_sb(context).copyWith(
                      color: _isActive ? AppColors.pri400 : AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// DiaryNoteSectionContent 위젯 클래스
/// 야구 일기 글자수 count + 뷰 디자인
class DiaryNoteSectionContent extends StatefulWidget {
  final ScrollController scrollController;

  const DiaryNoteSectionContent({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<DiaryNoteSectionContent> createState() => _DiaryNoteSectionContentState();
}

class _DiaryNoteSectionContentState extends State<DiaryNoteSectionContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _currentLength = 0;
  final int _maxLength = 500;
  bool _isFocused = false;
  bool _isMultiLine = false; // 다중행 상태

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateCharacterCount);
    _focusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCharacterCount);
    _focusNode.removeListener(_updateFocusState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _currentLength = _controller.text.length;
      _isMultiLine = _controller.text.contains('\n') || _needsMultiLine();
    });

    // Provider에 데이터 저장
    Provider.of<RecordState>(context, listen: false)
        .updateLongContent(_controller.text);
  }

  // 한 줄이 넘치는지 확인하는 함수
  bool _needsMultiLine() {
    if (_controller.text.isEmpty) return false;

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: _controller.text,
        style: AppFonts.c1_r(context).copyWith(
          color: AppColors.gray950,
          height: 1.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    );

    textPainter.layout(maxWidth: 288.w - 32.w); // 텍스트필드 너비에서 좌우 패딩 제외
    return textPainter.didExceedMaxLines;
  }

  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          400.0, // 야구일기 섹션 위치 근처
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updateFocusState() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // 포커스될 때마다 해당 위치로 스크롤 (재포커스 시에도 적용)
    if (_isFocused) {
      _scrollToTextField();
    }
  }

  // 텍스트 필드가 활성 상태인지 확인 (글자가 1개 이상일 때)
  bool get _isActive => _controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘과 제목/설명 부분
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘
            SvgPicture.asset(
              AppImages.diary,
              width: 48.w,
              height: 48.h,
            ),

            SizedBox(width: 12.w),

            // 텍스트 부분
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  FixedText(
                    '야구 일기',
                    style: AppFonts.b2_b(context).copyWith(
                      color: AppColors.gray800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // 설명
                  FixedText(
                    '오늘의 야구 일기를 적어주세요!',
                    style: AppFonts.c1_r(context).copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 텍스트 필드와 글자수 카운터
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 텍스트 필드
            Container(
              width: 288.w,
              height: _isMultiLine ? null : 40.h, // 다중행일 때만 자동 높이
              constraints: _isMultiLine ? BoxConstraints(minHeight: 40.h) : null,
              alignment: _isMultiLine ? Alignment.topLeft : Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gray30,
                borderRadius: BorderRadius.circular(6.r),
                border: _isActive
                    ? Border.all(color: AppColors.pri100, width: 1.0)
                    : null,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: _maxLength,
                maxLines: _isMultiLine ? null : 1,
                onTap: () => _scrollToTextField(),
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return null;
                },
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: _isMultiLine
                      ? EdgeInsets.all(16.w)
                      : EdgeInsets.only(left: 16.w), // OneWordSectionContent와 완전히 동일
                  hintText: '직접 작성해 주세요',
                  hintStyle: AppFonts.c1_r(context).copyWith(
                    color: AppColors.gray200,
                    height: 1.0,
                  ),
                  border: InputBorder.none,
                ),
                textAlignVertical: _isMultiLine ? TextAlignVertical.top : TextAlignVertical.center,
                style: AppFonts.c1_r(context).copyWith(
                  color: _isActive ? AppColors.gray950 : AppColors.gray200,
                  height: 1.0,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // 글자수 카운터
            Container(
              width: 288.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FixedText(
                    '$_currentLength/$_maxLength',
                    style: AppFonts.c2_sb(context).copyWith(
                      color: _isActive ? AppColors.pri400 : AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// BestPlayerSectionContent 위젯 클래스
/// 베스트 플레이어 글자수 count + 뷰 디자인
class BestPlayerSectionContent extends StatefulWidget {
  final ScrollController scrollController;

  const BestPlayerSectionContent({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<BestPlayerSectionContent> createState() => _BestPlayerSectionContentState();
}

class _BestPlayerSectionContentState extends State<BestPlayerSectionContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateState);
    _focusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _focusNode.removeListener(_updateFocusState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});

    // Provider에 데이터 저장
    Provider.of<RecordState>(context, listen: false)
        .updateBestPlayer(_controller.text);
  }


  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          600.0, // 베스트플레이어 섹션 위치 근처
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updateFocusState() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // 포커스될 때마다 해당 위치로 스크롤 (재포커스 시에도 적용)
    if (_isFocused) {
      _scrollToTextField();
    }
  }

  // 텍스트 필드가 활성 상태인지 확인 (글자가 1개 이상일 때)
  bool get _isActive => _controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘과 제목/설명 부분
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘
            SvgPicture.asset(
              AppImages.bestplayer,
              width: 48.w,
              height: 48.h,
            ),

            SizedBox(width: 12.w),

            // 텍스트 부분
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FixedText(
                    '베스트 플레이어',
                    style: AppFonts.b2_b(context).copyWith(
                      color: AppColors.gray800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FixedText(
                    '오늘의 베스트 플레이어를 뽑아주세요!',
                    style: AppFonts.c1_r(context).copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 텍스트 필드
        Container(
          width: 288.w,
          height: 40.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gray30,
            borderRadius: BorderRadius.circular(6.r),
            border: _isActive
                ? Border.all(color: AppColors.pri100, width: 1.0)
                : null,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onTap: () => _scrollToTextField(), // 터치할 때마다 스크롤
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.only(left: 16.w),
              hintText: '베스트 플레이어를 검색해 보세요',
              hintStyle: AppFonts.c1_r(context).copyWith(
                color: AppColors.gray200,
                height: 1.0,
              ),
              border: InputBorder.none,
            ),
            textAlignVertical: TextAlignVertical.center,
            style: AppFonts.c1_r(context).copyWith(
              color: _isActive ? AppColors.gray950 : AppColors.gray200,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

/// CheerFriendSectionContent 위젯 클래스
/// 함께 직관한 친구 뷰 디자인
class CheerFriendSectionContent extends StatefulWidget {
  final ScrollController scrollController;

  const CheerFriendSectionContent({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<CheerFriendSectionContent> createState() => _CheerFriendSectionContentState();
}

class _CheerFriendSectionContentState extends State<CheerFriendSectionContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateState);
    _focusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _focusNode.removeListener(_updateFocusState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});

    // Provider에 데이터 저장 (companions는 List<String>이므로 배열로 변환)
    final companions = _controller.text.isNotEmpty
        ? [_controller.text]
        : <String>[];
    Provider.of<RecordState>(context, listen: false)
        .updateCompanions(companions);
  }


  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          800.0, // 함께 직관한 친구 섹션 위치 근처
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updateFocusState() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // 포커스될 때마다 해당 위치로 스크롤 (재포커스 시에도 적용)
    if (_isFocused) {
      _scrollToTextField();
    }
  }

  // 텍스트 필드가 활성 상태인지 확인 (글자가 1개 이상일 때)
  bool get _isActive => _controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘과 제목/설명 부분
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘
            SvgPicture.asset(
              AppImages.cheer,
              width: 48.w,
              height: 48.h,
            ),

            SizedBox(width: 12.w),

            // 텍스트 부분
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FixedText(
                    '함께 직관한 친구',
                    style: AppFonts.b2_b(context).copyWith(
                      color: AppColors.gray800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FixedText(
                    '오늘의 경기를 함께 직관한 친구를 적어주세요!',
                    style: AppFonts.c1_r(context).copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 텍스트 필드
        Container(
          width: 288.w,
          height: 40.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gray30,
            borderRadius: BorderRadius.circular(6.r),
            border: _isActive
                ? Border.all(color: AppColors.pri100, width: 1.0)
                : null,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onTap: () => _scrollToTextField(), // 터치할 때마다 스크롤
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.only(left: 16.w),
              hintText: '팔로우 한 친구만 검색 가능해요!',
              hintStyle: AppFonts.c1_r(context).copyWith(
                color: AppColors.gray200,
                height: 1.0,
              ),
              border: InputBorder.none,
            ),
            textAlignVertical: TextAlignVertical.center,
            style: AppFonts.c1_r(context).copyWith(
              color: _isActive ? AppColors.gray950 : AppColors.gray200,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}


/*
// FoodTagSectionContent에서 먹거리 태그 선택 시 Provider 연동 추가 필요 (혜령)
void _onFoodTagSelected(List<String> selectedTags) {
  Provider.of<RecordState>(context, listen: false)
      .updateFoodTags(selectedTags);
}

 */


/// FoodTagSectionContent 위젯 클래스
/// 먹거리 태그 뷰 디자인
class FoodTagSectionContent extends StatefulWidget {
  final ScrollController scrollController;

  const FoodTagSectionContent({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<FoodTagSectionContent> createState() => _FoodTagSectionContentState();
}

class _FoodTagSectionContentState extends State<FoodTagSectionContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘과 제목/설명 부분
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘
            SvgPicture.asset(
              AppImages.food,
              width: 48.w,
              height: 48.h,
            ),

            SizedBox(width: 12.w),

            // 텍스트 부분
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FixedText(
                    '먹거리 태그',
                    style: AppFonts.b2_b(context).copyWith(
                      color: AppColors.gray800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FixedText(
                    '오늘의 먹거리 태그를 선택해 주세요!',
                    style: AppFonts.c1_r(context).copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // + 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // TODO: 먹거리 태그 선택 기능 구현
                print('먹거리 태그 선택');
              },
              child: Container(
                width: 28.w,
                height: 28.h,
                child: Center(
                  child: SvgPicture.asset(
                    AppImages.foodplus,
                    width: 28.w,
                    height: 28.h,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}