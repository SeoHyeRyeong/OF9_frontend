import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/features/mypage/friend_profile_screen.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/record_api.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:frontend/utils/feed_count_manager.dart';
import 'package:frontend/utils/comment_state_manager.dart';
import 'package:frontend/utils/follow_status_manager.dart';
import 'package:frontend/utils/team_utils.dart';
import 'package:frontend/utils/time_utils.dart';
import 'dart:math' as math;
import 'package:frontend/components/custom_action_sheet.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/features/upload/ticket_info_screen.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';
import 'package:frontend/features/feed/feed_screen.dart';
import 'package:frontend/components/custom_toast.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/upload/providers/record_state.dart';

class DetailFeedScreen extends StatefulWidget {
  final String? imagePath;
  final int recordId;
  final bool showUploadToast;
  final String? uploaderNickname;
  final bool isFirstRecord;
  final bool fromUpload;

  const DetailFeedScreen({
    Key? key,
    this.imagePath,
    required this.recordId,
    this.showUploadToast = false,
    this.uploaderNickname,
    this.isFirstRecord = false,
    this.fromUpload = false,
  }) : super(key: key);

  @override
  State<DetailFeedScreen> createState() => _DetailFeedScreenState();
}

class _DetailFeedScreenState extends State<DetailFeedScreen> {
  final TextEditingController _commentController = TextEditingController();
  final _feedCountManager = FeedCountManager();
  final _commentListManager = CommentListManager();
  final _followManager = FollowStatusManager();
  final FocusNode _commentFocusNode = FocusNode();

  Map<String, dynamic>? _recordDetail;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  List<CommentDto> _comments = [];

  int? _currentUserId;
  bool _isGameCardExpanded = false;

  // 팔로우 상태 관리
  String _followStatus = 'NOT_FOLLOWING';
  bool _isFollowLoading = false;

  // 댓글 수정 관련 상태
  int? _editingCommentId;

  // 댓글별 GlobalKey 저장
  final Map<int, GlobalKey> _commentKeys = {};

  bool get _isMyPost {
    if (_recordDetail == null || _currentUserId == null) return false;
    final authorId = _recordDetail!['userId'];
    return authorId == _currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _feedCountManager.addListener(_onGlobalCountChanged);
    _commentListManager.addListener(_onGlobalCommentListChanged);
    _followManager.addListener(_onFollowStatusChanged);
    _loadCurrentUserId();
    _loadRecordDetail();
    _loadComments();

    if (widget.showUploadToast && widget.uploaderNickname != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUploadToast(widget.uploaderNickname!);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _feedCountManager.removeListener(_onGlobalCountChanged);
    _commentListManager.removeListener(_onGlobalCommentListChanged);
    _followManager.removeListener(_onFollowStatusChanged);
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final userProfile = await UserApi.getMyProfile();
      final userId = userProfile['data']['id'];
      setState(() {
        _currentUserId = userId;
      });
      print('✅ 현재 사용자 ID: $userId');
    } catch (e) {
      print('❌ 사용자 ID 조회 실패: $e');
    }
  }

  void _onGlobalCountChanged() {
    final newIsLiked = _feedCountManager.getLikedStatus(widget.recordId);
    final newLikeCount = _feedCountManager.getLikeCount(widget.recordId);
    final newCommentCount = _feedCountManager.getCommentCount(widget.recordId);

    if (newIsLiked != null && newLikeCount != null && newCommentCount != null) {
      if (_isLiked != newIsLiked || _likeCount != newLikeCount ||
          _commentCount != newCommentCount) {
        setState(() {
          _isLiked = newIsLiked;
          _likeCount = newLikeCount;
          _commentCount = newCommentCount;
        });
      }
    }
  }

  void _onGlobalCommentListChanged() {
    final comments = _commentListManager.getComments(widget.recordId);

    if (comments != null) {
      setState(() {
        _comments = List.from(comments);
      });
    }
  }

  void _onFollowStatusChanged() {
    final userId = _recordDetail?['userId'];
    if (userId != null) {
      final newFollowStatus = _followManager.getFollowStatus(userId);
      if (newFollowStatus != null && newFollowStatus != _followStatus) {
        setState(() {
          _followStatus = newFollowStatus;
          if (_recordDetail != null) {
            _recordDetail!['followStatus'] = newFollowStatus;
          }
        });
      }
    }
  }

  Future<void> _loadRecordDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await RecordApi.getRecordDetail(widget.recordId.toString());

      // 백엔드 응답 우선 사용
      final backendIsLiked = data['isLiked'] ?? false;
      final backendLikeCount = data['likeCount'] ?? 0;
      final backendCommentCount = data['commentCount'] ?? 0;
      final backendFollowStatus = data['followStatus'] ?? 'NOT_FOLLOWING';

      setState(() {
        _recordDetail = data;
        _isLiked = backendIsLiked;
        _likeCount = backendLikeCount;
        _commentCount = backendCommentCount;
        _followStatus = backendFollowStatus;
        _isLoading = false;
      });

