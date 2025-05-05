import 'package:intl/intl.dart'; // 아직 사용X 나중에 날짜 포맷 깔끔하게 하기 위해 추가했습니당

class TicketInfoExtractor {
  // KBO 구단 리스트
  static const List<String> teamNames = [
    'KIA 타이거즈',
    '두산 베어스',
    '롯데 자이언츠',
    '삼성 라이온즈',
    '키움 히어로즈',
    '한화 이글스',
    'KT WIZ',
    'LG 트윈스',
    'NC 다이노스',
    'SSG 랜더스',
    '타이거즈',
    '베어스',
    '자이언츠',
    '라이온즈',
    '히어로즈',
    '이글스',
    'WIZ',
    '트윈스',
    '다이노스',
    '랜더스',
  ];

  /// OCR 텍스트를 분석해 홈구단, 원정구단, 경기 일시, 좌석을 추출하는 함수
  static Map<String, dynamic> extractTicketInfo(String ocrText) {
    final lines = ocrText.split('\n');
    String? homeTeam;
    String? awayTeam;
    String? date;
    String? time;
    String? seatInfo;

    // 홈구단, 원정구단 찾기
    List<String> foundTeams = [];
    for (final team in teamNames) {
      if (ocrText.contains(team)) {
        foundTeams.add(team);
      }
    }
    if (foundTeams.length >= 2) {
      homeTeam = foundTeams[0];
      awayTeam = foundTeams[1];
    }

    // 날짜 + 시간 찾기 (정규표현식 사용)
    final dateRegex = RegExp(r'(\d{4}[./-]\d{2}[./-]\d{2})');
    final timeRegex = RegExp(r'(\d{1,2}시\s?\d{1,2}분)');

    for (final line in lines) {
      if (date == null) {
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          date = match.group(0)?.replaceAll('.', '-').replaceAll('/', '-');
        }
      }
      if (time == null) {
        final match = timeRegex.firstMatch(line);
        if (match != null) {
          time = match.group(0);
        }
      }
      if (seatInfo == null) {
        if (line.contains('루') || line.contains('블록') || line.contains('열') || line.contains('석')) {
          seatInfo = line;
        }
      }
    }

    // 날짜와 시간을 합치기
    String? dateTime;
    if (date != null && time != null) {
      dateTime = "$date $time";
    }

    // 최종 결과 반환
    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'dateTime': dateTime,
      'seatInfo': seatInfo,
    };
  }
}
