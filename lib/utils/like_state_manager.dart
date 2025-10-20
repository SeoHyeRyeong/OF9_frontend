import 'package:flutter/material.dart';

/// 전역 좋아요 상태 관리 싱글톤
/// Feed, Search, Detail 화면 간 좋아요 상태 동기화
class LikeStateManager extends ChangeNotifier {
  static final LikeStateManager _instance = LikeStateManager._internal();
  factory LikeStateManager() => _instance;
  LikeStateManager._internal();

  // recordId를 키로 하는 좋아요 상태 저장소
  final Map<int, bool> _likedStatus = {};
  final Map<int, int> _likeCounts = {};

  /// 좋아요 상태 가져오기
  bool? getLikedStatus(int recordId) => _likedStatus[recordId];

  /// 좋아요 개수 가져오기
  int? getLikeCount(int recordId) => _likeCounts[recordId];

  /// 좋아요 상태 업데이트 (API 응답 후 호출)
  void updateLikeState(int recordId, bool isLiked, int likeCount) {
    _likedStatus[recordId] = isLiked;
    _likeCounts[recordId] = likeCount;

    print('🔄 [LikeStateManager] 전역 상태 업데이트: recordId=$recordId, isLiked=$isLiked, count=$likeCount');

    // 모든 리스너에게 변경 알림
    notifyListeners();
  }

  /// 초기 상태 설정 (백엔드에서 불러온 데이터로 초기화)
  void setInitialState(int recordId, bool isLiked, int likeCount) {
    // 항상 최신값으로 업데이트
    _likedStatus[recordId] = isLiked;
    _likeCounts[recordId] = likeCount;
  }

  /// 배치 초기화 (여러 게시글 한번에)
  void setInitialStates(List<Map<String, dynamic>> items) {
    for (var item in items) {
      final recordId = item['recordId'] as int?;
      if (recordId != null) {
        setInitialState(
          recordId,
          item['isLiked'] ?? false,
          item['likeCount'] ?? 0,
        );
      }
    }
    // 배치 업데이트 후 리스너에게 알림
    notifyListeners();
    print('📢 [LikeStateManager] 배치 업데이트 완료 (${items.length}개)');
  }

  /// 상태 초기화
  void clear() {
    _likedStatus.clear();
    _likeCounts.clear();
    notifyListeners();
  }
}