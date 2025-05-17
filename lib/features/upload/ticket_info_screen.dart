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
import 'package:frontend/features/upload/show_date_time_picker.dart';
import 'package:frontend/features/upload/show_seat_picker.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';

class TicketInfoScreen extends StatefulWidget {
  final String imagePath; // 이미지 경로 받기

  const TicketInfoScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<TicketInfoScreen> createState() => _TicketInfoScreenState();
}

class _TicketInfoScreenState extends State<TicketInfoScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    // 이미지 OCR 시작
    _processImage(widget.imagePath); // 이미지 처리 시작
  }

  Future<void> _processImage(String path) async {
    final inputImage = InputImage.fromFile(File(path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final recognizedText = await textRecognizer.processImage(inputImage);

    final text = recognizedText.text;
    print('📄 OCR 결과:\n$text');

    _extractTicketInfo(text); // 날짜, 시간, 팀 추출
    await _findMatchingGame(); // DB에서 매치된 경기 조회

    setState(() {
      _selectedImage = XFile(path); // UI에 표시할 이미지 저장
    });
  }

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

  // OCR 결과로 채워지는 값들 (기존 로직 유지)
  String? extractedHomeTeam;
  String? extractedAwayTeam;
  String? extractedDate;
  String? extractedTime;
  String? extractedSeat;

  // 수동 선택용 상태
  String? selectedHome;
  String? selectedAway;
  String? selectedDateTime; // 'YYYY-MM-DD HH:mm:00'
  String? selectedSeat;

  // 팀 리스트
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


  // OCR에서 추출한 'KIA' 같은 축약명을 팀 풀네임으로 변환해주는 함수 (나중에 picker에서 사용하기 위해)
  String? mapCorpToFullName(String shortName) {
    try {
      return teamListWithImages
          .firstWhere((team) => _teamToCorp[team['name']] == shortName)['name'];
    } catch (e) {
      return null; // 매칭 실패 시 null 반환
    }
  }

  //완료 조건 함수 정의
  bool get isComplete {
    final home = selectedHome ?? extractedHomeTeam;
    final away = selectedAway ?? extractedAwayTeam;
    final dateTime = selectedDateTime ?? ((extractedDate != null && extractedTime != null) ? '$extractedDate $extractedTime' : null);
    final seat = selectedSeat ?? extractedSeat;

    return home?.isNotEmpty == true &&
        away?.isNotEmpty == true &&
        dateTime?.isNotEmpty == true &&
        seat?.isNotEmpty == true;
  }


  List<GameResponse> matchedGames = [];

  // 📌 현재는 사용하지 않지만 추후 사진보관함에서 티켓 사진을 불러오는 기능을 위해 보존
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _selectedImage = pickedFile);

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage);
    final text = recognizedText.text;
    print('📄 OCR 결과:\n$text');

    _extractTicketInfo(text);
    await _findMatchingGame();
    setState(() {});
  }

  void _extractTicketInfo(String text) {
    final lines = text.split('\n');
    String? awayTeam, date, time;

    final vsRegex = RegExp(r'[vV][sS]\s*(.+)');
    for (final line in lines) {
      final match = vsRegex.firstMatch(line.replaceAll(' ', ''));
      if (match != null) {
        final candidate = match.group(1)!.trim();
        for (final keyword in _teamKeywords) {
          if (candidate.contains(keyword.replaceAll(' ', ''))) {
            awayTeam = _teamToCorp[keyword];
            break;
          }
        }
        if (awayTeam != null) break;
      }
    }

    for (final line in lines) {
      date = extractDate(line) ?? date;
      time = extractTime(line) ?? time;
    }

    extractedAwayTeam = awayTeam;
    extractedDate = date;
    extractedTime = time;

    print(
        '🔎 추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime');
  }

  Future<void> _findMatchingGame() async {
    matchedGames = [];
    if (extractedAwayTeam != null && extractedDate != null &&
        extractedTime != null) {
      try {
        final game = await GameApi.searchGame(
          awayTeam: extractedAwayTeam!,
          date: extractedDate!,
          time: extractedTime!,
        );
        matchedGames = [game];

        extractedHomeTeam = game.homeTeam;

        debugMatchResult(
          isMatched: true,
          homeTeam: game.homeTeam,
          awayTeam: game.awayTeam,
          date: DateFormat('yyyy-MM-dd').format(game.date),
          time: extractedTime!,
        );
      } catch (e) {
        print('❌ 오류: $e');
        debugMatchResult(isMatched: false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const baseScreenHeight = 800.0;

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
              child: Text('티켓 정보 확인', style: AppFonts.h1_b(context)),
            ),
            Positioned(
              top: (screenHeight * 174 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: Text(
                '스캔한 정보와 다른 부분이 있다면 수정해 주세요.',
                style: AppFonts.b2_m(context).copyWith(
                    color: AppColors.gray300),
              ),
            ),

            // 🎟️ 이미지 미리보기
            Positioned(
              top: (screenHeight * 218 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 107.w,
                  height: screenHeight * 156 / baseScreenHeight,
                  color: Colors.grey[200],
                  child: _selectedImage != null
                      ? Image.file(
                      File(_selectedImage!.path), fit: BoxFit.cover)
                      : const Center(child: Text('이미지 분석 중입니다...')),
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
                      SizedBox(
                        width: 34.w,
                        height: 12.h,
                        child: Text('홈 구단',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray400)),
                      ),
                      SizedBox(width: 2.w),
                      SizedBox(
                        width: 7.w,
                        height: 12.h,
                        child: Text('*',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray200)),
                      ),
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
                      child: Text(
                        selectedHome ?? extractedHomeTeam ?? '구단을 선택해 주세요',
                        style: AppFonts.b3_m(context).copyWith(
                          color: ((selectedHome ?? extractedHomeTeam) == null ||
                              (selectedHome ?? extractedHomeTeam)!.isEmpty)
                              ? AppColors.gray500
                              : AppColors.gray800,
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
                      SizedBox(
                        width: 44.w,
                        height: 12.h,
                        child: Text('원정 구단',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray400)),
                      ),
                      SizedBox(width: 2.w),
                      SizedBox(
                        width: 7.w,
                        height: 12.h,
                        child: Text('*',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray200)),
                      ),
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
                      child: Text(
                        selectedAway ?? extractedAwayTeam ?? '구단을 선택해 주세요',
                        style: AppFonts.b3_m(context).copyWith(
                          color: ((selectedAway ?? extractedAwayTeam) == null ||
                              (selectedAway ?? extractedAwayTeam)!.isEmpty)
                              ? AppColors.gray500
                              : AppColors.gray800,
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
                      SizedBox(
                        width: 21.w,
                        height: 12.h,
                        child: Text('일시',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray400)),
                      ),
                      SizedBox(width: 2.w),
                      SizedBox(
                        width: 7.w,
                        height: 12.h,
                        child: Text('*',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray200)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () async {
                      final dt = await showDateTimePicker(
                        context: context,
                        ocrDateText: extractedDate,
                        homeTeam: selectedHome,
                        opponentTeam: selectedAway,
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
                      child: Text(
                        selectedDateTime ??
                            ((extractedDate != null && extractedTime != null)
                                ? '$extractedDate $extractedTime'
                                : '경기 날짜를 선택해 주세요'),
                        style: AppFonts.b3_m(context).copyWith(
                          color: (selectedDateTime == null &&
                              (extractedDate == null || extractedTime == null))
                              ? AppColors.gray500
                              : AppColors.gray800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🎫 좌석
            Positioned(
              top: (screenHeight * 498 / baseScreenHeight) - statusBarHeight,
              left: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 21.w,
                        height: 12.h,
                        child: Text('좌석',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray400)),
                      ),
                      SizedBox(width: 2.w),
                      SizedBox(
                        width: 7.w,
                        height: 12.h,
                        child: Text('*',
                            style: AppFonts.c1_b(context).copyWith(
                                color: AppColors.gray200)),
                      ),
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
                      child: Text(
                        selectedSeat ?? extractedSeat ?? '좌석 정보를 작성해 주세요',
                        style: AppFonts.b3_m(context).copyWith(
                          color: ((selectedSeat ?? extractedSeat) == null ||
                              (selectedSeat ?? extractedSeat)!.isEmpty)
                              ? AppColors.gray500
                              : AppColors.gray800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장 완료')),
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
                  child: Text('완료',
                      style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}