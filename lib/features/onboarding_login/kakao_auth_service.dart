import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// Secure Storage인스턴스 (앱 전체에서 재사용)
final _secureStorage = FlutterSecureStorage();

class KakaoAuthService {
  /// 저장된 토큰 존재 여부만 확인 (만료 여부는 신경 안씀)
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

  /// 1) 카카오 로그인 → 액세스 토큰 획득 (기존 로직 유지)
  Future<String?> kakaoLogin() async {
    try {
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

  /// 2) 백엔드에 카카오 액세스 토큰 + favTeam 전송 →
  /// 백엔드에서 우리 서비스의 AccessToken/RefreshToken 수신
  Future<Map<String, String>?> sendKakaoTokenToBackend(
      String kakaoAccessToken,
      String favTeam,
      ) async {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final url = Uri.parse('$backendUrl/auth/kakao/login?platform=app');

    final payload = jsonEncode({
      'token': kakaoAccessToken,
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

        final data = responseData['data'] as Map<String, dynamic>?;
        if (data != null) {
          final ourAccessToken = data['accessToken'] as String?;
          final ourRefreshToken = data['refreshToken'] as String?;

          if (ourAccessToken != null && ourRefreshToken != null) {
            print('🎉 백엔드 토큰 수신: ourAccessToken=${ourAccessToken.substring(0, 20)}..., ourRefreshToken=${ourRefreshToken.substring(0, 20)}...');
            return {'accessToken': ourAccessToken, 'refreshToken': ourRefreshToken};
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

  /// 4) 저장된 토큰 읽기
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

  /// 5) 토큰 갱신 요청
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
        // ⚠️ 수정: 토큰 갱신 시 만료된 AccessToken을 헤더에 보내지 않도록 Authorization 헤더를 제거했습니다.
        // 백엔드에서 Refresh Token은 보통 Body를 통해 처리됩니다.
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $currentAccessToken', // 만료된 AT는 제거
        },
        body: payload,
      ).timeout(const Duration(seconds: 8));

      print('⬅️ [토큰 갱신 응답] ${response.statusCode}');
      print('   응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        final data = responseData['data'] as Map<String, dynamic>?;
        if (data != null) {
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

  /// 6) 인증이 필요한 API 호출 (자동 토큰 갱신 포함) = 자동 재시도 기능
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
    // ⚠️ 수정: backendUrl이 슬래시(/)로 끝나는 경우를 대비하여 중복 슬래시를 방지합니다.
    final cleanBackendUrl = backendUrl.endsWith('/') ? backendUrl.substring(0, backendUrl.length - 1) : backendUrl;
    final url = Uri.parse('$cleanBackendUrl$endpoint');
    print('✅ 최종 URL: $url'); // URL 확인 로그 추가

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

      // ⚠️ 400 에러는 재시도 없이 반환하여 상위 로직에서 처리하도록 합니다.
      if (response.statusCode == 400) {
        print('❌ 400 Bad Request 발생 - 서버가 요청을 이해하지 못함');
      }


      return response;
    } catch (e) {
      print('🔥 API 요청 오류: $e');
      return null;
    }
  }

  /// 기존 사용자 확인
  Future<bool> checkExistingUser(String kakaoAccessToken) async {
    try {
      final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
      final url = Uri.parse('$backendUrl/auth/kakao/check');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': kakaoAccessToken}),
      );

      print('🔍 기존 사용자 확인 응답: ${response.statusCode}');
      print('🔍 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data']['exists'] ?? false;
      }

      return false;
    } catch (e) {
      print('❌ 기존 사용자 확인 실패: $e');
      return false;
    }
  }

  /// 기존 사용자 로그인
  Future<bool> loginExistingUser(String kakaoAccessToken) async {
    try {
      print('🔄 기존 사용자 로그인 시작');

      // 'KIA 타이거즈'는 임시 값일 가능성이 있으므로, 실제 사용자 팀 정보를 사용해야 합니다.
      final ourTokens = await sendKakaoTokenToBackend(kakaoAccessToken, 'KIA 타이거즈');

      if (ourTokens != null) {
        await saveTokens(
          accessToken: ourTokens['accessToken']!,
          refreshToken: ourTokens['refreshToken']!,
        );
        print('✅ 기존 사용자 로그인 성공');
        return true;
      }

      print('❌ 기존 사용자 로그인 실패');
      return false;
    } catch (e) {
      print('❌ 기존 사용자 로그인 오류: $e');
      return false;
    }
  }

  /// 토큰 삭제 (로그아웃, 탈퇴)
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

  /// 7) 로그아웃: 서버 로그아웃 시도 후 로컬 토큰 무조건 삭제
  Future<bool> performLogout() async {
    print('🚪 performLogout 시작 (로컬/서버 처리)');

    // 1. 서버 로그아웃 요청 (로그에서 POST /users/me/logout 경로 확인됨)
    try {
      final response = await authenticatedRequest(
        endpoint: '/users/me/logout',
        method: 'POST',
      );

      // 서버 로그아웃 응답이 실패(400)하더라도 로컬 클리어는 계속 진행합니다.
      if (response != null) {
        print('✅ 서버 로그아웃 응답: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 서버 로그아웃 요청 중 오류 발생: $e');
    }

    // 2. 로컬 토큰 무조건 삭제 (가장 중요한 부분)
    await clearTokens();

    // 3. 카카오 세션도 해제
    try {
      await UserApi.instance.logout();
      print('✅ 카카오 세션 로그아웃 성공');
    } catch (e) {
      print('❌ 카카오 세션 로그아웃 실패: $e');
    }

    // 로컬 토큰을 지웠으므로 클라이언트 관점에서는 로그아웃 성공으로 간주
    return true;
  }

  /// 카카오 연결 해제 (탈퇴)
  Future<bool> unlinkKakaoAccount() async {
    try {
      print('🔗 카카오 연결 해제 시작');
      await UserApi.instance.unlink();
      print('✅ 카카오 연결 해제 완료');
      return true;
    } catch (e) {
      print('❌ 카카오 연결 해제 실패: $e');
      return false;
    }
  }
}
