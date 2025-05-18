import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_response.dart';

class GameApi {
  static String get _baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 1) 원정팀, 날짜, 시간으로 단일 경기 조회
  static Future<GameResponse> searchGame({
    required String awayTeam,
    required String date,
    required String time,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/games/search').replace(
      queryParameters: {
        'awayTeam': awayTeam,
        'date': date,
        'time': time,
      },
    );

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return GameResponse.fromJson(decoded);
    } else {
      throw Exception('게임 검색 실패: ${response.statusCode}');
    }
  }

  /// 2) 기간(from, to)으로 경기 목록 조회
  static Future<List<GameResponse>> listByDateRange({
    required String from,
    required String to,
  }) async {
    final uri = Uri.parse('$_baseUrl/games').replace(queryParameters: {
      'from': from,
      'to': to,
    });

    final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (resp.statusCode == 200) {
      final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
      return list.map((e) => GameResponse.fromJson(e)).toList();
    }
    throw Exception('기간별 경기 조회 실패: ${resp.statusCode}');
  }

  /// 3) 단일 경기 기본 정보 조회
  static Future<GameResponse> getGameById(String gameId) async {
    final uri = Uri.parse('$_baseUrl/games/$gameId');
    final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (resp.statusCode == 200) {
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      return GameResponse.fromJson(json);
    }
    throw Exception('경기 상세 조회 실패: ${resp.statusCode}');
  }

  /// 4) 상세 정보 즉시 갱신 요청
  static Future<String> updateGameDetail(String gameId) async {
    final uri = Uri.parse('$_baseUrl/games/$gameId/detail/update');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return utf8.decode(resp.bodyBytes);
    }
    throw Exception('상세 정보 갱신 실패: ${resp.statusCode}');
  }

  /// 5) 기록 저장 요청
  static Future<void> saveRecord({
    required String gameId,
    required String homeTeam,
    required String seat,
  }) async {
    final uri = Uri.parse('$_baseUrl/records');
    final body = jsonEncode({
      'gameId': gameId,
      'homeTeam': homeTeam,
      'seat': seat,
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('기록 저장 실패: ${resp.statusCode}');
    }
  }
}
