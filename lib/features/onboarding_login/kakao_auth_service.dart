// kakao_auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// Secure Storage인스턴스 (앱 전체에서 재사용)
final _secureStorage = FlutterSecureStorage();

class KakaoAuthService {
  ///저장된 토큰 존재 여부만 확인 (만료 여부는 신경 안씀)
  Future<bool> hasStoredTokens() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      final result = accessToken != null && refreshToken != null;
      print('🔍 hasStoredTokens() 결과: $result');
      return result;
    } catch (e) {
      print('❌ 토큰 존재 확인 실패: $e');
      return false;
    }
  }

  /// 1) 카카오 로그인 → 액세스 토큰 획득
  Future<String?> kakaoLogin() async {
    try {
      print('🚀 카카오 로그인 시작...');
      OAuthToken token;

      if (await isKakaoTalkInstalled()) {
        try {
          print('📱 카카오톡 앱으로 로그인 시도');
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          print('⚠️ 카카오톡 로그인 실패, 웹 로그인으로 전환: $e');
          print('🌐 카카오 계정으로 로그인 시도');
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        print('🌐 카카오 계정으로 로그인 시도');
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('✅ 카카오 로그인 성공, accessToken: ${token.accessToken?.substring(0, 20)}...');
      return token.accessToken;
    } catch (e) {
      print('❌ 카카오 로그인 실패: $e');
      return null;
    }
  }

  /// 2) 백엔드에 액세스 토큰 + favTeam 전송 →
  /// 백엔드에서 AccessToken/RefreshToken 둘 다 수신
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
        headers: {
          'Content-Type': 'application/json',
        },
        body: payload,
      ).timeout(const Duration(seconds: 8));

      print('⬅️ [HTTP ${response.statusCode}] ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // ✅ 수정: data 필드에서 토큰을 정확히 추출
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data != null) {
          final at = data['accessToken'] as String?;
          final rt = data['refreshToken'] as String?;

          if (at != null && rt != null) {
            print('🎉 백엔드 토큰 수신: accessToken=${at.substring(0, 20)}..., refreshToken=${rt.substring(0, 20)}...');
            return {'accessToken': at, 'refreshToken': rt};
          } else {
            print('❌ data 내부에 토큰이 없음: $data');
          }
        } else {
          print('❌ 백엔드 응답에 data 필드가 없음: $responseData');
        }
      }
    } catch (e) {
      print('🔥 백엔드 통신 오류: $e');
    }
    return null;
  }

  /// 3) Secure Storage에 두 토큰 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      print('🔐 토큰 저장 시작...');
      await _secureStorage.write(key: 'access_token',  value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      print('🔐 access_token 저장 완료: ${accessToken.substring(0, 20)}...');
      print('🔐 refresh_token 저장 완료: ${refreshToken.substring(0, 20)}...');

      // 저장 확인
      final savedAT = await _secureStorage.read(key: 'access_token');
      final savedRT = await _secureStorage.read(key: 'refresh_token');
      print('✅ 저장 확인 - AT: ${savedAT != null}, RT: ${savedRT != null}');
    } catch (e) {
      print('❌ 토큰 저장 실패: $e');
      rethrow;
    }
  }

  /// 4)전체 로그인 +토큰 저장 플로우
  Future<bool> loginAndStoreTokens(String favTeam) async {
    print('🚀 전체 로그인 플로우 시작...');

    // 1) 카카오 로그인으로 엑세스토큰 획득
    final kakaoAT = await kakaoLogin();
    if (kakaoAT == null) {
      print('❌ 1단계 실패: 카카오 로그인');
      return false;
    }

    // 2) 백엔드로 보내고 액세스·리프레시 토큰 수신
    final tokens = await sendTokenToBackend(kakaoAT, favTeam);
    if (tokens == null) {
      print('❌ 2단계 실패: 백엔드 토큰 교환');
      return false;
    }

    // 3) secure storage 에 저장
    await saveTokens(
      accessToken:  tokens['accessToken']!,
      refreshToken: tokens['refreshToken']!,
    );

    print('✅ 전체 로그인 플로우 완료');
    return true;
  }

  /// 5)저장된 토큰 읽기
  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) {
        print('⚠️ AccessToken이 null입니다');
      }
      return token;
    } catch (e) {
      print('❌ AccessToken 읽기 실패: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: 'refresh_token');
      if (token == null) {
        print('⚠️ RefreshToken이 null입니다');
      }
      return token;
    } catch (e) {
      print('❌ RefreshToken 읽기 실패: $e');
      return null;
    }
  }

  /// 6) 토큰 갱신 요청
  Future<Map<String, String>?> refreshTokens() async {
    print('🔄 ===== 토큰 갱신 시작 =====');

    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final url = Uri.parse('$backendUrl/auth/refresh');

    final currentAccessToken = await getAccessToken();
    final currentRefreshToken = await getRefreshToken();

    print('🔍 현재 토큰 상태:');
    print('  accessToken 존재: ${currentAccessToken != null}');
    print('  refreshToken 존재: ${currentRefreshToken != null}');

    if (currentAccessToken != null) {
      print('  accessToken 길이: ${currentAccessToken.length}');
      print('  accessToken 앞부분: ${currentAccessToken.substring(0, currentAccessToken.length > 20 ? 20 : currentAccessToken.length)}...');
    }

    if (currentRefreshToken != null) {
      print('  refreshToken 길이: ${currentRefreshToken.length}');
      print('  refreshToken 앞부분: ${currentRefreshToken.substring(0, currentRefreshToken.length > 20 ? 20 : currentRefreshToken.length)}...');
    }

    if (currentAccessToken == null || currentRefreshToken == null) {
      print('❌ 저장된 토큰이 없음 - 재로그인 필요');
      return null;
    }

    final payload = jsonEncode({'refreshToken': currentRefreshToken});
    print('➡️ [토큰 갱신 요청] $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $currentAccessToken',
          'Content-Type': 'application/json',
        },
        body: payload,
      ).timeout(const Duration(seconds: 8));

      print('⬅️ [토큰 갱신 응답] ${response.statusCode}');
      print('   응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // ✅ 수정: data 필드에서 토큰을 정확히 추출
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data != null) {
          final newAccessToken = data['accessToken'] as String?;
          final newRefreshToken = data['refreshToken'] as String?; // 백엔드가 새 리프레시 토큰을 줄 수도 있으므로 함께 처리

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
          } else {
            print('❌ data 내부에 새 토큰이 없음: $data');
            print('   newAccessToken: $newAccessToken');
            print('   newRefreshToken: $newRefreshToken');
          }
        } else {
          print('❌ 갱신 응답에 data 필드가 없음: $responseData');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('❌ 리프레시 토큰도 만료됨, 재로그인 필요');
        await clearTokens();
        return null;
      } else {
        print('❌ 토큰 갱신 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('🔥 토큰 갱신 오류: $e');
    }

    print('🔄 ===== 토큰 갱신 실패 =====');
    return null;
  }

  /// 7)토큰 삭제 (로그아웃 시 사용)
  Future<void> clearTokens() async {
    try {
      print('🗑️ 토큰 삭제 시작...');
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      print('🗑️ 모든 토큰 삭제 완료');

      // 삭제 확인
      final remainingAT = await _secureStorage.read(key: 'access_token');
      final remainingRT = await _secureStorage.read(key: 'refresh_token');
      print('✅ 삭제 확인 - AT: ${remainingAT == null}, RT: ${remainingRT == null}');
    } catch (e) {
      print('❌ 토큰 삭제 실패: $e');
    }
  }

  /// 8)인증이 필요한 API호출 (자동 토큰 갱신 포함) = 자동 재시도 기능
  Future<http.Response?> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    String? body,
  }) async {
    print('🌐 ===== API 요청 시작: $method $endpoint =====');

    // 토큰 상태 먼저 확인
    final hasTokens = await hasStoredTokens();
    if (!hasTokens) {
      print('❌ 토큰이 없어서 API 요청 불가');
      return null;
    }

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
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메서드: $method');
      }

      print('⬅️ 첫 번째 응답: ${response.statusCode}');

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
            case 'DELETE':
              response = await http.delete(url, headers: requestHeaders);
              break;
          }
          print('🎉 토큰 갱신 후 재요청 성공: ${response.statusCode}');
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