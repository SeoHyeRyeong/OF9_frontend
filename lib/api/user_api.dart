import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class UserApi {
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

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: body);
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
            case 'PATCH':
              response = await http.patch(uri, headers: newHeaders, body: body);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: newHeaders, body: body);
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

  //=====================================================================================
  // 마이페이지
  //=====================================================================================
  /// 1. 내 정보 조회
  static Future<Map<String, dynamic>> getMyProfile() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/me'),
      method: 'GET',
    );

    print('📥 내 정보 조회 응답 코드: ${res.statusCode}');
    print('📥 내 정보 조회 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('내 정보 조회 실패: ${res.statusCode}');
    }
  }

  /// 2. 내 정보 수정 (JSON 방식 - S3 URL 직접 전송)
  static Future<Map<String, dynamic>> updateMyProfile({
    required String nickname,
    String? favTeam,
    String? profileImageUrl, // S3 URL을 직접 받음
    bool? isPrivate,
  }) async {
    final requestBody = {
      'nickname': nickname,
      if (favTeam != null) 'favTeam': favTeam,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (isPrivate != null) 'isPrivate': isPrivate,
    };

    print('📝 프로필 수정 요청: ${jsonEncode(requestBody)}');

    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/me'),
      method: 'PATCH',
      body: jsonEncode(requestBody),
    );

    print('📝 프로필 수정 응답 코드: ${res.statusCode}');
    print('📝 프로필 수정 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('프로필 수정 실패: ${res.statusCode}');
    }
  }


  /// 3. 닉네임 중복 확인
  static Future<Map<String, dynamic>> checkNickname(String nickname) async {
    final uri = Uri.parse('$baseUrl/users/nickname/check').replace(
      queryParameters: {'nickname': nickname},
    );

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'GET',
    );

    print('🔍 닉네임 중복 확인 응답 코드: ${res.statusCode}');
    print('🔍 닉네임 중복 확인 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('닉네임 중복 확인 실패: ${res.statusCode}');
    }
  }

  /// 4. 로그아웃
  static Future<Map<String, dynamic>> logout() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/me/logout'),
      method: 'POST',
    );

    print('🚪 로그아웃 응답 코드: ${res.statusCode}');
    print('🚪 로그아웃 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('로그아웃 실패: ${res.statusCode}');
    }
  }

  /// 5. 회원 탈퇴
  static Future<Map<String, dynamic>> deleteAccount() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/me'),
      method: 'DELETE',
    );

    print('🗑️ 회원 탈퇴 응답 코드: ${res.statusCode}');
    print('🗑️ 회원 탈퇴 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('회원 탈퇴 실패: ${res.statusCode}');
    }
  }

  /// 6. 팔로잉 목록 조회
  static Future<Map<String, dynamic>> getFollowing(int userId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/$userId/following'),
      method: 'GET',
    );

    print('👥 팔로잉 목록 응답 코드: ${res.statusCode}');
    print('👥 팔로잉 목록 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('팔로잉 목록 조회 실패: ${res.statusCode}');
    }
  }

  /// 7. 팔로워 목록 조회
  static Future<Map<String, dynamic>> getFollowers(int userId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/$userId/followers'),
      method: 'GET',
    );

    print('👥 팔로워 목록 응답 코드: ${res.statusCode}');
    print('👥 팔로워 목록 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('팔로워 목록 조회 실패: ${res.statusCode}');
    }
  }

  //=====================================================================================
  // 피드
  //=====================================================================================

  /// 1. 친구 검색 (리팩토링 후 코드 수정 필요)
  static Future<Map<String, dynamic>> searchUsers(String nickname) async {
    final uri = Uri.parse('$baseUrl/users/search').replace(
      queryParameters: {'nickname': nickname},
    );

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'GET',
    );

    print('🔍 사용자 검색 응답 코드: ${res.statusCode}');
    print('🔍 사용자 검색 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('사용자 검색 실패: ${res.statusCode}');
    }
  }

  /// 2. 팔로우 요청
  static Future<Map<String, dynamic>> followUser(int targetId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/$targetId/follow'),
      method: 'POST',
    );

    print('👥 팔로우 요청 응답 코드: ${res.statusCode}');
    print('👥 팔로우 요청 응답 본문: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 202) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('팔로우 요청 실패: ${res.statusCode}');
    }
  }

  /// 3. 언팔로우
  static Future<Map<String, dynamic>> unfollowUser(int targetId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/$targetId/follow'),
      method: 'DELETE',
    );

    print('👥 언팔로우 응답 코드: ${res.statusCode}');
    print('👥 언팔로우 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('언팔로우 실패: ${res.statusCode}');
    }
  }

  /// 4. 팔로우 요청 목록 조회
  static Future<Map<String, dynamic>> getFollowRequests() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/me/follow-requests'),
      method: 'GET',
    );

    print('📬 팔로우 요청 목록 응답 코드: ${res.statusCode}');
    print('📬 팔로우 요청 목록 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('팔로우 요청 목록 조회 실패: ${res.statusCode}');
    }
  }

  /// 5. 팔로우 수락
  static Future<Map<String, dynamic>> acceptFollowRequest(int requestId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/me/follow-requests/$requestId/accept'),
      method: 'POST',
    );

    print('✅ 팔로우 요청 수락 응답 코드: ${res.statusCode}');
    print('✅ 팔로우 요청 수락 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('팔로우 요청 수락 실패: ${res.statusCode}');
    }
  }

  /// 6. 팔로우 거절
  static Future<Map<String, dynamic>> rejectFollowRequest(int requestId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/users/me/follow-requests/$requestId/reject'),
      method: 'POST',
    );

    print('❌ 팔로우 요청 거절 응답 코드: ${res.statusCode}');
    print('❌ 팔로우 요청 거절 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('팔로우 요청 거절 실패: ${res.statusCode}');
    }
  }
}