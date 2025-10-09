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

  static Future<http.Response> _makeRequestWithRetry({required Future<http.Response> Function(Map<String, String> headers) request}) async {
    try {
      var headers = await _authHeaders();
      var response = await request(headers);

      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshResult = await _kakaoAuth.refreshTokens();
        if (refreshResult != null) {
          headers = await _authHeaders();
          response = await request(headers);
        } else {
          throw Exception('Token refresh failed');
        }
      }
      return response;
    } catch (e) {
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
        _makeRequestWithRetry(
          request: (headers) => http.get(
            Uri.parse('$baseUrl/notifications?category=$category'),
            headers: headers,
          ),
        ),
        UserApi.getFollowRequests(),
        UserApi.getFollowers(myUserId),
      ]);

      final mainResponse = results[0] as http.Response;
      print('🔔 알림 조회 응답: ${mainResponse.statusCode}');
      print('🔔 알림 조회 본문: ${utf8.decode(mainResponse.bodyBytes)}');

      if (mainResponse.statusCode != 200) {
        throw Exception('Failed to load notifications: ${mainResponse.body}');
      }

      final mainData = jsonDecode(utf8.decode(mainResponse.bodyBytes));
      List<Map<String, dynamic>> notifications = (mainData['data'] as List).cast<Map<String, dynamic>>();
      print('📊 원본 알림 개수: ${notifications.length}');

      final followRequestsResponse = results[1] as Map<String, dynamic>;
      final followersResponse = results[2] as Map<String, dynamic>;

      print('📋 팔로우 요청 응답: $followRequestsResponse');
      print('📋 팔로워 응답: $followersResponse');

      final List<dynamic> pendingRequests = followRequestsResponse['data'] ?? [];
      final requestMap = { for (var req in pendingRequests) if (req['requesterNickname'] != null) req['requesterNickname']: req };

      final List<dynamic> followers = followersResponse['data'] ?? [];
      final followerMap = { for (var follower in followers) if(follower['nickname'] != null) follower['nickname']: follower };

      print('🗺️ 요청 맵: $requestMap');
      print('🗺️ 팔로워 맵: $followerMap');

      List<Map<String, dynamic>> validNotifications = [];

      for (var notification in notifications) {
        final nickname = notification['userNickname'];
        if (nickname == null) {
          validNotifications.add(notification);
          print('✅ userNickname null 알림 추가: ${notification['id']}');
          continue;
        }

        if (notification['type'] == 'FOLLOW_REQUEST') {
          print('🔍 FOLLOW_REQUEST 처리: $nickname');
          if (isMyAccountPrivate) {
            // 비공개 계정: 실제 팔로우 요청만 "수락/삭제" 버튼으로 표시
            print('  🔒 비공개 계정 - 실제 팔로우 요청 확인');
            final matchedRequest = requestMap[nickname];
            if (matchedRequest != null) {
              notification['userId'] = matchedRequest['requesterId'];
              notification['requestId'] = matchedRequest['requestId'];
              notification['isPrivateAccount'] = true;
              validNotifications.add(notification);
              print('  ✅ 실제 팔로우 요청 존재 → 수락/삭제 버튼 표시: $nickname');
            } else {
              print('  ❌ 팔로우 요청 없음 → 알림 제외 (이미 처리됨): $nickname');
            }
          } else {
            // 공개 계정: 자동 수락되었다고 가정하고 FOLLOW로 변환
            print('  🔓 공개 계정 - 자동 수락 처리 (FOLLOW_REQUEST → FOLLOW 변환)');
            notification['type'] = 'FOLLOW';

            // 팔로워 목록에서 매칭 시도
            final matchedFollower = followerMap[nickname];
            if (matchedFollower != null) {
              notification['userId'] = matchedFollower['id'];
              notification['isPrivateAccount'] = false;
              validNotifications.add(notification);
              print('  ✅ 자동 수락 후 매칭 성공 → 맞팔로우 버튼 표시: $nickname');
            } else {
              // 팔로워 목록에 없어도 requestMap에 있다면 표시
              final matchedRequest = requestMap[nickname];
              if (matchedRequest != null) {
                notification['userId'] = matchedRequest['requesterId'];
                notification['isPrivateAccount'] = false;
                validNotifications.add(notification);
                print('  ✅ 요청 맵에서 매칭 → 맞팔로우 버튼 표시 (동기화 지연): $nickname');
              } else {
                print('  ❌ 변환 후 매칭 실패 → 알림 제외: $nickname');
              }
            }
          }
        } else if (notification['type'] == 'FOLLOW') {
          print('🔍 FOLLOW 처리: $nickname');
          final matchedFollower = followerMap[nickname];
          if (matchedFollower != null) {
            notification['userId'] = matchedFollower['id'];
            notification['isPrivateAccount'] = false;
            validNotifications.add(notification);
            print('  ✅ FOLLOW 매칭 성공: $nickname');
          } else {
            print('  ❌ FOLLOW 매칭 실패: $nickname');
          }
        } else {
          validNotifications.add(notification);
          print('✅ 기타 알림 추가: ${notification['type']} - ${notification['id']}');
        }
      }

      print('📊 최종 알림 개수: ${validNotifications.length}');
      print('🎯 계정 상태별 처리 요약:');
      print('  - 비공개 계정: FOLLOW_REQUEST → 수락/삭제 버튼 (실제 요청만)');
      print('  - 공개 계정: FOLLOW_REQUEST → FOLLOW 변환 → 맞팔로우 버튼 (자동 수락됨)');

      return validNotifications;
    } catch (e) {
      print('❌ Error in getNotificationsByCategory: $e');
      rethrow;
    }
  }

  static Future<FollowRequestResult> acceptFollowRequest(int requestId, int userId) async {
    try {
      print('✅ 팔로우 요청 수락 시작: requestId=$requestId, userId=$userId');
      final result = await UserApi.acceptFollowRequest(requestId);
      print('✅ 팔로우 요청 수락 결과: $result');

      return FollowRequestResult(
        success: true,
        message: result['message'] ?? '팔로우 요청을 수락했습니다',
        myFollowStatus: FollowButtonStatus.canFollow,
      );
    } catch (e) {
      print('❌ 팔로우 요청 수락 실패: $e');
      return FollowRequestResult(success: false, message: '팔로우 요청 수락 실패', myFollowStatus: FollowButtonStatus.canFollow);
    }
  }

  static Future<Map<String, dynamic>> rejectFollowRequest(int requestId, int userId) {
    print('❌ 팔로우 요청 거절: requestId=$requestId, userId=$userId');
    return UserApi.rejectFollowRequest(requestId);
  }

  static Future<FollowActionResult> followUser(int userId) async {
    try {
      print('👥 팔로우 시작: userId=$userId');
      final result = await UserApi.followUser(userId);
      print('👥 팔로우 결과: $result');

      final data = result['data'];
      final pending = data?['pending'] ?? false;

      return FollowActionResult(
        success: true,
        message: result['message'] ?? '',
        buttonState: pending ? FollowButtonStatus.requestSent : FollowButtonStatus.following,
      );
    } catch (e) {
      print('❌ 팔로우 실패: $e');
      rethrow;
    }
  }

  static Future<FollowActionResult> unfollowUser(int userId) async {
    try {
      print('👋 언팔로우 시작: userId=$userId');
      final result = await UserApi.unfollowUser(userId);
      print('👋 언팔로우 결과: $result');

      return FollowActionResult(
        success: true,
        message: result['message'] ?? '언팔로우했습니다',
        buttonState: FollowButtonStatus.canFollow,
      );
    } catch (e) {
      print('❌ 언팔로우 실패: $e');
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
