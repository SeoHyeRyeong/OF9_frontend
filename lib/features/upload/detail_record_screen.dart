import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/features/upload/emotion_select_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/features/feed/feed_screen.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:frontend/features/upload/providers/record_state.dart';
import 'package:frontend/api/record_api.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/api/user_api.dart';

class DetailRecordScreen extends StatefulWidget {
  const DetailRecordScreen({Key? key}) : super(key: key);

  @override
  State<DetailRecordScreen> createState() => _DetailRecordScreenState();
}

class _DetailRecordScreenState extends State<DetailRecordScreen> {
  final ImagePicker _picker = ImagePicker();
  List<String> selectedImages = [];
  final int maxImages = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Provider에서 이전에 선택한 이미지 복원
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordState = Provider.of<RecordState>(context, listen: false);
      if (recordState.detailImages.isNotEmpty) {
        setState(() {
          selectedImages = List.from(recordState.detailImages);
        });
      }
    });
  }

  /// 날짜 포맷팅 함수 (2025 - 04 - 15 (수) 14시 00분 → 2025.04.15(수))
  String? formatDisplayDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
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

  Future<void> _pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 ${maxImages}개까지만 선택할 수 있습니다.')),
      );
      return;
    }

    try {
      final remainingCount = maxImages - selectedImages.length;
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        final filesToAdd = pickedFiles.take(remainingCount).toList();

        if (pickedFiles.length > remainingCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${remainingCount}개만 추가되었습니다. (최대 ${maxImages}개)')),
          );
        }

        for (final file in filesToAdd) {
          selectedImages.add(file.path);
        }
        print('✔️추가 후 서버로 전송할 이미지 경로: $selectedImages');
        setState(() {});

        Provider.of<RecordState>(context, listen: false).updateDetailImages(selectedImages);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
    print('🗑️삭제 후 서버로 전송할 이미지 경로: $selectedImages');
    Provider.of<RecordState>(context, listen: false).updateDetailImages(selectedImages);
  }

  Widget _buildGallerySection() {
    if (selectedImages.isEmpty) {
      return Column(
        children: [
          SizedBox(height: scaleHeight(23)),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: scaleWidth(320),
              height: scaleHeight(210),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(scaleWidth(20)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x08000000),
                    offset: const Offset(0, 0),
                    blurRadius: 5,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: scaleHeight(30),
                bottom: scaleHeight(23),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Image.asset(AppImages.gallery_detail, width: scaleWidth(44), height: scaleHeight(37)),
                      SizedBox(height: scaleHeight(15)),
                      FixedText('사진과 영상을 추가해 주세요',
                        style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray800),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: scaleHeight(8)),
                      FixedText('첫 번째 사진이 대표 사진으로 지정됩니다',
                        style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SvgPicture.asset(AppImages.plus, width: scaleWidth(42), height: scaleHeight(42)),
                ],
              ),
            ),
          ),
          SizedBox(height: scaleHeight(23)),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(height: scaleHeight(24)),
        Container(
          width: scaleWidth(320),
          height: scaleHeight(152),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final imagePath = entry.value;

                  return Container(
                    margin: EdgeInsets.only(right: scaleWidth(10)),
                    child: Stack(
                      children: [
                        Container(
                          width: scaleWidth(112),
                          height: scaleHeight(152),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(scaleWidth(8)),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(scaleWidth(8)),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error, color: Colors.red),
                                );
                              },
                            ),
                          ),
                        ),
                        if (index == 0)
                          Container(
                            width: scaleWidth(112),
                            height: scaleHeight(152),
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.only(top: scaleHeight(8), left: scaleWidth(7)),
                            child: Container(
                              width: scaleWidth(40),
                              height: scaleHeight(16),
                              decoration: BoxDecoration(
                                color: AppColors.pri600,
                                borderRadius: BorderRadius.circular(scaleWidth(11.16)),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(5), vertical: scaleHeight(3)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(AppImages.maincheck, width: scaleWidth(10), height: scaleHeight(10)),
                                  SizedBox(width: scaleWidth(2)),
                                  FixedText('대표', style: AppFonts.pretendard.c2_sb(context).copyWith(color: AppColors.gray20)),
                                ],
                              ),
                            ),
                          ),
                        Container(
                          width: scaleWidth(112),
                          height: scaleHeight(152),
                          alignment: Alignment.topRight,
                          padding: EdgeInsets.only(top: scaleHeight(8), right: scaleWidth(7)),
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: scaleWidth(16),
                              height: scaleHeight(16),
                              decoration: BoxDecoration(color: AppColors.gray400, shape: BoxShape.circle),
                              child: Icon(Icons.close, color: Colors.white, size: scaleWidth(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (selectedImages.length < maxImages) ...[
                  SizedBox(width: scaleWidth(20)),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: scaleWidth(42),
                      height: scaleHeight(42),
                      decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                      child: SvgPicture.asset(AppImages.plus, width: scaleWidth(24), height: scaleHeight(24)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: scaleHeight(24)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordState = Provider.of<RecordState>(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          recordState.updateDetailImages(selectedImages);
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => EmotionSelectScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              _buildBackButtonArea(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      SizedBox(height: scaleHeight(2)),
                      _buildTicketCard(),
                      Container(
                        width: double.infinity,
                        color: AppColors.gray20,
                        child: Column(
                          children: [
                            _buildGallerySection(),
                            _buildSection(
                              builder: () => OneWordSectionContent(scrollController: _scrollController),
                              cardWidth: 320,
                              cardHeight: 180,
                            ),
                            _buildSection(
                              builder: () => DiaryNoteSectionContent(scrollController: _scrollController),
                              cardWidth: 320,
                            ),
                            _buildSection(
                              builder: () => BestPlayerSectionContent(scrollController: _scrollController),
                              cardWidth: 320,
                              cardHeight: 170,
                            ),
                            _buildSection(
                              builder: () => CheerFriendSectionContent(scrollController: _scrollController),
                              cardWidth: 320,
                              cardHeight: 170,
                            ),
                            _buildSection(
                              builder: () => FoodTagSectionContent(scrollController: _scrollController),
                              cardWidth: 320,
                              cardHeight: 150,
                            ),
                            SizedBox(height: scaleHeight(5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildCompleteButtonArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButtonArea() {
    return Container(
      height: scaleHeight(60),
      padding: EdgeInsets.only(left: scaleWidth(20), top: scaleHeight(10)),
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          final recordState = Provider.of<RecordState>(context, listen: false);
          recordState.updateDetailImages(selectedImages);

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => EmotionSelectScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        child: SvgPicture.asset(AppImages.backBlack, width: scaleWidth(24), height: scaleWidth(24)),
      ),
    );
  }

  Widget _buildTicketCard() {
    final recordState = Provider.of<RecordState>(context);

    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: scaleHeight(2), left: scaleWidth(15), bottom: scaleHeight(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: scaleWidth(60.17),
              height: scaleHeight(88),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(scaleWidth(8)),
                color: Colors.grey[200],
                image: recordState.ticketImagePath != null
                    ? DecorationImage(
                  image: FileImage(File(recordState.ticketImagePath!)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: recordState.ticketImagePath == null
                  ? Center(child: FixedText('이미지X'))
                  : null,
            ),
            SizedBox(width: scaleWidth(15)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: scaleHeight(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FixedText(
                      formatDisplayDate(recordState.finalDateTime) ?? recordState.finalDateTime ?? '',
                      style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.gray800),
                    ),
                    SizedBox(height: scaleHeight(12)),
                    FixedText(
                      '${recordState.finalHome ?? ''}  VS  ${recordState.finalAway ?? ''}',
                      style: AppFonts.pretendard.b2_b(context).copyWith(color: AppColors.gray800),
                    ),
                    SizedBox(height: scaleHeight(16)),
                    FixedText(
                      recordState.finalStadium ?? '',
                      style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required Widget Function() builder,
    double cardWidth = 320,
    double? cardHeight,
    double paddingHorz = 19.5,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(paddingHorz)),
      child: Column(
        children: [
          Container(
            width: scaleWidth(cardWidth),
            height: cardHeight != null ? scaleHeight(cardHeight) : null,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(scaleWidth(20)),
              boxShadow: [
                const BoxShadow(color: Color(0x08000000), offset: Offset(0, 0), blurRadius: 5, spreadRadius: 0),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: scaleHeight(18),
                right: scaleWidth(16),
                bottom: scaleHeight(18),
                left: scaleWidth(16),
              ),
              child: builder(),
            ),
          ),
          SizedBox(height: scaleHeight(24)),
        ],
      ),
    );
  }

  Widget _buildCompleteButtonArea() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20), vertical: scaleHeight(24)),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
              if (_isSubmitting) return;

              setState(() {
                _isSubmitting = true;
              });

              try {
                final recordState = Provider.of<RecordState>(context, listen: false);

                // userId 가져오기
                final userInfo = await UserApi.getMyProfile();
                final userId = userInfo['data']['id'];

                // gameId 확인
                final gameId = recordState.gameId;
                if (gameId == null || gameId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('경기 정보가 없습니다.')),
                  );
                  return;
                }

                print('=== 서버로 전송할 데이터 ===');
                print('userId: $userId');
                print('gameId: $gameId');
                print('seatInfo: ${recordState.finalSeat}');
                print('emotionCode: ${recordState.emotionCode}');
                print('stadium: ${recordState.finalStadium}');
                print('comment: ${recordState.comment}');
                print('longContent: ${recordState.longContent}');
                print('bestPlayer: ${recordState.bestPlayer}');
                print('companionIds: ${recordState.companions}');
                print('foodTags: ${recordState.foodTags}');
                print('imagePaths: $selectedImages');
                print('========================');

                await Future.delayed(Duration(milliseconds: 100));

                final result = await RecordApi.createCompleteRecord(
                  userId: userId,
                  gameId: recordState.gameId!,
                  seatInfo: recordState.finalSeat ?? ''!,
                  emotionCode: recordState.emotionCode!,
                  stadium: recordState.finalStadium ?? '',
                  comment: recordState.comment,
                  longContent: recordState.longContent,
                  bestPlayer: recordState.bestPlayer,
                  companionIds: recordState.companions,
                  foodTags: recordState.foodTags,
                  imagePaths: selectedImages,
                );

                print('✅ 기록 저장 성공: $result');
                recordState.reset();

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => const FeedScreen(showCompletionPopup: true),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }
              } catch (e) {
                print('❌ 기록 저장 실패: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('기록 저장에 실패했습니다: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isSubmitting = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubmitting
                  ? AppColors.gray400
                  : AppColors.gray700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleWidth(16))),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(18)),
              minimumSize: Size(scaleWidth(320), scaleHeight(54)),
            ),
            child: _isSubmitting
                ? SizedBox(
              width: scaleWidth(20),
              height: scaleWidth(20),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : FixedText('작성 완료', style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20)),
          ),
        ],
      ),
    );
  }
}

