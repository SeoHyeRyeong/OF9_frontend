import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';

// 검색 결과 - 직관 기록 모델
class Record {
  final int recordId;
  final int authorId;
  final String authorNickname;
  final String? authorProfileImage;
  final String authorFavTeam;
  final String followStatus;
  final String gameDate;
  final String gameTime;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String stadium;
  final int emotionCode;
  final String emotionLabel;
  final String comment;
  final String longContent;
  final String result;
  final List<String> mediaUrls;
  final String createdAt;
  final int likeCount;
  final bool isLiked;
  final int commentCount;

  Record.fromJson(Map<String, dynamic> json)
      : recordId = json['recordId'],
        authorId = json['authorId'],
        authorNickname = json['authorNickname'],
        authorProfileImage = json['authorProfileImage'],
        authorFavTeam = json['authorFavTeam'],
        followStatus = json['followStatus'] ?? 'NOT_FOLLOWING',
        gameDate = json['gameDate'],
        gameTime = json['gameTime'],
        homeTeam = json['homeTeam'],
        awayTeam = json['awayTeam'],
        homeScore = json['homeScore'],
        awayScore = json['awayScore'],
        stadium = json['stadium'],
        emotionCode = json['emotionCode'],
        emotionLabel = json['emotionLabel'],
        comment = json['comment'],
        longContent = json['longContent'],
        result = json['result'],
        mediaUrls = List<String>.from(json['mediaUrls']),
        createdAt = json['createdAt'],
        likeCount = json['likeCount'] ?? 0,
        isLiked = json['isLiked'] ?? false,
        commentCount = json['commentCount'] ?? 0;
}

// 검색 결과 - 사용자 모델
class UserSearchResult {
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final String favTeam;
  final bool isPrivate;
  final String followStatus;
  final bool? isMutualFollow;

  UserSearchResult.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        nickname = json['nickname'],
        profileImageUrl = json['profileImageUrl'],
        favTeam = json['favTeam'],
        isPrivate = json['isPrivate'],
        followStatus = json['followStatus'],
        isMutualFollow = json['isMutualFollow'];
}

// 페이징 처리된 직관 기록 목록
class PaginatedRecords {
  final List<Record> records;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool hasNext;

  PaginatedRecords.fromJson(Map<String, dynamic> json)
      : records = (json['records'] as List).map((i) => Record.fromJson(i)).toList(),
        currentPage = json['currentPage'],
        totalPages = json['totalPages'],
        totalElements = json['totalElements'],
        hasNext = json['hasNext'];
}

// 페이징 처리된 사용자 목록
class PaginatedUsers {
  final List<UserSearchResult> users;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool hasNext;

  PaginatedUsers.fromJson(Map<String, dynamic> json)
      : users = (json['users'] as List).map((i) => UserSearchResult.fromJson(i)).toList(),
        currentPage = json['currentPage'],
        totalPages = json['totalPages'],
        totalElements = json['totalElements'],
        hasNext = json['hasNext'];
}

// 최종 검색 결과 (기록 + 사용자)
class SearchResult {
  final PaginatedRecords records;
  final PaginatedUsers users;

  SearchResult.fromJson(Map<String, dynamic> json)
      : records = PaginatedRecords.fromJson(json['records']),
        users = PaginatedUsers.fromJson(json['users']);
}

// 인기 검색어 모델
class PopularSearch {
  final String query;
  final int count;

  PopularSearch.fromJson(Map<String, dynamic> json)
      : query = json['query'],
        count = json['count'];
}

class SearchApi {
  static final _kakaoAuth = KakaoAuthService();

  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  /// 공통 Authorization 헤더 생성
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _kakaoAuth.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  /// API 응답 및 응답 파싱을 위한 공통 헬퍼
  static Future<T> _processResponse<T>(http.Response response, T Function(dynamic) fromJson) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (decodedBody['success'] == true) {
        return fromJson(decodedBody['data']);
      } else {
        throw Exception('API 응답 실패: ${decodedBody['message']}');
      }
    } else {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }
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
          response = await http.delete(uri, headers: headers, body: body);
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메서드: $method');
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        print('토큰 만료, 갱신 시도...');
        final refreshResult = await _kakaoAuth.refreshTokens();

        if (refreshResult != null) {
          final newHeaders = await _authHeaders();
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
              response = await http.delete(uri, headers: newHeaders, body: body);
              break;
          }
          print('토큰 갱신 후 재요청 성공');
        } else {
          print('토큰 갱신 실패, 재로그인 필요');
          throw Exception('토큰 갱신 실패. 재로그인하세요.');
        }
      }
      return response;
    } catch (e) {
      print('API 요청 오류: $e');
      rethrow;
    }
  }

  /// 1. 통합 검색 (게시글 + 사용자)
  static Future<SearchResult> search(
      String query, {
        int page = 0,
        int recordSize = 15,
        int userSize = 10,
      }) async {
    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
      'query': query,
      'recordPage': page.toString(),
      'userPage': '0',
      'recordSize': recordSize.toString(),
      'userSize': userSize.toString(),
    });
    final response = await _makeRequestWithRetry(uri: uri, method: 'GET');
    return _processResponse(response, (data) => SearchResult.fromJson(data));
  }

  /// 2. 최근 검색어 조회 (max 10개)
  static Future<List<String>> getRecentSearches() async {
    final uri = Uri.parse('$baseUrl/search/recent');
    final response = await _makeRequestWithRetry(uri: uri, method: 'GET');
    return _processResponse(response, (data) => List<String>.from(data));
  }

  /// 3. 최근 검색어 개별 삭제
  static Future<void> deleteRecentSearch(String query) async {
    final uri = Uri.parse('$baseUrl/search/recent').replace(queryParameters: {'query': query});
    final response = await _makeRequestWithRetry(uri: uri, method: 'DELETE');
    if (response.statusCode != 200) {
      throw Exception('최근 검색어 삭제 실패: ${response.statusCode}');
    }
  }

  /// 4. 최근 검색어 전체 삭제
  static Future<void> deleteAllRecentSearches() async {
    final uri = Uri.parse('$baseUrl/search/recent/all');
    final response = await _makeRequestWithRetry(uri: uri, method: 'DELETE');
    if (response.statusCode != 200) {
      throw Exception('모든 최근 검색어 삭제 실패: ${response.statusCode}');
    }
  }

  /// 5. 인기 검색어 조회
  static Future<List<PopularSearch>> getPopularSearches() async {
    final uri = Uri.parse('$baseUrl/search/popular');
    final response = await _makeRequestWithRetry(uri: uri, method: 'GET');
    return _processResponse(response, (data) {
      return (data as List).map((item) => PopularSearch.fromJson(item)).toList();
    });
  }
}