      // 전역 상태에 백엔드 데이터로 초기화/업데이트
      _feedCountManager.setInitialState(
        widget.recordId,
        backendIsLiked,
        backendLikeCount,
        commentCount: backendCommentCount,
      );

      // 팔로우 상태 전역 관리자에 백엔드 데이터로 초기화/업데이트
      final userId = data['userId'];
      if (userId != null) {
        _followManager.setInitialStatus(userId, backendFollowStatus);
      }

      print('✅ 직관 기록 조회 성공: ${data['nickname']}');
    } catch (e) {
      print('❌ 직관 기록 조회 실패: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '직관 기록을 불러올 수 없습니다.';
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final data = await FeedApi.getComments(widget.recordId.toString());
      final comments = data.map((e) => CommentDto.fromJson(e)).toList();

      _commentListManager.setInitialState(widget.recordId, comments);

      setState(() {
        _comments = comments;
      });

      print('✅ 댓글 목록 조회 성공: ${comments.length}개');
    } catch (e) {
      print('❌ 댓글 목록 조회 실패: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      final result = await FeedApi.toggleLike(widget.recordId.toString());

      final isLiked = result['isLiked'] as bool;
      final likeCountRaw = result['likeCount'];
      final likeCount = likeCountRaw is int
          ? likeCountRaw
          : (likeCountRaw as num).toInt();

      _feedCountManager.updateLikeState(widget.recordId, isLiked, likeCount);

      setState(() {
        _isLiked = isLiked;
        _likeCount = likeCount;
      });

      print('✅ 좋아요 토글 성공: isLiked=$isLiked, likeCount=$likeCount');
    } catch (e) {
      print('❌ 좋아요 토글 실패: $e');
    }
  }

  Future<void> _handleSendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final originalContent = content;
    _commentController.clear();
    _commentFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration(milliseconds: 100));

    try {
      if (_editingCommentId != null) {
        await FeedApi.updateComment(
          widget.recordId.toString(),
          _editingCommentId.toString(),
          originalContent,
        );
        print('✅ 댓글 수정 성공');

        setState(() {
          _editingCommentId = null;
        });

        await _loadComments();
      } else {
        // 댓글 작성 모드
        final result = await FeedApi.createComment(
            widget.recordId.toString(), originalContent);
        final newComment = CommentDto.fromJson(result);

        print('✅ 댓글 작성 API 응답 받음: ${newComment.content}');
        print('📊 응답에 포함된 totalCommentCount: ${newComment.totalCommentCount}');

        // 서버에서 최신 댓글 목록 다시 불러오기 (이게 가장 확실함)
        await _loadComments();

        // 댓글 카운트 업데이트
        if (newComment.totalCommentCount != null) {
          setState(() {
            _commentCount = newComment.totalCommentCount!;
          });
          _feedCountManager.updateCommentCount(
              widget.recordId, newComment.totalCommentCount!);
          print('✅ 댓글 카운트 업데이트: ${newComment.totalCommentCount}');
        }

        print('✅ 댓글 작성 완료 - 총 ${_comments.length}개');
      }
    } catch (e, stackTrace) {
      print('❌ 댓글 ${_editingCommentId != null ? "수정" : "작성"} 실패: $e');
      print('스택트레이스: $stackTrace');
      _commentController.text = originalContent;
    }
  }

  Future<void> _deleteComment(int commentId) async {
    // 포커스 해제
    _commentFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    // 편집 모드 초기화
    setState(() {
      _editingCommentId = null;
      _commentController.clear();
    });

    try {
      final response = await FeedApi.deleteComment(
        widget.recordId.toString(),
        commentId.toString(),
      );

      if (response != null && response['totalCommentCount'] != null) {
        final totalCount = response['totalCommentCount'] is int
            ? response['totalCommentCount']
            : (response['totalCommentCount'] as num).toInt();
        _commentListManager.removeComment(
          widget.recordId,
          commentId,
          totalCommentCount: totalCount,
        );
        print('✅ 댓글 삭제 완료 - totalCommentCount: $totalCount');
      } else {
        _commentListManager.removeComment(widget.recordId, commentId);
        print('✅ 댓글 삭제 완료, totalCommentCount 정보 없음');
      }
    } catch (e) {
      print('❌ 댓글 삭제 실패: $e');
    }
  }

  Future<void> _deleteRecord() async {
    try {
      await RecordApi.deleteRecord(widget.recordId.toString());
      print('✅ 게시글 삭제 성공');

      if (mounted) {
        // 업로드 직후 삭제한 경우: FeedScreen으로 이동
        if (widget.fromUpload) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1,
                  animation2) => const FeedScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else {
          // 일반 조회 후 삭제: 이전 화면으로 + 삭제 result 전달
          Navigator.pop(context, {
            'deleted': true,
            'recordId': widget.recordId,
          });
        }
      }
    } catch (e) {
      print('❌ 게시글 삭제 실패: $e');
    }
  }

  void _showMoreOptions() {
    // 본인 게시글일 때만 수정/삭제
    if (_isMyPost) {
      showCustomActionSheet(
        context: context,
        options: [
          ActionSheetOption(
            text: '게시글 수정',
            textColor: Colors.black,
            onTap: () async {
              Navigator.pop(context);

              // RecordState에 현재 게시글 데이터 로드
              final recordState = Provider.of<RecordState>(
                  context, listen: false);

              // 백업 저장 (취소 시 복원용)
              recordState.saveBackup();

              // 기존 게시글 데이터를 RecordState에 설정
              final mediaUrls = _recordDetail?['mediaUrls'] as List<dynamic>?;

              // 티켓 이미지는 ticketImageUrl 필드에서 가져옴 (없으면 null)
              final ticketImageUrl = _recordDetail?['ticketImageUrl'] as String?;

              // 게임 정보 직접 추출 (gameInfo가 아닌 최상위 필드)
              final homeTeam = _recordDetail?['homeTeam'] as String?;
              final awayTeam = _recordDetail?['awayTeam'] as String?;
              final gameDate = _recordDetail?['gameDate'] as String?;
              final gameTime = _recordDetail?['gameTime'] as String?;
              final gameId = _recordDetail?['gameId']?.toString();

              print('📋 추출된 데이터:');
              print('  ticketImageUrl: $ticketImageUrl');
              print('  mediaUrls: $mediaUrls');
              print('  homeTeam: $homeTeam');
              print('  awayTeam: $awayTeam');
              print('  gameDate: $gameDate');
              print('  gameTime: $gameTime');
              print('  gameId: $gameId');

              // gameDate 파싱: "2025년 04월 24일 (목)요일" -> "2025-04-24"
              String? parsedDate;
              if (gameDate != null) {
                final dateMatch = RegExp(r'(\d{4})년\s*(\d{2})월\s*(\d{2})일')
                    .firstMatch(gameDate);
                if (dateMatch != null) {
                  parsedDate =
                  '${dateMatch.group(1)}-${dateMatch.group(2)}-${dateMatch
                      .group(3)}';
                }
              }

              // gameTime 파싱: "18:30" -> "18:30:00"
              String? parsedTime;
              if (gameTime != null) {
                parsedTime = gameTime.contains(':') ? gameTime : null;
                if (parsedTime != null && !parsedTime.contains(':00')) {
                  parsedTime = '$parsedTime:00';
                }
              }

              print('📋 파싱된 데이터:');
              print('  parsedDate: $parsedDate');
              print('  parsedTime: $parsedTime');

              // 티켓 이미지 경로 설정 (없으면 빈 문자열)
              final ticketPath = ticketImageUrl ?? '';

              recordState.setTicketInfo(
                ticketImagePath: ticketPath,
                selectedHome: homeTeam,
                selectedAway: awayTeam,
                selectedDateTime: parsedDate != null && parsedTime != null
                    ? '$parsedDate $parsedTime'
                    : null,
                selectedStadium: _recordDetail?['stadium'] as String?,
                selectedSeat: _recordDetail?['seatInfo'] as String?,
                extractedHomeTeam: homeTeam,
                extractedAwayTeam: awayTeam,
                extractedDate: parsedDate,
                extractedTime: parsedTime,
                extractedStadium: _recordDetail?['stadium'] as String?,
                extractedSeat: _recordDetail?['seatInfo'] as String?,
                gameId: gameId,
              );

              // RecordState 저장 후 확인
              recordState.printCurrentState();

              // 감정 코드
              recordState.updateEmotionCode(_recordDetail?['emotionCode'] as int? ?? 1);

              // 상세 기록
              recordState.updateLongContent(_recordDetail?['longContent'] as String? ?? '');
              recordState.updateBestPlayer(_recordDetail?['bestPlayer'] as String? ?? '');

              // 친구 태그
              final companions = _recordDetail?['companions'] as List<dynamic>?;
              if (companions != null && companions.isNotEmpty) {
                recordState.updateCompanions(
                    companions.map((c) => c['id'] as int).toList()
                );
              }

              // 먹거리 태그
              final foodTags = _recordDetail?['foodTags'] as List<dynamic>?;
              if (foodTags != null && foodTags.isNotEmpty) {
                recordState.updateFoodTags(
                    foodTags.map((f) => f.toString()).toList()
                );
              }

              // 상세 이미지 (mediaUrls는 detailImages로 저장)
              if (mediaUrls != null && mediaUrls.isNotEmpty) {
                recordState.updateDetailImages(
                    mediaUrls.map((url) => url.toString()).toList()
                );
              }

              // TicketInfoScreen으로 이동
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      TicketInfoScreen(
                        imagePath: ticketPath,
                        recordId: widget.recordId,
                        isEditMode: true,
                      ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );

              // 수정 완료 후 데이터 새로고침
              if (result == true) {
                await _loadRecordDetail();
                setState(() {});
              }
            },
          ),
          ActionSheetOption(
            text: '게시글 삭제',
            textColor: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              _deleteRecord();
            },
          ),
        ],
      );
    } else {
      // 타인 게시글: 신고하기만
      showCustomActionSheet(
        context: context,
        options: [
          ActionSheetOption(
            text: '신고하기',
            textColor: AppColors.error,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    }
  }

  void _showCommentOptions(CommentDto comment) {
    if (comment.userId != _currentUserId) {
      return;
    }

    _commentFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    showCustomActionSheet(
      context: context,
      options: [
        ActionSheetOption(
          text: '댓글 수정',
          textColor: AppColors.gray950,
          onTap: () {
            Navigator.pop(context);
            _startEditComment(comment);
          },
        ),
        ActionSheetOption(
          text: '댓글 삭제',
          textColor: AppColors.error,
          onTap: () {
            Navigator.pop(context);
            _deleteComment(comment.id);
          },
        ),
      ],
    );
  }

  void _startEditComment(CommentDto comment) {
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.content;
    });

    // 텍스트필드에 포커스
    Future.delayed(Duration(milliseconds: 100), () {
      _commentFocusNode.requestFocus();
    });
  }

  String _extractShortTeamName(String fullTeamName) {
    if (fullTeamName.contains('KIA')) return 'KIA';
    if (fullTeamName.contains('두산')) return '두산';
    if (fullTeamName.contains('롯데')) return '롯데';
    if (fullTeamName.contains('삼성')) return '삼성';
    if (fullTeamName.contains('키움')) return '키움';
    if (fullTeamName.contains('한화')) return '한화';
    if (fullTeamName.contains('KT')) return 'KT';
    if (fullTeamName.contains('LG')) return 'LG';
    if (fullTeamName.contains('NC')) return 'NC';
    if (fullTeamName.contains('SSG')) return 'SSG';
    return fullTeamName;
  }

  /// createdAt 시간을 기준으로 "n초 전", "n분 전" 등으로 표시
  Future<void> _handleFollowToggle() async {
    if (_isFollowLoading) return;

    final userId = _recordDetail?['userId'];
    if (userId == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_followStatus == 'NOT_FOLLOWING') {
        // 팔로우 요청
        final result = await UserApi.followUser(userId);
        final data = result['data'];

        // API 응답에서 followStatus 계산
        final isFollowing = data['isFollowing'] as bool;
        final pending = data['pending'] as bool? ?? false;

        String newStatus;
        if (pending) {
          newStatus = 'REQUESTED';
        } else if (isFollowing) {
          newStatus = 'FOLLOWING';
        } else {
          newStatus = 'NOT_FOLLOWING';
        }

        _followManager.updateFollowStatus(userId, newStatus);

        setState(() {
          _followStatus = newStatus;
          if (_recordDetail != null) {
            _recordDetail!['followStatus'] = newStatus;
          }
        });

        print('✅ 팔로우 성공: userId=$userId, newStatus=$newStatus (isFollowing: $isFollowing, pending: $pending)');
      }
    } catch (e) {
      print('❌ 팔로우 실패: $e');
    } finally {
      setState(() {
        _isFollowLoading = false;
      });
    }
  }

  //토스트
  void _showUploadToast(String nickname) {
    CustomToast.showSimpleTop(
      context: context,
      iconAsset: AppImages.complete,
      message: '직관 기록이 업로드 완료됐어요!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            if (widget.fromUpload) {
              // 업로드/수정 완료 후 -> FeedScreen으로 이동
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1,
                      animation2) => const FeedScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else {
              // 일반 조회 -> 이전 화면으로 (업데이트된 데이터 전달)
              Navigator.pop(context, {
                'updated': true,
                'recordId': widget.recordId,
                'updatedData': _recordDetail,
              });
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: _buildErrorState())
                      : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildContent()),
                      SliverToBoxAdapter(
                          child: _buildCommentHeaderAndDivider()),
                      _buildCommentAreaSliver(),
                    ],
                  ),
                ),
                _buildCommentInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FixedText(
          _errorMessage!,
          style: AppFonts.pretendard.body_md_400(context).copyWith(
            color: AppColors.gray400,
          ),
        ),
        SizedBox(height: scaleHeight(16)),
        ElevatedButton(
          onPressed: () {
            _loadRecordDetail();
            _loadComments();
          },
          child: Text('다시 시도'),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: scaleHeight(40),
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              // fromUpload 분기 처리 추가
              if (widget.fromUpload) {
                // 업로드 완료 후 -> FeedScreen으로 이동
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1,
                        animation2) => const FeedScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              } else {
                // 일반 조회 -> 이전 화면으로 (업데이트된 데이터 전달)
                Navigator.pop(context, {
                  'updated': true,
                  'recordId': widget.recordId,
                  'updatedData': _recordDetail,
                });
              }
            },
            child: SvgPicture.asset(
              AppImages.backBlack,
              width: scaleWidth(24),
              height: scaleHeight(24),
              fit: BoxFit.contain,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => print('공유하기'),
                child: SvgPicture.asset(
                  AppImages.Share,
                  width: scaleWidth(24),
                  height: scaleHeight(24),
                  fit: BoxFit.contain,
                  color: AppColors.gray900,
                ),
              ),
              SizedBox(width: scaleWidth(12)),
              GestureDetector(
                onTap: _showMoreOptions,
                child: SvgPicture.asset(
                  AppImages.dots,
                  width: scaleWidth(24),
                  height: scaleHeight(24),
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_recordDetail == null) return SizedBox.shrink();

    final nickname = _recordDetail!['nickname'] ?? '';
    final profileImageUrl = _recordDetail!['profileImageUrl'] ?? '';
    final favTeam = _recordDetail!['favTeam'] ?? '';
    final longContent = _recordDetail!['longContent'] ?? '';
    final gameDate = _recordDetail!['gameDate'] ?? '';
    final gameTime = _recordDetail!['gameTime'] ?? '';
    final stadium = _recordDetail!['stadium'] ?? '';
    final homeTeam = _recordDetail!['homeTeam'] ?? '';
    final awayTeam = _recordDetail!['awayTeam'] ?? '';
    final homeScore = _recordDetail!['homeScore'];
    final awayScore = _recordDetail!['awayScore'];
    final emotionCode = _recordDetail!['emotionCode'];
    final emotionLabel = _recordDetail!['emotionLabel'] ?? '';
    final mediaUrls = _recordDetail!['mediaUrls'] as List<dynamic>? ?? [];

    final bool hasLongContent = longContent
        .trim()
        .isNotEmpty;
    final homeTeamShort = _extractShortTeamName(homeTeam);
    final awayTeamShort = _extractShortTeamName(awayTeam);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final userId = _recordDetail!['userId'];
            if (userId != null) {
              if (userId == _currentUserId) {
                // 내 프로필이면 MyPage로 이동
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const MyPageScreen(
                      fromNavigation: false,
                      showBackButton: true,
                    ),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              } else {
                // 다른 사람 프로필이면 FriendProfileScreen으로 이동
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FriendProfileScreen(userId: userId),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(
              top: scaleHeight(14),
              left: scaleWidth(20),
              right: scaleWidth(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(scaleWidth(18)),
                  child: (profileImageUrl.isNotEmpty)
                      ? Image.network(
                    profileImageUrl,
                    width: scaleWidth(36),
                    height: scaleHeight(36),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        SvgPicture.asset(
                          AppImages.profile,
                          width: scaleWidth(36),
                          height: scaleHeight(36),
                          fit: BoxFit.cover,
                        ),
                  )
                      : SvgPicture.asset(
                    AppImages.profile,
                    width: scaleWidth(36),
                    height: scaleHeight(36),
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: scaleWidth(12)),

                // 닉네임 + 팀 배지 + 시간
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 닉네임 + 팀 배지
                      Row(
                        children: [
                          Flexible(
                            child: FixedText(
                              nickname,
                              style: AppFonts.pretendard.body_sm_500(context)
                                  .copyWith(
                                color: AppColors.gray950,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (favTeam.isNotEmpty && favTeam != '-' &&
                              favTeam != '응원팀 없음') ...[
                            SizedBox(width: scaleWidth(6)),
                            TeamUtils.buildTeamBadge(
                              context: context,
                              teamName: favTeam,
                              textStyle: AppFonts.pretendard.caption_sm_500(
                                  context),
                              padding: EdgeInsets.symmetric(
                                  horizontal: scaleWidth(7)),
                              borderRadius: scaleWidth(4),
                              height: scaleHeight(18),
                              suffix: ' 팬',
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: scaleHeight(2)),
                      // 시간
                      FixedText(
                        TimeUtils.getTimeAgo(_recordDetail!['createdAt']),
                        style: AppFonts.pretendard.caption_md_500(context)
                            .copyWith(
                          color: AppColors.gray300,
                        ),
                      ),
                    ],
                  ),
                ),

                // 팔로우 버튼 (본인 아니면서 NOT_FOLLOWING일 때만 표시)
                if (!_isMyPost && _followStatus == 'NOT_FOLLOWING') ...[
                  SizedBox(width: scaleWidth(8)),
                  GestureDetector(
                    onTap: _isFollowLoading ? null : _handleFollowToggle,
                    child: Container(
                      width: scaleWidth(52),
                      height: scaleHeight(28),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: _isFollowLoading
                          ? SizedBox(
                        width: scaleWidth(16),
                        height: scaleHeight(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.pri700),
                        ),
                      )
                          : FixedText(
                        '팔로우',
                        style: AppFonts.pretendard.caption_md_500(context)
                            .copyWith(
                          color: AppColors.pri700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: scaleHeight(12)),
        if (hasLongContent) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
            child: FixedText(
              longContent,
              style: AppFonts.pretendard.body_sm_400(context).copyWith(
                  color: Colors.black),
            ),
          ),
          SizedBox(height: scaleHeight(12)),
        ],
        _buildGameCard(
            homeTeamShort,
            awayTeamShort,
            homeScore,
            awayScore,
            emotionCode,
            emotionLabel,
            gameDate,
            gameTime,
            stadium,
            _recordDetail!),
        if (mediaUrls.isNotEmpty) ...[
          SizedBox(height: scaleHeight(16)),
          _buildMediaSection(mediaUrls),
        ],
        SizedBox(height: scaleHeight(16)),
        Padding(
          padding: EdgeInsets.only(left: scaleWidth(20), bottom: scaleHeight(
              16)),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      _isLiked ? AppImages.heart_filled : AppImages
                          .heart_outlined,
                      width: scaleWidth(20),
                      height: scaleHeight(20),
                    ),
                    SizedBox(width: scaleWidth(4)),
                    FixedText(
                      _likeCount.toString(),
                      style: AppFonts.pretendard.body_sm_400(context).copyWith(
                          color: AppColors.gray300),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scaleWidth(14)),
              Row(
                children: [
                  SvgPicture.asset(AppImages.comment, width: scaleWidth(20),
                      height: scaleHeight(20)),
                  SizedBox(width: scaleWidth(4)),
                  FixedText(
                    _commentCount.toString(),
                    style: AppFonts.pretendard.body_sm_400(context).copyWith(
                        color: AppColors.gray300),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentHeaderAndDivider() {
    if (_recordDetail == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          child: Container(height: 1, color: AppColors.gray50),
        ),
        Padding(
          padding: EdgeInsets.only(top: scaleHeight(12), left: scaleWidth(20), bottom: scaleHeight(16)),
          child: FixedText(
            '댓글',
            style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray300),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentAreaSliver() {
    if (_comments.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: scaleHeight(43)),
            child: FixedText(
              '댓글이 없어요.\n가장 먼저 남겨보세요.',
              style: AppFonts.pretendard.body_md_500(context).copyWith(
                color: AppColors.gray400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final comment = _comments[index];
          final bottomPadding = index == _comments.length - 1
              ? scaleHeight(20)
              : scaleHeight(24);
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildCommentItem(comment),
          );
        },
        childCount: _comments.length,
      ),
    );
  }

  Widget _buildCommentItem(CommentDto comment) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지 (28x28) - 클릭 가능
              GestureDetector(
                onTap: () async {
                  if (comment.userId == _currentUserId) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const MyPageScreen(
                          fromNavigation: false,
                          showBackButton: true,
                        ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            FriendProfileScreen(userId: comment.userId),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: scaleWidth(28),
                  height: scaleHeight(28),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray50, width: 1),
                    borderRadius: BorderRadius.circular(scaleWidth(14)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(scaleWidth(14)),
                    child: comment.profileImageUrl.isNotEmpty
                        ? Image.network(
                      comment.profileImageUrl,
                      width: scaleWidth(28),
                      height: scaleHeight(28),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => SvgPicture.asset(
                        AppImages.profile,
                        width: scaleWidth(28),
                        height: scaleHeight(28),
                        fit: BoxFit.cover,
                      ),
                    )
                        : SvgPicture.asset(
                      AppImages.profile,
                      width: scaleWidth(28),
                      height: scaleHeight(28),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(width: scaleWidth(12)),
              // 닉네임+팀배지+시간 영역
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (comment.userId == _currentUserId) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                          const MyPageScreen(
                            fromNavigation: false,
                            showBackButton: true,
                          ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              FriendProfileScreen(userId: comment.userId),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      // 닉네임
                      Flexible(
                        child: FixedText(
                          comment.nickname,
                          style: AppFonts.pretendard.body_sm_500(context).copyWith(
                            color: AppColors.gray950,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: scaleWidth(6)),
                      // 팀 배지
                      if (comment.favTeam.isNotEmpty &&
                          comment.favTeam != "응원팀 없음" &&
                          comment.favTeam != "-")
                        TeamUtils.buildTeamBadge(
                          context: context,
                          teamName: comment.favTeam,
                          textStyle: AppFonts.pretendard.caption_sm_500(context),
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(7)),
                          borderRadius: scaleWidth(4),
                          height: scaleHeight(18),
                          suffix: ' 팬',
                        ),
                      if (comment.favTeam.isNotEmpty &&
                          comment.favTeam != "응원팀 없음" &&
                          comment.favTeam != "-")
                        SizedBox(width: scaleWidth(6)),
                      // 시간
                      FixedText(
                        TimeUtils.getTimeAgo(comment.createdAt),
                        style: AppFonts.pretendard.caption_re_400(context).copyWith(
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // dots
              if (comment.userId == _currentUserId)
                GestureDetector(
                  onTap: () => _showCommentOptions(comment),
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    AppImages.more,
                    width: scaleWidth(20),
                    height: scaleHeight(20),
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
          // 하단: 댓글 내용
          Padding(
            padding: EdgeInsets.only(left: scaleWidth(40), right: scaleWidth(20)),
            child: FixedText(
              comment.content,
              style: AppFonts.pretendard.body_sm_400(context).copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(String homeTeamShort, String awayTeamShort,
      int? homeScore, int? awayScore, int? emotionCode, String emotionLabel,
      String gameDate, String gameTime, String stadium,
      Map<String, dynamic> recordDetail) {
    return GestureDetector(
      onTap: () => setState(() => _isGameCardExpanded = !_isGameCardExpanded),
      child: AnimatedSize(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          width: MediaQuery.of(context).size.width - scaleWidth(40),
          margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          padding: EdgeInsets.only(
            top: scaleHeight(12),
            bottom: scaleHeight(12),
            left: scaleWidth(20),
            right: scaleWidth(16),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(scaleHeight(12)),
            border: Border.all(color: AppColors.gray50, width: 1),
          ),
          child: Stack(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // emotion 이미지와 라벨
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: scaleHeight(2)),
                          _getEmotionImage(emotionCode),
                          SizedBox(height: scaleHeight(5)),
                          FixedText(
                            emotionLabel,
                            style: AppFonts.suite.caption_md_400(context).copyWith(
                              color: AppColors.gray900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: scaleWidth(18)),
                    // 구분선
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: scaleHeight(4)),
                      child: Container(
                        width: 1,
                        color: AppColors.gray50,
                      ),
                    ),
                    SizedBox(width: scaleWidth(18)),
                    // 게임 정보 영역
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜, 시간, 경기장 정보
                          Row(
                            children: [
                              FixedText(
                                _formatGameDateTime(gameDate, gameTime),
                                style: AppFonts.pretendard.caption_re_400(context).copyWith(color: AppColors.gray400,
                                    fontSize: scaleFont(10),
                                    height: 14 / 10),
                              ),
                              SizedBox(width: scaleWidth(4)),
                              SvgPicture.asset(AppImages.ellipse, width: scaleWidth(2), height: scaleHeight(2)),
                              SizedBox(width: scaleWidth(4)),
                              FixedText(
                                stadium,
                                style: AppFonts.pretendard.caption_re_400(context).copyWith(color: AppColors.gray400,
                                    fontSize: scaleFont(10),
                                    height: 14 / 10),
                              ),
                            ],
                          ),
                          SizedBox(height: scaleHeight(5)),
                          // 팀 로고와 스코어
                          Row(
                            children: [
                              _getTeamLogo(homeTeamShort, size: 40),
                              SizedBox(width: scaleWidth(12)),
                              FixedText(homeScore?.toString() ?? '0', style: AppFonts.suite.title_lg_700(context).copyWith(color: AppColors.gray500)),
                              SizedBox(width: scaleWidth(10)),
                              FixedText(':', style: AppFonts.suite.title_lg_700(context).copyWith(color: AppColors.gray500)),
                              SizedBox(width: scaleWidth(12)),
                              FixedText(awayScore?.toString() ?? '0', style: AppFonts.suite.title_lg_700(context).copyWith(color: AppColors.gray500)),
                              SizedBox(width: scaleWidth(11)),
                              _getTeamLogo(awayTeamShort, size: 40),
                            ],
                          ),
                          // 확장 정보
                          if (_isGameCardExpanded) ...[
                            SizedBox(height: scaleHeight(10)),
                            _buildExpandedInfo(recordDetail),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: scaleHeight(20),
                child: AnimatedRotation(
                  duration: Duration(milliseconds: 300),
                  turns: _isGameCardExpanded ? 0.25 : -0.25,
                  child: SvgPicture.asset(
                    AppImages.backBlack,
                    width: scaleWidth(20),
                    height: scaleHeight(20),
                    fit: BoxFit.contain,
                    color: AppColors.gray200,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(List<dynamic> mediaUrls) {
    if (mediaUrls.length == 1) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
        height: scaleHeight(159),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
              image: NetworkImage(mediaUrls[0]), fit: BoxFit.cover),
        ),
      );
    } else if (mediaUrls.length == 2) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
        height: scaleHeight(159),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                      image: NetworkImage(mediaUrls[0]), fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                      image: NetworkImage(mediaUrls[1]), fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(left: scaleWidth(20)),
        height: scaleHeight(159),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: mediaUrls.length,
          itemBuilder: (context, index) {
            return Container(
              width: scaleWidth(139),
              margin: EdgeInsets.only(right: scaleWidth(8)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                    image: NetworkImage(mediaUrls[index]), fit: BoxFit.cover),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _getTeamLogo(String team, {double size = 18}) {
    final teamLogos = {
      'LG': AppImages.twins,
      'KT': AppImages.ktwiz,
      '두산': AppImages.bears,
      '삼성': AppImages.lions,
      'SSG': AppImages.landers,
      'NC': AppImages.dinos,
      '롯데': AppImages.giants,
      'KIA': AppImages.tigers,
      '한화': AppImages.eagles,
      '키움': AppImages.kiwoom,
    };

    final logoPath = teamLogos[team];
    if (logoPath == null) {
      return SizedBox(width: scaleWidth(size), height: scaleHeight(size));
    }

    return Image.asset(
      logoPath,
      width: scaleWidth(size),
      height: scaleHeight(size),
      fit: BoxFit.contain,
    );
  }

  Widget _getEmotionImage(int? emotionCode) {
    final emotionImages = {
      1: AppImages.emotion_1,
      2: AppImages.emotion_2,
      3: AppImages.emotion_3,
      4: AppImages.emotion_4,
      5: AppImages.emotion_5,
      6: AppImages.emotion_6,
      7: AppImages.emotion_7,
      8: AppImages.emotion_8,
      9: AppImages.emotion_9,
      10: AppImages.emotion_10,
      11: AppImages.emotion_11,
      12: AppImages.emotion_12,
      13: AppImages.emotion_13,
      14: AppImages.emotion_14,
      15: AppImages.emotion_15,
      16: AppImages.emotion_16,
    };

    final imagePath = emotionImages[emotionCode];
    if (imagePath == null) {
      return SizedBox(width: scaleWidth(36), height: scaleHeight(36));
    }

    return SvgPicture.asset(
      imagePath,
      width: scaleWidth(36),
      height: scaleHeight(36),
    );
  }

  String _formatGameDateTime(String gameDate, String gameTime) {
    if (gameDate.isEmpty || gameTime.isEmpty) return '';

    try {
      final dateOnlyPart = gameDate.split('(')[0].trim();
      final yearMatch = RegExp(r'(\d{4})년').firstMatch(dateOnlyPart);
      final monthMatch = RegExp(r'(\d{2})월').firstMatch(dateOnlyPart);
      final dayMatch = RegExp(r'(\d{2})일').firstMatch(dateOnlyPart);

      if (yearMatch == null || monthMatch == null || dayMatch == null) {
        return '';
      }

      final year = yearMatch.group(1)!;
      final month = int.parse(monthMatch.group(1)!).toString();
      final day = int.parse(dayMatch.group(1)!).toString();

      final timeComponents = gameTime.split(':');
      if (timeComponents.length == 2) {
        final hour = timeComponents[0];
        final minute = timeComponents[1];
        return '$year년 $month월 $day일 $hour시 $minute분';
      }

      return '';
    } catch (e) {
      print('❌ 날짜 포맷 변환 실패: $e');
      return '';
    }
  }

  Widget _buildExpandedInfo(Map<String, dynamic> recordDetail) {
    final seatInfo = recordDetail['seatInfo'] ?? '';
    final bestPlayer = recordDetail['bestPlayer'];
    final companions = recordDetail['companions'] as List<dynamic>?;
    final homeTeam = recordDetail['homeTeam'] ?? '';

    final hasBestPlayer = bestPlayer != null && bestPlayer
        .toString()
        .trim()
        .isNotEmpty;
    final hasCompanions = companions != null && companions.isNotEmpty;

    String bestPlayerText = '';
    if (hasBestPlayer) {
      bestPlayerText = homeTeam.isNotEmpty
          ? '$homeTeam ${bestPlayer.toString()}'
          : bestPlayer.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('좌석', seatInfo, AppColors.gray400),
        if (hasBestPlayer) ...[
          SizedBox(height: scaleHeight(6)),
          _buildInfoRow('MVP', bestPlayerText, AppColors.gray400),
        ],
        if (hasCompanions) ...[
          SizedBox(height: scaleHeight(6)),
          _buildInfoRow(
            '직관 친구',
            companions!.map((c) => '@${c is Map ? c['nickname'] ?? '' : c}')
                .join(' '),
            AppColors.pri600,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    // "직관 친구" 텍스트의 너비를 기준으로 레이블 영역 크기 고정
    final labelWidth = _calculateTextWidth(
        '직관 친구',
        AppFonts.pretendard.caption_re_400(context).copyWith(
            color: AppColors.gray300)
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: FixedText(
            label,
            style: AppFonts.pretendard.caption_re_400(context).copyWith(
                color: AppColors.gray300),
            textAlign: TextAlign.left,
          ),
        ),
        SizedBox(width: scaleWidth(10)),
        Expanded(
          child: FixedText(
            value,
            style: AppFonts.pretendard.caption_re_400(context).copyWith(
                color: valueColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInputArea() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: scaleWidth(20),
        vertical: scaleHeight(10),
      ),
      child: Container(
        height: scaleHeight(48),
        decoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleHeight(10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                style: AppFonts.pretendard.body_sm_400(context).copyWith(
                    color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: '댓글을 작성해 보세요',
                  hintStyle: AppFonts.pretendard.body_sm_400(context).copyWith(
                      color: AppColors.gray200),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: scaleWidth(16),
                    top: scaleHeight(14),
                    bottom: scaleHeight(14),
                  ),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) {
                  _handleSendComment();
                },
              ),
            ),
            GestureDetector(
              onTap: _handleSendComment,
              child: Padding(
                padding: EdgeInsets.only(right: scaleWidth(14)),
                child: SvgPicture.asset(
                  AppImages.send,
                  width: scaleWidth(20),
                  height: scaleHeight(20),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 텍스트 너비 계산 헬퍼 함수
  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )
      ..layout();
    return textPainter.size.width;
  }
}