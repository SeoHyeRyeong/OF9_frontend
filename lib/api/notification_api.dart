import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/api/user_api.dart';

class NotificationApi {
  static final _kakaoAuth = KakaoAuthService();

  // 임시 더미데이터 사용 플래그 (개발 중에만 true로 설정)
  static const bool _useDummyData = false; // ⭐ 여기만 false로 바꾸면 실제 API 사용

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

  //=====================================================================================
  // 더미 데이터
  //=====================================================================================

  /// 더미 사용자 계정 상태 (비공개 여부)
  static final Map<int, bool> _dummyUserPrivacyStatus = {
    101: false, // 민지 - 공개 계정
    102: true,  // 준호 - 비공개 계정
    103: false, // 서연 - 공개 계정
    104: true,  // 태민 - 비공개 계정
    105: false, // 유진 - 공개 계정
    106: true,  // 현우 - 비공개 계정
    107: false, // 지은 - 공개 계정
    108: true,  // 도현 - 비공개 계정
    109: false, // 수빈 - 공개 계정
    110: true,  // 성민 - 비공개 계정
    111: false, // 하늘 - 공개 계정
    112: true,  // 은서 - 비공개 계정
  };

  /// 현재 사용자의 계정 상태 (개발용 - 실제로는 로그인한 사용자 정보에서 가져와야 함)
  static bool _isMyAccountPrivate = true; // ⭐ 내 계정이 비공개인지 여부

  /// 더미 팔로우 관계 상태
  static final Map<int, FollowRelationStatus> _dummyFollowStatus = {
    101: FollowRelationStatus.notFollowing, // 민지와는 팔로우 관계 없음
    102: FollowRelationStatus.requestSent, // 준호에게 팔로우 요청 보낸 상태
    103: FollowRelationStatus.following,   // 서연을 팔로우 중
    104: FollowRelationStatus.notFollowing, // 태민과는 팔로우 관계 없음
    105: FollowRelationStatus.following,   // 유진을 팔로우 중
    106: FollowRelationStatus.requestSent, // 현우에게 팔로우 요청 보낸 상태
  };

  /// 더미 알림 데이터 (팔로우 시스템 로직 반영)
  static final List<Map<String, dynamic>> _dummyNotifications = [
    // 팔로우 요청들 (내 계정이 비공개일 때만 나타남)
    if (_isMyAccountPrivate) ...[
      {
        'id': 1,
        'type': 'FOLLOW_REQUEST',
        'content': '민지님의 팔로우 요청',
        'timeAgo': '방금 전',
        'createdAt': '2025-10-06 02:50:00',
        'userNickname': '민지',
        'userProfileImage': 'https://picsum.photos/200/200?random=1',
        'userId': 101,
        'requestId': 1,
        'actionButton': 'ACCEPT_REJECT',
        'category': 'NEWS',
        'badge': 'NEW',
        // 민지는 공개 계정이므로, 내가 수락하면 즉시 팔로우 관계 성립
        'targetAccountPrivate': false,
      },
      {
        'id': 2,
        'type': 'FOLLOW_REQUEST',
        'content': '준호님의 팔로우 요청',
        'timeAgo': '5분 전',
        'createdAt': '2025-10-06 02:45:00',
        'userNickname': '준호',
        'userProfileImage': 'https://picsum.photos/200/200?random=2',
        'userId': 102,
        'requestId': 2,
        'actionButton': 'ACCEPT_REJECT',
        'category': 'NEWS',
        'badge': 'NEW',
        // 준호는 비공개 계정이므로, 내가 수락 후 준호를 팔로우하려면 다시 요청 필요
        'targetAccountPrivate': true,
      },
    ],

    // 팔로우 알림들 (내 계정이 공개일 때의 즉시 팔로우)
    if (!_isMyAccountPrivate) ...[
      {
        'id': 3,
        'type': 'FOLLOW',
        'content': '서연님이 나를 팔로우 했어요',
        'timeAgo': '10분 전',
        'createdAt': '2025-10-06 02:40:00',
        'userNickname': '서연',
        'userProfileImage': 'https://picsum.photos/200/200?random=3',
        'userId': 103,
        'actionButton': 'FOLLOW_BUTTON',
        'category': 'NEWS',
        'badge': 'NEW',
        // 서연은 공개 계정, 내가 서연을 팔로우하고 있는지에 따라 버튼 상태 결정
        'targetAccountPrivate': false,
        'amIFollowing': true, // 내가 서연을 이미 팔로우 중이므로 '팔로잉' 표시
      },
      {
        'id': 4,
        'type': 'FOLLOW',
        'content': '태민님이 나를 팔로우 했어요',
        'timeAgo': '30분 전',
        'createdAt': '2025-10-06 02:20:00',
        'userNickname': '태민',
        'userProfileImage': 'https://picsum.photos/200/200?random=4',
        'userId': 104,
        'actionButton': 'FOLLOW_BUTTON',
        'category': 'NEWS',
        // 태민은 비공개 계정, 내가 태민을 팔로우하지 않았으므로 '팔로우' 표시 -> 클릭 시 '요청됨'으로 변경
        'targetAccountPrivate': true,
        'amIFollowing': false,
      },
    ],

    // 반응 공감 알림들 (기존과 동일)
    {
      'id': 5,
      'type': 'REACTION',
      'content': '유진님이 나의 직관기록에 짜릿해요 반응을 남겼어요',
      'timeAgo': '1시간 전',
      'createdAt': '2025-10-06 01:50:00',
      'userNickname': '유진',
      'userProfileImage': 'https://picsum.photos/200/200?random=5',
      'userId': 105,
      'relatedRecordId': 54,
      'emotionName': '짜릿해요',
      'emotionCode': 1,
      'category': 'REACTION',
      'badge': 'NEW',
    },

    // 친구 직관기록 알림들 (기존과 동일)
    {
      'id': 9,
      'type': 'NEW_RECORD',
      'content': '수빈님이 직관 기록을 업로드했어요',
      'timeAgo': '5시간 전',
      'createdAt': '2025-10-05 21:50:00',
      'userNickname': '수빈',
      'userProfileImage': 'https://picsum.photos/200/200?random=9',
      'userId': 109,
      'relatedRecordId': 60,
      'category': 'FRIEND_RECORD',
    },

    // 시스템 알림들 (기존과 동일)
    {
      'id': 13,
      'type': 'SYSTEM',
      'content': '새로운 업데이트 v2.1.0이 출시되었습니다',
      'timeAgo': '1일 전',
      'createdAt': '2025-10-05 02:50:00',
      'userNickname': 'LookIT',
      'userProfileImage': null,
      'category': 'NEWS',
    },
  ];

