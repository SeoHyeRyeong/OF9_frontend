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
