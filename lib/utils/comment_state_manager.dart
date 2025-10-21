import 'package:flutter/material.dart';
import 'package:frontend/utils/feed_count_manager.dart';

/// 댓글 정보 DTO
class CommentDto {
  final int id;
  final int recordId;
  final int userId;
  final String nickname;
  final String profileImageUrl;
  final String favTeam;
  final String content;
  final String createdAt;
  final String updatedAt;
  final bool isAuthor;
  final bool isEdited;
  final int? parentCommentId;
  final int replyCount;
  final List<CommentDto>? replies;
  final int? totalCommentCount;

  CommentDto({
    required this.id,
    required this.recordId,
    required this.userId,
    required this.nickname,
    required this.profileImageUrl,
    required this.favTeam,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isAuthor,
    this.isEdited = false,
    this.parentCommentId,
    this.replyCount = 0,
    this.replies,
    this.totalCommentCount,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: json['id'] is int ? json['id'] : (json['id'] as num).toInt(),
      recordId: json['recordId'] is int ? json['recordId'] : (json['recordId'] as num).toInt(),
      userId: json['userId'] is int ? json['userId'] : (json['userId'] as num).toInt(),
      nickname: json['nickname'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      favTeam: json['favTeam'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      isAuthor: json['isAuthor'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      parentCommentId: json['parentCommentId'] as int?,
      replyCount: json['replyCount'] is int
          ? json['replyCount']
          : (json['replyCount'] as num?)?.toInt() ?? 0,
      replies: json['replies'] != null
          ? (json['replies'] as List<dynamic>)
          .map((e) => CommentDto.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      totalCommentCount: json['totalCommentCount'] is int
          ? json['totalCommentCount']
          : (json['totalCommentCount'] as num?)?.toInt(),
    );
  }
}

/// 전역 댓글 목록 상태 관리 싱글톤
class CommentListManager extends ChangeNotifier {
  static final CommentListManager _instance = CommentListManager._internal();
  factory CommentListManager() => _instance;
  CommentListManager._internal();

  final Map<int, List<CommentDto>> _comments = {};

  List<CommentDto>? getComments(int recordId) => _comments[recordId];

  /// 초기 상태 설정
  void setInitialState(int recordId, List<CommentDto> comments) {
    _comments[recordId] = comments;

    // totalCommentCount가 있으면 FeedCountManager 업데이트
    if (comments.isNotEmpty && comments.first.totalCommentCount != null) {
      FeedCountManager().updateCommentCount(recordId, comments.first.totalCommentCount!);
    }

    notifyListeners();
  }

  /// 댓글 추가
  void addComment(int recordId, CommentDto newComment) {
    final currentComments = _comments[recordId] ?? [];
    currentComments.add(newComment);
    _comments[recordId] = currentComments;

    // totalCommentCount가 있으면 FeedCountManager 업데이트
    if (newComment.totalCommentCount != null) {
      FeedCountManager().updateCommentCount(recordId, newComment.totalCommentCount!);
    }

    notifyListeners();
  }

  /// 댓글 삭제
  void removeComment(int recordId, int commentId) {
    final currentComments = _comments[recordId] ?? [];
    final updatedComments = currentComments.where((c) => c.id != commentId).toList();
    _comments[recordId] = updatedComments;

    // 삭제 후 FeedCountManager도 자동 업데이트
    FeedCountManager().updateCommentCount(recordId, updatedComments.length);

    notifyListeners();
  }

  /// 상태 초기화 (필요 시)
  void clear() {
    _comments.clear();
    notifyListeners();
  }
}