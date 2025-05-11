import 'package:intl/intl.dart';

// 날짜 추출
String? extractDate(String text) {
  final patterns = [
    // 가장 정확한 형식부터 순서대로
    RegExp(r'(\d{4})[년\s.]*([01]?\d)[월\s.]*([0-3]?\d)[일\s.]*'),      // 2025년 04월 19일
    RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),                             // 2025-04-19
    RegExp(r'(\d{2})[./-](\d{2})[./-](\d{2})'),                         // 25.04.19
    RegExp(r'\((\d{1,2})\.(\d{1,2})\)'),                                // (4.19)
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String year, month, day;

      if (pattern.pattern.contains(r'\(')) {
        // 괄호 날짜는 연도 없이 들어오므로 현재 연도 보정
        final now = DateTime.now();
        year = now.year.toString();
        month = match.group(1)!;
        day = match.group(2)!;
      } else if (pattern.pattern.contains('/') || pattern.pattern.contains('-')) {
        year = match.group(1)!;
        if (year.length == 2) {
          year = (int.parse(year) + 2000).toString();
        }
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

// 좌석 추출
String? extractSeat(String text) {
  final seatRegex = RegExp(r'(\d+루)?\s*(블럭)?\s*(\d+)[블럭\s]*(\d+)열\s*(\d+)번');
  final match = seatRegex.firstMatch(text);
  if (match != null) {
    return match.group(0);
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
}) {
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
