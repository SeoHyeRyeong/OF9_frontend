import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/api/notification_api.dart';
import 'package:frontend/main.dart'; // Global Navigator Key
import 'package:flutter/material.dart';
import 'package:frontend/features/mypage/friend_profile_screen.dart';
import 'package:frontend/features/feed/detail_feed_screen.dart';
import 'package:frontend/features/notification/notification_screen.dart';

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

  Future<void> initialize() async {
    try {
      print('🔥 FCM 초기화 시작');

      // 권한 요청
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM 권한 허용됨');

        // FCM 토큰 가져오기
        String? token = await _messaging.getToken();
        if (token != null) {
          print('📱 FCM 토큰: $token');

          Future.delayed(const Duration(seconds: 2), () {
            _saveFCMTokenToBackend(token);
          });
        }
      } else {
        print('❌ FCM 권한 거부됨');
      }

      // 백그라운드 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 토큰 갱신 시 백엔드 업데이트
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 토큰 갱신: $newToken');
        _saveFCMTokenToBackend(newToken);
      });

      // Foreground 메시지
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
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleNotificationTap(initialMessage.data);
        });
      }

      print('✅ FCM 초기화 완료');
    } catch (e) {
      print('🔥 FCM 초기화 오류: $e');
    }
  }

  // 🔎 디버그/릴리즈 공통 토큰 로그용
  Future<void> logFcmToken() async {
    try {
      final token = await _messaging.getToken();
      developer.log('FCM TOKEN (manual log): $token', name: 'FCM');
    } catch (e) {
      developer.log('FCM TOKEN ERROR: $e', name: 'FCM');
    }
  }

  Future<void> _saveFCMTokenToBackend(String token) async {
    try {
      print('📤 FCM 토큰 백엔드 저장 시도');
      await NotificationApi.saveFcmToken(token);
      print('✅ FCM 토큰 백엔드 저장 완료');
    } catch (e) {
      print('❌ FCM 토큰 저장 실패 (무시): $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('❌ Navigator context를 찾을 수 없습니다');
      return;
    }

    final type = data['type'];
    print('🎯 알림 타입: $type, 데이터: $data');

    // 1) FOLLOW / FOLLOW_REQUEST → FriendProfileScreen (targetId 또는 userId)
    if (type == 'FOLLOW' || type == 'FOLLOW_REQUEST') {
      final userId = _parseId(data['targetId']) ?? _parseId(data['userId']);  // ✅ targetId 우선
      if (userId != null) {
        print('👤 프로필 화면으로 이동: userId=$userId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendProfileScreen(userId: userId),
          ),
        );
        return;
      }
    }

    // 2) COMMENT / LIKE / NEW_RECORD → DetailFeedScreen (targetId)
    if (type == 'COMMENT' || type == 'LIKE' || type == 'NEW_RECORD') {
      final recordId = _parseId(data['targetId']);  // ✅ targetId
      if (recordId != null) {
        print('📝 게시글 상세 화면으로 이동: recordId=$recordId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailFeedScreen(recordId: recordId),
          ),
        );
        return;
      }
    }

    // 3) SYSTEM / NEWS → NotificationScreen
    if (type == 'SYSTEM' || type == 'NEWS') {
      print('📢 시스템/소식 알림 - 알림 화면으로 이동');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
      return;
    }

    // 4) 그 외: targetId 또는 userId 있으면 프로필
    final userId = _parseId(data['targetId']) ?? _parseId(data['userId']);
    if (userId != null) {
      print('👤 userId 기반 프로필 화면으로 이동: userId=$userId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendProfileScreen(userId: userId),
        ),
      );
    } else {
      print('⚠️ 알 수 없는 알림 타입 또는 데이터 부족 - 알림 화면으로 이동');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
    }
  }



  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
