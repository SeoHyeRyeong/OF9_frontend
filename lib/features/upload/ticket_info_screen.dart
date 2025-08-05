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

// 좌석 매칭용 클래스
// 개선된 좌석 매칭용 클래스
class SeatParser {
  // 구역명 패턴들 (다양한 끝맺음 고려)
  static const List<String> zonePatterns = [
    r'(\S+(?:석|존|zone|Zone|ZONE))', // ~석, ~존, ~zone
    r'(\S+(?:테이블|table|Table|TABLE))', // ~테이블
    r'(\S+(?:박스|box|Box|BOX))', // ~박스
    r'(\S+(?:클럽|club|Club|CLUB))', // ~클럽
    r'(\S+(?:라이브|live|Live|LIVE))', // ~라이브
    r'(\S+(?:패밀리|family|Family))', // ~패밀리
    r'(\S+(?:커플|couple|Couple))', // ~커플
    r'(\S+(?:응원|cheer|Cheer))', // ~응원
    r'(\S+(?:VIP|vip|Vip))', // VIP
    r'(\S+(?:SKY|sky|Sky))', // SKY
    r'(\d+루\s*\S*)', // 1루~, 3루~
    r'(중앙\s*\S*)', // 중앙~
    r'(외야\s*\S*)', // 외야~
    r'(\S*캠핑\S*)', // ~캠핑~
    r'(\S*그린\S*)', // ~그린~
  ];

  // 블럭 패턴들
  static const List<String> blockPatterns = [
    r'(\S+)블럭', // ~블럭
    r'(\S+)구역', // ~구역
    r'([A-Z]\d+)', // A1, B2 등
    r'([A-Z]-\d+)', // A-1, B-2 등
    r'(\d+[A-Z])', // 1A, 2B 등
    r'(\S+)-(\d+)구역', // T1-1구역 등
    r'([TUS]-?\d+)', // T01, U-1, S-301 등
    r'(\d{3})', // 세자리 숫자 (101, 201 등)
    r'([A-Z]+\d*[A-Z]*)', // 복합 알파벳+숫자 패턴
  ];

  // 열 패턴들
  static const List<String> rowPatterns = [
    r'(\d+)열', // 숫자+열
    r'([A-Z])열', // 알파벳+열
    r'(\d+)row', // 숫자+row
    r'([A-Z])row', // 알파벳+row
  ];

  // 번호 패턴들
  static const List<String> numberPatterns = [
    r'(\d+)번', // 숫자+번
    r'(\d+)호', // 숫자+호
    r'(\d+)seat', // 숫자+seat
    r'No\.?\s*(\d+)', // No.1, No 1 등
  ];

  /// OCR 텍스트에서 좌석 정보를 파싱하여 구조화된 형태로 반환
  static Map<String, String>? parseAdvancedSeat(String? ocrText, String? stadium) {
    if (ocrText == null || ocrText.isEmpty) return null;

    final cleanedText = ocrText.replaceAll(RegExp(r'\s+'), ' ').trim();
    print('🎫 좌석 파싱 시작: $cleanedText');

    Map<String, String> result = {};

    // 1. 구역 찾기 (개선된 로직)
    String? foundZone = _findZoneAdvanced(cleanedText, stadium);
    if (foundZone != null) {
      result['zone'] = foundZone;
      print('🎯 구역 발견: $foundZone');
    }

    // 2. 블럭 찾기
    String? foundBlock = _findBlock(cleanedText, stadium, foundZone);
    if (foundBlock != null) {
      result['block'] = foundBlock;
      print('🎯 블럭 발견: $foundBlock');
    }

    // 3. 열 찾기
    String? foundRow = _findRow(cleanedText);
    if (foundRow != null) {
      result['row'] = foundRow;
      print('🎯 열 발견: $foundRow');
    }

    // 4. 번호 찾기
    String? foundNumber = _findNumber(cleanedText);
    if (foundNumber != null) {
      result['num'] = foundNumber;
      print('🎯 번호 발견: $foundNumber');
    }

    print('🎫 파싱 결과: $result');
    return result.isNotEmpty ? result : null;
  }

