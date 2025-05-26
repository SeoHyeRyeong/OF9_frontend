import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_response.dart';

class GameApi {
  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 월별 경기 목록 조회
  static Future<List<GameResponse>> listByMonth(String yearMonth) async {
    final res = await http.get(Uri.parse('$baseUrl/games/month/$yearMonth'));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => GameResponse.fromJson(e)).toList();
    } else {
      throw Exception('월별 경기 불러오기 실패');
    }
  }

  /// 기간별 경기 목록 조회
  static Future<List<GameResponse>> listByDateRange({required String from, required String to}) async {
    final uri = Uri.parse('$baseUrl/games?from=$from&to=$to');
    final res = await http.get(uri);

    print('📥 응답 코드: ${res.statusCode}');
    print('📥 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => GameResponse.fromJson(e)).toList();
    } else {
      throw Exception('기간별 경기 불러오기 실패');
    }
  }

  /// 특정 경기 단일 조회
  static Future<GameResponse> getById(String gameId) async {
    final res = await http.get(Uri.parse('$baseUrl/games/$gameId'));
    if (res.statusCode == 200) {
      return GameResponse.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('단일 경기 조회 실패');
    }
  }

  /// 홈/원정/날짜/시간 조건으로 경기 찾기 (extracted info 매칭용)
  static Future<GameResponse> searchGame({
    required String awayTeam,
    required String date,
    required String time,
  }) async {
    final uri = Uri.parse('$baseUrl/games/search').replace(
      queryParameters: {
        'awayTeam': awayTeam,
        'date': date,
        'time': time,
      },
    );

    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return GameResponse.fromJson(decoded);
    } else {
      throw Exception('게임 검색 실패: ${res.statusCode}');
    }
  }
}
