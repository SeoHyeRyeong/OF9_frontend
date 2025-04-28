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
      'accessToken': accessToken,
      'favTeam': favTeam,
    });

    print('➡️ [HTTP POST] $url');
    print('   headers: {"Content-Type": "application/json"}');
    print('   body: $payload');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 5));

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
}