  /// 카테고리별 더미 데이터 필터링
  static List<Map<String, dynamic>> _getDummyNotificationsByCategory(String category) {
    switch (category.toUpperCase()) {
      case 'ALL':
        return List.from(_dummyNotifications);
      case 'FRIEND_RECORD':
        return _dummyNotifications.where((n) => n['category'] == 'FRIEND_RECORD').toList();
      case 'REACTION':
        return _dummyNotifications.where((n) => n['category'] == 'REACTION').toList();
      case 'NEWS':
        return _dummyNotifications.where((n) => n['category'] == 'NEWS').toList();
      default:
        return [];
    }
  }

  //=====================================================================================
  // 알림 조회 (기존 API 활용 예정)
  //=====================================================================================

  /// 카테고리별 알림 조회
  static Future<List<Map<String, dynamic>>> getNotificationsByCategory(String category) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미데이터 사용: $category (내 계정 비공개: $_isMyAccountPrivate)');
      await Future.delayed(Duration(milliseconds: 800)); // 네트워크 지연 시뮬레이션
      return _getDummyNotificationsByCategory(category);
    }

    // 실제 API 호출 - 알림 관련 API는 이미 있다고 했으니 그대로 사용
    try {
      final res = await _makeRequestWithRetry(
        uri: Uri.parse('$baseUrl/notifications?category=$category'),
        method: 'GET',
      );

      print('🔔 $category 알림 응답: ${res.statusCode} - ${res.body}');

      if (res.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> notifications = responseData['data'];
        return notifications.cast<Map<String, dynamic>>();
      } else {
        throw Exception('$category 알림 조회 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ 알림 조회 실패: $e');
      rethrow;
    }
  }

  //=====================================================================================
  // 팔로우 시스템 로직 (기존 UserApi 활용)
  //=====================================================================================

  /// 팔로우 요청 수락 (기존 UserApi 활용)
  static Future<FollowRequestResult> acceptFollowRequest(int requestId, int userId) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미 팔로우 수락: 요청ID=$requestId, 사용자ID=$userId');
      await Future.delayed(Duration(milliseconds: 1000));

      print('✅ $userId 사용자가 내 팔로워가 되었습니다');
      final targetIsPrivate = _dummyUserPrivacyStatus[userId] ?? false;

      return FollowRequestResult(
        success: true,
        message: '팔로우 요청을 수락했습니다',
        newFollowerUserId: userId,
        targetAccountPrivate: targetIsPrivate,
        myFollowStatus: FollowButtonStatus.canFollow,
      );
    }

    // 실제 API 호출 - 기존 UserApi 사용
    try {
      print('✅ 팔로우 요청 수락 시작: $requestId');
      final result = await UserApi.acceptFollowRequest(requestId);

      // 백엔드 응답에서 추가 정보 추출 (필요시)
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

  /// 팔로우 요청 거절/삭제 (기존 UserApi 활용)
  static Future<Map<String, dynamic>> rejectFollowRequest(int requestId, int userId) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미 팔로우 거절: 요청ID=$requestId, 사용자ID=$userId');
      await Future.delayed(Duration(milliseconds: 1000));

      print('❌ $userId 사용자의 팔로우 요청을 거절했습니다');

      return {
        'success': true,
        'message': '팔로우 요청을 거절했습니다',
        'rejectedUserId': userId,
        'canRequestAgain': true,
      };
    }

    // 실제 API 호출 - 기존 UserApi 사용
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

  /// 지능형 팔로우 액션 (기존 UserApi 활용)
  static Future<FollowActionResult> followUser(int userId) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미 지능형 팔로우: $userId');
      await Future.delayed(Duration(milliseconds: 1200));

      final targetIsPrivate = _dummyUserPrivacyStatus[userId] ?? false;

      if (targetIsPrivate) {
        print('🔒 $userId는 비공개 계정입니다. 팔로우 요청을 보냈습니다.');
        _dummyFollowStatus[userId] = FollowRelationStatus.requestSent;

        return FollowActionResult(
          success: true,
          status: FollowActionStatus.requestSent,
          message: '팔로우 요청을 보냈습니다',
          requestId: userId + 1000,
          buttonState: FollowButtonStatus.requestSent,
        );
      } else {
        print('🔓 $userId는 공개 계정입니다. 즉시 팔로우했습니다.');
        _dummyFollowStatus[userId] = FollowRelationStatus.following;

        return FollowActionResult(
          success: true,
          status: FollowActionStatus.following,
          message: '팔로우했습니다',
          requestId: null,
          buttonState: FollowButtonStatus.following,
        );
      }
    }

    // 실제 API 호출 - 기존 UserApi 사용
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
          // 비공개 계정에 팔로우 요청 전송
          return FollowActionResult(
            success: true,
            status: FollowActionStatus.requestSent,
            message: message,
            requestId: requestId,
            buttonState: FollowButtonStatus.requestSent,
          );
        } else if (followed && !pending) {
          // 공개 계정에 즉시 팔로우
          return FollowActionResult(
            success: true,
            status: FollowActionStatus.following,
            message: message,
            requestId: null,
            buttonState: FollowButtonStatus.following,
          );
        }
      }

      // 기본값 (공개 계정 팔로우로 처리)
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

  /// 언팔로우 (기존 UserApi 활용)
  static Future<FollowActionResult> unfollowUser(int userId) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미 언팔로우: $userId');
      await Future.delayed(Duration(milliseconds: 800));

      _dummyFollowStatus[userId] = FollowRelationStatus.notFollowing;

      return FollowActionResult(
        success: true,
        status: FollowActionStatus.unfollowed,
        message: '언팔로우했습니다',
        requestId: null,
        buttonState: FollowButtonStatus.canFollow,
      );
    }

    // 실제 API 호출 - 기존 UserApi 사용
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

  /// ✅ 팔로우 요청 취소 (기존 UserApi의 DELETE /users/{targetId}/follow 활용)
  /// 이 API는 관계 상태에 따라 언팔로우 또는 팔로우 요청 취소 역할을 합니다
  static Future<FollowActionResult> cancelFollowRequest(int userId, int requestId) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미 팔로우 요청 취소: $userId');
      await Future.delayed(Duration(milliseconds: 800));

      _dummyFollowStatus[userId] = FollowRelationStatus.notFollowing;

      return FollowActionResult(
        success: true,
        status: FollowActionStatus.requestCancelled,
        message: '팔로우 요청을 취소했습니다',
        requestId: null,
        buttonState: FollowButtonStatus.canFollow,
      );
    }

    // ✅ 실제 API 호출 - 기존 UserApi의 unfollowUser 사용
    // DELETE /users/{userId}/follow는 팔로우 상태에 따라 언팔로우 또는 요청 취소 처리
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

  /// ✅ 현재 팔로우 상태 조회 (기존 UserApi 조합 활용)
  static Future<FollowButtonStatus> getFollowStatus(int userId) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미 팔로우 상태 조회: $userId');
      await Future.delayed(Duration(milliseconds: 300));

      final relationStatus = _dummyFollowStatus[userId] ?? FollowRelationStatus.notFollowing;

      switch (relationStatus) {
        case FollowRelationStatus.following:
          return FollowButtonStatus.following;
        case FollowRelationStatus.requestSent:
          return FollowButtonStatus.requestSent;
        case FollowRelationStatus.notFollowing:
          return FollowButtonStatus.canFollow;
      }
    }

    // ✅ 실제 API 호출 - 기존 UserApi 조합 사용
    try {
      print('🔍 팔로우 상태 조회 시작: $userId');

      // 1. 내 정보 가져오기
      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];

      // 2. 내가 팔로잉하는 목록에서 해당 사용자 확인
      final followingResult = await UserApi.getFollowing(myUserId);
      final followingList = followingResult['data'] as List;

      final isFollowing = followingList.any((user) => user['id'] == userId);

      if (isFollowing) {
        return FollowButtonStatus.following;
      }

      // 3. 팔로우 요청 목록에서 해당 사용자 확인 (선택적)
      try {
        final requestsResult = await UserApi.getFollowRequests();
        final requestsList = requestsResult['data'] as List;

        // 내가 보낸 요청인지 확인하는 로직 (API 응답 구조에 따라 조정 필요)
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

  //=====================================================================================
  // 시스템 알림 생성 (기존과 동일)
  //=====================================================================================

  /// 시스템 알림 생성
  static Future<Map<String, dynamic>> createSystemNotification({
    required String title,
    required String content,
  }) async {
    // 더미데이터 사용
    if (_useDummyData) {
      print('🎭 더미 시스템 알림 생성: $title');
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'success': true,
        'message': '시스템 알림이 생성되었습니다',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }

    // 실제 API 호출
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

  //=====================================================================================
  // 편의 메서드들 (기존과 동일)
  //=====================================================================================

  /// 알림에서 사용자 ID 추출
  static int? extractUserIdFromNotification(Map<String, dynamic> notification) {
    return notification['userId'] as int?;
  }

  /// 알림에서 요청 ID 추출
  static int? extractRequestIdFromNotification(Map<String, dynamic> notification) {
    return notification['requestId'] ?? notification['id'] as int?;
  }

  //=====================================================================================
  // 개발용 설정 메서드들 (기존과 동일)
  //=====================================================================================

  /// 개발용: 내 계정의 비공개 상태 변경
  static void setMyAccountPrivacy(bool isPrivate) {
    _isMyAccountPrivate = isPrivate;
    print('🔧 개발용 설정: 내 계정 비공개 = $isPrivate');
  }

  /// 개발용: 현재 내 계정 비공개 상태 확인
  static bool get isMyAccountPrivate => _isMyAccountPrivate;

  /// 개발용: 특정 사용자의 계정 비공개 상태 확인
  static bool isUserAccountPrivate(int userId) {
    return _dummyUserPrivacyStatus[userId] ?? false;
  }
}

//=====================================================================================
// 열거형 및 결과 클래스들 (기존과 동일)
//=====================================================================================

/// 팔로우 관계 상태
enum FollowRelationStatus {
  notFollowing,  // 팔로우하지 않음
  following,     // 팔로우 중
  requestSent,   // 팔로우 요청 보낸 상태
}

/// 팔로우 버튼 상태 (UI에서 표시할 버튼 상태)
enum FollowButtonStatus {
  canFollow,    // '팔로우' 버튼 표시
  following,    // '팔로잉' 버튼 표시 (언팔로우 가능)
  requestSent,  // '요청됨' 버튼 표시 (요청 취소 가능)
}

/// 팔로우 액션 상태
enum FollowActionStatus {
  following,        // 팔로우 완료
  requestSent,      // 팔로우 요청 전송
  unfollowed,       // 언팔로우 완료
  requestCancelled, // 팔로우 요청 취소
  error,            // 오류 발생
}

/// 팔로우 요청 수락 결과
class FollowRequestResult {
  final bool success;
  final String message;
  final int? newFollowerUserId;      // 새로 내 팔로워가 된 사용자 ID
  final bool targetAccountPrivate;   // 상대방 계정이 비공개인지 여부
  final FollowButtonStatus myFollowStatus; // 내가 상대방에게 표시할 팔로우 버튼 상태

  FollowRequestResult({
    required this.success,
    required this.message,
    this.newFollowerUserId,
    required this.targetAccountPrivate,
    required this.myFollowStatus,
  });
}

/// 팔로우 액션 결과 클래스
class FollowActionResult {
  final bool success;
  final FollowActionStatus status;
  final String message;
  final int? requestId;                 // 팔로우 요청 ID (비공개 계정용)
  final FollowButtonStatus buttonState; // UI에서 표시할 버튼 상태

  FollowActionResult({
    required this.success,
    required this.status,
    required this.message,
    this.requestId,
    required this.buttonState,
  });
}