///===============================================================================
///===============================================================================
///공통 UI 조각

// 섹션 헤더
Widget _buildSectionHeader(BuildContext context, String iconPath, String title, String description) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SvgPicture.asset(iconPath, width: scaleWidth(48), height: scaleHeight(48)),
      SizedBox(width: scaleWidth(12)),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FixedText(title, style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray800)),
            SizedBox(height: scaleHeight(8)),
            FixedText(description, style: AppFonts.suite.b3_m(context).copyWith(color: AppColors.gray500)),
          ],
        ),
      ),
    ],
  );
}

// 입력창 + 카운터
Widget _buildInputWithCounter({
  required BuildContext context,
  required TextEditingController controller,
  required FocusNode focusNode,
  required int currentLength,
  required int maxLength,
  required bool isActive,
  required VoidCallback onTap,
  required String hintText,
  bool isMultiLine = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: scaleWidth(288),
        height: isMultiLine ? null : scaleHeight(54),
        constraints: isMultiLine ? BoxConstraints(minHeight: scaleHeight(54)) : null,
        alignment: isMultiLine ? Alignment.topLeft : Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleWidth(12)),
          border: isActive ? Border.all(color: AppColors.gray200, width: 1.0) : null,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLength: maxLength,
          maxLines: isMultiLine ? null : 1,
          onTap: onTap,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: isMultiLine
                ? EdgeInsets.all(scaleWidth(16))
                : EdgeInsets.only(left: scaleWidth(16)),
            hintText: hintText,
            hintStyle: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray200, height: 1.0),
            border: InputBorder.none,
          ),
          textAlignVertical: isMultiLine ? TextAlignVertical.top : TextAlignVertical.center,
          style: AppFonts.pretendard.b3_m(context).copyWith(
            color: isActive ? Colors.black : AppColors.gray200,
            height: 1.5,
          ),
        ),
      ),
      SizedBox(height: scaleHeight(6)),
      Container(
        width: scaleWidth(288),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FixedText(
              '$currentLength/$maxLength',
              style: AppFonts.suite.c2_m(context).copyWith(
                color: isActive ? AppColors.pri400 : AppColors.gray300,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// 카운터 없는 단순 입력창
Widget _buildSimpleInput({
  required BuildContext context,
  required TextEditingController controller,
  required FocusNode focusNode,
  required bool isActive,
  required VoidCallback onTap,
  required String hintText,
}) {
  return Container(
    width: scaleWidth(288),
    height: scaleHeight(54),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.gray30,
      borderRadius: BorderRadius.circular(scaleWidth(12)),
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: onTap,
      decoration: InputDecoration(
        isCollapsed: true,
        contentPadding: EdgeInsets.only(left: scaleWidth(16)),
        hintText: hintText,
        hintStyle: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray200, height: 1.0),
        border: InputBorder.none,
      ),
      textAlignVertical: TextAlignVertical.center,
      style: AppFonts.pretendard.b3_m(context).copyWith(
        color: isActive ? Colors.black : AppColors.gray200,
        height: 1.0,
      ),
    ),
  );
}

// 먹거리 태그 섹션
Widget _buildFoodTagSection({
  required BuildContext context,
  required VoidCallback onAddTag,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(
        context,
        AppImages.food,
        '먹거리 태그',
        '오늘의 먹거리 태그를 선택해 주세요',
      ),
      SizedBox(height: scaleHeight(20)),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onAddTag,
            child: Container(
              width: scaleWidth(28),
              height: scaleHeight(28),
              child: Center(
                child: SvgPicture.asset(
                  AppImages.foodplus,
                  width: scaleWidth(28),
                  height: scaleHeight(28),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// 직관 한 마디
class OneWordSectionContent extends StatefulWidget {
  final ScrollController scrollController;
  const OneWordSectionContent({required this.scrollController});

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
    Provider.of<RecordState>(context, listen: false)
        .updateComment(_controller.text);
  }

  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          scaleHeight(200),
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
    if (_isFocused) _scrollToTextField();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          AppImages.oneword,
          '직관 한 마디',
          '이번 경기의 한 줄 평을 남겨주세요',
        ),
        SizedBox(height: scaleHeight(18)),
        _buildInputWithCounter(
          context: context,
          controller: _controller,
          focusNode: _focusNode,
          currentLength: _currentLength,
          maxLength: _maxLength,
          isActive: _controller.text.isNotEmpty,
          onTap: _scrollToTextField,
          hintText: '직접 작성해 주세요',
        ),
      ],
    );
  }
}

/// 야구 일기
class DiaryNoteSectionContent extends StatefulWidget {
  final ScrollController scrollController;
  const DiaryNoteSectionContent({required this.scrollController});

  @override
  State<DiaryNoteSectionContent> createState() => _DiaryNoteSectionContentState();
}

class _DiaryNoteSectionContentState extends State<DiaryNoteSectionContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _currentLength = 0;
  final int _maxLength = 1000;
  bool _isFocused = false;
  bool _isMultiLine = false;

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
    Provider.of<RecordState>(context, listen: false)
        .updateLongContent(_controller.text);
  }

  bool _needsMultiLine() {
    if (_controller.text.isEmpty) return false;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: _controller.text,
        style: AppFonts.pretendard.c1_m(context).copyWith(color: AppColors.gray950, height: 1.0),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(maxWidth: scaleWidth(230));
    return textPainter.didExceedMaxLines;
  }

  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          scaleHeight(400),
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
    if (_isFocused) _scrollToTextField();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          AppImages.diary,
          '야구 일기',
          '오늘의 야구 일기를 적어주세요',
        ),
        SizedBox(height: scaleHeight(18)),
        _buildInputWithCounter(
          context: context,
          controller: _controller,
          focusNode: _focusNode,
          currentLength: _currentLength,
          maxLength: _maxLength,
          isActive: _controller.text.isNotEmpty,
          onTap: _scrollToTextField,
          hintText: '직접 작성해 주세요',
          isMultiLine: _isMultiLine,
        ),
      ],
    );
  }
}

