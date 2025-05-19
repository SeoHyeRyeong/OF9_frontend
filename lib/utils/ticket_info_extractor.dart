import 'package:intl/intl.dart';

// 어웨이팀 추출
String? extractAwayTeam(String cleanedText, Map<String, String> teamToCorp, List<String> teamKeywords) {
  final words = cleanedText.split(RegExp(r'\s+'));

  for (int i = 0; i < words.length; i++) {
    final word = words[i].toLowerCase();

    if (word == 'vs') {
      if (i + 1 < words.length) {
        final one = words[i + 1].replaceAll(RegExp(r'[^가-힣A-Za-z]'), '');
        final two = (i + 2 < words.length) ? words[i + 2].replaceAll(RegExp(r'[^가-힣A-Za-z]'), '') : '';
        final candidates = [one, one + two];

        for (final candidate in candidates) {
          for (final keyword in teamKeywords) {
            if (candidate.toLowerCase().contains(keyword.replaceAll(' ', '').toLowerCase())) {
              return teamToCorp[keyword];
            }
          }
        }
      }
    } else if (word.startsWith('vs')) {
      // 'vs'와 팀명이 붙어있는 경우 (예: vsSSG랜더스)
      final trimmed = word.replaceFirst('vs', '');
      final cleaned = trimmed.replaceAll(RegExp(r'[^가-힣A-Za-z]'), '');

      for (final keyword in teamKeywords) {
        if (cleaned.toLowerCase().contains(keyword.replaceAll(' ', '').toLowerCase())) {
          return teamToCorp[keyword];
        }
      }
    }
  }

  return null;
}

// 날짜 유효성 검증 함수
bool isValidDate(String year, String month, String day) {
  try {
    final y = int.parse(year);
    final m = int.parse(month);
    final d = int.parse(day);
    final date = DateTime(y, m, d);
    return date.year == y && date.month == m && date.day == d;
  } catch (_) {
    return false;
  }
}

// 날짜 추출 함수 (유효성 검증 포함)
String? extractDate(String cleanedText) {
  final patterns = [
    RegExp(r'(\d{2})[./-](\d{2})[./-](\d{2})'), // 25/04/23
    RegExp(r'(\d{4})[년\s.]*([01]?\d)[월\s.]*([0-3]?\d)[일\s.]?'), // 2025년 4월 23일
    RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // 2025-04-23
    RegExp(r'\((\d{1,2})\.(\d{1,2})\)'), // (4.23)
  ];

  for (final pattern in patterns) {
    final match =  pattern.firstMatch(cleanedText);
    if (match != null) {
      String year, month, day;

      if (pattern.pattern.contains(r'\\(')) {
        // (4.23) → 현재 연도 기준
        final now = DateTime.now();
        year = now.year.toString();
        month = match.group(1)!;
        day = match.group(2)!;
      } else if (pattern.pattern.contains('/')) {
        // 25/04/23 형식 → 연도 보정
        year = '20' + match.group(1)!;
        month = match.group(2)!;
        day = match.group(3)!;
      } else {
        year = match.group(1)!;
        month = match.group(2)!;
        day = match.group(3)!;
      }

      if (isValidDate(year, month, day)) {
        final fixedYear = '20' + year.padLeft(4, '0').substring(2);  // 21세기로 강제
        return '${fixedYear}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
      }
    }
  }

  return null;
}

// 시간 추출
String? extractTime(String cleanedText) {

  final patterns = [
    RegExp(r'(\d{1,2})[:시]\s*(\d{2})[분]?'),  // 18:30, 18시 30분
    RegExp(r'\b(\d{1,2})\s+(\d{2})\b'),        // 18 30 (공백 포함)
    RegExp(r'\b(\d{4})\b'),                    // 1830 (붙어있는 4자리 숫자)
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(cleanedText);
    if (match != null) {
      String hour = '';
      String minute = '';
      int? h, m;

      if (pattern.pattern == r'\b(\d{4})\b') {
        final value = match.group(1)!;
        h = int.tryParse(value.substring(0, 2));
        m = int.tryParse(value.substring(2, 4));
      } else {
        hour = match.group(1)!;
        minute = match.group(2)!;
        h = int.tryParse(hour);
        m = int.tryParse(minute);
      }

      // 공통 검증 로직: 시는 10~19, 분은 0~59
      if (h != null && m != null && h >= 10 && h <= 19 && m >= 0 && m < 60) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
      }
    }
  }

  return null;
}


