/*import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_response.dart';

class GameApi {
  static Future<GameResponse> searchGame({
    required String awayTeam,
    required String date,
    required String time,
  }) async {
    final Uri url = Uri.parse('http://192.168.0.5:8080/games/search')
        .replace(queryParameters: {
      'awayTeam': awayTeam,
      'date': date,
      'time': time,
    });

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return GameResponse.fromJson(decoded);
    } else {
      throw Exception('게임 검색 실패: ${response.statusCode}');
    }
  }
}*/
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_response.dart';

class GameApi {
  static Future<GameResponse> searchGame({
    required String awayTeam,
    required String date,
    required String time,
  }) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');

    final Uri url = Uri.parse('$backendUrl/games/search').replace(
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
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return GameResponse.fromJson(decoded);
    } else {
      throw Exception('게임 검색 실패: ${response.statusCode}');
    }
  }
}

