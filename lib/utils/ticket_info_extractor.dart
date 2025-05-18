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

// 원정 구단 추출
// 대소문자 구분 없이 'vs'로 시작하고 그 뒤에 팀 이름이 나오는 패턴을 정규식으로 정의
// 예: "vs 삼성", "VS LG", "Vs 두산" 등에서 '삼성', 'LG', '두산' 등을 추출
String? extractAwayTeam(String text, Map<String, String> teamToCorp, List<String> teamKeywords) {
  final lines = text.split('\n');
  final vsRegex = RegExp(r'[vV][sS]\s*(.+)');

  for (final line in lines) {
    // 공백을 모두 제거한 후, 정규식 패턴과 일치하는 부분 찾기
    final match = vsRegex.firstMatch(line.replaceAll(' ', ''));

    // 만약 해당 줄에서 'vs' 패턴이 발견되었다면
    if (match != null) {
      // 정규식의 첫 번째 그룹(팀 이름 부분)을 추출, 앞뒤 공백 제거
      final candidate = match.group(1)!.trim();

      // teamKeywords 리스트에 있는 각 키워드(팀명 등)에 대해 반복
      for (final keyword in teamKeywords) {
        if (candidate.contains(keyword.replaceAll(' ', ''))) {
          // _teamToCorp 맵에서 해당 키워드에 매핑된 값을 반환
          // 예: _teamToCorp["삼성 라이온즈"] = "삼성"
          return teamToCorp[keyword];
        }
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
}) {
  if (isMatched) {
    print('✅ DB 매칭 성공');
    print('🏟️ 홈팀: \$homeTeam');
    print('🏟️ 원정팀: \$awayTeam');
    print('📅 날짜: \$date');
    print('⏰ 시간: \$time');
  } else {
    print('❌ DB 매칭 실패');
  }
}
