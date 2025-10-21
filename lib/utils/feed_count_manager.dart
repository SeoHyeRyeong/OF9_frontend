import 'package:flutter/material.dart';

/// 전역 피드 카운트 관리 싱글톤
/// Feed, Search, Detail 화면 간 좋아요 상태 및 카운트 동기화
class FeedCountManager extends ChangeNotifier {
  static final FeedCountManager _instance = FeedCountManager._internal();
  factory FeedCountManager() => _instance;
  FeedCountManager._internal();

  // recordId를 키로 하는 상태 저장소
  final Map<int, bool> _likedStatus = {};
  final Map<int, int> _likeCounts = {};
  final Map<int, int> _commentCounts = {};

  /// 좋아요 상태 가져오기
  bool? getLikedStatus(int recordId) => _likedStatus[recordId];

  /// 좋아요 개수 가져오기
  int? getLikeCount(int recordId) => _likeCounts[recordId];

  /// 댓글 개수 가져오기
  int? getCommentCount(int recordId) => _commentCounts[recordId];

  /// 좋아요 상태 업데이트 (API 응답 후 호출)
  void updateLikeState(int recordId, bool isLiked, int likeCount) {
    _likedStatus[recordId] = isLiked;
    _likeCounts[recordId] = likeCount;

    notifyListeners();
  }

  /// 댓글 개수만 업데이트 (CommentListManager에서 호출됨)
  void updateCommentCount(int recordId, int commentCount) {
    _commentCounts[recordId] = commentCount;
    notifyListeners();
  }

  /// 초기 상태 설정 (백엔드에서 불러온 데이터로 초기화)
  void setInitialState(int recordId, bool isLiked, int likeCount, {int commentCount = 0}) {
    _likedStatus[recordId] = isLiked;
    _likeCounts[recordId] = likeCount;
    _commentCounts[recordId] = commentCount;
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
          commentCount: item['commentCount'] ?? 0,
        );
      }
    }
    notifyListeners();
  }

  /// 상태 초기화
  void clear() {
    _likedStatus.clear();
    _likeCounts.clear();
    _commentCounts.clear();
    notifyListeners();
  }
}
