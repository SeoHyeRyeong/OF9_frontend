import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart'; // KakaoAuthService 경로 확인 필요

class ReportApi {
  static final _kakaoAuth = KakaoAuthService(); // KakaoAuthService 인스턴스

  // 백엔드 기본 URL 가져오기 (.env 파일)
  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 공통 Authorization 헤더 생성
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _kakaoAuth.getAccessToken();
    // TODO: 토큰이 null일 경우 예외 처리 또는 재로그인 유도 로직 추가 고려
    if (token == null) {
      print('❌ ReportApi: Access Token is null. Re-login required.');
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // JSON 요청 기본
    };
  }

  /// 토큰 갱신 후 재시도하는 공통 로직 (RecordApi에서 가져옴)
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
      // TODO: 필요하다면 POST, PATCH, DELETE 메서드 추가
        default:
          throw Exception('지원하지 않는 HTTP 메서드: $method');
      }

      // 401 (Unauthorized) 또는 403 (Forbidden) 에러 시 토큰 갱신 시도
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('🔄 ReportApi: 토큰 만료 또는 권한 없음 (${response.statusCode}), 갱신 시도...');

        // TODO: KakaoAuthService에 토큰 갱신 메서드(refreshTokens) 구현 및 호출 필요
        // final refreshResult = await _kakaoAuth.refreshTokens();
        final refreshResult = null; // 실제 토큰 갱신 로직으로 교체 필요

        if (refreshResult != null) {
          print('✅ ReportApi: 토큰 갱신 성공');
          // 새 토큰으로 헤더 재생성
          final newHeaders = await _authHeaders();

          // 원래 요청 재시도
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: newHeaders);
              break;
          // TODO: POST, PATCH, DELETE 재시도 로직 추가
          }
          print('🎉 ReportApi: 토큰 갱신 후 재요청 성공 (${response.statusCode})');
        } else {
          print('❌ ReportApi: 토큰 갱신 실패, 재로그인 필요');
          // TODO: 사용자에게 재로그인 안내 또는 자동 로그아웃 처리 구현
          throw Exception('토큰 갱신에 실패했습니다. 다시 로그인해주세요.');
        }
      }

      // 최종 응답 반환
      return response;

    } catch (e) {
      // 네트워크 오류 또는 기타 예외 처리
      print('🔥 ReportApi: API 요청 오류 ($uri): $e');
      rethrow; // 호출한 곳에서 에러를 처리할 수 있도록 다시 던짐
    }
  }

  //=====================================================================================
  // 리포트 API 호출 메서드
  //=====================================================================================

  /// 메인 리포트 조회 (GET /reports/main)
  static Future<Map<String, dynamic>> getMainReport() async {
    final uri = Uri.parse('$baseUrl/reports/main');
    print('📊 [GET] 메인 리포트 요청: $uri');

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'GET',
    );

    print('📊 메인 리포트 응답 코드: ${res.statusCode}'); // 응답 코드 로그

    // ▼▼▼ 응답 본문 로그 추가 ▼▼▼
    final String responseBodyString = utf8.decode(res.bodyBytes);
    print('📊 메인 리포트 응답 본문: $responseBodyString');
    // ▲▲▲ 응답 본문 로그 추가 ▲▲▲

    if (res.statusCode == 200) {
      final responseData = jsonDecode(responseBodyString); // 미리 디코드한 문자열 사용
      // 응답 구조 확인 (success 필드, data 필드 타입)
      if (responseData['success'] == true && responseData['data'] is Map<String, dynamic>) {
        print('✅ 메인 리포트 조회 성공');
        // data 필드만 추출하여 반환
        return responseData['data'] as Map<String, dynamic>;
      } else {
        print('❌ 메인 리포트 응답 형식 오류');
        throw Exception('메인 리포트 응답 형식이 올바르지 않습니다.');
      }
    } else {
      // HTTP 에러 처리
      print('❌ 메인 리포트 조회 실패: ${res.statusCode}');
      throw Exception('메인 리포트 조회 실패: ${res.statusCode}');
    }
  }

  /// 뱃지 현황 조회 (GET /reports/badge)
  static Future<Map<String, dynamic>> getBadgeReport() async {
    final uri = Uri.parse('$baseUrl/reports/badge');
    print('뱃지 [GET] 뱃지 현황 요청: $uri');

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'GET',
    );

    print('뱃지 뱃지 현황 응답 코드: ${res.statusCode}'); // 응답 코드 로그

    // ▼▼▼ 응답 본문 로그 추가 ▼▼▼
    final String responseBodyString = utf8.decode(res.bodyBytes);
    print('뱃지 뱃지 현황 응답 본문: $responseBodyString');
    // ▲▲▲ 응답 본문 로그 추가 ▲▲▲

    if (res.statusCode == 200) {
      final responseData = jsonDecode(responseBodyString); // 미리 디코드한 문자열 사용
      // 응답 구조 확인
      if (responseData['success'] == true && responseData['data'] is Map<String, dynamic>) {
        print('✅ 뱃지 현황 조회 성공');
        // data 필드만 추출하여 반환
        return responseData['data'] as Map<String, dynamic>;
      } else {
        print('❌ 뱃지 현황 응답 형식 오류');
        throw Exception('뱃지 현황 응답 형식이 올바르지 않습니다.');
      }
    } else {
      // HTTP 에러 처리
      print('❌ 뱃지 현황 조회 실패: ${res.statusCode}');
      throw Exception('뱃지 현황 조회 실패: ${res.statusCode}');
    }
  }
}