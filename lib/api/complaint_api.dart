import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';

class ComplaintApi {
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
  // =============================== 신고 관련 API ====================================
  // ================================================================================

  /// 신고하기
  /// - reportedUserId: 사용자 신고
  /// - reportedRecordId: 게시글 신고
  static Future<bool> createComplaint({
    int? reportedUserId,
    int? reportedRecordId,
  }) async {
    if (reportedUserId == null && reportedRecordId == null) {
      throw Exception('신고 대상을 선택해주세요');
    }

    final uri = Uri.parse('$baseUrl/complaints');

    final body = jsonEncode({
      if (reportedUserId != null) 'reportedUserId': reportedUserId,
      if (reportedRecordId != null) 'reportedRecordId': reportedRecordId,
    });

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'POST',
      body: body,
    );

    print('🚨 신고 접수 응답 코드: ${res.statusCode}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      print('✅ 신고 성공: ${decoded['message']}');
      return true;
    } else if (res.statusCode == 400) {
      // 중복 신고, 자기 자신 신고 등의 에러
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      throw Exception(decoded['message'] ?? '신고 처리 중 오류가 발생했습니다');
    } else {
      throw Exception('신고 접수 실패: ${res.statusCode}');
    }
  }

  /// 사용자 신고
  static Future<bool> reportUser(int userId) async {
    return await createComplaint(reportedUserId: userId);
  }

  /// 게시글 신고
  static Future<bool> reportRecord(int recordId) async {
    return await createComplaint(reportedRecordId: recordId);
  }
}