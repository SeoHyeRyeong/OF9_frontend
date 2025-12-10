/// KBO 티켓 OCR 정보 추출 유틸리티
///
/// 이 파일은 ticket_ocr_screen.dart에서 사용하는
/// 팀명/날짜/시간 추출 로직을 담당합니다.

// 어웨이팀 추출
String? extractAwayTeam(
    String cleanedText,
    Map<String, String> teamToCorp,
    List<String> teamKeywords,
    ) {
  final words = cleanedText.split(RegExp(r'\s+'));

  for (int i = 0; i < words.length; i++) {
    final word = words[i].toLowerCase();

    if (word == 'vs') {
      if (i + 1 < words.length) {
        final one = words[i + 1].replaceAll(RegExp(r'[^가-힣A-Za-z]'), '');
        final two = (i + 2 < words.length)
            ? words[i + 2].replaceAll(RegExp(r'[^가-힣A-Za-z]'), '')
            : '';
        final candidates = [one, one + two];

        for (final candidate in candidates) {
          for (final keyword in teamKeywords) {
            if (candidate.toLowerCase().contains(
                keyword.replaceAll(' ', '').toLowerCase())) {
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
        if (cleaned.toLowerCase().contains(
            keyword.replaceAll(' ', '').toLowerCase())) {
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

// 날짜 추출
String? extractDate(String cleanedText) {
  final patterns = [
    // [1] 4자리 연도 (구분자 포함): YYYY[./-]MM[./-]DD
    RegExp(r'(\d{4})[./\-](\d{1,2})[./\-](\d{1,2})'),

    // [2] 2자리 연도 (구분자 포함): YY[./-]MM[./-]DD
    RegExp(r'(\d{2})[./\-](\d{1,2})[./\-](\d{1,2})'),

    // [3] 한글 형식: YYYY년 MM월 DD일
    RegExp(r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일'),

    // [4] 괄호: (M.D)
    RegExp(r'\((\d{1,2})\.(\d{1,2})\)'),

    // [5] 붙어있는 8자리 숫자: YYYYMMDD
    RegExp(r'\b(\d{4})(\d{2})(\d{2})\b'),
  ];

  Match? bestMatch;

  for (final pattern in patterns) {
    final matches = pattern.allMatches(cleanedText);
    for (final match in matches) {
      String year, month, day;
      final patternString = pattern.pattern;

      if (patternString.contains(r'\(')) {
        // [4] 괄호 형식: 현재 연도 사용
        final now = DateTime.now();
        year = now.year.toString();
        month = match.group(1)!;
        day = match.group(2)!;
      } else if (patternString.contains(r'(\d{2})[./\-]')) {
        // [2] 2자리 연도: 20XX로 보정
        year = '20' + match.group(1)!;
        month = match.group(2)!;
        day = match.group(3)!;
      } else {
        // [1], [3], [5] 4자리 연도
        year = match.group(1)!;
        month = match.group(2)!;
        day = match.group(3)!;
      }

      if (isValidDate(year, month, day)) {
        if (bestMatch == null || match.start < bestMatch.start) {
          bestMatch = match;
        }
      }
    }
  }

  if (bestMatch != null) {
    String year, month, day;
    final match = bestMatch;
    final patternString = bestMatch.pattern.toString();

    if (patternString.contains(r'\(')) {
      final now = DateTime.now();
      year = now.year.toString();
      month = match.group(1)!;
      day = match.group(2)!;
    } else if (patternString.contains(r'(\d{2})[./\-]')) {
      year = '20' + match.group(1)!;
      month = match.group(2)!;
      day = match.group(3)!;
    } else {
      year = match.group(1)!;
      month = match.group(2)!;
      day = match.group(3)!;
    }

    return '${year.padLeft(4, '0')}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
  }

  return null;
}

// 시간 추출
String? extractTime(String cleanedText) {
  final patterns = [
    // [1] 콜론/공백/한글 구분자: 18:30, 18시 30분
    RegExp(r'(\d{1,2})\s*[:시][^\d]*(\d{2})[분]?'),

    // [2] 붙어있는 4자리 숫자: 1830
    RegExp(r'\b(\d{4})\b'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(cleanedText);
    if (match != null) {
      int? h, m;

      if (pattern.pattern.contains(r'\b(\d{4})\b')) {
        // 4자리 숫자
        final value = match.group(1)!;
        if (value.length != 4) continue;
        h = int.tryParse(value.substring(0, 2));
        m = int.tryParse(value.substring(2, 4));
      } else {
        // 콜론/공백/한글 구분자
        h = int.tryParse(match.group(1)!.trim());
        m = int.tryParse(match.group(2)!.trim());
      }

      // 야구 경기 시간 검증: 시는 10~19, 분은 0~59
      if (h != null && m != null && h >= 10 && h <= 19 && m >= 0 && m < 60) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
      }
    }
  }

  return null;
}

/// ✨ 요일과 월 정보를 기반으로 KBO 표준 경기 시작 시간을 반환
///
/// 공휴일 판단은 어려우므로, 평일은 18시 30분을 기본값으로 사용합니다.
///
/// DB에 정확한 시간이 있으면 그걸 우선 사용하고,
/// 이 함수는 DB 시간이 없을 때만 사용됩니다.
String getStandardKboGameTime(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    final weekday = date.weekday; // 1=월요일, 7=일요일
    final month = date.month;

    // 일요일 (7)
    if (weekday == 7) {
      // 혹서기(6-8월)는 17시 또는 18시, 일반 시즌은 14시
      if (month >= 6 && month <= 8) {
        return '17:00:00'; // 혹서기 일요일
      }
      return '14:00:00'; // 일반 시즌 일요일
    }

    // 토요일 (6)
    if (weekday == 6) {
      // 지상파 중계 시 14시, 일반적으로는 17시
      return '17:00:00';
    }

    // 평일 (월-금: 1-5)
    if (month >= 6 && month <= 8) {
      // 혹서기: 18시 시작 (더위 대응)
      return '18:00:00';
    } else {
      // 일반 시즌: 18시 30분 시작 (가장 일반적인 평일 경기 시간)
      return '18:30:00';
    }
  } catch (e) {
    // 파싱 실패 시 가장 일반적인 평일 시간 반환
    return '18:30:00';
  }
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
