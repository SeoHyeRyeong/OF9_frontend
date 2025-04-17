// kakao_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

final _secureStorage = FlutterSecureStorage();

class KakaoAuthService {
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

  Future<String?> sendTokenToBackend(String accessToken, String favTeam) async {
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
      );

      print('⬅️ [HTTP ${response.statusCode}] ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🎉 백엔드 JWT 토큰 수신: ${data['token']}');
        return data['token'];
      } else {
        print('⚠️ 백엔드 인증 실패: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('🔥 백엔드 통신 오류: $e');
      return null;
    }
  }

  Future<void> saveJwt(String jwt) async {
    await _secureStorage.write(key: 'jwt_token', value: jwt);
    print('🔐 JWT를 secure storage에 저장 완료');
  }

  Future<bool> loginAndStoreJwt(String favTeam) async {
    final accessToken = await kakaoLogin();
    if (accessToken == null) return false;

    final jwt = await sendTokenToBackend(accessToken, favTeam);
    if (jwt == null) return false;

    await saveJwt(jwt);
    return true;
  }

  Future<String?> getJwt() async {
    return await _secureStorage.read(key: 'jwt_token');
  }
}
