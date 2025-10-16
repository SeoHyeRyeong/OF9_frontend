import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/api/user_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';

class NotificationApi {
  static final _kakaoAuth = KakaoAuthService();

  static String get baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) throw Exception('BACKEND_URL is not set');
    return backendUrl;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _kakaoAuth.getAccessToken();
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  /// ✨ 수정: user_api.dart를 참고하여 토큰 갱신 및 재시도 로직 활성화
  static Future<http.Response> _makeRequestWithRetry(
      {required Future<http.Response> Function(Map<String, String> headers) request}) async {
    try {
      var headers = await _authHeaders();
      var response = await request(headers);

      // 401/403 에러 시 토큰 갱신 후 재시도
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('🔄 [NotificationApi] 토큰 만료, 갱신 시도...');
        // user_api.dart와 마찬가지로 kakaoAuthService에 refreshTokens()가 있다고 가정합니다.
        final refreshResult = await _kakaoAuth.refreshTokens();

        if (refreshResult != null) {
          print('🎉 [NotificationApi] 토큰 갱신 성공, 재요청 시작');
          headers = await _authHeaders(); // 새 토큰으로 헤더 갱신
          response = await request(headers); // 원래 요청 재시도
        } else {
          print('❌ [NotificationApi] 토큰 갱신 실패, 재로그인 필요');
          throw Exception('토큰 갱신에 실패했습니다. 다시 로그인해주세요.');
        }
      }
      return response;
    } catch (e) {
      print('🔥 [NotificationApi] API 요청 오류: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getNotificationsByCategory(String category) async {
    try {
      print('🚀 알림 조회 시작: category=$category');

      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];
      final isMyAccountPrivate = myProfile['data']['isPrivate'] ?? false;

      print('👤 내 계정 정보: userId=$myUserId, isPrivate=$isMyAccountPrivate');

      final results = await Future.wait([
        _makeRequestWithRetry( // ✨ 수정된 함수 호출
          request: (headers) => http.get(
            Uri.parse('$baseUrl/notifications?category=$category'),
            headers: headers,
          ),
        ),
        UserApi.getFollowRequests(),
        UserApi.getFollowers(myUserId),
      ]);

      final mainResponse = results[0] as http.Response;
      if (mainResponse.statusCode != 200) {
        throw Exception('Failed to load notifications: ${mainResponse.body}');
      }

      final mainData = jsonDecode(utf8.decode(mainResponse.bodyBytes));
      List<Map<String, dynamic>> notifications = (mainData['data'] as List).cast<Map<String, dynamic>>();
      print('📊 원본 알림 개수: ${notifications.length}');

      notifications.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

      final followRequestsResponse = results[1] as Map<String, dynamic>;
      final followersResponse = results[2] as Map<String, dynamic>;

      final List<dynamic> pendingRequests = followRequestsResponse['data'] ?? [];
      final requestMap = { for (var req in pendingRequests) if (req['requesterNickname'] != null) req['requesterNickname']: req };

      final List<dynamic> followers = followersResponse['data'] ?? [];
      final followerMap = { for (var follower in followers) if(follower['nickname'] != null) follower['nickname']: follower };

      Map<String, Map<String, dynamic>> finalNotificationsMap = {};
      const Set<String> followRelatedTypes = {'FOLLOW_REQUEST', 'FOLLOW'};

      for (var notification in notifications) {
        final nickname = notification['userNickname'];
        final type = notification['type'];

        String key;
        if (nickname != null && followRelatedTypes.contains(type)) {
          key = '$nickname-follow_action';
        } else {
          key = 'unique-${notification['id']}';
        }

        Map<String, dynamic>? processedNotification;

        if (type == 'FOLLOW_REQUEST') {
          if (isMyAccountPrivate) {
            final matchedRequest = requestMap[nickname];
            if (matchedRequest != null) {
              // 아직 처리되지 않은 유효한 팔로우 요청
              notification['userId'] = matchedRequest['requesterId'];
              notification['requestId'] = matchedRequest['requestId'];
              processedNotification = notification;
            } else {
              // 이 '요청' 알림을 '최신 팔로우' 알림으로 변환하여 처리
              final matchedFollower = followerMap[nickname];
              if (matchedFollower != null) {
                print('🔄 처리된 팔로우 요청(ID: ${notification['id']})을 최신 팔로우 알림으로 변환합니다.');
                notification['type'] = 'FOLLOW';
                notification['userId'] = matchedFollower['id'];
                processedNotification = notification;
              }
              // 요청도 없고 팔로워도 아니면 (거절/삭제됨) -> 아무것도 안 함 (processedNotification = null)
            }
          } else { // 공개 계정일 때
            notification['type'] = 'FOLLOW';
            final matchedUser = followerMap[nickname] ?? requestMap[nickname];
            if (matchedUser != null) {
              notification['userId'] = matchedUser['id'] ?? matchedUser['requesterId'];
              processedNotification = notification;
            }
          }
        } else if (type == 'FOLLOW') {
          processedNotification = notification;
          if (notification['userId'] == null) {
            final matchedUser = followerMap[nickname] ?? requestMap[nickname];
            if (matchedUser != null) {
              notification['userId'] = matchedUser['id'] ?? matchedUser['requesterId'];
            }
          }
        } else {
          processedNotification = notification;
        }

        if (processedNotification != null) {
          finalNotificationsMap[key] = processedNotification;
        }
      }

      var validNotifications = finalNotificationsMap.values.toList();

      validNotifications.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

      print('📊 최종 필터링된 알림 개수: ${validNotifications.length}');
      return validNotifications;

    } catch (e) {
      print('❌ Error in getNotificationsByCategory: $e');
      rethrow;
    }
  }

  static Future<FollowRequestResult> acceptFollowRequest(int requestId, int userId) async {
    try {
      final result = await UserApi.acceptFollowRequest(requestId);
      return FollowRequestResult(
        success: true,
        message: result['message'] ?? '팔로우 요청을 수락했습니다',
        myFollowStatus: FollowButtonStatus.canFollow,
      );
    } catch (e) {
      return FollowRequestResult(success: false, message: '팔로우 요청 수락 실패', myFollowStatus: FollowButtonStatus.canFollow);
    }
  }

  static Future<Map<String, dynamic>> rejectFollowRequest(int requestId, int userId) {
    return UserApi.rejectFollowRequest(requestId);
  }

  static Future<FollowActionResult> followUser(int userId) async {
    try {
      final result = await UserApi.followUser(userId);
      final data = result['data'];
      final pending = data?['pending'] ?? false;

      return FollowActionResult(
        success: true,
        message: result['message'] ?? '',
        buttonState: pending ? FollowButtonStatus.requestSent : FollowButtonStatus.following,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<FollowActionResult> unfollowUser(int userId) async {
    try {
      final result = await UserApi.unfollowUser(userId);
      return FollowActionResult(
        success: true,
        message: result['message'] ?? '언팔로우했습니다',
        buttonState: FollowButtonStatus.canFollow,
      );
    } catch (e) {
      rethrow;
    }
  }
}

enum FollowButtonStatus { canFollow, following, requestSent }

class FollowRequestResult {
  final bool success;
  final String message;
  final FollowButtonStatus myFollowStatus;
  FollowRequestResult({required this.success, required this.message, required this.myFollowStatus});
}

class FollowActionResult {
  final bool success;
  final String message;
  final FollowButtonStatus buttonState;
  FollowActionResult({required this.success, required this.message, required this.buttonState});
}