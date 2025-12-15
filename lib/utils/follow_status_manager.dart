import 'package:flutter/foundation.dart';

/// 팔로우 상태를 전역으로 관리하는 싱글톤 클래스
class FollowStatusManager extends ChangeNotifier {
  static final FollowStatusManager _instance = FollowStatusManager._internal();
  factory FollowStatusManager() => _instance;
  FollowStatusManager._internal();

  // userId -> followStatus 매핑
  final Map<int, String> _followStatusMap = {};

  /// 특정 사용자의 팔로우 상태 가져오기
  String? getFollowStatus(int userId) {
    return _followStatusMap[userId];
  }

  /// 특정 사용자의 팔로우 상태 업데이트
  void updateFollowStatus(int userId, String followStatus) {
    _followStatusMap[userId] = followStatus;
    notifyListeners();
  }

  /// 초기 상태 설정 (이미 있으면 무시)
  void setInitialStatus(int userId, String followStatus) {
    if (!_followStatusMap.containsKey(userId)) {
      _followStatusMap[userId] = followStatus;
    }
  }

  /// 특정 사용자 상태 삭제 (언팔로우 등)
  void removeStatus(int userId) {
    _followStatusMap.remove(userId);
    notifyListeners();
  }

  /// 모든 상태 초기화
  void clearAll() {
    _followStatusMap.clear();
    notifyListeners();
  }
}