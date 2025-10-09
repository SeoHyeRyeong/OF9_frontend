import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/api/user_api.dart';

class NotificationApi {
  static final _kakaoAuth = KakaoAuthService();

  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('백엔드 URL이 설정되지 않았습니다');
    return backendUrl;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _kakaoAuth.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<http.Response> _makeRequestWithRetry({
    required Uri uri,
    required String method,
    String? body,
  }) async {
    // ... (수정 없음)
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
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메서드: $method');
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        print('🔄 토큰 만료, 갱신 시도...');
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

  static Future<List<Map<String, dynamic>>> getNotificationsByCategory(String category) async {
    try {
      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];

      final results = await Future.wait([
        _makeRequestWithRetry(
          uri: Uri.parse('$baseUrl/notifications?category=$category'),
          method: 'GET',
        ),
        UserApi.getFollowRequests(),
        UserApi.getFollowers(myUserId),
      ]);

      final mainResponse = results[0] as http.Response;
      final followRequestsResponse = results[1] as Map<String, dynamic>;
      final followersResponse = results[2] as Map<String, dynamic>;

      if (mainResponse.statusCode != 200) {
        throw Exception('$category 알림 조회 실패: ${mainResponse.statusCode}');
      }

      final mainData = jsonDecode(utf8.decode(mainResponse.bodyBytes));
      print('🔔 실제 API 응답 데이터: $mainData');
      List<Map<String, dynamic>> notifications = (mainData['data'] as List).cast<Map<String, dynamic>>();

      final List<dynamic> pendingRequests = followRequestsResponse['data'] ?? [];
      final requestMap = {
        for (var req in pendingRequests)
          if (req['requesterNickname'] != null)
            req['requesterNickname']: req
      };

      final List<dynamic> followers = followersResponse['data'] ?? [];
      final followerMap = {
        for (var follower in followers)
          if(follower['nickname'] != null)
            follower['nickname']: follower
      };

      for (var notification in notifications) {
        final nickname = notification['userNickname'];
        if (nickname == null) continue;

        if (notification['type'] == 'FOLLOW_REQUEST') {
          if (requestMap.containsKey(nickname)) {
            final matchedRequest = requestMap[nickname]!;
            notification['userId'] = matchedRequest['requesterId'];
            notification['requestId'] = matchedRequest['requestId'];
            print('🔄 [요청] "${nickname}"님에 상세 정보(userId, requestId)를 병합했습니다.');
          }
        }
        else if (notification['type'] == 'FOLLOW') {
          if (followerMap.containsKey(nickname)) {
            final matchedFollower = followerMap[nickname]!;
            notification['userId'] = matchedFollower['id'];
            print('🔄 [팔로우] "${nickname}"님에 상세 정보(userId)를 병합했습니다.');
          }
        }
      }
      return notifications;

    } catch (e) {
      print('❌ 알림 조회 및 데이터 조합 실패: $e');
      rethrow;
    }
  }

  static Future<FollowRequestResult> acceptFollowRequest(int requestId, int userId) async {
    try {
      print('✅ 팔로우 요청 수락 시작: $requestId');
      final result = await UserApi.acceptFollowRequest(requestId);

      final data = result['data'];
      final targetIsPrivate = data?['targetAccountPrivate'] ?? false;
      final amIAlreadyFollowing = data?['amIAlreadyFollowing'] ?? false;

      FollowButtonStatus myFollowStatus = amIAlreadyFollowing
          ? FollowButtonStatus.following
          : FollowButtonStatus.canFollow;

      return FollowRequestResult(
        success: true,
        message: result['message'] ?? '팔로우 요청을 수락했습니다',
        newFollowerUserId: userId,
        targetAccountPrivate: targetIsPrivate,
        myFollowStatus: myFollowStatus,
      );
    } catch (e) {
      print('❌ 팔로우 요청 수락 실패: $e');
      return FollowRequestResult(
        success: false,
        message: '팔로우 요청 수락 실패: $e',
        newFollowerUserId: null,
        targetAccountPrivate: false,
        myFollowStatus: FollowButtonStatus.canFollow,
      );
    }
  }

  static Future<Map<String, dynamic>> rejectFollowRequest(int requestId, int userId) async {
    try {
      print('❌ 팔로우 요청 거절 시작: $requestId');
      final result = await UserApi.rejectFollowRequest(requestId);
      print('❌ 팔로우 요청 거절 성공: $requestId');
      return result;
    } catch (e) {
      print('❌ 팔로우 요청 거절 실패: $e');
      rethrow;
    }
  }

  static Future<FollowActionResult> followUser(int userId) async {
    try {
      print('👥 지능형 팔로우 시작: $userId');
      final result = await UserApi.followUser(userId);
      print('👥 지능형 팔로우 응답: $result');

      final data = result['data'];
      final message = result['message'] ?? '';

      if (data != null) {
        final pending = data['pending'] ?? false;
        final followed = data['followed'] ?? false;
        final requestId = data['requestId'];

        if (pending && requestId != null) {
          return FollowActionResult(
            success: true,
            status: FollowActionStatus.requestSent,
            message: message,
            requestId: requestId,
            buttonState: FollowButtonStatus.requestSent,
          );
        } else if (followed && !pending) {
          return FollowActionResult(
            success: true,
            status: FollowActionStatus.following,
            message: message,
            requestId: null,
            buttonState: FollowButtonStatus.following,
          );
        }
      }

      return FollowActionResult(
        success: true,
        status: FollowActionStatus.following,
        message: message,
        requestId: null,
        buttonState: FollowButtonStatus.following,
      );
    } catch (e) {
      print('❌ 팔로우 실패: $e');
      return FollowActionResult(
        success: false,
        status: FollowActionStatus.error,
        message: '팔로우 실패: $e',
        requestId: null,
        buttonState: FollowButtonStatus.canFollow,
      );
    }
  }

