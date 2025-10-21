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
import 'package:frontend/api/game_api.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:frontend/api/player_api.dart';

class DetailRecordScreen extends StatefulWidget {
  const DetailRecordScreen({Key? key}) : super(key: key);

  @override
  State<DetailRecordScreen> createState() => _DetailRecordScreenState();
}

class _DetailRecordScreenState extends State<DetailRecordScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  List<String> selectedImages = [];
  final int maxImages = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordState = Provider.of<RecordState>(context, listen: false);
      if (recordState.detailImages.isNotEmpty) {
        setState(() {
          selectedImages = List.from(recordState.detailImages);
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  // 키보드 상태 감지
  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    if (_isKeyboardVisible != isKeyboardVisible) {
      final wasHidden = !_isKeyboardVisible;

      setState(() {
        _isKeyboardVisible = isKeyboardVisible;
      });

      // 키보드가 방금 올라왔으면 포커스된 위젯으로 스크롤
      if (wasHidden && isKeyboardVisible) {
        Future.delayed(Duration(milliseconds: 100), () {
          final focusedContext = FocusManager.instance.primaryFocus?.context;
          if (focusedContext != null) {
            Scrollable.ensureVisible(
              focusedContext,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.27,
            );
          }
        });
      }
    }
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
                      _buildTicketCard(),
                      Container(
                        width: double.infinity,
                        color: AppColors.gray30,
                        child: Column(
                          children: [
                            _buildGallerySection(),
                            _buildDiarySection(),
                            _buildBestPlayerSection(),
                            _buildCheerFriendSection(),
                            if (_isKeyboardVisible) SizedBox(height: scaleHeight(300)),
                            // _buildFoodTagSection(),
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

  // ==================== 1. 뒤로가기 영역 ====================
  Widget _buildBackButtonArea() {
    return Container(
      width: double.infinity,
      height: scaleHeight(60),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final recordState = Provider.of<RecordState>(
                    context, listen: false);
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
              child: Container(
                alignment: Alignment.center,
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
    );
  }

  // ==================== 2. 티켓 카드 영역 ====================
  //풀네임 변환
  final Map<String, String> _teamCorpToFullName = {
    'KIA': 'KIA 타이거즈',
    '두산': '두산 베어스',
    '롯데': '롯데 자이언츠',
    '삼성': '삼성 라이온즈',
    '키움': '키움 히어로즈',
    '한화': '한화 이글스',
    'KT': 'KT WIZ',
    'LG': 'LG 트윈스',
    'NC': 'NC 다이노스',
    'SSG': 'SSG 랜더스',
  };

  String getFullTeamName(String? teamName) {
    if (teamName == null || teamName.isEmpty) return '팀 정보 없음';
    if (teamName.contains(' ')) {
      return teamName;
    }
    final fullName = _teamCorpToFullName[teamName.toUpperCase()];

    return fullName ?? teamName;
  }

  // 문자열 변환
  String? formatDisplayDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      String cleanedStr = dateStr
          .split('(')
          .first
          .trim();

      final datePattern = RegExp(r'(\d{4})\s*-\s*(\d{2})\s*-\s*(\d{2})');
      final dateMatch = datePattern.firstMatch(cleanedStr);

      if (dateMatch != null) {
        final datePart = dateMatch.group(0)!;
        final date = DateTime.parse(datePart);
        final formattedDate = DateFormat('yyyy.MM.dd').format(date);
        final weekday = DateFormat('E', 'ko_KR').format(
            date); // '월', '화', '수' 등

        return '$formattedDate ($weekday)';
      }

      // 정규식 파싱 실패 시 원본 반환
      return dateStr;
    } catch (e) {
      // DateTime 파싱 실패 등 예외 발생 시 원본 반환
      print('날짜 포맷팅 오류: $e');
      return dateStr;
    }
  }

  Widget _buildTicketCard() {
    final recordState = Provider.of<RecordState>(context);
    final homeTeamFullName = getFullTeamName(recordState.finalHome);
    final awayTeamFullName = getFullTeamName(recordState.finalAway);

    return Container(
      width: double.infinity,
      height: scaleHeight(110),

      decoration: BoxDecoration(
        color: AppColors.gray20,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(scaleWidth(14)),
          bottomRight: Radius.circular(scaleWidth(14)),
        ),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, scaleHeight(5)),
            blurRadius: scaleHeight(20),
            spreadRadius: scaleHeight(-5),
            color: const Color(0x1A9397A1),
          ),
        ],
      ),

      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: scaleHeight(10.5),
          horizontal: scaleWidth(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
          children: [
            // 1. 사진 영역
            Container(
              width: scaleWidth(60),
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
              child: recordState.ticketImagePath == null ? Center(
                  child: FixedText('이미지X')) : null,
            ),

            SizedBox(width: scaleWidth(15)),

            // 2. 텍스트 영역
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: scaleHeight(2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 2-1. 날짜 및 요일
                    FixedText(
                      formatDisplayDate(recordState.finalDateTime) ??
                          recordState.finalDateTime ?? '',
                      style: AppFonts.suite.caption_md_500(context).copyWith(
                          color: AppColors.gray900),
                    ),
                    SizedBox(height: scaleHeight(4)),

                    // 2-2. 팀 매치업
                    FixedText(
                      '$homeTeamFullName VS $awayTeamFullName',
                      style: AppFonts.pretendard.head_sm_600(context).copyWith(
                          color: AppColors.gray900),
                    ),
                    SizedBox(height: scaleHeight(10)),

                    // 2-3. 경기장 정보
                    FixedText(
                      recordState.finalStadium ?? '',
                      style: AppFonts.suite.body_sm_500(context).copyWith(
                          color: AppColors.gray700),
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

  // ==================== 3. 사진과 영상 추가 영역 ====================
  Widget _buildGallerySection() {
    if (selectedImages.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
        child: Column(
          children: [
            SizedBox(height: scaleHeight(24)),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: double.infinity,
                height: scaleHeight(210),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(scaleWidth(20)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0A9397A1),
                      offset: const Offset(0, 0),
                      blurRadius: 16.0,
                      spreadRadius: 0.0,
                    ),
                  ],
                ),
                padding: EdgeInsets.only(top: scaleHeight(22),),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Image.asset(
                            AppImages.gallery_detail, width: scaleWidth(52),
                            height: scaleHeight(52)),
                        SizedBox(height: scaleHeight(8)),
                        FixedText(
                          '사진과 영상을 추가해 주세요',
                          style: AppFonts.suite.head_sm_700(context).copyWith(
                              color: AppColors.gray900),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: scaleHeight(4)),
                        FixedText(
                          '첫 번째 사진이 대표 사진으로 지정됩니다',
                          style: AppFonts.suite.body_sm_500(context).copyWith(
                              color: AppColors.gray500),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: scaleHeight(12)),
                        Container(
                          width: scaleWidth(42),
                          height: scaleHeight(42),
                          decoration: BoxDecoration(
                              color: AppColors.gray50,
                              shape: BoxShape.circle
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              AppImages.plus,
                              width: scaleWidth(18),
                              height: scaleHeight(18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: scaleHeight(22)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20.5)),
      child: Column(
        children: [
          SizedBox(height: scaleHeight(24)),
          Container(
            width: double.infinity,
            height: scaleHeight(152),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...selectedImages
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final imagePath = entry.value;

                    return Container(
                      margin: EdgeInsets.only(right: scaleWidth(12)),
                      child: Stack(
                        children: [
                          Container(
                            width: scaleWidth(112),
                            height: scaleHeight(152),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  scaleWidth(8)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  scaleWidth(8)),
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
                          Container(
                            width: scaleWidth(112),
                            height: scaleHeight(152),
                            alignment: Alignment.topRight,
                            padding: EdgeInsets.only(
                                top: scaleHeight(10), right: scaleWidth(8)),
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                width: scaleWidth(15),
                                height: scaleHeight(15),
                                decoration: BoxDecoration(
                                    color: AppColors.trans200,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.close, color: Colors.white,
                                    size: scaleWidth(11)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (selectedImages.length < maxImages) ...[
                    SizedBox(width: scaleWidth(15)),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: scaleWidth(42),
                        height: scaleHeight(42),
                        decoration: BoxDecoration(
                            color: AppColors.gray50,
                            shape: BoxShape.circle
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            AppImages.plus,
                            width: scaleWidth(16),
                            height: scaleHeight(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: scaleHeight(20)),
        ],
      ),
    );
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
            SnackBar(content: Text(
                '${remainingCount}개만 추가되었습니다. (최대 ${maxImages}개)')),
          );
        }

        for (final file in filesToAdd) {
          selectedImages.add(file.path);
        }
        print('✔️추가 후 서버로 전송할 이미지 경로: $selectedImages');
        setState(() {});

        Provider.of<RecordState>(context, listen: false).updateDetailImages(
            selectedImages);
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
    Provider.of<RecordState>(context, listen: false).updateDetailImages(
        selectedImages);
  }

  // ==================== 4. 야구일기 영역 ====================
  Widget _buildDiarySection() {
    return _buildSectionCard(
      child: DiaryNoteSectionContent(scrollController: _scrollController),
      height: null,
    );
  }

  // ==================== 5. 베스트플레이어 영역 ====================
  Widget _buildBestPlayerSection() {
    return _buildSectionCard(
      child: BestPlayerSectionContent(scrollController: _scrollController),
      height: null,
    );
  }

  // ==================== 6. 함께 직관한 친구 영역 ====================
  Widget _buildCheerFriendSection() {
    return _buildSectionCard(
      child: CheerFriendSectionContent(scrollController: _scrollController),
      height: null,
    );
  }

  // ==================== 7. 먹거리 태그 영역 ====================
  /*
  Widget _buildFoodTagSection() {
    return _buildSectionCard(
      child: FoodTagSectionContent(scrollController: _scrollController),
      height: 150,
    );
  }
  */

  // 섹션 카드 공통 위젯
  Widget _buildSectionCard({required Widget child, double? height}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: height != null ? scaleHeight(height) : null,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(scaleWidth(20)),
              boxShadow: [
                const BoxShadow(color: const Color(0x0A9397A1),
                  offset: const Offset(0, 0),
                  blurRadius: 16.0,
                  spreadRadius: 0.0,),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: scaleHeight(18),
                right: scaleWidth(16),
                bottom: scaleHeight(18),
                left: scaleWidth(16),
              ),
              child: child,
            ),
          ),
          SizedBox(height: scaleHeight(20)), //섹션 간 간격
        ],
      ),
    );
  }

  // ==================== 8. 건너뛰기, 완료 UI 영역 ====================
  Widget _buildCompleteButtonArea() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: EdgeInsets.only(
        top: scaleHeight(24),
        right: scaleWidth(20),
        bottom: scaleHeight(10),
        left: scaleWidth(20),
      ),
      child: Row(
        children: [
          // 건너뛰기 버튼
          Expanded(
            flex: 10,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _showSkipConfirmationSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gray50,
                disabledBackgroundColor: AppColors.gray50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleWidth(16))),
                elevation: 0,
                padding: EdgeInsets.zero,
                minimumSize: Size(0, scaleHeight(54)),
              ),
              child: Center(
                child: FixedText(
                  '건너뛰기',
                  style: AppFonts.suite.head_sm_700(context).copyWith(
                      color: AppColors.gray700),
                ),
              ),
            ),
          ),

          SizedBox(width: scaleWidth(8)),

          // 완료 버튼
          Expanded(
            flex: 21,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gray700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleWidth(16))),
                elevation: 0,
                padding: EdgeInsets.zero,
                minimumSize: Size(0, scaleHeight(54)),
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
                  : Center(
                child: FixedText(
                  '완료',
                  style: AppFonts.suite.head_sm_700(context).copyWith(
                      color: AppColors.gray20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ==================== 9. 건너뛰기, 완료 로직 함수들 ====================
  // 공통 제출 로직
  Future<void> _submitRecord({required bool includeDetailData}) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final recordState = Provider.of<RecordState>(context, listen: false);
      final userInfo = await UserApi.getMyProfile();
      final userId = userInfo['data']['id'];

      String? finalGameId = recordState.gameId;

      // gameId 검증 및 재매칭
      if (finalGameId == null || finalGameId.isEmpty) {
        print('⚠️ gameId가 없음. 다시 매칭 시도...');
        try {
          final game = await GameApi.searchGame(
            awayTeam: recordState.finalAway!,
            date: recordState.extractedDate!,
            time: recordState.extractedTime!,
          );
          finalGameId = game.gameId;
          print('✅ 경기 매칭 성공: $finalGameId');
        } catch (e) {
          print('❌ 경기 매칭 실패: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('경기 정보를 찾을 수 없습니다. 네트워크를 확인해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // 로그 출력
      print('=== ${includeDetailData ? "완료" : "건너뛰기"}: 서버로 전송할 데이터 ===');
      print('userId: $userId');
      print('gameId: $finalGameId');
      print('imagePaths: $selectedImages');
      print('stadium: ${recordState.finalStadium}');
      print('seatInfo: ${recordState.finalSeat}');
      print('emotionCode: ${recordState.emotionCode}');
      if (includeDetailData) {
        print('longContent: ${recordState.longContent}');
        print('bestPlayer: ${recordState.bestPlayer}');
        print('companionIds: ${recordState.companions}');
        print('foodTags: ${recordState.foodTags}');
      }
      print('========================');

      await Future.delayed(Duration(milliseconds: 100));

      // API 호출
      final result = await RecordApi.createCompleteRecord(
        userId: userId,
        gameId: finalGameId,
        imagePaths: selectedImages,
        stadium: recordState.finalStadium ?? '',
        seatInfo: recordState.finalSeat ?? '',
        emotionCode: recordState.emotionCode!,
        longContent: includeDetailData ? recordState.longContent : null,
        bestPlayer: includeDetailData ? recordState.bestPlayer : null,
        companionIds: includeDetailData ? recordState.companions : null,
        foodTags: includeDetailData ? recordState.foodTags : null,
      );

      print('✅ 기록 저장 성공${includeDetailData ? "" : " (건너뛰기)"}: $result');
      recordState.reset();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
            const FeedScreen(),
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
  }

  // 완료 버튼 (전체 데이터 전송)
  Future<void> _handleSubmit() async {
    await _submitRecord(includeDetailData: true);
  }

  // 건너뛰기 버튼 (필수 데이터만 전송)
  Future<void> _handleSkipSubmit() async {
    await _submitRecord(includeDetailData: false);
  }

// 건너뛰기 확인 ActionSheet
  void _showSkipConfirmationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.trans700,
      builder: (BuildContext sheetContext) {
        bool isLoading = false; // 로컬 상태 변수 추가

        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: scaleWidth(20),
                  right: scaleWidth(20),
                  bottom: scaleHeight(10),
                ),
                child: Container(
                  height: scaleHeight(188),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(scaleWidth(20)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: scaleHeight(18)),
                      Center(
                        child: Container(
                          width: scaleWidth(54),
                          height: scaleHeight(4),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(scaleWidth(6)),
                          ),
                        ),
                      ),
                      SizedBox(height: scaleHeight(20)),
                      FixedText(
                        '상세 기록을 건너뛰기 하시겠어요?',
                        style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray900),
                      ),
                      SizedBox(height: scaleHeight(8)),
                      FixedText(
                        '직관 기록은 완료 후 수정이 불가능해요',
                        style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray400),
                      ),
                      SizedBox(height: scaleHeight(24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(18)),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gray50,
                                  disabledBackgroundColor: AppColors.gray50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleWidth(16)),
                                  ),
                                  elevation: 0,
                                  minimumSize: Size(0, scaleHeight(46)),
                                ),
                                child: Center(
                                  child: FixedText(
                                    '계속 작성하기',
                                    style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray700),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: scaleWidth(8)),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () async {
                                  setModalState(() {
                                    isLoading = true; // 모달 내부 로딩만 활성화
                                  });

                                  Navigator.pop(context); // 모달 닫기
                                  await _handleSkipSubmit(); // 제출
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pri900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleWidth(16)),
                                  ),
                                  elevation: 0,
                                  minimumSize: Size(0, scaleHeight(46)),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                  width: scaleWidth(20),
                                  height: scaleWidth(20),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Center(
                                  child: FixedText(
                                    '건너뛰기',
                                    style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}


// ===============================================================================
// ===============================================================================
// 공통 UI 컴포넌트
Widget _buildSectionHeader(BuildContext context, String iconPath, String title, String description) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SvgPicture.asset(iconPath, width: scaleWidth(52), height: scaleHeight(52)),
      SizedBox(width: scaleWidth(14)),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FixedText(title, style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray900)),
            SizedBox(height: scaleHeight(2)),
            FixedText(description, style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray500)),
          ],
        ),
      ),
    ],
  );
}

