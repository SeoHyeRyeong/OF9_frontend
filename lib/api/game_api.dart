import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_response.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';

class GameApi {
  static final _kakaoAuth = KakaoAuthService();

  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 공통 Authorization 헤더 생성
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _kakaoAuth.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// 토큰 갱신 후 재시도하는 공통 로직
  static Future<http.Response> _makeRequestWithRetry({
    required Uri uri,
    required String method,
    String? body,
  }) async {
    try {
      final headers = await _authHeaders();
      http.Response response;

      // 첫 번째 요청
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메서드: $method');
      }

      // 401/403 에러 시 토큰 갱신 후 재시도
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('🔄 토큰 만료, 갱신 시도...');
        final refreshResult = await _kakaoAuth.refreshTokens();

        if (refreshResult != null) {
          // 새 토큰으로 헤더 재생성
          final newHeaders = await _authHeaders();

          // 재시도
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: newHeaders);
              break;
            case 'POST':
              response = await http.post(uri, headers: newHeaders, body: body);
              break;
          }
          print('🎉 토큰 갱신 후 재요청 성공');
        } else {
          print('❌ 토큰 갱신 실패, 재로그인 필요');
          throw Exception('토큰 갱신 실패. 재로그인하세요.');
        }
      }

      return response;
    } catch (e) {
      print('🔥 API 요청 오류: $e');
      rethrow;
    }
  }

  /// 월별 경기 목록 조회
  static Future<List<GameResponse>> listByMonth(String yearMonth) async {
    final uri = Uri.parse('$baseUrl/games/month/$yearMonth');
    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => GameResponse.fromJson(e)).toList();
    } else {
      throw Exception('월별 경기 불러오기 실패: ${res.statusCode}');
    }
  }

  /// 기간별 경기 목록 조회
  static Future<List<GameResponse>> listByDateRange({
    required String from,
    required String to,
  }) async {
    final uri = Uri.parse('$baseUrl/games').replace(
      queryParameters: {'from': from, 'to': to},
    );
    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('📥 응답 코드: ${res.statusCode}');
    print('📥 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => GameResponse.fromJson(e)).toList();
    } else {
      throw Exception('기간별 경기 불러오기 실패: ${res.statusCode}');
    }
  }

  /// 특정 경기 단일 조회
  static Future<GameResponse> getById(String gameId) async {
    final uri = Uri.parse('$baseUrl/games/$gameId');
    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    if (res.statusCode == 200) {
      return GameResponse.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('단일 경기 조회 실패: ${res.statusCode}');
    }
  }

  /// 원정팀/날짜/시간 조건으로 경기 찾기
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
    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return GameResponse.fromJson(decoded);
    } else {
      throw Exception('게임 검색 실패: ${res.statusCode}');
    }
  }
}