import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/models/game_response.dart';
import 'package:frontend/utils/ticket_info_extractor.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/features/upload/show_team_picker.dart';
import 'package:frontend/features/upload/show_stadium_picker.dart'; // 추가된 import
import 'package:frontend/features/upload/show_date_time_picker.dart';
import 'package:frontend/features/upload/show_seat_picker.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';
import 'package:frontend/features/upload/emotion_select_screen.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_popup_dialog.dart';

class TicketInfoScreen extends StatefulWidget {
  final String imagePath;
  final bool skipOcrFailPopup;
  final String? preExtractedAwayTeam;
  final String? preExtractedDate;
  final String? preExtractedTime;

  const TicketInfoScreen({
    Key? key,
    required this.imagePath,
    this.skipOcrFailPopup = false,
    this.preExtractedAwayTeam,
    this.preExtractedDate,
    this.preExtractedTime,
  }) : super(key: key);
  @override
  State<TicketInfoScreen> createState() => _TicketInfoScreenState();
}

class _TicketInfoScreenState extends State<TicketInfoScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String rawOcrText = '';

  String? extractedHomeTeam;
  String? extractedAwayTeam;
  String? extractedDate;
  String? extractedTime;
  String? extractedStadium;
  String? extractedSeat;

  String? selectedHome;
  String? selectedAway;
  String? selectedDateTime;
  String? selectedStadium;
  String? selectedSeat;

  // 날짜(yyyy-MM-dd) → '2025 - 04 - 15 (수)' 형식
  String? formatKoreanDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final date = DateTime.parse(dateStr);
      final weekday = DateFormat('E', 'ko_KR').format(date); // '수'
      return '${date.year} - ${date.month.toString().padLeft(2, '0')} - ${date.day.toString().padLeft(2, '0')} ($weekday)';
    } catch (_) {
      return dateStr;
    }
  }

  // 시간(HH:mm:ss) → '14시 00분' 형식
  String? formatKoreanTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        return '${timeParts[0]}시 ${timeParts[1]}분';
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }


  // 날짜+시간 → '2025 - 04 - 15 (수) 14시 00분' 형식
  String? formatKoreanDateTime(String? dateStr, String? timeStr) {
    final formattedDate = formatKoreanDate(dateStr);
    final formattedTime = formatKoreanTime(timeStr);
    if (formattedDate != null && formattedTime != null) {
      return '$formattedDate $formattedTime';
    } else if (formattedDate != null) {
      return formattedDate;
    } else if (formattedTime != null) {
      return formattedTime;
    }
    return null;
  }


  List<GameResponse> matchedGames = [];

  final Map<String, String> _teamToCorp = {
    'KIA 타이거즈': 'KIA',
    'KIA': 'KIA',
    '두산 베어스': '두산',
    '두산': '두산',
    '롯데 자이언츠': '롯데',
    '롯데': '롯데',
    '삼성 라이온즈': '삼성',
    '삼성': '삼성',
    '키움 히어로즈': '키움',
    '키움': '키움',
    '한화 이글스': '한화',
    '한화': '한화',
    'KT WIZ': 'KT',
    'KT': 'KT',
    'LG 트윈스': 'LG',
    'LG': 'LG',
    'NC 다이노스': 'NC',
    'NC': 'NC',
    'SSG 랜더스': 'SSG',
    'SSG': 'SSG',
    '자이언츠': '롯데',
    '타이거즈': 'KIA',
    '라이온즈': '삼성',
    '히어로즈': '키움',
    '이글스': '한화',
    'WIZ': 'KT',
    '트윈스': 'LG',
    '다이노스': 'NC',
    '랜더스': 'SSG',
    '베어스': '두산',
    'Eagles': '한화'
  };

  final List<String> _teamKeywords = [
    'KIA 타이거즈', '두산 베어스', '롯데 자이언츠', '삼성 라이온즈', '키움 히어로즈', '한화 이글스',
    'KT WIZ', 'LG 트윈스', 'NC 다이노스', 'SSG 랜더스', '자이언츠', '타이거즈', '라이온즈',
    '히어로즈', '이글스', '트윈스', '다이노스', '랜더스', '베어스', 'Eagles', 'KIA', '두산',
    '롯데', '삼성', '키움', '한화', 'KT', 'LG', 'NC', 'SSG', 'WIZ'
  ];

  final List<Map<String, String>> teamListWithImages = [
    {'name': 'KIA 타이거즈', 'image': AppImages.tigers},
    {'name': '두산 베어스', 'image': AppImages.bears},
    {'name': '롯데 자이언츠', 'image': AppImages.giants},
    {'name': '삼성 라이온즈', 'image': AppImages.lions},
    {'name': '키움 히어로즈', 'image': AppImages.kiwoom},
    {'name': '한화 이글스', 'image': AppImages.eagles},
    {'name': 'KT WIZ', 'image': AppImages.ktwiz},
    {'name': 'LG 트윈스', 'image': AppImages.twins},
    {'name': 'NC 다이노스', 'image': AppImages.dinos},
    {'name': 'SSG 랜더스', 'image': AppImages.landers},
  ];

  // 구장 리스트 추가 (images를 List<String>으로 변경)
  final List<Map<String, dynamic>> stadiumListWithImages = [
    {'name': '잠실 야구장', 'images': [AppImages.bears, AppImages.twins]}, // 두산, LG 홈구장
    {'name': '사직 야구장', 'images': [AppImages.giants]},
    {'name': '고척 SKYDOME', 'images': [AppImages.kiwoom]},
    {'name': '대구삼성라이온즈파크', 'images': [AppImages.lions]},
    {'name': '한화생명 볼파크', 'images': [AppImages.eagles]},
    {'name': '기아 챔피언스 필드', 'images': [AppImages.tigers]},
    {'name': '수원 케이티 위즈 파크', 'images': [AppImages.ktwiz]},
    {'name': '창원 NC파크', 'images': [AppImages.dinos]},
    {'name': '인천 SSG 랜더스필드', 'images': [AppImages.landers]},
    {'name': '직접 작성하기', 'images': []}, // 이미지 없는 옵션
  ];

  final Map<String, String> _stadiumMapping = {
    '잠실': '잠실 야구장',
    '문학': '인천 SSG 랜더스필드',
    '대구': '대구삼성라이온즈파크',
    '수원': '수원 케이티 위즈 파크',
    '광주': '기아 챔피언스 필드',
    '창원': '창원 NC파크',
    '고척': '고척 SKYDOME',
    '대전(신)': '한화생명 볼파크',
    '사직': '사직 야구장',
  };

  // OCR에서 추출된 구장명을 정식 이름으로 변환
  String? mapStadiumName(String? extractedName) {
    if (extractedName == null || extractedName.isEmpty) return null;

    final cleaned = extractedName.trim();

    // 정확히 일치하는 경우
    if (_stadiumMapping.containsKey(cleaned)) {
      return _stadiumMapping[cleaned];
    }

    // 부분 일치 검색 (대소문자 무시)
    for (final entry in _stadiumMapping.entries) {
      if (cleaned.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(cleaned.toLowerCase())) {
        return entry.value;
      }
    }

    // 매핑되지 않은 경우 원본 반환
    return extractedName;
  }

  // OCR에서 추출한 'KIA' 같은 축약명을 팀 풀네임으로 변환해주는 함수 (나중에 picker에서 사용하기 위해)
  String? mapCorpToFullName(String shortName) {
    final cleaned = shortName.trim();
    for (final team in teamListWithImages) {
      final fullName = team['name']!;
      final corp = _teamToCorp[fullName]?.trim();
      if (corp == cleaned) return fullName;
    }
    return null;
  }

  bool get isComplete {
    final home = selectedHome ?? extractedHomeTeam;
    final away = selectedAway ?? extractedAwayTeam;
    final dateTime = selectedDateTime ?? extractedDate; // extractedTime 제거
    final seat = selectedSeat ?? extractedSeat;
    final stadium = selectedStadium ?? extractedStadium;

    return home?.isNotEmpty == true &&
        away?.isNotEmpty == true &&
        dateTime?.isNotEmpty == true &&
        seat?.isNotEmpty == true &&
        stadium?.isNotEmpty == true;
  }

  @override
  void initState() {
    super.initState();

    if (widget.preExtractedAwayTeam != null) {
      extractedAwayTeam = widget.preExtractedAwayTeam;
    }
    if (widget.preExtractedDate != null) {
      extractedDate = widget.preExtractedDate;
    }
    if (widget.preExtractedTime != null) {
      extractedTime = widget.preExtractedTime;
    }

    // OCR 및 팝업 노출을 첫 프레임 이후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _processImage(widget.imagePath);
      // _handleImage 내부에서 인식 실패 시 _showMissingInfoDialog가 호출됩니다.
    });
  }


  void _showMissingInfoDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomPopupDialog(
        imageAsset: AppImages.icAlert,
        title: '티켓 속 정보를\n인식하지 못했어요',
        subtitle: '다시 선택하거나 정보를 직접 입력해 주세요',
        firstButtonText: '직접 입력',
        firstButtonAction: () {
          Navigator.pop(context);
          // 팝업만 닫고, 사용자가 직접 입력하도록 유도
        },
        secondButtonText: '다시 선택하기',
        secondButtonAction: () async {
          Navigator.pop(context);
          await _pickImage(); // 이미지 다시 선택
        },
      ),
    );
  }

  Future<void> _handleImage(String path, {bool updateSelectedImage = true}) async {
    try {

      // 이미지를 변경하면 OCR 자동 입력 및 수동 입력 관련 상태 초기화
      setState(() {
        rawOcrText = '';
        extractedHomeTeam = null;
        extractedAwayTeam = null;
        extractedDate = null;
        extractedTime = null;
        extractedStadium = null;
        extractedSeat = null;

        selectedHome = null;
        selectedAway = null;
        selectedDateTime = null;
        selectedStadium = null;
        selectedSeat = null;
      });

      final inputImage = InputImage.fromFile(File(path));
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final result = await textRecognizer.processImage(inputImage);
      rawOcrText = result.text;
      print('📄 OCR 전체 텍스트:\n$rawOcrText');

      final cleanedText = rawOcrText.replaceAll(RegExp(r'\s+'), ' ').trim();
      extractedAwayTeam = extractAwayTeam(cleanedText, _teamToCorp, _teamKeywords);
      extractedDate = extractDate(cleanedText);
      extractedTime = extractTime(cleanedText);

      if (extractedAwayTeam == null || extractedAwayTeam!.isEmpty ||
          extractedDate == null || extractedDate!.isEmpty ||
          extractedTime == null || extractedTime!.isEmpty) {
        if (!widget.skipOcrFailPopup) {
          _showMissingInfoDialog(path);
        }
      }

      await _findMatchingGame(cleanedText);

      if (updateSelectedImage) {
        setState(() => _selectedImage = XFile(path));
      }
    } catch (e) {
      print('이미지 처리 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다')),
        );
      }
    }
  }

  Future<void> _processImage(String path) async {
    await _handleImage(path, updateSelectedImage: true);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _handleImage(pickedFile.path, updateSelectedImage: true);
    }
  }

  Future<void> _findMatchingGame(String cleanedText) async {
    matchedGames = [];
    if (extractedAwayTeam != null && extractedDate != null && extractedTime != null) {
      try {
        final game = await GameApi.searchGame(
          awayTeam: extractedAwayTeam!,
          date: extractedDate!,
          time: extractedTime!,
        );
        matchedGames = [game];
        extractedHomeTeam = game.homeTeam;
        extractedStadium = game.stadium;
        extractedSeat = extractSeat(cleanedText, game.stadium);

        print('🔍추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime, seat: $extractedSeat');

        debugMatchResult(
          isMatched: true,
          homeTeam: game.homeTeam,
          awayTeam: game.awayTeam,
          date: DateFormat('yyyy-MM-dd').format(game.date),
          time: extractedTime ?? '',
          stadium: extractedStadium!,
        );
      } catch (e) {
        print('DB 매칭 실패 오류: $e');
        debugMatchResult(isMatched: false);
      }
    }
  }


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
            // 🔙 뒤로가기 버튼
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
                                builder: (_) => const TicketOcrScreen()),
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

            // 📄 텍스트 타이틀
            Positioned(
              top: (screenHeight * 130 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: FixedText('티켓 정보 확인', style: AppFonts.h1_b(context)),
            ),
            Positioned(
              top: (screenHeight * 174 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: FixedText(
                '스캔한 정보와 다른 부분이 있다면 수정해 주세요.',
                style: AppFonts.b2_m(context).copyWith(
                    color: AppColors.gray300),
              ),
            ),

            // 🎟️ 이미지 미리보기
            Positioned(
              top: (screenHeight * 218 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 107.w,
                    height: screenHeight * 156 / baseScreenHeight,
                    color: Colors.grey[200],
                    child: _selectedImage != null
                        ? Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    )
                        : const Center(
                      child: FixedText('  처리 중..'),
                    ),
                  ),
                ),
              ),
            ),


            // 🏠 홈 구단
            Positioned(
              top: (screenHeight * 218 / baseScreenHeight) - statusBarHeight,
              left: 151.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FixedText('홈 구단', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                      SizedBox(width: 2.w),
                      FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () async {
                      final team = await showTeamPicker(
                        context: context,
                        title: '홈 구단',
                        teams: teamListWithImages,
                        initial: selectedHome ?? mapCorpToFullName(
                            extractedHomeTeam ?? ''),
                      );
                      if (team != null) setState(() => selectedHome = team);
                    },
                    child: Container(
                      width: 189.w,
                      height: screenHeight * 48 / baseScreenHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FixedText(
                        (selectedHome ?? mapCorpToFullName(extractedHomeTeam ?? '')) ?? '구단을 선택해 주세요',
                        style: AppFonts.b3_sb_long(context).copyWith(
                          color: ((selectedHome ?? extractedHomeTeam) == null ||
                              (selectedHome ?? extractedHomeTeam)!.isEmpty)
                              ? AppColors.gray300
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🛫 원정 구단
            Positioned(
              top: (screenHeight * 306 / baseScreenHeight) - statusBarHeight,
              left: 151.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FixedText('원정 구단', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                      SizedBox(width: 2.w),
                      FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () async {
                      final team = await showTeamPicker(
                        context: context,
                        title: '원정 구단',
                        teams: teamListWithImages,
                        initial: selectedAway ?? mapCorpToFullName(
                            extractedAwayTeam ?? ''),
                      );
                      if (team != null) setState(() => selectedAway = team);
                    },
                    child: Container(
                      width: 189.w,
                      height: screenHeight * 48 / baseScreenHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FixedText(
                        (selectedAway ?? mapCorpToFullName(extractedAwayTeam ?? '')) ?? '구단을 선택해 주세요',
                        style: AppFonts.b3_sb_long(context).copyWith(
                          color: ((selectedAway ?? extractedAwayTeam) == null ||
                              (selectedAway ?? extractedAwayTeam)!.isEmpty)
                              ? AppColors.gray300
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🗓️ 일시
            Positioned(
              top: (screenHeight * 398 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FixedText('일시', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                      SizedBox(width: 2.w),
                      FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () async {
                      final home = selectedHome ?? mapCorpToFullName(extractedHomeTeam ?? '');
                      final away = selectedAway ?? mapCorpToFullName(extractedAwayTeam ?? '');

                      if (home == null || home.isEmpty || away == null || away.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: FixedText('홈 구단과 원정 구단을 먼저 선택해 주세요.')),
                        );
                        return;
                      }

                      final dt = await showDateTimePicker(
                        context: context,
                        ocrDateText: extractedDate,
                        homeTeam: home,
                        opponentTeam: away,
                      );
                      if (dt != null) setState(() => selectedDateTime = dt);
                    },
                    child: Container(
                      width: 320.w,
                      height: screenHeight * 52 / baseScreenHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FixedText(
                        selectedDateTime ?? formatKoreanDateTime(extractedDate, extractedTime)
                            ?? '경기 날짜를 선택해 주세요', // 단순화
                        style: AppFonts.b3_sb_long(context).copyWith(
                          color: (selectedDateTime == null && extractedDate == null && extractedTime == null)
                              ? AppColors.gray300
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🏟️ 구장 - showStadiumPicker로 변경
            Positioned(
              top: (screenHeight * 482 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FixedText('구장', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                      SizedBox(width: 2.w),
                      FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () async {
                      final stadium = await showStadiumPicker(
                        context: context,
                        title: '구장',
                        stadiums: stadiumListWithImages, // 구장 리스트 사용
                        initial: selectedStadium ?? mapStadiumName(extractedStadium), // 현재 선택된 값을 initial로 전달
                      );
                      if (stadium != null) {
                        setState(() => selectedStadium = stadium);
                      }
                    },
                    child: Container(
                      width: 320.w,
                      height: screenHeight * 52 / baseScreenHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FixedText(
                        selectedStadium ?? mapStadiumName(extractedStadium) ?? '구장 정보를 작성해 주세요',
                        style: AppFonts.b3_sb_long(context).copyWith(
                          color: ((selectedStadium ?? extractedStadium) == null ||
                              (selectedStadium ?? extractedStadium)!.isEmpty)
                              ? AppColors.gray300
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FixedText(
                    '*홈 구장과 실제 경기 구장이 다를 경우 직접 작성해 주세요',
                    style: AppFonts.c2_sb(context).copyWith(
                        color: AppColors.gray300),
                  ),
                ],
              ),
            ),

            // 🎫 좌석
            Positioned(
              top: (screenHeight * 592 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FixedText('좌석', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                      SizedBox(width: 2.w),
                      FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () async {
                      final seat = await showSeatInputDialog(
                        context,
                        initial: selectedSeat,
                      );
                      if (seat != null) setState(() => selectedSeat = seat);
                    },
                    child: Container(
                      width: 320.w,
                      height: screenHeight * 52 / baseScreenHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FixedText(
                        selectedSeat ?? extractedSeat ?? '좌석 정보를 작성해 주세요',
                        style: AppFonts.b3_sb_long(context).copyWith(
                          color: ((selectedSeat ?? extractedSeat) == null ||
                              (selectedSeat ?? extractedSeat)!.isEmpty)
                              ? AppColors.gray300
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FixedText(
                    '*상세 좌석 정보는 나에게만 보여요',
                    style: AppFonts.c2_sb(context).copyWith(
                        color: AppColors.gray300),
                  ),
                ],
              ),
            ),

            // ✅ 완료 버튼
            Positioned(
              top: (screenHeight * 688 / baseScreenHeight) - statusBarHeight,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                width: 360.w,
                height: screenHeight * 88 / baseScreenHeight,
                padding: EdgeInsets.only(
                  top: screenHeight * 24 / baseScreenHeight,
                  left: 20.w,
                  right: 20.w,
                  bottom: screenHeight * 10 / baseScreenHeight,
                ),
                child: ElevatedButton(
                  onPressed: isComplete
                      ? () {
                    final String finalStadium = selectedStadium ?? extractedStadium ?? '';
                    final String finalSeat = selectedSeat ?? extractedSeat ?? '';
                    final String finalGameId = matchedGames.isNotEmpty ? matchedGames.first.gameId : '';
                    final int userId = 1; // 또는 사용자 세션에서 불러오기

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmotionSelectScreen(
                          userId: userId,
                          gameId: finalGameId,
                          seatInfo: finalSeat,
                          stadium: finalStadium,
                        ),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isComplete ? AppColors.gray700 : AppColors.gray200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                  ),
                  child: FixedText('완료',
                      style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20)),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}