import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';

class FeedApi {
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
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
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
            case 'PUT':
              response = await http.put(uri, headers: newHeaders, body: body);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: newHeaders);
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

  // ================================================================================
  // =============================== 피드 관련 API ====================================
  /// 1. 전체 피드 조회
  static Future<List<Map<String, dynamic>>> getAllFeed({
    String? team,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    if (team != null && team.isNotEmpty) {
      queryParams['team'] = team;
    }

    final uri = Uri.parse('$baseUrl/feed/all').replace(
      queryParameters: queryParams,
    );

    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('📱 전체 피드 조회 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = decoded['data'] as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('전체 피드 조회 실패: ${res.statusCode}');
    }
  }

  /// 2. 팔로잉 피드 조회
  static Future<List<Map<String, dynamic>>> getFollowingFeed({
    String? team,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    if (team != null && team.isNotEmpty) {
      queryParams['team'] = team;
    }

    final uri = Uri.parse('$baseUrl/feed/following').replace(
      queryParameters: queryParams,
    );

    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('👥 팔로잉 피드 조회 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = decoded['data'] as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('팔로잉 피드 조회 실패: ${res.statusCode}');
    }
  }


  // ================================================================================
  // =============================== 좋아요 관련 API ====================================
  /// 1. 좋아요 토글 (추가/삭제)
  static Future<Map<String, dynamic>> toggleLike(String recordId) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/likes');

    final res = await _makeRequestWithRetry(uri: uri, method: 'POST');

    print('❤️ 좋아요 토글 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = decoded['data'] as Map<String, dynamic>;

      return {
        'isLiked': data['liked'],
        'likeCount': data['totalLikes'],
      };
    } else {
      throw Exception('좋아요 토글 실패: ${res.statusCode}');
    }
  }

  /// 2. 좋아요 개수 조회
  static Future<int> getLikeCount(String recordId) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/likes/count');

    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('📊 좋아요 개수 조회 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded['data'] as int;
    } else {
      throw Exception('좋아요 개수 조회 실패: ${res.statusCode}');
    }
  }

  /// 3. 좋아요 여부 확인
  static Future<bool> checkLikeStatus(String recordId) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/likes/check');

    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('✅ 좋아요 여부 확인 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded['data'] as bool;
    } else {
      throw Exception('좋아요 여부 확인 실패: ${res.statusCode}');
    }
  }

  /// 4. 좋아요 누른 사용자 목록 조회
  static Future<List<Map<String, dynamic>>> getLikeUsers(String recordId) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/likes/users');

    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('👥 좋아요 사용자 목록 조회 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = decoded['data'] as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('좋아요 사용자 목록 조회 실패: ${res.statusCode}');
    }
  }


  // ================================================================================
  // =============================== 댓글 관련 API ====================================
  /// 1. 댓글 작성
  static Future<Map<String, dynamic>> createComment(
      String recordId,
      String content,
      ) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/comments');

    final body = jsonEncode({
      'content': content,
    });

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'POST',
      body: body,
    );

    print('💬 댓글 작성 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded['data'] as Map<String, dynamic>;
    } else {
      throw Exception('댓글 작성 실패: ${res.statusCode}');
    }
  }

  /// 2. 댓글 목록 조회
  static Future<List<Map<String, dynamic>>> getComments(String recordId) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/comments');

    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('📝 댓글 목록 조회 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = decoded['data'] as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('댓글 목록 조회 실패: ${res.statusCode}');
    }
  }

  /// 3. 댓글 수정
  static Future<Map<String, dynamic>> updateComment(
      String recordId,
      String commentId,
      String content,
      ) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/comments/$commentId');

    final body = jsonEncode({
      'content': content,
    });

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'PUT',
      body: body,
    );

    print('✏️ 댓글 수정 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded['data'] as Map<String, dynamic>;
    } else {
      throw Exception('댓글 수정 실패: ${res.statusCode}');
    }
  }

  /// 4. 댓글 삭제
  static Future<void> deleteComment(String recordId, String commentId) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/comments/$commentId');

    final res = await _makeRequestWithRetry(uri: uri, method: 'DELETE');

    print('🗑️ 댓글 삭제 응답 코드: ${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception('댓글 삭제 실패: ${res.statusCode}');
    }
  }

  /// 5. 댓글 개수 조회
  static Future<int> getCommentCount(String recordId) async {
    final uri = Uri.parse('$baseUrl/records/$recordId/comments/count');

    final res = await _makeRequestWithRetry(uri: uri, method: 'GET');

    print('📊 댓글 개수 조회 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded['data'] as int;
    } else {
      throw Exception('댓글 개수 조회 실패: ${res.statusCode}');
    }
  }
}