  static Future<FollowActionResult> unfollowUser(int userId) async {
    try {
      print('👋 언팔로우 시작: $userId');
      final result = await UserApi.unfollowUser(userId);
      print('👋 언팔로우 성공: $userId');

      return FollowActionResult(
        success: true,
        status: FollowActionStatus.unfollowed,
        message: result['message'] ?? '언팔로우했습니다',
        requestId: null,
        buttonState: FollowButtonStatus.canFollow,
      );
    } catch (e) {
      print('❌ 언팔로우 실패: $e');
      return FollowActionResult(
        success: false,
        status: FollowActionStatus.error,
        message: '언팔로우 실패: $e',
        requestId: null,
        buttonState: FollowButtonStatus.following,
      );
    }
  }

  static Future<FollowActionResult> cancelFollowRequest(int userId, int requestId) async {
    try {
      print('🚫 팔로우 요청 취소 시작: $userId (requestId: $requestId)');
      final result = await UserApi.unfollowUser(userId);
      print('🚫 팔로우 요청 취소 성공: $userId');

      return FollowActionResult(
        success: true,
        status: FollowActionStatus.requestCancelled,
        message: result['message'] ?? '팔로우 요청을 취소했습니다',
        requestId: null,
        buttonState: FollowButtonStatus.canFollow,
      );
    } catch (e) {
      print('❌ 팔로우 요청 취소 실패: $e');
      return FollowActionResult(
        success: false,
        status: FollowActionStatus.error,
        message: '팔로우 요청 취소 실패: $e',
        requestId: requestId,
        buttonState: FollowButtonStatus.requestSent,
      );
    }
  }

  static Future<FollowButtonStatus> getFollowStatus(int userId) async {
    try {
      print('🔍 팔로우 상태 조회 시작: $userId');

      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];

      final followingResult = await UserApi.getFollowing(myUserId);
      final followingList = followingResult['data'] as List;

      final isFollowing = followingList.any((user) => user['id'] == userId);

      if (isFollowing) {
        return FollowButtonStatus.following;
      }

      try {
        final requestsResult = await UserApi.getFollowRequests();
        final requestsList = requestsResult['data'] as List;

        final hasPendingRequest = requestsList.any((req) =>
        req['fromUserId'] == myUserId && req['toUserId'] == userId
        );

        if (hasPendingRequest) {
          return FollowButtonStatus.requestSent;
        }
      } catch (e) {
        print('⚠️ 팔로우 요청 목록 조회 실패 (무시): $e');
      }

      return FollowButtonStatus.canFollow;

    } catch (e) {
      print('❌ 팔로우 상태 조회 실패: $e');
      return FollowButtonStatus.canFollow;
    }
  }

  static Future<Map<String, dynamic>> createSystemNotification({
    required String title,
    required String content,
  }) async {
    final requestBody = {
      'title': title,
      'content': content,
    };

    final res = await _makeRequestWithRetry(
      uri: Uri.parse('$baseUrl/notifications/system'),
      method: 'POST',
      body: jsonEncode(requestBody),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final responseData = jsonDecode(utf8.decode(res.bodyBytes));
      return responseData;
    } else {
      throw Exception('시스템 알림 생성 실패: ${res.statusCode}');
    }
  }

  static int? extractUserIdFromNotification(Map<String, dynamic> notification) {
    return notification['userId'] as int?;
  }

  static int? extractRequestIdFromNotification(Map<String, dynamic> notification) {
    return notification['requestId'] ?? notification['id'] as int?;
  }
}


enum FollowRelationStatus {
  notFollowing,
  following,
  requestSent,
}

enum FollowButtonStatus {
  canFollow,
  following,
  requestSent,
}

enum FollowActionStatus {
  following,
  requestSent,
  unfollowed,
  requestCancelled,
  error,
}

class FollowRequestResult {
  final bool success;
  final String message;
  final int? newFollowerUserId;
  final bool targetAccountPrivate;
  final FollowButtonStatus myFollowStatus;

  FollowRequestResult({
    required this.success,
    required this.message,
    this.newFollowerUserId,
    required this.targetAccountPrivate,
    required this.myFollowStatus,
  });
}

class FollowActionResult {
  final bool success;
  final FollowActionStatus status;
  final String message;
  final int? requestId;
  // ✅ [오류 수정] 'FollowButton-Status'를 'FollowButtonStatus'로 오타 수정
  final FollowButtonStatus buttonState;

  FollowActionResult({
    required this.success,
    required this.status,
    required this.message,
    this.requestId,
    required this.buttonState,
  });
}