// 좌석 추출 (구장별 정제 포함)
String? extractSeat(String cleanedText, String stadium) {
  final text = cleanedText.toUpperCase();

  if (stadium == '잠실') {
    final blocks = RegExp(r'\b(\d{3})\b');
    final match = blocks.firstMatch(text);
    if (match != null) {
      final block = match.group(1)!;
      final int blockNum = int.parse(block);

      final List<Map<String, dynamic>> seatRules = [
        {'name': '1루 테이블석', 'range': ['110', '111', '212', '213']},
        {'name': '1루 블루석', 'range': ['107', '108', '109', '209', '210', '211']},
        {'name': '1루 오렌지석', 'range': ['205', '206', '207', '208']},
        {'name': '1루 레드석', 'range': [
          ...List.generate(5, (i) => (102 + i).toString()),      // 102~106
          ...List.generate(4, (i) => (201 + i).toString()),      // 201~204
        ]},
        {'name': '1루 네이비석', 'range': List.generate(12, (i) => (301 + i).toString())},  // 301~312
        {'name': '1루 외야석', 'range': List.generate(11, (i) => (401 + i).toString())},    // 401~411
        {'name': '중앙 네이비석', 'range': List.generate(10, (i) => (313 + i).toString())}, // 313~322
        {'name': '3루 테이블석', 'range': ['112', '113', '213', '214']},
        {'name': '3루 블루석', 'range': ['114', '115', '116', '216', '217', '218']},
        {'name': '3루 오렌지석', 'range': ['219', '220', '221', '222']},
        {'name': '3루 레드석', 'range': [
          ...List.generate(6, (i) => (117 + i).toString()),      // 117~122
          ...List.generate(4, (i) => (223 + i).toString()),      // 223~226
        ]},
        {'name': '3루 네이비석', 'range': List.generate(12, (i) => (323 + i).toString())}, // 323~334
        {'name': '3루 외야석', 'range': List.generate(11, (i) => (412 + i).toString())},   // 412~422
        {'name': '익사이팅존', 'range': []},  // 별도 키워드로 탐색
      ];

      for (final rule in seatRules) {
        if (rule['range'].contains(block)) {
          return '${rule['name']} $block';
        }
      }
    }

    // 익사이팅존 키워드가 텍스트에 있을 경우 처리
    final exciting = RegExp(r'익사이팅');
    final matchExciting = exciting.firstMatch(text);
    if (matchExciting != null) return '익사이팅존';

    // 그 외 네이비석, 블루석 등 키워드 탐색
    final fallback = RegExp(r'(테이블|블루|오렌지|레드|네이비|외야|익사이팅)[석존]?', caseSensitive: false);
    final m = fallback.firstMatch(text);
    if (m != null) return '${m.group(0)}';
  }

  else if (stadium == '사직') {
    final blocks = RegExp(r'\b(\d{3})\b');
    final match = blocks.firstMatch(text);
    if (match != null) {
      final block = match.group(1)!;

      final List<Map<String, dynamic>> seatRules = [
        {'name': '에비뉴엘석', 'range': ['012', '013']},
        {'name': '중앙탁자석', 'range': [
          ...List.generate(4, (i) => (21 + i).toString().padLeft(3, '0')),   // 021~024
          ...List.generate(4, (i) => (31 + i).toString().padLeft(3, '0')),   // 031~034
          '041', '044'
        ]},
        {'name': '응원탁자석', 'range': ['121', '131']},
        {'name': '와이드탁자석', 'range': ['321', '322', '331', '332']},
        {'name': '3루 단체석', 'range': ['327', '337']},
        {'name': '1루 내야상단석', 'range': [
          '116', '126', '127',
          ...List.generate(4, (i) => (134 + i).toString()),  // 134~137
          '142', '143'
        ]},
        {'name': '1루 내야필드석', 'range': [
          ...List.generate(5, (i) => (111 + i).toString()),  // 111~115
          ...List.generate(4, (i) => (122 + i).toString()),  // 122~125
        ]},
        {'name': '중앙 상단석', 'range': List.generate(7, (i) => (51 + i).toString().padLeft(3, '0'))}, // 051~057
        {'name': '3루 내야상단석', 'range': [
          '315', '316', '325', '326',
          ...List.generate(4, (i) => (333 + i).toString()), // 333~336
          '342', '343'
        ]},
        {'name': '3루 내야필드석', 'range': [
          ...List.generate(4, (i) => (311 + i).toString()), // 311~314
          '323', '324'
        ]},
        {'name': '1루 외야석', 'range': [
          ...List.generate(5, (i) => (921 + i).toString()), // 921~925
          ...List.generate(5, (i) => (931 + i).toString()), // 931~935
        ]},
        {'name': '3루 외야석', 'range': [
          ...List.generate(4, (i) => (721 + i).toString()), // 721~724
          ...List.generate(4, (i) => (731 + i).toString()), // 731~734
        ]},
        {'name': '1루 외야 탁자석', 'range': ['941', '942']},
        {'name': '3루 외야 탁자석', 'range': ['338']},
      ];

      for (final rule in seatRules) {
        if (rule['range'].contains(block)) {
          return '${rule['name']} $block';
        }
      }
    }

    // 키워드 기반 좌석 탐색 (블럭 없이도 가능한 좌석)
    final keywords = ['SKYBOX', '에비뉴엘석', '중앙탁자석', '응원탁자석', '와이드탁자석', '단체석', '필드석', '상단석', '외야석', '탁자석', '휠체어석'];
    for (final keyword in keywords) {
      if (text.contains(keyword.toUpperCase()) || text.contains(keyword)) {
        return keyword;
      }
    }
  }

  else if (stadium == '고척') {
    final blocks = RegExp(r'\b([DT]?\d{2,4})\b');
    final match = blocks.firstMatch(text);
    if (match != null) {
      final block = match.group(1)!;

      final List<Map<String, dynamic>> seatRules = [
        {'name': 'R.d_club석', 'range': ['D01', 'D02', 'D03', 'D04', 'D05', 'D06', 'D07']},
        {'name': '1루 테이블석', 'range': ['T01', 'T02', 'T11', 'T12', 'T13']},
        {'name': '중앙 테이블석', 'range': ['T03', 'T04', 'T05']},
        {'name': '3루 테이블석', 'range': ['T06', 'T07', 'T15', 'T16', 'T17']},
        {'name': '1루 다크버건디석', 'range': ['106', '107', '204', '205']},
        {'name': '3루 다크버건디석', 'range': ['108', '109', '206', '207']},
        {'name': '1루 버건디석', 'range': [
          ...List.generate(5, (i) => (101 + i).toString()),    // 101~105
          ...List.generate(3, (i) => (201 + i).toString()),    // 201~203
        ]},
        {'name': '3루 버건디석', 'range': [
          ...List.generate(5, (i) => (110 + i).toString()),    // 110~114
          ...List.generate(3, (i) => (208 + i).toString()),    // 208~210
        ]},
        {'name': '1루 3층 지정석', 'range': List.generate(11, (i) => (301 + i).toString())},   // 301~311
        {'name': '3루 3층 지정석', 'range': List.generate(11, (i) => (312 + i).toString())},   // 312~322
        {'name': '1루 4층 지정석', 'range': List.generate(9, (i) => (401 + i).toString())},    // 401~409
        {'name': '중앙 4층 지정석', 'range': List.generate(6, (i) => (410 + i).toString())},   // 410~415
        {'name': '3루 4층 지정석', 'range': List.generate(9, (i) => (416 + i).toString())},    // 416~424
        {'name': '1루 1~2층 외야 일반석', 'range': [
          ...List.generate(9, (i) => (124 + i).toString()),    // 124~132
          ...List.generate(6, (i) => (217 + i).toString()),    // 217~222
        ]},
        {'name': '1루 3~4층 외야 일반석', 'range': [
          ...List.generate(6, (i) => (329 + i).toString()),    // 329~334
          ...List.generate(6, (i) => (430 + i).toString()),    // 430~435
        ]},
        {'name': '3루 1~2층 외야 일반석', 'range': [
          ...List.generate(9, (i) => (115 + i).toString()),    // 115~123
          ...List.generate(6, (i) => (211 + i).toString()),    // 211~216
        ]},
        {'name': '3루 3~4층 외야 일반석', 'range': [
          ...List.generate(6, (i) => (323 + i).toString()),    // 323~328
          ...List.generate(5, (i) => (425 + i).toString()),    // 425~429
        ]},
      ];

      for (final rule in seatRules) {
        if (rule['range'].contains(block)) {
          return '${rule['name']} $block';
        }
      }
    }

    // 커플석, 패밀리석, 유아동반석, 휠체어석은 키워드 탐색으로 처리
    final keywordRules = [
      '커플석', '패밀리석', '유아동반석', '휠체어석',
      '테이블석', '버건디석', '다크버건디석', '지정석', '일반석',
      'R.D_CLUB석', 'R.d_club석'
    ];

    for (final keyword in keywordRules) {
      if (text.contains(keyword.toUpperCase()) || text.contains(keyword)) {
        return keyword;
      }
    }
  }


  else {
    final fallback = RegExp(r'(\d+루)?\s*(블럭)?\s*(\d+)[블럭\s]*(\d+)열\s*(\d+)번');
    final match = fallback.firstMatch(text);
    if (match != null) return match.group(0);
  }
  return null;
}

// 디버그 출력
void debugMatchResult({
  bool isMatched = false,
  String? homeTeam,
  String? awayTeam,
  String? date,
  String? time,
  String? stadium,
}) {
  if (isMatched) {
    print('✅ DB 매칭 성공');
    print('🏟️ 홈팀: $homeTeam');
    print('🏟️ 원정팀: $awayTeam');
    print('📅 날짜: $date');
    print('⏰ 시간: $time');
    print('⚾ 구장: $stadium');
  }
}
