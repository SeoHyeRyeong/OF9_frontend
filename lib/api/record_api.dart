import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';


class RecordApi {
  static final _kakaoAuth = KakaoAuthService();

  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 공통 Authorization 헤더 생성 (JSON용)
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
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: body);
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
            case 'PATCH':
              response = await http.patch(uri, headers: newHeaders, body: body);
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

  //=====================================================================================
  // 직관 기록
  //=====================================================================================

  /// 직관 기록 등록
  /// 모든 기록을 한 번에 업로드 (JSON + Base64 방식)
  static Future<Map<String, dynamic>> createCompleteRecord({
    required int userId,
    required String gameId,
    required String seatInfo,
    required int emotionCode,
    required String stadium,
    String? comment,
    String? longContent,
    String? bestPlayer,
    List<int>? companionIds,
    List<String>? foodTags,
    List<String>? imagePaths,
  }) async {
    // 이미지를 Base64로 인코딩
    List<String> base64Images = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (String imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            final base64String = base64Encode(bytes);
            base64Images.add(base64String);
            print('📤 이미지 Base64 인코딩 완료: ${imagePath}');
          } catch (e) {
            print('❌이미지 인코딩 실패: $imagePath, 에러: $e');
          }
        }
      }
    }

    final requestBody = {
      'userId': userId,
      'gameId': gameId,
      'seatInfo': seatInfo,
      'emotionCode': emotionCode,
      'stadium': stadium,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (longContent != null && longContent.isNotEmpty) 'longContent': longContent,
      if (bestPlayer != null && bestPlayer.isNotEmpty) 'bestPlayer': bestPlayer,
      if (companionIds != null && companionIds.isNotEmpty) 'companions': companionIds,
      if (foodTags != null && foodTags.isNotEmpty) 'foodTags': foodTags,
      if (base64Images.isNotEmpty) 'mediaUrls': base64Images,
    };

    print('📤 기록 업로드 요청 본문: ${jsonEncode(requestBody).length} bytes');
    print('📤 Base64 이미지 개수: ${base64Images.length}');

    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records'),
      method: 'POST',
      body: jsonEncode(requestBody),
    );

    print('📥 기록 업로드 응답 코드: ${res.statusCode}');
    print('📥 기록 업로드 응답 본문: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      return responseData['data'];
    } else {
      throw Exception('기록 업로드 실패: ${res.statusCode}');
    }
  }

  /// 맞팔 친구 검색
  static Future<List<Map<String, dynamic>>> getMutualFriends({String? query}) async {
    Uri uri;
    if (query != null && query.isNotEmpty) {
      uri = Uri.parse('$baseUrl/records/me/mutual-friends?query=${Uri.encodeComponent(query)}');
    } else {
      uri = Uri.parse('$baseUrl/records/me/mutual-friends');
    }

    final res = await _makeRequestWithRetry(
      uri: uri,
      method: 'GET',
    );

    print('👥 맞팔 친구 응답: ${res.statusCode} - ${res.body}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      final List<dynamic> friends = responseData['data'];
      return friends.cast<Map<String, dynamic>>();
    } else {
      throw Exception('맞팔 친구 조회 실패: ${res.statusCode}');
    }
  }

  /// 직관 기록 수정 (디테일한 정보 추가)
  static Future<Map<String, dynamic>> updateRecord({
    required String recordId,
    String? comment,
    String? longContent,
    String? bestPlayer,
    List<int>? companionIds,
    List<String>? foodTags,
    List<String>? imagePaths,
  }) async {
    // 이미지를 Base64로 인코딩
    List<String> base64Images = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (String imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            final base64String = base64Encode(bytes);
            base64Images.add(base64String);
            print('📤 이미지 Base64 인코딩 완료: ${imagePath}');
          } catch (e) {
            print('❌ 이미지 인코딩 실패: $imagePath, 에러: $e');
          }
        }
      }
    }

    final requestBody = {
      if (comment != null) 'comment': comment,
      if (longContent != null) 'longContent': longContent,
      if (bestPlayer != null) 'bestPlayer': bestPlayer,
      if (companionIds != null) 'companions': companionIds,
      if (foodTags != null) 'foodTags': foodTags,
      if (base64Images.isNotEmpty) 'mediaUrls': base64Images,
    };

    print('📤 기록 수정 요청 본문: ${jsonEncode(requestBody)}');

    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/$recordId'),
      method: 'PATCH',
      body: jsonEncode(requestBody),
    );

    print('📥 기록 수정 응답 코드: ${res.statusCode}');
    print('📥 기록 수정 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      return responseData['data']; // ApiResponse의 data 필드 반환
    } else {
      throw Exception('기록 수정 실패: ${res.statusCode}');
    }
  }

  /// 하나의 직관 기록 조회
  static Future<Map<String, dynamic>> getRecordDetail(String recordId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/$recordId/details'),
      method: 'GET',
    );

    print('📋 기록 상세 응답 코드: ${res.statusCode}');
    print('📋 기록 상세 응답: ${res.body}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      return responseData['data']; // ApiResponse의 data 필드 반환
    } else {
      throw Exception('기록 상세 조회 실패: ${res.statusCode}');
    }
  }

  /// 직관 기록 삭제
  static Future<void> deleteRecord(String recordId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/$recordId'),
      method: 'DELETE',
    );

    print('🗑️ 기록 삭제 응답 코드: ${res.statusCode}');

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('기록 삭제 실패: ${res.statusCode}');
    }
  }


  //=====================================================================================
  // 마이페이지
  //=====================================================================================

  /// 내 피드 조회 (전체)
  static Future<List<Map<String, dynamic>>> getMyRecordsFeed() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/me/feed'),
      method: 'GET',
    );

    print('📷 FEED 응답 코드: ${res.statusCode}');
    print('📷 FEED 응답: ${res.body}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      final List<dynamic> records = responseData['data'];
      return records.cast<Map<String, dynamic>>();
    } else {
      throw Exception('내 기록 조회 실패: ${res.statusCode}');
    }
  }

  /// 내 리스트 조회
  static Future<List<Map<String, dynamic>>> getMyRecordsList() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/me/list'),
      method: 'GET',
    );

    print('📋 LIST 응답: ${res.statusCode} - ${res.body}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      final List<dynamic> records = responseData['data'];
      return records.cast<Map<String, dynamic>>();
    } else {
      throw Exception('리스트 조회 실패: ${res.statusCode}');
    }
  }

  /// 내 캘린더 조회
  static Future<List<Map<String, dynamic>>> getMyRecordsCalendar() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/me/calendar'),
      method: 'GET',
    );

    print('📅 CALENDAR 응답: ${res.statusCode} - ${res.body}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      final List<dynamic> calendarData = responseData['data'];
      return calendarData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('캘린더 조회 실패: ${res.statusCode}');
    }
  }


  /// 기존 getRecordById 메서드는 getRecordDetail로 통일했으므로 제거하거나 별칭으로 유지
  @Deprecated('Use getRecordDetail instead')
  static Future<Map<String, dynamic>> getRecordById(String recordId) async {
    return getRecordDetail(recordId);
  }
}