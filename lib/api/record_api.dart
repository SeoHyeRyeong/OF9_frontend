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
    List<String>? companions,
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
      'userId': userId,
      'gameId': gameId,
      'seatInfo': seatInfo,
      'emotionCode': emotionCode,
      'stadium': stadium,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (longContent != null && longContent.isNotEmpty) 'longContent': longContent,
      if (bestPlayer != null && bestPlayer.isNotEmpty) 'bestPlayer': bestPlayer,
      //if (companions != null && companions.isNotEmpty) 'companions': companions, // 수정필요!!!
      if (foodTags != null && foodTags.isNotEmpty) 'foodTags': foodTags,
      //if (base64Images.isNotEmpty) 'mediaFiles': base64Images,
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
      return jsonDecode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('기록 업로드 실패: ${res.statusCode}');
    }
  }

  /// 내 피드 조회
  static Future<List<Map<String, dynamic>>> getMyRecordsFeed() async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/me/feed'),
      method: 'GET',
    );

    print('📷 FEED 응답 코드: ${res.statusCode}');
    print('📷 FEED 응답: ${res.body}');

    if (res.statusCode == 200) {
      // UTF-8 디코딩 추가
      final List<dynamic> records = jsonDecode(utf8.decode(res.bodyBytes));
      return records.cast<Map<String, dynamic>>();
    } else {
      throw Exception('내 기록 조회 실패: ${res.statusCode}');
    }
  }


  /// 특정 기록 상세 조회
  static Future<Map<String, dynamic>> getRecordById(String recordId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/$recordId'),
      method: 'GET',
    );

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('기록 상세 조회 실패: ${res.statusCode}');
    }
  }

  /// 기록 삭제
  static Future<void> deleteRecord(String recordId) async {
    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/records/$recordId'),
      method: 'DELETE',
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('기록 삭제 실패: ${res.statusCode}');
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
      final List<dynamic> records = jsonDecode(utf8.decode(res.bodyBytes)); // UTF-8 처리
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
      final List<dynamic> calendarData = jsonDecode(utf8.decode(res.bodyBytes));
      return calendarData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('캘린더 조회 실패: ${res.statusCode}');
    }
  }
}