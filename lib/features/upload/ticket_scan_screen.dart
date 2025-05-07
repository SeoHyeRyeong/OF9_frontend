/*import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// 경기 정보 모델 (DB 엔티티와 호환)
class GameResponse {
  final String gameId;
  final DateTime date;
  final String time;
  final String playtime;
  final String stadium;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final String homeImg;
  final String awayImg;

  GameResponse({
    required this.gameId,
    required this.date,
    required this.time,
    required this.playtime,
    required this.stadium,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.homeImg,
    required this.awayImg,
  });

  factory GameResponse.fromJson(Map<String, dynamic> json) {
    return GameResponse(
      gameId: json['gameId'] ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '00:00:00',
      playtime: json['playtime'] ?? '00:00:00',
      stadium: json['stadium'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      homeScore: json['homeScore'],
      awayScore: json['awayScore'],
      status: json['status'] ?? '',
      homeImg: json['homeImg'] ?? '',
      awayImg: json['awayImg'] ?? '',
    );
  }
}

// 서버에서 경기 검색 (한글 깨짐 방지, 리스트/객체 모두 지원)
class GameApi {
  static Future<List<GameResponse>> searchGame({
    required String awayTeam,
    required String date,
    required String time,
  }) async {
    final Uri url = Uri.parse('http://192.168.0.9:8080/games/search').replace(
      queryParameters: {
        'awayTeam': awayTeam,
        'date': date,
        'time': time,
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) {
        return decoded.map((e) => GameResponse.fromJson(e)).toList();
      } else if (decoded is Map<String, dynamic>) {
        return [GameResponse.fromJson(decoded)];
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('게임 검색 실패: ${response.statusCode}');
    }
  }
}

// 날짜 추출
String? extractDate(String text) {
  final patterns = [
    // 예시: "2025년 03월 26일(수)", "2025년03월28일", "2025년 04월 09일 수요일"
    RegExp(r'(\d{4})[년\s.]*([01]?\d)[월\s.]*([0-3]?\d)[일\s.]*'),

    // 예시: "25/04/23", "25-04-23" (2자리 연도)
    // 2자리 연도는 코드에서 자동으로 2000년대 변환됨
    RegExp(r'(\d{2})[./-](\d{2})[./-](\d{2})'),

    // 예시: "2025-04-20"
    RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),

    // 예시: "(4.18)"
    RegExp(r'\((\d{1,2})\.(\d{1,2})\)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String year, month, day;
      // 2자리 연도 처리
      if (pattern.pattern.contains('/')) {
        year = match.group(1)!;
        if (year.length == 2) year = (int.parse(year) + 2000).toString();
        month = match.group(2)!;
        day = match.group(3)!;
      } else if (pattern.pattern.contains('(') && pattern.pattern.contains('\\.')) {
        final now = DateTime.now();
        year = now.year.toString();
        month = match.group(1)!;
        day = match.group(2)!;
      } else if (pattern.pattern.contains('-') && match.groupCount == 3 && match.group(1)!.length == 2) {
        // 2자리 연도 (예: 25-04-23)
        year = (int.parse(match.group(1)!) + 2000).toString();
        month = match.group(2)!;
        day = match.group(3)!;
      } else {
        year = match.group(1)!;
        month = match.group(2)!;
        day = match.group(3)!;
      }
      return '${year.padLeft(4, '0')}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
    }
  }
  return null;
}

// 시간 추출
String? extractTime(String text) {
  final patterns = [
    // 예시: "18:30", "14:00"
    RegExp(r'(\d{1,2}):(\d{2})'),
    // 예시: "18시30분"
    RegExp(r'(\d{1,2})시\s?(\d{1,2})분'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!.padLeft(2, '0')}:00';
    }
  }
  return null;
}

class TicketScanScreen extends StatefulWidget {
  const TicketScanScreen({Key? key}) : super(key: key);

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final ImagePicker _picker = ImagePicker();

  // 팀명 → 기업명 매핑 (모든 팀명/별칭 포함)
  final Map<String, String> _teamToCorp = {
    'KIA 타이거즈': 'KIA', 'KIA': 'KIA',
    '두산 베어스': '두산', '두산': '두산',
    '롯데 자이언츠': '롯데', '롯데': '롯데',
    '삼성 라이온즈': '삼성', '삼성': '삼성',
    '키움 히어로즈': '키움', '키움': '키움',
    '한화 이글스': '한화', '한화': '한화',
    'KT WIZ': 'KT', 'KT': 'KT',
    'LG 트윈스': 'LG', 'LG': 'LG',
    'NC 다이노스': 'NC', 'NC': 'NC',
    'SSG 랜더스': 'SSG', 'SSG': 'SSG',
    '자이언츠': '롯데', '타이거즈': 'KIA', '라이온즈': '삼성',
    '히어로즈': '키움', '이글스': '한화', 'WIZ': 'KT',
    '트윈스': 'LG', '다이노스': 'NC', '랜더스': 'SSG',
    '베어스': '두산', 'Eagles': '한화'
  };

  // 팀명 리스트 (긴 순서, 부분 일치 정확도 향상)
  final List<String> _teamKeywords = [
    'KIA 타이거즈', '두산 베어스', '롯데 자이언츠', '삼성 라이온즈', '키움 히어로즈', '한화 이글스',
    'KT WIZ', 'LG 트윈스', 'NC 다이노스', 'SSG 랜더스',
    '자이언츠', '타이거즈', '라이온즈', '히어로즈', '이글스', '트윈스', '다이노스', '랜더스',
    '베어스', 'Eagles', 'KIA', '두산', '롯데', '삼성', '키움', '한화', 'KT', 'LG', 'NC', 'SSG', 'WIZ'
  ];

  String ocrText = '';
  String? extractedAwayTeam;
  String? extractedDate;
  String? extractedTime;
  List<GameResponse> matchedGames = [];

  // 티켓 이미지 선택 & OCR
  Future<void> scanTicket() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    ocrText = recognizedText.text;
    print('📄 OCR 결과:\n$ocrText');

    extractTicketInfo(ocrText);
    await findMatchingGame();
    setState(() {});
  }

  // VS 뒤 팀명(어웨이 팀명) 추출 → 기업명 변환, 날짜/시간 추출
  void extractTicketInfo(String text) {
    final lines = text.split('\n');
    String? awayTeam;
    String? date;
    String? time;

    // 부분 일치: 3글자 이상이면 앞 2글자, 2글자 이하는 완전 일치
    bool isPartialMatch(String keyword, String candidate) {
      if (keyword.length >= 3) {
        return candidate.startsWith(keyword.substring(0, 2));
      } else {
        return candidate == keyword;
      }
    }

    // VS 뒤 팀명 추출 (VS가 줄 앞에 있어도 인식)
    final vsRegex = RegExp(r'^[^\w]*[vV][sS]?\s*(.+)$', caseSensitive: false);
    for (final line in lines) {
      final match = vsRegex.firstMatch(line);
      if (match != null) {
        final vsTail = match.group(1)!.trim();
        final candidates = vsTail.split(RegExp(r'\s+'));
        for (final candidate in candidates) {
          for (final keyword in _teamKeywords) {
            if (isPartialMatch(keyword, candidate)) {
              awayTeam = keyword;
              break;
            }
          }
          if (awayTeam != null) break;
        }
      }
      if (awayTeam != null) break;
    }

    // 기업명 변환
    extractedAwayTeam = awayTeam != null ? _teamToCorp[awayTeam] : null;

    // 날짜 추출
    for (final line in lines) {
      final d = extractDate(line);
      if (d != null) {
        date = d;
        break;
      }
    }

    // 시간 추출
    for (final line in lines) {
      final t = extractTime(line);
      if (t != null) {
        time = t;
        break;
      }
    }

    extractedDate = date;
    extractedTime = time;

    print('🔎 추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime');
  }

  // 서버에서 경기 매칭
  Future<void> findMatchingGame() async {
    matchedGames = [];
    if (extractedAwayTeam != null && extractedDate != null && extractedTime != null) {
      try {
        final games = await GameApi.searchGame(
          awayTeam: extractedAwayTeam!,
          date: extractedDate!,
          time: extractedTime!,
        );
        matchedGames = games;
        print('✅ 매칭된 경기 수: ${matchedGames.length}');
      } catch (e) {
        print('❌ 오류: $e');
      }
    }
    setState(() {});
  }

  // UI: OCR 결과, 추출 결과, 매칭 결과 표시
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('티켓 스캔')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: scanTicket,
                child: const Text('티켓 사진 선택해서 스캔'),
              ),
              const SizedBox(height: 20),
              Text('📄 OCR 결과:\n$ocrText'),
              const SizedBox(height: 20),
              Text('🔎 추출 결과 → Away Team: $extractedAwayTeam, Date: $extractedDate, Time: $extractedTime'),
              const SizedBox(height: 20),
              matchedGames.isNotEmpty
                  ? Column(
                children: matchedGames.map((game) => Card(
                  child: ListTile(
                    title: Text('${game.homeTeam} vs ${game.awayTeam}'),
                    subtitle: Text('${game.date.toString().split(" ")[0]} ${game.time}'),
                  ),
                )).toList(),
              )
                  : const Text('❌ 매칭된 경기 없음'),
            ],
          ),
        ),
      ),
    );
  }
}





import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/models/game_response.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';

// 날짜 추출 함수
String? extractDate(String text) {
  final patterns = [
    RegExp(r'(\d{4})[년\s.]*([01]?\d)[월\s.]*([0-3]?\d)[일\s.]*'),
    RegExp(r'(\d{2})[./-](\d{2})[./-](\d{2})'),
    RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
    RegExp(r'\((\d{1,2})\.(\d{1,2})\)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String year, month, day;
      if (pattern.pattern.contains('/')) {
        year = match.group(1)!;
        if (year.length == 2) year = (int.parse(year) + 2000).toString();
        month = match.group(2)!;
        day = match.group(3)!;
      } else if (pattern.pattern.contains('(') && pattern.pattern.contains('\\.')) {
        final now = DateTime.now();
        year = now.year.toString();
        month = match.group(1)!;
        day = match.group(2)!;
      } else if (pattern.pattern.contains('-') && match.groupCount == 3 && match.group(1)!.length == 2) {
        year = (int.parse(match.group(1)!) + 2000).toString();
        month = match.group(2)!;
        day = match.group(3)!;
      } else {
        year = match.group(1)!;
        month = match.group(2)!;
        day = match.group(3)!;
      }
      return '${year.padLeft(4, '0')}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
    }
  }
  return null;
}

// 시간 추출 함수
String? extractTime(String text) {
  final patterns = [
    RegExp(r'(\d{1,2}):(\d{2})'),
    RegExp(r'(\d{1,2})시\s?(\d{1,2})분'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!.padLeft(2, '0')}:00';
    }
  }
  return null;
}

class TicketScanScreen extends StatefulWidget {
  const TicketScanScreen({Key? key}) : super(key: key);

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final ImagePicker _picker = ImagePicker();

  final Map<String, String> _teamToCorp = {
    'KIA 타이거즈': 'KIA', 'KIA': 'KIA',
    '두산 베어스': '두산', '두산': '두산',
    '롯데 자이언츠': '롯데', '롯데': '롯데',
    '삼성 라이온즈': '삼성', '삼성': '삼성',
    '키움 히어로즈': '키움', '키움': '키움',
    '한화 이글스': '한화', '한화': '한화',
    'KT WIZ': 'KT', 'KT': 'KT',
    'LG 트윈스': 'LG', 'LG': 'LG',
    'NC 다이노스': 'NC', 'NC': 'NC',
    'SSG 랜더스': 'SSG', 'SSG': 'SSG',
    '자이언츠': '롯데', '타이거즈': 'KIA', '라이온즈': '삼성',
    '히어로즈': '키움', '이글스': '한화', 'WIZ': 'KT',
    '트윈스': 'LG', '다이노스': 'NC', '랜더스': 'SSG',
    '베어스': '두산', 'Eagles': '한화'
  };

  final List<String> _teamKeywords = [
    'KIA 타이거즈', '두산 베어스', '롯데 자이언츠', '삼성 라이온즈', '키움 히어로즈', '한화 이글스',
    'KT WIZ', 'LG 트윈스', 'NC 다이노스', 'SSG 랜더스',
    '자이언츠', '타이거즈', '라이온즈', '히어로즈', '이글스', '트윈스', '다이노스', '랜더스',
    '베어스', 'Eagles', 'KIA', '두산', '롯데', '삼성', '키움', '한화', 'KT', 'LG', 'NC', 'SSG', 'WIZ'
  ];

  String ocrText = '';
  String? extractedAwayTeam;
  String? extractedDate;
  String? extractedTime;
  List<GameResponse> matchedGames = [];

  Future<void> scanTicket() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    ocrText = recognizedText.text;
    print('📄 OCR 결과:');
    for (final line in ocrText.split('\n')) {
      print(line);
    }

    extractTicketInfo(ocrText);
    await findMatchingGame();
    setState(() {});
  }

  void extractTicketInfo(String text) {
    final lines = text.split('\n');
    String? awayTeam;
    String? date;
    String? time;

    bool isPartialMatch(String keyword, String candidate) {
      if (keyword.length >= 3) {
        return candidate.startsWith(keyword.substring(0, 2));
      } else {
        return candidate == keyword;
      }
    }

    final vsRegex = RegExp(r'^[^\w]*[vV][sS]?\s*(.+)$', caseSensitive: false);
    for (final line in lines) {
      final match = vsRegex.firstMatch(line);
      if (match != null) {
        final vsTail = match.group(1)!.trim();
        final candidates = vsTail.split(RegExp(r'\s+'));
        for (final candidate in candidates) {
          for (final keyword in _teamKeywords) {
            if (isPartialMatch(keyword, candidate)) {
              awayTeam = keyword;
              break;
            }
          }
          if (awayTeam != null) break;
        }
      }
      if (awayTeam != null) break;
    }

    extractedAwayTeam = awayTeam != null ? _teamToCorp[awayTeam] : null;

    for (final line in lines) {
      final d = extractDate(line);
      if (d != null) {
        date = d;
        break;
      }
    }

    for (final line in lines) {
      final t = extractTime(line);
      if (t != null) {
        time = t;
        break;
      }
    }

    extractedDate = date;
    extractedTime = time;

    print('🔎 추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime');
  }

  Future<void> findMatchingGame() async {
    matchedGames = [];
    if (extractedAwayTeam != null && extractedDate != null && extractedTime != null) {
      try {
        final games = await GameApi.searchGame(
          awayTeam: extractedAwayTeam!,
          date: extractedDate!,
          time: extractedTime!,
        );
        matchedGames = games;
        if (matchedGames.isEmpty) {
          print('❗ 매칭된 경기가 없습니다.');
        } else {
          print('✅ 매칭된 경기 수: ${matchedGames.length}');
          for (final game in matchedGames) {
            print('📢 매칭된 경기 상세 - 홈팀: ${game.homeTeam}, 어웨이팀: ${game.awayTeam}, 날짜: ${game.date.toString().split(' ')[0]}, 시간: ${game.time}');
          }
        }
      } catch (e) {
        print('❌ 오류: $e');
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('티켓 스캔')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: scanTicket,
                child: const Text('티켓 사진 선택해서 스캔'),
              ),
              const SizedBox(height: 20),
              Text('📄 OCR 결과:\n$ocrText'),
              const SizedBox(height: 20),
              Text('🔎 추출 결과 → Away Team: $extractedAwayTeam, Date: $extractedDate, Time: $extractedTime'),
              const SizedBox(height: 20),
              matchedGames.isNotEmpty
                  ? Column(
                children: matchedGames.map((game) => Card(
                  child: ListTile(
                    title: Text('${game.homeTeam} vs ${game.awayTeam}'),
                    subtitle: Text('${game.date.toString().split(" ")[0]} ${game.time}'),
                  ),
                )).toList(),
              )
                  : const Text('❌ 매칭된 경기 없음'),
            ],
          ),
        ),
      ),
    );
  }
}
*/


