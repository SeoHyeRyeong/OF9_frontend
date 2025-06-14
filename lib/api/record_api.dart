import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';


class RecordApi {
  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 공통 Authorization 헤더 생성 (JSON용)
  static Future<Map<String, String>> _authHeaders() async {
    final token = await KakaoAuthService().getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
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
    final headers = await _authHeaders();

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
      if (base64Images.isNotEmpty) 'mediaFiles': base64Images,
    };

    print('📤 기록 업로드 요청 본문: ${jsonEncode(requestBody).length} bytes');
    print('📤 Base64 이미지 개수: ${base64Images.length}');

    final res = await http.post(
      Uri.parse('$baseUrl/records'),
      headers: headers,
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

  /// 내 기록 목록 조회 (마이페이지용)
  static Future<List<Map<String, dynamic>>> getMyRecords() async {
    final headers = await _authHeaders();
    final res = await http.get(
      //Uri.parse('$baseUrl/records/me/feed'),
      Uri.parse('$baseUrl/records/me/list'),
      headers: headers,
    );

    print('📥 내 기록 조회 응답 코드: ${res.statusCode}');
    print('📥 기록 조회 응답 본문: ${res.body}');

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
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/records/$recordId'),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('기록 상세 조회 실패: ${res.statusCode}');
    }
  }

  /// 기록 삭제
  static Future<void> deleteRecord(String recordId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/records/$recordId'),
      headers: headers,
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('기록 삭제 실패: ${res.statusCode}');
    }
  }

  /// 다른 엔드포인트들 테스트
  static Future<void> testAllEndpoints() async {
    final headers = await _authHeaders();

    // 1. list 엔드포인트 테스트
    try {
      final listRes = await http.get(
        Uri.parse('$baseUrl/records/me/list'),
        headers: headers,
      );
      print('📋 LIST 응답: ${listRes.statusCode} - ${listRes.body}');
    } catch (e) {
      print('❌ LIST 오류: $e');
    }

    // 2. calendar 엔드포인트 테스트
    try {
      final calRes = await http.get(
        Uri.parse('$baseUrl/records/me/calendar'),
        headers: headers,
      );
      print('📅 CALENDAR 응답: ${calRes.statusCode} - ${calRes.body}');
    } catch (e) {
      print('❌ CALENDAR 오류: $e');
    }
  }

}


