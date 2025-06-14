import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';


class UserApi {
  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 공통 Authorization 헤더 생성
  static Future<Map<String, String>> _authHeaders() async {
    final token = await KakaoAuthService().getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// 내 정보 조회
  static Future<Map<String, dynamic>> getMyInfo() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
    );

    print('📥 내 정보 조회 응답 코드: ${res.statusCode}');
    print('📥 내 정보 조회 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      // UTF-8 디코딩 추가
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } else {
      throw Exception('내 정보 조회 실패: ${res.statusCode}');
    }
  }

}