import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/models/game_response.dart';


// 날짜 추출
String? extractDate(String text) {
  final patterns = [
    // 예시: "2025년 03월 26일(수)", "2025년03월28일", "2025년 04월 09일 수요일"
    RegExp(r'(\d{4})[년\s.]*([01]?\d)[월\s.]*([0-3]?\d)[일\s.]*'),

    // 예시: "2025-04-20"
    RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),

    // 예시: "25/04/23" or "25-04-23" (2자리 연도)
    RegExp(r'(\d{2})[./-](\d{2})[./-](\d{2})'),

    // 예시: "(4.18)" (괄호)
    RegExp(r'\((\d{1,2})\.(\d{1,2})\)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String year, month, day;

      if (pattern.pattern.contains('(') && pattern.pattern.contains('\\.')) {
        // 괄호 (4.18) → 올해 연도 사용
        final now = DateTime.now();
        year = now.year.toString();
        month = match.group(1)!;
        day = match.group(2)!;
      } else if (pattern.pattern.contains('/') || pattern.pattern.contains('-')) {
        // 2자리 연도 (예: 25-04-23)
        year = match.group(1)!;
        if (year.length == 2) {
          year = (int.parse(year) + 2000).toString();
        }
        month = match.group(2)!;
        day = match.group(3)!;
      } else {
        // 4자리 연도 (정상)
        year = match.group(1)!;
        month = match.group(2)!;
        day = match.group(3)!;
      }

      // 최종 안전처리
      return '${year.padLeft(4, '0')}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
    }
  }
  return null;
}


