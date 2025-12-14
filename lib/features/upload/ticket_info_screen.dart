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
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/upload/show_team_picker.dart';
import 'package:frontend/features/upload/show_stadium_picker.dart';
import 'package:frontend/features/upload/show_date_time_picker.dart';
import 'package:frontend/features/upload/show_seat_picker.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';
import 'package:frontend/features/upload/emotion_select_screen.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_popup_dialog.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/upload/providers/record_state.dart';

class TicketInfoScreen extends StatefulWidget {
  final String imagePath;
  final bool skipOcrFailPopup;
  final bool isEditMode;
  final int? recordId;

  const TicketInfoScreen({
    Key? key,
    required this.imagePath,
    this.skipOcrFailPopup = false,
    this.isEditMode = false,
    this.recordId,
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

  String? selectedGameId;

  // 날짜(yyyy-MM-dd) → '2025 - 04 - 15 (수)' 형식
  String? formatKoreanDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final date = DateTime.parse(dateStr);
      final weekday = DateFormat('E', 'ko_KR').format(date);
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

  // "2025-09-11 18:30:00" → "2025 - 09 - 11 (목) 18시 30분" 형식
  String? formatSelectedDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    try {
      // "2025-09-11 18:30:00" 형식을 파싱
      final parts = dateTimeStr.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0]; // "2025-09-11"
        final timePart = parts[1]; // "18:30:00"
        return formatKoreanDateTime(datePart, timePart);
      }
      return dateTimeStr;
    } catch (e) {
      return dateTimeStr;
    }
  }

  List<GameResponse> matchedGames = [];

  final Map<String, String> _teamToCorp = {
    'KIA 타이거즈': 'KIA', 'KIA': 'KIA', '두산 베어스': '두산', '두산': '두산',
    '롯데 자이언츠': '롯데', '롯데': '롯데', '삼성 라이온즈': '삼성', '삼성': '삼성',
    '키움 히어로즈': '키움', '키움': '키움', '한화 이글스': '한화', '한화': '한화',
    'KT WIZ': 'KT', 'KT': 'KT', 'LG 트윈스': 'LG', 'LG': 'LG',
    'NC 다이노스': 'NC', 'NC': 'NC', 'SSG 랜더스': 'SSG', 'SSG': 'SSG',
    '자이언츠': '롯데', '타이거즈': 'KIA', '라이온즈': '삼성', '히어로즈': '키움',
    '이글스': '한화', 'WIZ': 'KT', '트윈스': 'LG', '다이노스': 'NC',
    '랜더스': 'SSG', '베어스': '두산', 'Eagles': '한화'
  };

  final List<String> _teamKeywords = [
    'KIA 타이거즈', '두산 베어스', '롯데 자이언츠', '삼성 라이온즈', '키움 히어로즈', '한화 이글스',
    'KT WIZ', 'LG 트윈스', 'NC 다이노스', 'SSG 랜더스', '자이언츠', '타이거즈', '라이온즈',
    '히어로즈', '이글스', '트윈스', '다이노스', '랜더스', '베어스', 'Eagles', 'KIA', '두산',
    '롯데', '삼성', '키움', '한화', 'KT', 'LG', 'NC', 'SSG', 'WIZ'
  ];
  final List<Map<String, String>> teamListWithImages = [
    {'name': '두산 베어스', 'image': AppImages.bears},
    {'name': '롯데 자이언츠', 'image': AppImages.giants},
    {'name': '삼성 라이온즈', 'image': AppImages.lions},
    {'name': '키움 히어로즈', 'image': AppImages.kiwoom},
    {'name': '한화 이글스', 'image': AppImages.eagles},
    {'name': 'KIA 타이거즈', 'image': AppImages.tigers},
    {'name': 'KT WIZ', 'image': AppImages.ktwiz},
    {'name': 'LG 트윈스', 'image': AppImages.twins},
    {'name': 'NC 다이노스', 'image': AppImages.dinos},
    {'name': 'SSG 랜더스', 'image': AppImages.landers},
  ];


  final List<Map<String, dynamic>> stadiumListWithImages = [
    {'name': '잠실 야구장', 'images': [AppImages.bears, AppImages.twins]},
    {'name': '사직 야구장', 'images': [AppImages.giants]},
    {'name': '대구삼성라이온즈파크', 'images': [AppImages.lions]},
    {'name': '고척 SKYDOME', 'images': [AppImages.kiwoom]},
    {'name': '한화생명 볼파크', 'images': [AppImages.eagles]},
    {'name': '기아 챔피언스 필드', 'images': [AppImages.tigers]},
    {'name': '수원 케이티 위즈 파크', 'images': [AppImages.ktwiz]},
    {'name': '창원 NC 파크', 'images': [AppImages.dinos]},
    {'name': '인천 SSG 랜더스필드', 'images': [AppImages.landers]},
  ];

  final Map<String, String> _stadiumMapping = {
    '잠실': '잠실 야구장', '문학': '인천 SSG 랜더스필드', '대구': '대구삼성라이온즈파크',
    '수원': '수원 케이티 위즈 파크', '광주': '기아 챔피언스 필드', '창원': '창원 NC 파크',
    '고척': '고척 SKYDOME', '대전(신)': '한화생명 볼파크', '사직': '사직 야구장',
  };

  String? mapStadiumName(String? extractedName) {
    if (extractedName == null || extractedName.isEmpty) return null;
    final cleaned = extractedName.trim();
    if (_stadiumMapping.containsKey(cleaned)) {
      return _stadiumMapping[cleaned];
    }
    for (final entry in _stadiumMapping.entries) {
      if (cleaned.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(cleaned.toLowerCase())) {
        return entry.value;
      }
    }
    return extractedName;
  }

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
    final dateTime = selectedDateTime ?? extractedDate;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordState = Provider.of<RecordState>(context, listen: false);

      // ✨ 디버그 로그 추가
      print('📖 TicketInfoScreen initState:');
      print('  recordState.selectedHome: ${recordState.selectedHome}');
      print('  recordState.selectedAway: ${recordState.selectedAway}');
      print('  recordState.selectedDateTime: ${recordState.selectedDateTime}');
      print('  recordState.selectedStadium: ${recordState.selectedStadium}');
      print('  recordState.gameId: ${recordState.gameId}');

      if (widget.isEditMode && widget.recordId != null) {
        // 수정 모드: RecordState에서 데이터 복원
        setState(() {
          selectedHome = recordState.selectedHome;
          selectedAway = recordState.selectedAway;
          selectedDateTime = recordState.selectedDateTime;
          selectedStadium = recordState.selectedStadium;
          selectedSeat = recordState.selectedSeat;
          selectedGameId = recordState.gameId;

          // extracted 값 복원
          extractedHomeTeam = recordState.extractedHomeTeam;
          extractedAwayTeam = recordState.extractedAwayTeam;
          extractedDate = recordState.extractedDate;
          extractedTime = recordState.extractedTime;
          extractedStadium = recordState.extractedStadium;
          extractedSeat = recordState.extractedSeat;
        });

        // 이미지 설정
        if (widget.imagePath.isNotEmpty) {
          _selectedImage = XFile(widget.imagePath);
        }
      } else if (widget.imagePath.isNotEmpty) {
        // ✨ OCR 스캔에서 온 경우: RecordState에 이미 데이터가 있는지 확인
        if (recordState.selectedHome != null || recordState.selectedAway != null) {
          // OCR 스캔 완료 후 넘어온 경우 - RecordState에서 정보 가져오기
          print('✅ OCR 스캔 완료 상태: RecordState에서 정보 복원');
          setState(() {
            selectedHome = recordState.selectedHome;
            selectedAway = recordState.selectedAway;
            selectedDateTime = recordState.selectedDateTime;
            selectedStadium = recordState.selectedStadium;
            selectedSeat = recordState.selectedSeat;
            selectedGameId = recordState.gameId;

            extractedHomeTeam = recordState.extractedHomeTeam;
            extractedAwayTeam = recordState.extractedAwayTeam;
            extractedDate = recordState.extractedDate;
            extractedTime = recordState.extractedTime;
            extractedStadium = recordState.extractedStadium;
            extractedSeat = recordState.extractedSeat;

            _selectedImage = XFile(widget.imagePath);
          });
        } else {
          // 갤러리에서 직접 선택한 경우 - OCR 실행
          print('🔄 갤러리 선택: OCR 실행 필요');
          _processImage(widget.imagePath);
        }
      }
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
        },
        secondButtonText: '다시 선택하기',
        secondButtonAction: () async {
          Navigator.pop(context);
          await _pickImage();
        },
      ),
    );
  }

  Future<void> _handleImage(String path, {bool updateSelectedImage = true}) async {
    try {
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

        setState(() {
          selectedGameId = game.gameId; // 성공 시 설정
        });

        final mappedStadiumForSeat = mapStadiumName(game.stadium) ?? game.stadium;
        final parsedSeat = parseSeatStringWithMapping(cleanedText, stadium: mappedStadiumForSeat);

        if (parsedSeat != null) {
          final zone = parsedSeat['zone'] ?? '';
          final block = parsedSeat['block'] ?? '';
          final row = parsedSeat['row'] ?? '';
          final num = parsedSeat['num'] ?? '';

          if (zone.isNotEmpty && block.isNotEmpty && num.isNotEmpty) {
            if (row.isNotEmpty) {
              extractedSeat = '$zone ${block}블럭 ${row}열 ${num}번';
            } else {
              extractedSeat = '$zone ${block}블럭 ${num}번';
            }
          } else if (zone.isNotEmpty && num.isNotEmpty) {
            if (row.isNotEmpty) {
              extractedSeat = '$zone ${row}열 ${num}번';
            } else {
              extractedSeat = '$zone ${num}번';
            }
          } else if (num.isNotEmpty) {
            extractedSeat = '${num}번';
          }
        }

        print('🔍추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime');
        print('🏟️ 구장 매핑: ${game.stadium} → $mappedStadiumForSeat');
        print('🎫 추출된 좌석: $extractedSeat');

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
        setState(() {
          selectedGameId = null;  // ← 실패 시 null로 초기화
        });
        debugMatchResult(isMatched: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (widget.isEditMode) {
            // 수정 모드: RecordState 복원하고 detail_feed로
            final recordState = Provider.of<RecordState>(context, listen: false);
            recordState.restoreFromBackup();
            Navigator.of(context).pop();
          } else {
            // 일반 모드: TicketOcrScreen으로
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => TicketOcrScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // 뒤로가기 영역
                  Container(
                    width: double.infinity,
                    height: scaleHeight(60),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: scaleWidth(20)),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.isEditMode) {
                          // 수정 모드: RecordState 복원하고 detail_feed로
                          final recordState = Provider.of<RecordState>(context, listen: false);
                          recordState.restoreFromBackup();
                          Navigator.of(context).pop();
                        } else {
                          // 일반 모드: TicketOcrScreen으로
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => TicketOcrScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        }
                      },
                      child: SvgPicture.asset(
                        AppImages.backBlack,
                        width: scaleWidth(24),
                        height: scaleHeight(24),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // 콘텐츠 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: scaleHeight(18)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                          child: FixedText(
                            '티켓 정보 확인',
                            style: AppFonts.pretendard.title_lg_600(context).copyWith(color: AppColors.gray900),
                          ),
                        ),
                        SizedBox(height: scaleHeight(4)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                          child: FixedText(
                            '스캔한 정보와 다른 부분이 있다면 수정해 주세요',
                            style: AppFonts.pretendard.body_md_400(context).copyWith(color: AppColors.gray300),
                          ),
                        ),
                        SizedBox(height: scaleHeight(24)),

                        // 메인 영역
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 이미지 미리보기 + 홈/원정 구단
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: scaleWidth(107),
                                          height: scaleHeight(156),
                                          color: Colors.grey[200],
                                          child: _selectedImage != null
                                              ? (_selectedImage!.path.startsWith('http')
                                              ? Image.network(
                                            _selectedImage!.path,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(Icons.image, color: Colors.grey),
                                              );
                                            },
                                          )
                                              : Image.file(
                                            File(_selectedImage!.path),
                                            fit: BoxFit.cover,
                                          ))
                                              : Center(
                                            child: Icon(
                                              Icons.add_photo_alternate,  // ← 이 부분도 바꿉니다 (조건문 삭제)
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: scaleWidth(24)),

                                    // 홈/원정 구단 영역
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 홈 구단
                                          Row(
                                            children: [
                                              SizedBox(height: scaleHeight(1)),
                                              FixedText('홈 구단', style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray600)),
                                              SizedBox(width: scaleWidth(2)),
                                              FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700)),
                                            ],
                                          ),
                                          SizedBox(height: scaleHeight(4)),
                                          GestureDetector(
                                            onTap: () async {
                                              final team = await showTeamPicker(
                                                context: context,
                                                title: '홈 구단',
                                                teams: teamListWithImages,
                                                initial: selectedHome ?? mapCorpToFullName(extractedHomeTeam ?? ''),
                                              );
                                              if (team != null) setState(() => selectedHome = team);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              height: scaleHeight(48),
                                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                              alignment: Alignment.centerLeft,
                                              decoration: BoxDecoration(
                                                color: AppColors.gray50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: FixedText(
                                                      (selectedHome ?? mapCorpToFullName(extractedHomeTeam ?? '')) ?? '구단을 선택해 주세요',
                                                      style: AppFonts.pretendard.body_sm_400(context).copyWith(
                                                        color: ((selectedHome ?? extractedHomeTeam) == null || (selectedHome ?? extractedHomeTeam)!.isEmpty)
                                                            ? AppColors.gray300 : AppColors.gray900,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: scaleWidth(14)),
                                                  SvgPicture.asset(AppImages.dropdown, width: scaleWidth(20), height: scaleHeight(20), fit: BoxFit.contain),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: scaleHeight(15)),

                                          // 원정 구단
                                          Row(
                                            children: [
                                              FixedText('원정 구단', style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray600)),
                                              SizedBox(width: scaleWidth(2)),
                                              FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700)),
                                            ],
                                          ),
                                          SizedBox(height: scaleHeight(4)),
                                          GestureDetector(
                                            onTap: () async {
                                              final team = await showTeamPicker(
                                                context: context,
                                                title: '원정 구단',
                                                teams: teamListWithImages,
                                                initial: selectedAway ?? mapCorpToFullName(extractedAwayTeam ?? ''),
                                              );
                                              if (team != null) setState(() => selectedAway = team);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              height: scaleHeight(48),
                                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                              alignment: Alignment.centerLeft,
                                              decoration: BoxDecoration(
                                                color: AppColors.gray50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: FixedText(
                                                      (selectedAway ?? mapCorpToFullName(extractedAwayTeam ?? '')) ?? '구단을 선택해 주세요',
                                                      style: AppFonts.pretendard.body_sm_400(context).copyWith(
                                                        color: ((selectedAway ?? extractedAwayTeam) == null || (selectedAway ?? extractedAwayTeam)!.isEmpty)
                                                            ? AppColors.gray300 : AppColors.gray900,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: scaleWidth(14)),
                                                  SvgPicture.asset(AppImages.dropdown, width: scaleWidth(20), height: scaleHeight(20), fit: BoxFit.contain),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: scaleHeight(14)),

                                // 일시
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        FixedText('일시', style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray600)),
                                        SizedBox(width: scaleWidth(2)),
                                        FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700)),
                                      ],
                                    ),
                                    SizedBox(height: scaleHeight(4)),
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

                                        final result = await showDateTimePicker(
                                          context: context,
                                          ocrDateText: extractedDate,
                                          homeTeam: home,
                                          opponentTeam: away,
                                        );
                                        if (result != null) {
                                          setState(() {
                                            selectedDateTime = result['dateTime']?.toString();
                                            selectedGameId = result['gameId']?.toString();
                                          });
                                          print('📅 선택된 일시: $selectedDateTime');
                                          print('🎮 선택된 gameId: $selectedGameId');
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: scaleHeight(52),
                                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          color: AppColors.gray50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: FixedText(
                                                selectedDateTime != null
                                                    ? (selectedDateTime!.contains(' - ')
                                                    ? selectedDateTime!
                                                    : (formatSelectedDateTime(selectedDateTime) ?? selectedDateTime!))
                                                    : formatKoreanDateTime(extractedDate, extractedTime) ?? '경기 날짜를 선택해 주세요',
                                                style: AppFonts.pretendard.body_sm_400(context).copyWith(
                                                  color: (selectedDateTime == null && extractedDate == null && extractedTime == null)
                                                      ? AppColors.gray300 : AppColors.gray900,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: scaleWidth(14)),
                                            SvgPicture.asset(AppImages.dropdown_calendar, width: scaleWidth(20), height: scaleHeight(20), fit: BoxFit.contain),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: scaleHeight(14)),

                                // 구장
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        FixedText('구장', style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray600)),
                                        SizedBox(width: scaleWidth(2)),
                                        FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700)),
                                      ],
                                    ),
                                    SizedBox(height: scaleHeight(4)),
                                    GestureDetector(
                                      onTap: () async {
                                        final previousStadium = selectedStadium ?? mapStadiumName(extractedStadium) ?? extractedStadium;
                                        final stadium = await showStadiumPicker(
                                          context: context,
                                          title: '구장',
                                          stadiums: stadiumListWithImages,
                                          initial: previousStadium,
                                        );
                                        if (stadium != null) {
                                          setState(() {
                                            selectedStadium = stadium;
                                            if (stadium != previousStadium) {
                                              selectedSeat = null;
                                              extractedSeat = null;
                                            }
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: scaleHeight(52),
                                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          color: AppColors.gray50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: FixedText(
                                                selectedStadium ?? mapStadiumName(extractedStadium) ?? extractedStadium ?? '구장 정보를 작성해 주세요',
                                                style: AppFonts.pretendard.body_sm_400(context).copyWith(
                                                  color: (selectedStadium ?? mapStadiumName(extractedStadium) ?? extractedStadium) == null
                                                      ? AppColors.gray300 : AppColors.gray900,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: scaleWidth(14)),
                                            SvgPicture.asset(AppImages.dropdown, width: scaleWidth(20), height: scaleHeight(20), fit: BoxFit.contain),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: scaleHeight(14)),

                                // 좌석
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        FixedText('좌석', style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray600)),
                                        SizedBox(width: scaleWidth(2)),
                                        FixedText('*', style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri700)),
                                      ],
                                    ),
                                    SizedBox(height: scaleHeight(4)),
                                    GestureDetector(
                                      onTap: () async {
                                        FocusScope.of(context).unfocus();
                                        final currentStadium = selectedStadium ?? mapStadiumName(extractedStadium) ?? extractedStadium;
                                        final seat = await showSeatInputDialog(
                                          context,
                                          initial: selectedSeat ?? extractedSeat,
                                          stadium: currentStadium,
                                          previousStadium: currentStadium,
                                        );
                                        if (seat != null) setState(() => selectedSeat = seat);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: scaleHeight(52),
                                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          color: AppColors.gray50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: FixedText(
                                                selectedSeat ?? extractedSeat ?? '좌석 정보를 작성해 주세요',
                                                style: AppFonts.pretendard.body_sm_400(context).copyWith(
                                                  color: (selectedSeat ?? extractedSeat) == null || (selectedSeat ?? extractedSeat)!.isEmpty
                                                      ? AppColors.gray300 : AppColors.gray900,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: scaleWidth(14)),
                                            SvgPicture.asset(
                                              AppImages.dropdown,
                                              width: scaleWidth(20),
                                              height: scaleHeight(20),
                                              fit: BoxFit.contain,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: scaleHeight(4)),
                                    FixedText(
                                      '*상세 좌석 정보는 나에게만 보여요',
                                      style: AppFonts.pretendard.caption_re_400(context).copyWith(color: AppColors.gray300),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 완료 버튼 영역
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
                            onPressed: isComplete ? () {
                              final recordState = Provider.of<RecordState>(context, listen: false);

                              recordState.setTicketInfo(
                                ticketImagePath: _selectedImage?.path ?? widget.imagePath,
                                selectedHome: selectedHome ?? extractedHomeTeam,
                                selectedAway: selectedAway ?? extractedAwayTeam,
                                selectedDateTime: selectedDateTime ?? formatKoreanDateTime(extractedDate, extractedTime),
                                selectedStadium: selectedStadium ?? extractedStadium,
                                selectedSeat: selectedSeat ?? extractedSeat,
                                extractedHomeTeam: extractedHomeTeam,
                                extractedAwayTeam: extractedAwayTeam,
                                extractedDate: extractedDate,
                                extractedTime: extractedTime,
                                extractedStadium: extractedStadium,
                                extractedSeat: extractedSeat,
                                gameId: selectedGameId ?? recordState.gameId,
                              );

                              if (widget.isEditMode) {
                                // 수정 모드: EmotionSelectScreen으로
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => EmotionSelectScreen(
                                      isEditMode: true,
                                      recordId: widget.recordId,
                                    ),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              } else {
                                // 일반 모드: EmotionSelectScreen으로
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => EmotionSelectScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              }
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isComplete ? AppColors.gray700 : AppColors.gray200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(scaleHeight(16)),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: Center(
                              child: FixedText(
                                '완료',
                                style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}