/// 베스트 플레이어
class BestPlayerSectionContent extends StatefulWidget {
  final ScrollController scrollController;
  const BestPlayerSectionContent({required this.scrollController});

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
    Provider.of<RecordState>(context, listen: false)
        .updateBestPlayer(_controller.text);
  }

  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          scaleHeight(600),
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
    if (_isFocused) _scrollToTextField();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          AppImages.bestplayer,
          '베스트 플레이어',
          '오늘의 베스트 플레이어를 뽑아주세요',
        ),
        SizedBox(height: scaleHeight(18)),
        _buildSimpleInput(
          context: context,
          controller: _controller,
          focusNode: _focusNode,
          isActive: _controller.text.isNotEmpty,
          onTap: _scrollToTextField,
          hintText: '베스트 플레이어를 검색해 보세요',
        ),
      ],
    );
  }
}

/// 함께 직관한 친구
class CheerFriendSectionContent extends StatefulWidget {
  final ScrollController scrollController;
  const CheerFriendSectionContent({required this.scrollController});

  @override
  State<CheerFriendSectionContent> createState() => _CheerFriendSectionContentState();
}

class _CheerFriendSectionContentState extends State<CheerFriendSectionContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  List<int> selectedCompanionIds = []; // 선택된 친구들의 ID 목록

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
    // 현재는 실제 친구 선택 기능이 없으므로 빈 리스트로 처리
    Provider.of<RecordState>(context, listen: false)
        .updateCompanions(selectedCompanionIds);
  }

  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          scaleHeight(800),
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
    if (_isFocused) _scrollToTextField();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          AppImages.cheer,
          '함께 직관한 친구',
          '경기를 함께 직관한 친구를 적어주세요',
        ),
        SizedBox(height: scaleHeight(18)),
        _buildSimpleInput(
          context: context,
          controller: _controller,
          focusNode: _focusNode,
          isActive: _controller.text.isNotEmpty,
          onTap: _scrollToTextField,
          hintText: '팔로우 한 친구만 검색 가능해요',
        ),
      ],
    );
  }
}

/// 먹거리 태그
class FoodTagSectionContent extends StatefulWidget {
  final ScrollController scrollController;
  const FoodTagSectionContent({required this.scrollController});

  @override
  State<FoodTagSectionContent> createState() => _FoodTagSectionContentState();
}

class _FoodTagSectionContentState extends State<FoodTagSectionContent> {
  void _onAddTag() {
    // TODO: 먹거리 태그 선택 UI와 연동
    Provider.of<RecordState>(context, listen: false)
        .updateFoodTags(['TODO: 태그 리스트 넘겨받기']);
    // 실제로는 태그 선택 다이얼로그/모달 띄워서 selectedTags 넘기는 로직 필요
    print('먹거리 태그 선택');
  }

  @override
  Widget build(BuildContext context) {
    return _buildFoodTagSection(
      context: context,
      onAddTag: _onAddTag,
    );
  }
}