// 시간 추출
String? extractTime(String text) {
  final patterns = [
    // 예시: "18:30", "14:00"
    RegExp(r'(\d{1,2}):(\d{2})'),
    // 예시: "18시30분"
    RegExp(r'(\d{1,2})시\s?(\d{1,2})분'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!.padLeft(2, '0')}:00';
    }
  }
  return null;
}

String? extractSeat(String text) {
  final seatRegex = RegExp(r'(\d+루)?\s*(블럭)?\s*(\d+)[블럭\s]*(\d+)열\s*(\d+)번');
  final match = seatRegex.firstMatch(text);
  if (match != null) {
    return match.group(0);
  }
  return null;
}

// 🧩 디버그용 로그 함수
void debugMatchResult({bool isMatched = false, String? homeTeam, String? awayTeam, String? date, String? time}) {
  if (isMatched) {
    print('✅ DB 매칭 성공');
    print('🏟️ 홈팀: $homeTeam');
    print('🏟️ 원정팀: $awayTeam');
    print('📅 날짜: $date');
    print('⏰ 시간: $time');
  } else {
    print('❌ DB 매칭 실패');
  }
}

// 🧩 TicketScanScreen
class TicketScanScreen extends StatefulWidget {
  const TicketScanScreen({Key? key}) : super(key: key);

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  final Map<String, String> _teamToCorp = {
    'KIA 타이거즈': 'KIA', 'KIA': 'KIA',
    '두산 베어스': '두산', '두산': '두산',
    '롯데 자이언츠': '롯데', '롯데': '롯데',
    '삼성 라이온즈': '삼성', '삼성': '삼성',
    '키움 히어로즈': '키움', '키움': '키움',
    '한화 이글스': '한화', '한화': '한화',
    'KT WIZ': 'KT', 'KT': 'KT',
    'LG 트윈스': 'LG', 'LG': 'LG',
    'NC 다이노스': 'NC', 'NC': 'NC',
    'SSG 랜더스': 'SSG', 'SSG': 'SSG',
    '자이언츠': '롯데', '타이거즈': 'KIA', '라이온즈': '삼성',
    '히어로즈': '키움', '이글스': '한화', 'WIZ': 'KT',
    '트윈스': 'LG', '다이노스': 'NC', '랜더스': 'SSG',
    '베어스': '두산', 'Eagles': '한화'
  };

