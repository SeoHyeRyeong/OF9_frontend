// kakao_auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// Secure Storage 인스턴스 (앱 전체에서 재사용)
final _secureStorage = FlutterSecureStorage();

class KakaoAuthService {
  /// 1) 카카오 로그인 → 액세스 토큰 획득
  Future<String?> kakaoLogin() async {
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
      print('✅ 카카오 로그인 성공, accessToken: ${token.accessToken}');
      return token.accessToken;
    } catch (e) {
      print('❌ 카카오 로그인 실패: $e');
      return null;
    }
  }

  /// 2) 백엔드에 엑세스 토큰 + favTeam 전송 →
  ///    백엔드에서 AccessToken/RefreshToken 둘 다 수신
  Future<Map<String, String>?> sendTokenToBackend(
      String accessToken,
      String favTeam,
      ) async {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final url = Uri.parse('$backendUrl/auth/kakao');
    final payload = jsonEncode({
      'accessToken': accessToken,  // 추가 (accessToken을 RequestBody에 포함)
      'favTeam': favTeam,
    });

    print('➡️ [HTTP POST] $url');
    print('   headers: {"Content-Type": "application/json"}');
    print('   body: $payload');

    try {
      final response = await http.post(
        url,
        headers: {
          //'Authorization': 'Bearer $accessToken',  Authorization 헤더 제거 (RequestBody로 보내므로)
          'Content-Type': 'application/json',
        },
        body: payload,
      ).timeout(const Duration(seconds: 8));

      print('⬅️ [HTTP ${response.statusCode}] ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final at = data['accessToken']  as String?;
        final rt = data['refreshToken'] as String?;
        if (at != null && rt != null) {
          print('🎉 백엔드 토큰 수신: accessToken=$at, refreshToken=$rt');
          return {'accessToken': at, 'refreshToken': rt};
        }
      } else {
        print('⚠️ 백엔드 인증 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('🔥 백엔드 통신 오류: $e');
    }
    return null;
  }

  /// 3) Secure Storage 에 두 토큰 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: 'access_token',  value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    print('🔐 access_token 저장: $accessToken');
    print('🔐 refresh_token 저장: $refreshToken');
  }

  /// 4) 전체 로그인 + 토큰 저장 플로우
  Future<bool> loginAndStoreTokens(String favTeam) async {
    // 1) 카카오 로그인으로 엑세스토큰 획득
    final kakaoAT = await kakaoLogin();
    if (kakaoAT == null) return false;

    // 2) 백엔드로 보내고 액세스·리프레시 토큰 수신
    final tokens = await sendTokenToBackend(kakaoAT, favTeam);
    if (tokens == null) return false;

    // 3) secure storage 에 저장
    await saveTokens(
      accessToken:  tokens['accessToken']!,
      refreshToken: tokens['refreshToken']!,
    );
    return true;
  }

  /// 5) 저장된 토큰 읽기
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  /// 6) 토큰 갱신 요청
  Future<Map<String, String>?> refreshTokens() async {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final url = Uri.parse('$backendUrl/auth/refresh');

    final currentAccessToken = await getAccessToken();
    final currentRefreshToken = await getRefreshToken();

    if (currentAccessToken == null || currentRefreshToken == null) {
      print('❌ 저장된 토큰이 없음');
      return null;
    }

    final payload = jsonEncode({'refreshToken': currentRefreshToken});

    try {
      final response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $currentAccessToken', //헤더에 에세스 토큰
              'Content-Type': 'application/json',
            },
            body: payload, //바디에 리프레시 토큰
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          print('🔄 토큰 갱신 성공');
          return {
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          };
        }
      }
    } catch (e) {
      print('🔥 토큰 갱신 오류: $e');
    }
    return null;
  }

  /// 7) 인증이 필요한 API 호출 (자동 토큰 갱신 포함) = 자동 재시도 기능
  Future<http.Response?> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    String? body,
  }) async {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final url = Uri.parse('$backendUrl$endpoint');

    String? accessToken = await getAccessToken();
    if (accessToken == null) {
      print('❌ 액세스 토큰이 없음');
      return null;
    }

    final requestHeaders = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      ...?headers,
    };

    try {
      http.Response response;

      // HTTP 메서드에 따른 요청
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(url, headers: requestHeaders, body: body);
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메서드: $method');
      }

      // 401 에러 시 토큰 갱신 후 재시도
      if (response.statusCode == 401) {
        print('🔄 토큰 만료, 갱신 시도...');
        final refreshResult = await refreshTokens();

        if (refreshResult != null) {
          // 새 토큰으로 재요청
          requestHeaders['Authorization'] = 'Bearer ${refreshResult['accessToken']}';

          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(url, headers: requestHeaders);
              break;
            case 'POST':
              response = await http.post(url, headers: requestHeaders, body: body);
              break;
          }
          print('🎉 토큰 갱신 후 재요청 성공');
        } else {
          print('❌ 토큰 갱신 실패, 재로그인 필요');
          return null;
        }
      }

      return response;
    } catch (e) {
      print('🔥 API 요청 오류: $e');
      return null;
    }
  }
}