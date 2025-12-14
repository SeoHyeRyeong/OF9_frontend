import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/api/notification_api.dart';
import 'package:frontend/main.dart'; // Global Navigator Key
import 'package:flutter/material.dart';
import 'package:frontend/features/mypage/friend_profile_screen.dart';
import 'package:frontend/features/feed/detail_feed_screen.dart';

// 백그라운드 메시지 핸들러 (top-level 함수 필수)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 백그라운드 메시지: ${message.notification?.title}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // FCM 초기화
  Future<void> initialize() async {
    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // iOS 권한 요청
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM 토큰 가져오기 및 백엔드 저장
    String? token = await _messaging.getToken();
    if (token != null) {
      print('📱 FCM 토큰: $token');
      await _saveFCMTokenToBackend(token);
    }

    // 토큰 갱신 시 백엔드 업데이트
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔄 토큰 갱신: $newToken');
      _saveFCMTokenToBackend(newToken);
    });

    // Foreground 메시지 (앱 사용 중)
    FirebaseMessaging.onMessage.listen((message) {
      print('📩 Foreground 알림 수신');
      print('   제목: ${message.notification?.title}');
      print('   내용: ${message.notification?.body}');
      print('   데이터: ${message.data}');
    });

    // 알림 탭 (백그라운드에서)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('🔔 백그라운드 알림 탭: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // 앱 종료 상태에서 알림으로 실행
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 알림으로 앱 실행: ${initialMessage.data}');
      // 약간의 딜레이 후 화면 이동 (앱 초기화 완료 대기)
      Future.delayed(const Duration(milliseconds: 1000), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  // FCM 토큰을 백엔드에 저장
  // FCM 토큰을 백엔드에 저장
  Future<void> _saveFCMTokenToBackend(String token) async {
    try {
      print('📤 FCM 토큰 백엔드 저장 시도');
      await NotificationApi.saveFcmToken(token);
      print('✅ FCM 토큰 백엔드 저장 완료');
    } catch (e) {
      print('❌ FCM 토큰 저장 실패 (무시): $e');
      // ✅ 에러 발생해도 앱 실행 계속되도록 catch만 하고 끝
    }
  }


  // 알림 탭 처리 - NotificationScreen 로직과 동일하게 구현
  void _handleNotificationTap(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('❌ Navigator context를 찾을 수 없습니다');
      return;
    }

    final type = data['type'];
    print('🎯 알림 타입: $type, 데이터: $data');

    // FOLLOW, FOLLOW_REQUEST → FriendProfileScreen
    if (type == 'FOLLOW' || type == 'FOLLOW_REQUEST') {
      final userId = _parseId(data['userId']);
      if (userId != null) {
        print('👤 프로필 화면으로 이동: userId=$userId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendProfileScreen(userId: userId),
          ),
        );
      }
    }
    // LIKE, COMMENT, NEW_RECORD → DetailFeedScreen
    else if (type == 'LIKE' || type == 'COMMENT' || type == 'NEW_RECORD') {
      final recordId = _parseId(data['recordId']);
      if (recordId != null) {
        print('📝 게시글 상세 화면으로 이동: recordId=$recordId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailFeedScreen(recordId: recordId),
          ),
        );
      }
    }
    // SYSTEM, NEWS는 특별한 처리 없음
    else if (type == 'SYSTEM' || type == 'NEWS') {
      print('📢 시스템/소식 알림 - 별도 화면 이동 없음');
    }
    // 알 수 없는 타입
    else {
      print('⚠️ 알 수 없는 알림 타입: $type');
    }
  }

  // String이나 int를 int로 파싱
  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // FCM 토큰 가져오기 (외부에서 필요할 때)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