  /// 개선된 구역 찾기 - 실제 구장 데이터 우선 매칭
  static String? _findZoneAdvanced(String text, String? stadium) {
    print('🔍 구역 찾기 시작 - 텍스트: "$text", 구장: "$stadium"');

    // 해당 구장의 실제 구역명과 직접 매칭 시도
    if (stadium != null) {
      try {
        // StadiumSeatInfo에서 해당 구장의 구역 리스트 가져오기
        final zones = StadiumSeatInfo.getZones(stadium);

        print('🔍 구장 "$stadium"의 구역들: $zones');

        // 더 구체적이고 긴 구역명을 먼저 매칭 (길이순 정렬)
        final sortedZones = List<String>.from(zones)
          ..sort((a, b) => b.length.compareTo(a.length));

        print('📏 길이순 정렬된 구역들: $sortedZones');

        // 1차: 완전 일치 매칭 (대소문자 구분 없이)
        for (final zone in sortedZones) {
          if (text.toLowerCase().contains(zone.toLowerCase())) {
            print('✅ 완전 일치 발견: $zone');
            return zone;
          }
        }

        // 2차: 공백 및 특수문자 제거 후 매칭
        final cleanText = text.replaceAll(RegExp(r'[\s\-_]'), '').toLowerCase();
        for (final zone in sortedZones) {
          final cleanZone = zone.replaceAll(RegExp(r'[\s\-_]'), '').toLowerCase();
          if (cleanText.contains(cleanZone)) {
            print('✅ 공백 제거 후 일치 발견: $zone (clean: "$cleanZone" in "$cleanText")');
            return zone;
          }
        }

        // 3차: 순차적 키워드 매칭 (순서대로 모든 키워드가 포함되는지 확인)
        for (final zone in sortedZones) {
          if (_matchZoneSequentially(text, zone)) {
            print('✅ 순차 키워드 매칭 발견: $zone');
            return zone;
          }
        }

        // 4차: 핵심 키워드 기반 매칭
        for (final zone in sortedZones) {
          if (_matchZoneByKeywords(text, zone)) {
            print('✅ 핵심 키워드 매칭 발견: $zone');
            return zone;
          }
        }

        // 5차: 부분 키워드 매칭 (모든 단어가 포함되는지)
        for (final zone in sortedZones) {
          final zoneKeywords = zone.split(RegExp(r'[\s\-_]+'));
          if (zoneKeywords.length >= 2) {
            bool allFound = true;
            for (final keyword in zoneKeywords) {
              if (keyword.length > 1 && !text.toLowerCase().contains(keyword.toLowerCase())) {
                allFound = false;
                break;
              }
            }
            if (allFound) {
              print('✅ 부분 키워드 매칭 발견: $zone (키워드: $zoneKeywords)');
              return zone;
            }
          }
        }

      } catch (e) {
        print('❌ 구역 매칭 중 오류: $e');
      }
    }

    // 6차: 패턴 기반 매칭 (최후의 수단)
    for (final pattern in zonePatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        final matched = match.group(1);
        if (matched != null && matched.length >= 2) {
          print('⚠️ 패턴 매칭 발견: $matched');
          return matched;
        }
      }
    }