  final List<String> _teamKeywords = [
    'KIA 타이거즈', '두산 베어스', '롯데 자이언츠', '삼성 라이온즈', '키움 히어로즈', '한화 이글스',
    'KT WIZ', 'LG 트윈스', 'NC 다이노스', 'SSG 랜더스',
    '자이언츠', '타이거즈', '라이온즈', '히어로즈', '이글스', '트윈스', '다이노스', '랜더스',
    '베어스', 'Eagles', 'KIA', '두산', '롯데', '삼성', '키움', '한화', 'KT', 'LG', 'NC', 'SSG', 'WIZ'
  ];

  String? extractedHomeTeam;
  String? extractedAwayTeam;
  String? extractedDate;
  String? extractedTime;
  String? extractedSeat;

  List<GameResponse> matchedGames = [];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _selectedImage = pickedFile);

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final text = recognizedText.text;
    print('📄 OCR 결과:\n$text');

    _extractTicketInfo(text);
    await _findMatchingGame();
    setState(() {});
  }

  void _extractTicketInfo(String text) {
    final lines = text.split('\n');
    String? awayTeam;
    String? date;
    String? time;

    // 🧩 VS 기준으로 어웨이팀 추출
    final vsRegex = RegExp(r'[vV][sS]\s*(.+)'); // "vs" 또는 "VS" 뒤쪽만 추출
    for (final line in lines) {
      final match = vsRegex.firstMatch(line.replaceAll(' ', '')); // 줄 공백 제거 후 vs 찾기
      if (match != null) {
        final awayCandidate = match.group(1)!.trim();
        // 후보에서 팀명 매칭
        for (final keyword in _teamKeywords) {
          if (awayCandidate.contains(keyword.replaceAll(' ', ''))) {
            awayTeam = _teamToCorp[keyword];
            break;
          }
        }
        if (awayTeam != null) break;
      }
    }

    // 🧩 날짜 추출
    for (final line in lines) {
      final d = extractDate(line);
      if (d != null) {
        date = d;
        break;
      }
    }

    // 🧩 시간 추출
    for (final line in lines) {
      final t = extractTime(line);
      if (t != null) {
        time = t;
        break;
      }
    }

    // 결과 저장
    extractedAwayTeam = awayTeam;
    extractedDate = date;
    extractedTime = time;

    print('🔎 추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime');
  }


  Future<void> _findMatchingGame() async {
    matchedGames = [];
    if (extractedAwayTeam != null && extractedDate != null && extractedTime != null) {
      try {
        final game = await GameApi.searchGame(   // ✅ 단일 객체 받기
          awayTeam: extractedAwayTeam!,
          date: extractedDate!,
          time: extractedTime!,
        );
        matchedGames = [game];   // ✅ 리스트로 감싸서 저장

        if (matchedGames.isNotEmpty) {
          debugMatchResult(
            isMatched: true,
            homeTeam: matchedGames[0].homeTeam,
            awayTeam: matchedGames[0].awayTeam,
            date: DateFormat('yyyy-MM-dd').format(matchedGames[0].date),
            time: extractedTime!,
          );
        } else {
          debugMatchResult(isMatched: false);
        }
      } catch (e) {
        print('❌ 오류: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('티켓 정보 확인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  color: Colors.red[100],
                  child: _selectedImage != null
                      ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                      : const Center(child: Text('티켓 사진 선택')),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: '홈 구단',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: matchedGames.isNotEmpty ? matchedGames[0].homeTeam : '',
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: '원정 구단',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: extractedAwayTeam ?? '',
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: '일시',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: extractedDate != null && extractedTime != null ? '$extractedDate $extractedTime' : '',
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: '좌석',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: extractedSeat ?? '',
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