// 1000 -> 1,000으로 포맷
String _formatNumber(int number) {
  final formatter = NumberFormat('#,###');
  return formatter.format(number);
}

// 야구일기용 텍스트 필드와 카운터
Widget _buildInputWithCounter({
  required BuildContext context,
  required TextEditingController controller,
  required FocusNode focusNode,
  required int currentLength,
  required int maxLength,
  required bool isActive,
  required VoidCallback onTap,
  required String hintText,
  required TextStyle hintTextStyle,
  required TextStyle counterTextStyle,
  required double counterTopSpacing,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: scaleHeight(92),
        ),
        alignment: Alignment.topLeft,
        decoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleWidth(12)),
          border: isActive ? Border.all(color: AppColors.pri700, width: 1.0) : null,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLength: maxLength,
          maxLines: null,
          onTap: onTap,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: EdgeInsets.all(scaleWidth(16)),
            hintText: hintText,
            hintStyle: hintTextStyle,
            border: InputBorder.none,
          ),
          textAlignVertical: TextAlignVertical.top,
          style: AppFonts.pretendard.body_sm_500(context).copyWith(
            color: isActive ? AppColors.gray900 : AppColors.gray200,
            height: 1.5,
          ),
        ),
      ),
      SizedBox(height: scaleHeight(counterTopSpacing)),
      Container(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FixedText(
              '${_formatNumber(currentLength)}/${_formatNumber(maxLength)}',
              style: counterTextStyle.copyWith(
                color: isActive ? AppColors.pri800 : counterTextStyle.color,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// 단순 텍스트 필드 (베스트 플레이어 / 함께 직관한 친구)
Widget _buildSimpleInput({
  Key? key,
  required BuildContext context,
  required TextEditingController controller,
  required FocusNode focusNode,
  required bool isActive,
  required VoidCallback onTap,
  required String hintText,
  required double inputHeight,
  required TextStyle hintTextStyle,
  required bool showDropdown,
  required VoidCallback onClear,
  required List<Map<String, dynamic>> searchResults,
  required Function(Map<String, dynamic>) onSelectItem,
  required String type,
  required bool isSelected,
}) {
  return Column(
    children: [
      Container(
        key: key,
        width: double.infinity,
        height: inputHeight,
        decoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleWidth(12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onTap: onTap,
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.all(scaleWidth(16)),
                  hintText: focusNode.hasFocus ? null : hintText,
                  hintStyle: hintTextStyle,
                  border: InputBorder.none,
                ),
                textAlignVertical: TextAlignVertical.center,
                style: AppFonts.pretendard.body_sm_500(context).copyWith(
                  color: isSelected ? AppColors.pri600 : AppColors.gray900,
                  height: 1.0,
                ),
              ),
            ),
            GestureDetector(
              onTap: focusNode.hasFocus ? onClear : null,
              child: Padding(
                padding: EdgeInsets.only(right: scaleWidth(16)),
                child: focusNode.hasFocus
                    ? Image.asset(
                  AppImages.textfield_delete,
                  width: scaleWidth(18),
                  height: scaleHeight(18),
                )
                    : SvgPicture.asset(
                  AppImages.search,
                  width: scaleWidth(22),
                  height: scaleHeight(22),
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
      ),
      if (showDropdown) ...[
        SizedBox(height: scaleHeight(10)),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.gray30,
            borderRadius: BorderRadius.circular(scaleWidth(12)),
          ),
          child: searchResults.isEmpty
              ? Container(
            height: scaleHeight(100),
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
            child: Center(
              child: FixedText(
                '해당 검색어에 대한 검색결과가 없어요!',
                style: AppFonts.suite.caption_md_500(context).copyWith(
                  color: AppColors.gray300,
                ),
              ),
            ),
          )
              : Padding(
            padding: EdgeInsets.symmetric(vertical: scaleHeight(6)),
            child: Column(
              children: List.generate(
                searchResults.length,
                    (index) {
                  final item = searchResults[index];
                  final isLast = index == searchResults.length - 1;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => onSelectItem(item),
                        child: Container(
                          height: scaleHeight(55),
                          color: Colors.transparent,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: scaleHeight(8),
                              left: scaleWidth(13),
                              right: scaleWidth(13),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 프로필 이미지
                                Padding(
                                  padding: EdgeInsets.only(top: scaleHeight(4)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(scaleWidth(15)),
                                    child: Image.network(
                                      type == 'player'
                                          ? (item['imageUrl'] ?? '')
                                          : (item['profileImageUrl'] ?? ''),
                                      width: scaleWidth(30),
                                      height: scaleHeight(30),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: scaleWidth(30),
                                          height: scaleHeight(30),
                                          color: AppColors.gray100,
                                          child: Icon(
                                            Icons.person,
                                            size: scaleWidth(20),
                                            color: AppColors.gray400,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: scaleWidth(12)),
                                // 텍스트 영역
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FixedText(
                                        type == 'player'
                                            ? (item['name'] ?? '')
                                            : (item['nickname'] ?? ''),
                                        style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                      FixedText(
                                        type == 'player'
                                            ? (item['team'] ?? '')
                                            : (item['favTeam'] ?? ''),
                                        style: AppFonts.suite.caption_re_400(context).copyWith(
                                          color: AppColors.gray300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(14)),
                          child: Container(
                            height: scaleHeight(1),
                            color: AppColors.gray100,
                          ),
                        ),
                        SizedBox(height: scaleHeight(2)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ],
  );
}


// ===============================================================================
// ===============================================================================
// 각 섹션별 Content 위젯

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
  final GlobalKey _textFieldKey = GlobalKey();
  int _currentLength = 0;
  final int _maxLength = 1000;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordState = Provider.of<RecordState>(context, listen: false);
      if (recordState.longContent != null && recordState.longContent!.isNotEmpty) {
        _controller.text = recordState.longContent!;
        _currentLength = _controller.text.length;
      }
    });
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
    Provider.of<RecordState>(context, listen: false).updateLongContent(
        _controller.text);
  }


  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_textFieldKey.currentContext != null) {
        Scrollable.ensureVisible(
          _textFieldKey.currentContext!,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.27,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          context,
          AppImages.diary,
          '야구일기',
          '오늘의 야구일기를 적어주세요',
        ),
        SizedBox(height: scaleHeight(22)),
        // 텍스트 필드 영역
        ConstrainedBox(
          key: _textFieldKey,
          constraints: BoxConstraints(
            minHeight: scaleHeight(92),
          ),
          child: _buildInputWithCounter(
            context: context,
            controller: _controller,
            focusNode: _focusNode,
            currentLength: _currentLength,
            maxLength: _maxLength,
            isActive: _controller.text.isNotEmpty,
            onTap: _scrollToTextField,
            hintText: '작성해 주세요',
            hintTextStyle: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray200, height: 1.0),
            counterTopSpacing: 4,
            counterTextStyle: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray400),
          ),
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

class _BestPlayerSectionContentState extends State<BestPlayerSectionContent> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  bool _isFocused = false;
  bool _showDropdown = false;
  bool _wasKeyboardVisible = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  bool _isPlayerSelected = false;
  String _selectedPlayerName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 초기 값 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordState = Provider.of<RecordState>(context, listen: false);
      if (recordState.bestPlayer != null && recordState.bestPlayer!.isNotEmpty) {
        _controller.text = '@${recordState.bestPlayer!}';
        _isPlayerSelected = true;
        _selectedPlayerName = recordState.bestPlayer!;
      }
    });
    _controller.addListener(_updateState);
    _focusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_updateState);
    _focusNode.removeListener(_updateFocusState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    if (_wasKeyboardVisible && !isKeyboardVisible && _focusNode.hasFocus) {
      final trimmedText = _controller.text.trim();

      if (!_isPlayerSelected && (trimmedText.isEmpty || trimmedText == '@')) {
        _controller.removeListener(_updateState);
        _focusNode.removeListener(_updateFocusState);

        _focusNode.unfocus();
        _controller.clear();

        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            _controller.addListener(_updateState);
            _focusNode.addListener(_updateFocusState);
            setState(() {
              _showDropdown = false;
            });
          }
        });
      }
    }

    _wasKeyboardVisible = isKeyboardVisible;
  }

  // 텍스트 변화 감지 및 검색/선택 상태 업데이트
  void _updateState() async {
    final currentText = _controller.text;

    // 포커스 중일 때 @ 문자 유지
    if (_focusNode.hasFocus && !currentText.startsWith('@')) {
      _controller.text = '@${currentText.replaceAll('@', '')}';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      return;
    }

    // 텍스트 변경 시 선택 상태 해제 로직
    final currentName = currentText.replaceAll('@', '').trim();
    if (_isPlayerSelected && currentName != _selectedPlayerName) {
      setState(() {
        _isPlayerSelected = false;
        _selectedPlayerName = '';
      });
      Provider.of<RecordState>(context, listen: false).updateBestPlayer('');
    }

    // 포커스 상태면 항상 드롭다운 표시
    setState(() {
      _showDropdown = _focusNode.hasFocus;
    });

    // 디바운스 로직 (검색 딜레이)
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () async {
      final searchText = currentText.replaceAll('@', '').trim();

      if (searchText.isNotEmpty) {
        // API 검색 호출
        try {
          final results = await PlayerApi.searchPlayers(searchText);
          setState(() {
            _searchResults = results;
          });
        } catch (e) {
          print('❌ 선수 검색 실패: $e');
          setState(() {
            _searchResults = [];
          });
        }
      } else {
        // 검색어 없으면 결과 초기화
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  // 텍스트 필드로 스크롤
  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_textFieldKey.currentContext != null) {
        Scrollable.ensureVisible(
          _textFieldKey.currentContext!,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.27,
        );
      }
    });
  }

  void _updateFocusState() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      _showDropdown = _focusNode.hasFocus;
    });

    if (_isFocused && !_controller.text.startsWith('@')) {
      _controller.text = '@${_controller.text}';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    if (_isFocused) {
      _scrollToTextField(); // 초기 스크롤만
    }
  }

  // 텍스트 초기화 및 포커스 해제
  void _clearText() {
    setState(() {
      _controller.clear(); // 텍스트 완전 삭제
      _searchResults = [];
      _isPlayerSelected = false;
      _selectedPlayerName = '';
    });

    // 텍스트 지운 후 @ 자동 추가
    _controller.text = '@';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: 1),
    );
    Provider.of<RecordState>(context, listen: false).updateBestPlayer('');
  }

  // 선수 선택 처리
  void _selectPlayer(Map<String, dynamic> player) {
    final playerName = player['name'] ?? '';
    setState(() {
      _controller.text = '@$playerName';
      _searchResults = [];
      _isPlayerSelected = true;
      _selectedPlayerName = playerName;
      _showDropdown = false; // 선택 완료 시 드롭다운 숨김
    });

    Provider.of<RecordState>(context, listen: false).updateBestPlayer(playerName);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          AppImages.bestplayer,
          '베스트플레이어',
          '오늘의 베스트플레이어를 뽑아주세요',
        ),
        SizedBox(height: scaleHeight(22)),
        _buildSimpleInput(
          key: _textFieldKey,
          context: context,
          controller: _controller,
          focusNode: _focusNode,
          // @만 남았을 때는 비활성화된 것처럼 보이도록 처리
          isActive: _controller.text.isNotEmpty && _controller.text.trim() != '@',
          onTap: _scrollToTextField,
          hintText: '베스트 플레이어를 검색해 보세요',
          inputHeight: scaleHeight(54),
          hintTextStyle: AppFonts.pretendard.body_sm_500(context).copyWith(
              color: AppColors.gray200, height: 1.0),
          showDropdown: _showDropdown,
          onClear: _clearText,
          searchResults: _searchResults,
          onSelectItem: _selectPlayer,
          type: 'player',
          isSelected: _isPlayerSelected, // 선택된 상태일 때 pri600
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

class _CheerFriendSectionContentState extends State<CheerFriendSectionContent> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  bool _isFocused = false;
  bool _showDropdown = false;
  bool _wasKeyboardVisible = false;
  List<Map<String, dynamic>> _selectedFriends = [];
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  int? _myUserId;
  bool _isAllSelected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final userInfo = await UserApi.getMyProfile();
        _myUserId = userInfo['data']['id'];
      } catch (e) {
        print('❌ 사용자 정보 가져오기 실패: $e');
      }
    });
    _controller.addListener(_updateState);
    _focusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_updateState);
    _focusNode.removeListener(_updateFocusState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    if (_wasKeyboardVisible && !isKeyboardVisible && _focusNode.hasFocus) {
      final trimmedText = _controller.text.trim();

      // ✅ 베스트플레이어와 동일: 선택하지 않았고 @만 남았거나 비어있으면 초기화
      if (_selectedFriends.isEmpty && (trimmedText.isEmpty || trimmedText == '@')) {
        _controller.removeListener(_updateState);
        _focusNode.removeListener(_updateFocusState);

        _focusNode.unfocus();
        _controller.clear();

        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            _controller.addListener(_updateState);
            _focusNode.addListener(_updateFocusState);
            setState(() {
              _showDropdown = false;
            });
          }
        });
      }
      // 친구를 선택했지만 마지막 @에서 아무것도 선택하지 않은 경우
      else if (_selectedFriends.isNotEmpty && trimmedText.endsWith('@')) {
        final nicknames = _selectedFriends.map((f) => '@${f['nickname']}').join(' ');
        _controller.removeListener(_updateState);
        _controller.text = nicknames;
        _controller.addListener(_updateState);

        setState(() {
          _showDropdown = false;
        });
      }
    }

    _wasKeyboardVisible = isKeyboardVisible;
  }

  void _updateState() async {
    final text = _controller.text;

    // ✅ 베스트플레이어와 동일: 포커스 중일 때 @ 문자 유지
    if (_focusNode.hasFocus && !text.startsWith('@')) {
      _controller.removeListener(_updateState);
      _controller.text = '@${text.replaceAll('@', '')}';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _controller.addListener(_updateState);
      return;
    }

    // 텍스트가 변경되면 미완성 선택 상태 해제
    if (_isAllSelected) {
      setState(() {
        _isAllSelected = false;
      });
    }

    setState(() {});

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final lastAtIndex = text.lastIndexOf('@');

      if (lastAtIndex != -1 && _myUserId != null) {
        final searchText = text.substring(lastAtIndex + 1).trim();

        if (searchText.isNotEmpty) {
          try {
            final result = await UserApi.getFollowing(_myUserId!);
            final followingList = result['data'] as List<dynamic>;

            final filtered = followingList.where((user) {
              final nickname = user['nickname'] as String;
              return nickname.toLowerCase().contains(searchText.toLowerCase());
            }).map((e) => e as Map<String, dynamic>).toList();

            setState(() {
              _searchResults = filtered;
            });
          } catch (e) {
            print('❌ 팔로잉 목록 검색 실패: $e');
            setState(() {
              _searchResults = [];
            });
          }
        } else {
          setState(() {
            _searchResults = [];
          });
        }
      }
    });
  }

  void _scrollToTextField() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_textFieldKey.currentContext != null) {
        Scrollable.ensureVisible(
          _textFieldKey.currentContext!,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.25,
        );
      }
    });
  }

  void _updateFocusState() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      _showDropdown = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _controller.removeListener(_updateState);

      // 텍스트가 비어있거나, 친구가 선택되어 있으면 마지막에 @ 추가
      if (_controller.text.isEmpty) {
        _controller.text = '@';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: 1),
        );
      } else if (_selectedFriends.isNotEmpty && !_controller.text.endsWith('@')) {
        // 이미 선택된 친구가 있고 @로 끝나지 않으면 @ 추가
        _controller.text = '${_controller.text} @';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }

      _controller.addListener(_updateState);
      _scrollToTextField();
    }
  }

  void _clearText() {
    setState(() {
      _controller.clear(); // 텍스트 완전 삭제
      _searchResults = [];
      _selectedFriends = []; // 선택된 친구 초기화
      _isAllSelected = false;
    });

    _controller.text = '@';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: 1),
    );
    Provider.of<RecordState>(context, listen: false).updateCompanions([]);
  }

  void _selectFriend(Map<String, dynamic> friend) {
    final friendId = friend['id'] as int;

    if (!_selectedFriends.any((f) => f['id'] == friendId)) {
      setState(() {
        _selectedFriends.add(friend);
        _searchResults = [];

        final nicknames = _selectedFriends.map((f) => '@${f['nickname']}').join(' ');

        _controller.removeListener(_updateState);
        _controller.text = nicknames;
        _isAllSelected = true;

        // 커서를 맨 끝으로 이동
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        _controller.addListener(_updateState);
      });

      final companionIds = _selectedFriends.map((f) => f['id'] as int).toList();
      Provider.of<RecordState>(context, listen: false).updateCompanions(companionIds);

      _focusNode.unfocus();
    }
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
          '오늘의 경기를 함께 한 친구를 적어주세요',
        ),
        SizedBox(height: scaleHeight(22)),
        _buildSimpleInput(
          key: _textFieldKey,
          context: context,
          controller: _controller,
          focusNode: _focusNode,
          isActive: _controller.text.isNotEmpty && _controller.text.trim() != '@',
          onTap: () {
            _scrollToTextField();
          },
          hintText: '팔로우 한 친구만 검색 가능해요',
          inputHeight: scaleHeight(54),
          hintTextStyle: AppFonts.pretendard.body_sm_500(context).copyWith(
              color: AppColors.gray200, height: 1.0),
          showDropdown: _showDropdown,
          onClear: _clearText,
          searchResults: _searchResults,
          onSelectItem: _selectFriend,
          type: 'user',
          isSelected: _selectedFriends.isNotEmpty,
        ),
      ],
    );
  }
}

/// 먹거리 태그
/*
class FoodTagSectionContent extends StatefulWidget {
  final ScrollController scrollController;
  const FoodTagSectionContent({required this.scrollController});

  @override
  State<FoodTagSectionContent> createState() => _FoodTagSectionContentState();
}

class _FoodTagSectionContentState extends State<FoodTagSectionContent> {
  void _onAddTag() {
    Provider.of<RecordState>(context, listen: false).updateFoodTags(['TODO: 태그 리스트 넘겨받기']);
    print('먹거리 태그 선택');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          AppImages.food,
          '먹거리 태그',
          '오늘의 먹거리 태그를 선택해 주세요',
        ),
        SizedBox(height: scaleHeight(22)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _onAddTag,
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
}
*/