class GameResponse {
  final String gameId;        // 경기 ID
  final DateTime date;        // 경기 날짜
  final String time;          // 경기 예정 시간 (HH:mm:ss)
  final String playtime;      // 실제 경기 시작 시간 (nullable 가능)
  final String stadium;       // 경기장 이름
  final String homeTeam;      // 홈팀 이름
  final String awayTeam;      // 어웨이팀 이름
  final int? homeScore;       // 홈팀 점수 (nullable)
  final int? awayScore;       // 어웨이팀 점수 (nullable)
  final String status;        // 경기 상태 (예: SCHEDULED, LIVE, FINISHED)
  final String homeImg;       // 홈팀 로고 이미지 URL
  final String awayImg;       // 어웨이팀 로고 이미지 URL

  const GameResponse({
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

  /// JSON -> GameResponse 객체 변환
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