    print('❌ 구역을 찾을 수 없음');
    return null;
  }

  /// 순차적 키워드 매칭 - 구역명의 단어들이 텍스트에 순서대로 포함되는지 확인
  static bool _matchZoneSequentially(String text, String zone) {
    final zoneWords = zone.toLowerCase().split(RegExp(r'[\s\-_]+'));
    final textLower = text.toLowerCase();

    if (zoneWords.length < 2) return false; // 단일 단어는 제외

    int lastIndex = -1;
    for (final word in zoneWords) {
      if (word.length <= 1) continue; // 너무 짧은 단어 제외

      final foundIndex = textLower.indexOf(word, lastIndex + 1);
      if (foundIndex == -1) {
        return false; // 단어를 찾을 수 없음
      }
      lastIndex = foundIndex;
    }

    print('🔄 순차 매칭 성공: "$zone" 의 모든 단어가 순서대로 발견됨');
    return true;
  }

  /// 핵심 키워드 기반 구역 매칭
  static bool _matchZoneByKeywords(String text, String zone) {
    // 구역명을 핵심 키워드로 분해
    final keywords = _extractZoneKeywords(zone);

    if (keywords.isEmpty) return false;

    // 모든 핵심 키워드가 텍스트에 포함되어야 함
    int matchCount = 0;
    for (final keyword in keywords) {
      if (text.toLowerCase().contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }

    // 키워드의 70% 이상 매칭되면 성공으로 간주
    return matchCount >= (keywords.length * 0.7).ceil();
  }

  /// 구역명에서 핵심 키워드 추출
  static List<String> _extractZoneKeywords(String zone) {
    final keywords = <String>[];

    // 방향 키워드
    if (zone.contains('1루')) keywords.add('1루');
    if (zone.contains('3루')) keywords.add('3루');
    if (zone.contains('중앙')) keywords.add('중앙');
    if (zone.contains('외야')) keywords.add('외야');

    // 색상 키워드
    if (zone.contains('네이비')) keywords.add('네이비');
    if (zone.contains('블루')) keywords.add('블루');
    if (zone.contains('레드')) keywords.add('레드');
    if (zone.contains('오렌지')) keywords.add('오렌지');
    if (zone.contains('버건디')) keywords.add('버건디');
    if (zone.contains('다크버건디')) keywords.add('다크버건디');

    // 석종 키워드
    if (zone.contains('테이블')) keywords.add('테이블');
    if (zone.contains('박스')) keywords.add('박스');
    if (zone.contains('VIP')) keywords.add('VIP');
    if (zone.contains('SKY')) keywords.add('SKY');
    if (zone.contains('지정석')) keywords.add('지정석');
    if (zone.contains('내야')) keywords.add('내야');
    if (zone.contains('필드')) keywords.add('필드');
    if (zone.contains('상단')) keywords.add('상단');
    if (zone.contains('덕아웃')) keywords.add('덕아웃');
    if (zone.contains('응원')) keywords.add('응원');
    if (zone.contains('패밀리')) keywords.add('패밀리');
    if (zone.contains('커플')) keywords.add('커플');
    if (zone.contains('익사이팅')) keywords.add('익사이팅');
    if (zone.contains('휠체어')) keywords.add('휠체어');

    // 특수 키워드
    if (zone.contains('챔피언')) keywords.add('챔피언');
    if (zone.contains('라이브')) keywords.add('라이브');
    if (zone.contains('랜더스')) keywords.add('랜더스');
    if (zone.contains('으쓱이')) keywords.add('으쓱이');
    if (zone.contains('캠핑')) keywords.add('캠핑');
    if (zone.contains('그린')) keywords.add('그린');

    return keywords;
  }

  /// 블럭 찾기
  static String? _findBlock(String text, String? stadium, String? zone) {
    // 패턴 기반 매칭
    for (final pattern in blockPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        // 복합 패턴의 경우 (예: T1-1구역)
        if (match.groupCount >= 2 && match.group(2) != null) {
          return '${match.group(1)}-${match.group(2)}구역';
        }
        return match.group(1);
      }
    }

    return null;
  }

  /// 열 찾기
  static String? _findRow(String text) {
    for (final pattern in rowPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// 번호 찾기
  static String? _findNumber(String text) {
    for (final pattern in numberPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    // 마지막으로 단순 숫자 매칭 (1-4자리)
    final simpleNumber = RegExp(r'\b(\d{1,4})\b');
    final matches = simpleNumber.allMatches(text);
    if (matches.isNotEmpty) {
      // 가장 마지막 숫자를 좌석 번호로 간주
      return matches.last.group(1);
    }

    return null;
  }
}

// 실제 ticket_info_screen 클래스
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
      return '${date.year} - ${date.month.toString().padLeft(2, '0')} - ${date
          .day.toString().padLeft(2, '0')} ($weekday)';
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
    {'name': '잠실 야구장', 'images': [AppImages.bears, AppImages.twins]},
    // 두산, LG 홈구장
    {'name': '사직 야구장', 'images': [AppImages.giants]},
    {'name': '고척 SKYDOME', 'images': [AppImages.kiwoom]},
    {'name': '한화생명 볼파크', 'images': [AppImages.eagles]},
    {'name': '대구삼성라이온즈파크', 'images': [AppImages.lions]},
    {'name': '기아 챔피언스 필드', 'images': [AppImages.tigers]},
    {'name': '수원 케이티 위즈 파크', 'images': [AppImages.ktwiz]},
    {'name': '창원 NC파크', 'images': [AppImages.dinos]},
    {'name': '인천 SSG 랜더스필드', 'images': [AppImages.landers]},
    {'name': '직접 작성하기', 'images': []},
    // 이미지 없는 옵션
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
      builder: (context) =>
          CustomPopupDialog(
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

  Future<void> _handleImage(String path,
      {bool updateSelectedImage = true}) async {
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
      final textRecognizer = TextRecognizer(
          script: TextRecognitionScript.korean);
      final result = await textRecognizer.processImage(inputImage);
      rawOcrText = result.text;
      print('📄 OCR 전체 텍스트:\n$rawOcrText');

      final cleanedText = rawOcrText.replaceAll(RegExp(r'\s+'), ' ').trim();
      extractedAwayTeam =
          extractAwayTeam(cleanedText, _teamToCorp, _teamKeywords);
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
        extractedStadium = game.stadium;

        // <좌석 매칭용>
        final mappedStadiumForSeat = mapStadiumName(game.stadium) ??
            game.stadium;

        // 향상된 파싱 로직 사용
        final parsedSeat = SeatParser.parseAdvancedSeat(
            cleanedText, mappedStadiumForSeat);
        if (parsedSeat != null) {
          // 파싱된 정보를 문자열로 조합
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
            // 블럭 정보가 없어도 구역과 번호가 있으면 기본 형태로
            if (row.isNotEmpty) {
              extractedSeat = '$zone ${row}열 ${num}번';
            } else {
              extractedSeat = '$zone ${num}번';
            }
          } else if (num.isNotEmpty) {
            // 번호만 있는 경우
            extractedSeat = '${num}번';
          }
        }

        print(
            '🔍추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime');
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
        debugMatchResult(isMatched: false);
      }
    }
  }


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
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation1, animation2) => const TicketOcrScreen(),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                            },
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

                // 콘텐츠 영역
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
                              '티켓 정보 확인',
                              style: AppFonts.h1_b(context).copyWith(color: Colors.black),
                            ),
                          ),

                          const Spacer(flex: 18),

                          // 서브타이틀
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: FixedText(
                              '스캔한 정보와 다른 부분이 있다면 수정해 주세요.',
                              style: AppFonts.b2_m(context).copyWith(color: AppColors.gray300),
                            ),
                          ),

                          const Spacer(flex: 16),

                          // 메인 영역
                          Expanded(
                            flex: 520,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Spacer(flex: 20),

                                  // 이미지 + 홈/원정 구단 영역
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 이미지 미리보기
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: scaleWidth(107),
                                            height: scaleHeight(156),
                                            color: Colors.grey[200],
                                            child: _selectedImage != null
                                                ? Image.file(
                                              File(_selectedImage!.path),
                                              fit: BoxFit.cover,
                                            )
                                                : widget.imagePath.isNotEmpty
                                                ? Image.file(
                                              File(widget.imagePath),
                                              fit: BoxFit.cover,
                                            )
                                                : const Center(
                                              child: FixedText('이미지 없음'),
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
                                                FixedText('홈 구단', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                                                SizedBox(width: scaleWidth(2)),
                                                FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                                              ],
                                            ),
                                            SizedBox(height: scaleHeight(8)),
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

                                            SizedBox(height: scaleHeight(20)),

                                            // 원정 구단
                                            Row(
                                              children: [
                                                FixedText('원정 구단', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                                                SizedBox(width: scaleWidth(2)),
                                                FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                                              ],
                                            ),
                                            SizedBox(height: scaleHeight(8)),
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
                                    ],
                                  ),

                                  const Spacer(flex: 38), // 이미지-일시 간격

                                  // 일시
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          FixedText('일시', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                                          SizedBox(width: scaleWidth(2)),
                                          FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                                        ],
                                      ),
                                      SizedBox(height: scaleHeight(8)),
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
                                          width: double.infinity,
                                          height: scaleHeight(52),
                                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: AppColors.gray50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: FixedText(
                                            selectedDateTime ?? formatKoreanDateTime(extractedDate, extractedTime)
                                                ?? '경기 날짜를 선택해 주세요',
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

                                  const Spacer(flex: 28), // 일시-구장 간격

                                  // 구장
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          FixedText('구장', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                                          SizedBox(width: scaleWidth(2)),
                                          FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                                        ],
                                      ),
                                      SizedBox(height: scaleHeight(8)),
                                      GestureDetector(
                                        onTap: () async {
                                          final stadium = await showStadiumPicker(
                                            context: context,
                                            title: '구장',
                                            stadiums: stadiumListWithImages,
                                            initial: selectedStadium ?? mapStadiumName(extractedStadium),
                                          );
                                          if (stadium != null) {
                                            setState(() => selectedStadium = stadium);
                                          }
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          height: scaleHeight(52),
                                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
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
                                      SizedBox(height: scaleHeight(8)),
                                      FixedText(
                                        '*홈 구장과 실제 경기 구장이 다를 경우 직접 작성해 주세요',
                                        style: AppFonts.c2_sb(context).copyWith(color: AppColors.gray300),
                                      ),
                                    ],
                                  ),

                                  const Spacer(flex: 37), // 구장-좌석 간격

                                  // 좌석
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          FixedText('좌석', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                                          SizedBox(width: scaleWidth(2)),
                                          FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                                        ],
                                      ),
                                      SizedBox(height: scaleHeight(8)),
                                      GestureDetector(
                                        onTap: () async {
                                          final currentStadium = selectedStadium ?? mapStadiumName(extractedStadium) ?? extractedStadium;
                                          final seat = await showSeatInputDialog(
                                            context,
                                            initial: selectedSeat ?? extractedSeat,
                                            stadium: currentStadium,
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
                                      SizedBox(height: scaleHeight(8)),
                                      FixedText(
                                        '*상세 좌석 정보는 나에게만 보여요',
                                        style: AppFonts.c2_sb(context).copyWith(color: AppColors.gray300),
                                      ),
                                    ],
                                  ),

                                  const Spacer(flex: 25), // 하단 여백
                                ],
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
                                onPressed: isComplete
                                    ? () {
                                  final String finalStadium = selectedStadium ?? extractedStadium ?? '';
                                  final String finalSeat = selectedSeat ?? extractedSeat ?? '';
                                  final String finalGameId = matchedGames.isNotEmpty ? matchedGames.first.gameId : '';
                                  final int userId = 1;

                                  final String finalHomeTeam = selectedHome ?? mapCorpToFullName(extractedHomeTeam ?? '') ?? '';
                                  final String finalAwayTeam = selectedAway ?? mapCorpToFullName(extractedAwayTeam ?? '') ?? '';
                                  final String finalGameDate = selectedDateTime ?? formatKoreanDateTime(extractedDate, extractedTime) ?? '';

                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation1, animation2) => EmotionSelectScreen(
                                        userId: userId,
                                        gameId: finalGameId,
                                        seatInfo: finalSeat,
                                        stadium: finalStadium,
                                        imagePath: widget.imagePath,
                                        homeTeam: finalHomeTeam,
                                        awayTeam: finalAwayTeam,
                                        gameDate: finalGameDate,
                                      ),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isComplete ? AppColors.gray700 : AppColors.gray200,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(18)),
                                ),
                                child: FixedText(
                                  '완료',
                                  style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20),
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