import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';

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

  /// 공통 Authorization 헤더 생성 (multipart/form-data용)
  static Future<Map<String, String>> _authHeadersMultipart() async {
    final token = await KakaoAuthService().getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      // Content-Type은 multipart 요청 시 자동으로 설정됨
    };
  }

  /// 모든 기록을 한 번에 업로드 (메인 메서드)
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
    final headers = await _authHeadersMultipart();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/records'),
    );

    // 헤더 추가
    request.headers.addAll(headers);

    // 필수 필드 추가
    request.fields['userId'] = userId.toString();
    request.fields['gameId'] = gameId;
    request.fields['seatInfo'] = seatInfo;
    request.fields['emotionCode'] = emotionCode.toString();
    request.fields['stadium'] = stadium;

    // 선택적 필드 추가
    if (comment != null && comment.isNotEmpty) {
      request.fields['comment'] = comment;
    }
    if (longContent != null && longContent.isNotEmpty) {
      request.fields['longContent'] = longContent;
    }
    if (bestPlayer != null && bestPlayer.isNotEmpty) {
      request.fields['bestPlayer'] = bestPlayer;
    }
    if (companions != null && companions.isNotEmpty) {
      request.fields['companions'] = jsonEncode(companions);
    }
    if (foodTags != null && foodTags.isNotEmpty) {
      request.fields['foodTags'] = jsonEncode(foodTags);
    }

    // 이미지 파일 추가
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (int i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'mediaFiles', // 서버에서 기대하는 필드명
              file.path,
            ),
          );
        }
      }
    }

    print('📤 기록 업로드 요청 필드: ${request.fields}');
    print('📤 기록 업로드 파일 개수: ${request.files.length}');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 기록 업로드 응답 코드: ${response.statusCode}');
    print('📥 기록 업로드 응답 본문: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('기록 업로드 실패: ${response.statusCode}');
    }
  }

  /// 내 기록 목록 조회 (마이페이지용)
  static Future<List<Map<String, dynamic>>> getMyRecords() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/records/my'),
      headers: headers,
    );

    print('📥 내 기록 조회 응답 코드: ${res.statusCode}');
    print('📥 내 기록 조회 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      final List<dynamic> records = data['records'] ?? [];
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
      return jsonDecode(res.body);
    } else {
      throw Exception('기록 상세 조회 실패: ${res.statusCode}');
    }
  }

  /// 기록 수정 (필요한 경우)
  static Future<Map<String, dynamic>> updateRecord({
    required String recordId,
    String? comment,
    String? longContent,
    String? bestPlayer,
    List<String>? companions,
    List<String>? foodTags,
    List<String>? imagePaths,
  }) async {
    final headers = await _authHeadersMultipart();

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/records/$recordId'),
    );

    request.headers.addAll(headers);

    // 수정할 필드만 추가
    if (comment != null) request.fields['comment'] = comment;
    if (longContent != null) request.fields['longContent'] = longContent;
    if (bestPlayer != null) request.fields['bestPlayer'] = bestPlayer;
    if (companions != null) request.fields['companions'] = jsonEncode(companions);
    if (foodTags != null) request.fields['foodTags'] = jsonEncode(foodTags);

    // 새 이미지 파일 추가
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (String imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('mediaFiles', file.path),
          );
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('기록 수정 실패: ${response.statusCode}');
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
}
