import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/record_api.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:frontend/utils/feed_count_manager.dart';
import 'package:frontend/utils/comment_state_manager.dart';
import 'dart:math' as math;
import 'package:frontend/components/custom_action_sheet.dart';
import 'package:frontend/api/user_api.dart';

class DetailFeedScreen extends StatefulWidget {
  final int recordId;

  const DetailFeedScreen({
    Key? key,
    required this.recordId,
  }) : super(key: key);

  @override
  State<DetailFeedScreen> createState() => _DetailFeedScreenState();
}

class _DetailFeedScreenState extends State<DetailFeedScreen> {
  final TextEditingController _commentController = TextEditingController();
  final _feedCountManager = FeedCountManager();
  final _commentListManager = CommentListManager();
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
    _loadCurrentUserId();
    _loadRecordDetail();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _feedCountManager.removeListener(_onGlobalCountChanged);
    _commentListManager.removeListener(_onGlobalCommentListChanged);
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
      if (_isLiked != newIsLiked || _likeCount != newLikeCount || _commentCount != newCommentCount) {
        setState(() {
          _isLiked = newIsLiked;
          _likeCount = newLikeCount;
          _commentCount = newCommentCount;
        });
        print('✅ [DetailFeedScreen] 전역 카운트 동기화 - commentCount: $newCommentCount');
      }
    }
  }

  void _onGlobalCommentListChanged() {
    final comments = _commentListManager.getComments(widget.recordId);

    if (comments != null) {
      setState(() {
        _comments = List.from(comments);
      });
      print('✅ [DetailFeedScreen] 전역 댓글 목록 동기화: ${comments.length}개');
    }
  }

  Future<void> _loadRecordDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('📋 직관 기록 조회 시작: recordId=${widget.recordId}');

      final data = await RecordApi.getRecordDetail(widget.recordId.toString());

      final globalIsLiked = _feedCountManager.getLikedStatus(widget.recordId);
      final globalLikeCount = _feedCountManager.getLikeCount(widget.recordId);
      final globalCommentCount = _feedCountManager.getCommentCount(widget.recordId);

      setState(() {
        _recordDetail = data;
        _isLiked = globalIsLiked ?? (data['isLiked'] ?? false);
        _likeCount = globalLikeCount ?? (data['likeCount'] ?? 0);
        _commentCount = globalCommentCount ?? (data['commentCount'] ?? 0);
        _isLoading = false;
      });

      _feedCountManager.setInitialState(
        widget.recordId,
        _isLiked,
        _likeCount,
        commentCount: _commentCount,
      );

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
      print('💬 댓글 목록 조회 시작: recordId=${widget.recordId}');

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
      print('🔄 좋아요 토글 시작: recordId=${widget.recordId}');

      final result = await FeedApi.toggleLike(widget.recordId.toString());

      final isLiked = result['isLiked'] as bool;
      final likeCountRaw = result['likeCount'];
      final likeCount = likeCountRaw is int ? likeCountRaw : (likeCountRaw as num).toInt();

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
        // 댓글 수정 모드
        print('✏️ 댓글 수정 시작: commentId=$_editingCommentId');

        await FeedApi.updateComment(
          widget.recordId.toString(),
          _editingCommentId.toString(),
          originalContent,
        );

        print('✅ 댓글 수정 성공');

        // 수정 모드 종료
        setState(() {
          _editingCommentId = null;
        });

        // 댓글 목록 다시 불러오기
        await _loadComments();
      } else {
        // 댓글 작성 모드
        final result = await FeedApi.createComment(widget.recordId.toString(), originalContent);
        print('💬 댓글 작성 응답: $result');

        final newComment = CommentDto.fromJson(result);
        _commentListManager.addComment(widget.recordId, newComment);

        print('✅ 댓글 작성 성공 - totalCommentCount: ${newComment.totalCommentCount}');
      }
    } catch (e, stackTrace) {
      print('❌ 댓글 ${_editingCommentId != null ? "수정" : "작성"} 실패: $e');
      print('스택트레이스: $stackTrace');
      _commentController.text = originalContent;
    }
  }

  Future<void> _deleteComment(int commentId) async {
    if (_commentFocusNode.hasFocus) {
      _commentFocusNode.unfocus();
    }
    FocusScope.of(context).unfocus();

    try {
      print('🗑️ 댓글 삭제 시작: commentId=$commentId');
      await FeedApi.deleteComment(
          widget.recordId.toString(),
          commentId.toString()
      );
      print('✅ 댓글 삭제 API 호출 완료');
      _commentListManager.removeComment(widget.recordId, commentId);
      print('✅ 댓글 삭제 성공');
    } catch (e) {
      print('❌ 댓글 삭제 실패: $e');
    }
  }

  Future<void> _deleteRecord() async {
    try {
      print('🗑️ 게시글 삭제 시작: recordId=${widget.recordId}');

      await RecordApi.deleteRecord(widget.recordId.toString());

      print('✅ 게시글 삭제 성공');

      if (mounted) {
        Navigator.pop(context, {
          'deleted': true,
          'recordId': widget.recordId,
        });
      }
    } catch (e) {
      print('❌ 게시글 삭제 실패: $e');
    }
  }

  void _showMoreOptions() {
    showCustomActionSheet(
      context: context,
      options: [
        ActionSheetOption(
          text: '게시글 수정',
          textColor: AppColors.gray950,
          onTap: () {
            Navigator.pop(context);
            print('게시글 수정');
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

    print('✏️ 댓글 수정 모드 진입: commentId=${comment.id}');
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) {
            print('🔙 [Detail PopScope] 뒤로가기');
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
                      SliverToBoxAdapter(child: _buildCommentHeaderAndDivider()),
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
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset(
              AppImages.backBlack,
              width: scaleWidth(24),
              height: scaleHeight(24),
              fit: BoxFit.contain,
            ),
          ),
          _isMyPost
              ? Row(
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
          )
              : GestureDetector(
            onTap: () => print('공유하기'),
            child: SvgPicture.asset(
              AppImages.Share,
              width: scaleWidth(24),
              height: scaleHeight(24),
              fit: BoxFit.contain,
              color: AppColors.gray900,
            ),
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

    final bool hasLongContent = longContent.trim().isNotEmpty;
    final homeTeamShort = _extractShortTeamName(homeTeam);
    final awayTeamShort = _extractShortTeamName(awayTeam);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(top: scaleHeight(12), left: scaleWidth(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(scaleWidth(18)),
                child: (profileImageUrl.isNotEmpty)
                    ? Image.network(
                  profileImageUrl,
                  width: scaleWidth(36),
                  height: scaleHeight(36),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SvgPicture.asset(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FixedText(
                    nickname,
                    style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray950),
                  ),
                  SizedBox(height: scaleHeight(2)),
                  FixedText(
                    '$favTeam 팬',
                    style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray400),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: scaleHeight(12)),
        if (hasLongContent) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
            child: FixedText(
              longContent,
              style: AppFonts.pretendard.body_sm_400(context).copyWith(color: Colors.black),
            ),
          ),
          SizedBox(height: scaleHeight(12)),
        ],
        _buildGameCard(homeTeamShort, awayTeamShort, homeScore, awayScore, emotionCode, emotionLabel, gameDate, gameTime, stadium, _recordDetail!),
        if (mediaUrls.isNotEmpty) ...[
          SizedBox(height: scaleHeight(16)),
          _buildMediaSection(mediaUrls),
        ],
        SizedBox(height: scaleHeight(16)),
        Padding(
          padding: EdgeInsets.only(left: scaleWidth(20), bottom: scaleHeight(16)),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      _isLiked ? AppImages.heart_filled : AppImages.heart_outlined,
                      width: scaleWidth(24),
                      height: scaleHeight(24),
                    ),
                    SizedBox(width: scaleWidth(4)),
                    FixedText(
                      _likeCount.toString(),
                      style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scaleWidth(8)),
              Row(
                children: [
                  SvgPicture.asset(AppImages.comment_detail, width: scaleWidth(24), height: scaleHeight(24)),
                  SizedBox(width: scaleWidth(6)),
                  FixedText(
                    _commentCount.toString(),
                    style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
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
          padding: EdgeInsets.only(top: scaleHeight(16), left: scaleWidth(20), bottom: scaleHeight(16)),
          child: FixedText(
            '댓글',
            style: AppFonts.suite.body_re_400(context).copyWith(color: AppColors.gray300),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentAreaSliver() {
    if (_comments.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: scaleHeight(120)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedText(
                  '댓글이 없어요.',
                  style: AppFonts.pretendard.body_md_400(context).copyWith(color: AppColors.gray400),
                ),
                SizedBox(height: scaleHeight(4)),
                FixedText(
                  '가장 먼저 남겨보세요.',
                  style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final comment = _comments[index];
          final bottomPadding = index < _comments.length - 1 ? scaleHeight(20) : scaleHeight(0);
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
              ClipRRect(
                borderRadius: BorderRadius.circular(scaleWidth(14)),
                child: (comment.profileImageUrl.isNotEmpty)
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
              SizedBox(width: scaleWidth(8)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FixedText(
                      comment.nickname,
                      style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray950),
                    ),
                    SizedBox(width: scaleWidth(4)),
                    SvgPicture.asset(AppImages.ellipse, width: scaleWidth(2), height: scaleHeight(2)),
                    SizedBox(width: scaleWidth(4)),
                    FixedText(
                      '${comment.favTeam} 팬',
                      style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray400),
                    ),
                  ],
                ),
              ),
              if (comment.userId == _currentUserId)
                GestureDetector(
                  onTap: () => _showCommentOptions(comment),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(scaleWidth(4)),
                    child: SvgPicture.asset(
                        AppImages.more,
                        width: scaleWidth(20),
                        height: scaleHeight(20),
                        fit: BoxFit.contain
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: scaleWidth(36), top: scaleHeight(4)),
            child: FixedText(
              comment.content,
              style: AppFonts.pretendard.body_sm_400(context).copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(String homeTeamShort, String awayTeamShort, int? homeScore, int? awayScore, int? emotionCode, String emotionLabel, String gameDate, String gameTime, String stadium, Map<String, dynamic> recordDetail) {
    return GestureDetector(
      onTap: () => setState(() => _isGameCardExpanded = !_isGameCardExpanded),
      child: AnimatedSize(
        duration: Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          padding: EdgeInsets.all(scaleHeight(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(scaleHeight(12)),
            border: Border.all(color: AppColors.gray50, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getEmotionImage(emotionCode),
                    FixedText(emotionLabel, style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600)),
                  ],
                ),
                SizedBox(width: scaleWidth(17)),
                Container(width: 1, height: double.infinity, color: AppColors.gray50, margin: EdgeInsets.symmetric(vertical: scaleHeight(4))),
                SizedBox(width: scaleWidth(20)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FixedText(
                            _formatGameDateTime(gameDate, gameTime),
                            style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300, fontSize: scaleFont(10), height: 14 / 10),
                          ),
                          SizedBox(width: scaleWidth(4)),
                          SvgPicture.asset(AppImages.ellipse, width: scaleWidth(2), height: scaleHeight(2)),
                          SizedBox(width: scaleWidth(3)),
                          FixedText(
                            stadium,
                            style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300, fontSize: scaleFont(10), height: 14 / 10),
                          ),
                        ],
                      ),
                      SizedBox(height: scaleHeight(7)),
                      Row(
                        children: [
                          _getTeamLogo(homeTeamShort, size: 40),
                          SizedBox(width: scaleWidth(13)),
                          FixedText(homeScore?.toString() ?? '0', style: AppFonts.suite.title_lg_700(context).copyWith(color: AppColors.gray500)),
                          SizedBox(width: scaleWidth(10)),
                          FixedText(':', style: AppFonts.suite.title_lg_700(context).copyWith(color: AppColors.gray500)),
                          SizedBox(width: scaleWidth(13)),
                          FixedText(awayScore?.toString() ?? '0', style: AppFonts.suite.title_lg_700(context).copyWith(color: AppColors.gray500)),
                          SizedBox(width: scaleWidth(11)),
                          _getTeamLogo(awayTeamShort, size: 40),
                        ],
                      ),
                      if (_isGameCardExpanded) ...[
                        SizedBox(height: scaleHeight(10)),
                        _buildExpandedInfo(recordDetail),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: scaleHeight(20)),
                  child: AnimatedRotation(
                    duration: Duration(milliseconds: 300),
                    turns: _isGameCardExpanded ? -0.25 : 0.25,
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
          image: DecorationImage(image: NetworkImage(mediaUrls[0]), fit: BoxFit.cover),
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
                  image: DecorationImage(image: NetworkImage(mediaUrls[0]), fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(image: NetworkImage(mediaUrls[1]), fit: BoxFit.cover),
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
                image: DecorationImage(image: NetworkImage(mediaUrls[index]), fit: BoxFit.cover),
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
    };

    final imagePath = emotionImages[emotionCode];
    if (imagePath == null) {
      return SizedBox(width: scaleWidth(50), height: scaleHeight(50));
    }

    return SvgPicture.asset(
      imagePath,
      width: scaleWidth(50),
      height: scaleHeight(50),
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

    final hasBestPlayer = bestPlayer != null && bestPlayer.toString().trim().isNotEmpty;
    final hasCompanions = companions != null && companions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('좌석', seatInfo, AppColors.gray400),
        if (hasBestPlayer) ...[
          SizedBox(height: scaleHeight(6)),
          _buildInfoRow('MVP', bestPlayer.toString(), AppColors.gray400),
        ],
        if (hasCompanions) ...[
          SizedBox(height: scaleHeight(6)),
          _buildInfoRow(
            '직관친구',
            companions!.map((c) => '@${c is Map ? c['nickname'] ?? '' : c}').join(' '),
            AppColors.pri600,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: scaleWidth(40),
          child: Center(
            child: FixedText(
              label,
              style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
            ),
          ),
        ),
        SizedBox(width: scaleWidth(8)),
        Expanded(
          child: FixedText(
            value,
            style: AppFonts.suite.caption_re_400(context).copyWith(color: valueColor),
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
                style: AppFonts.pretendard.body_sm_400(context).copyWith(color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: '댓글을 작성해 보세요',
                  hintStyle: AppFonts.pretendard.body_sm_400(context).copyWith(color: AppColors.gray200),
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
}