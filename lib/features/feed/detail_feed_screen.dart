import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/record_api.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:frontend/utils/like_state_manager.dart';
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
  final _likeManager = LikeStateManager();

  Map<String, dynamic>? _recordDetail;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isLiked = false;
  int _likeCount = 0;
  int? _currentUserId;
  bool _isGameCardExpanded = false;

  // 작성자 여부 확인
  bool get _isMyPost {
    if (_recordDetail == null || _currentUserId == null) return false;
    final authorId = _recordDetail!['userId'];
    return authorId == _currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _likeManager.addListener(_onGlobalLikeStateChanged);
    _loadCurrentUserId();
    _loadRecordDetail();
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

  @override
  void dispose() {
    _commentController.dispose();
    _likeManager.removeListener(_onGlobalLikeStateChanged);
    super.dispose();
  }

  void _onGlobalLikeStateChanged() {
    final newIsLiked = _likeManager.getLikedStatus(widget.recordId);
    final newLikeCount = _likeManager.getLikeCount(widget.recordId);

    if (newIsLiked != null && newLikeCount != null) {
      if (_isLiked != newIsLiked || _likeCount != newLikeCount) {
        setState(() {
          _isLiked = newIsLiked;
          _likeCount = newLikeCount;
        });
        print('✅ [DetailFeedScreen] 전역 상태 동기화');
      }
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

      final globalIsLiked = _likeManager.getLikedStatus(widget.recordId);
      final globalLikeCount = _likeManager.getLikeCount(widget.recordId);

      setState(() {
        _recordDetail = data;
        _isLiked = globalIsLiked ?? (data['isLiked'] ?? false);
        _likeCount = globalLikeCount ?? (data['likeCount'] ?? 0);
        _isLoading = false;
      });

      _likeManager.setInitialState(widget.recordId, _isLiked, _likeCount);

      print('✅ 직관 기록 조회 성공: ${data['nickname']}');
    } catch (e) {
      print('❌ 직관 기록 조회 실패: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '직관 기록을 불러올 수 없습니다.';
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      print('🔄 좋아요 토글 시작: recordId=${widget.recordId}');

      final result = await FeedApi.toggleLike(widget.recordId.toString());

      final isLiked = result['isLiked'] as bool;
      final likeCountRaw = result['likeCount'];
      final likeCount = likeCountRaw is int ? likeCountRaw : (likeCountRaw as num).toInt();

      _likeManager.updateLikeState(widget.recordId, isLiked, likeCount);

      setState(() {
        _isLiked = isLiked;
        _likeCount = likeCount;
      });

      print('✅ 좋아요 토글 성공: isLiked=$isLiked, likeCount=$likeCount');
    } catch (e) {
      print('❌ 좋아요 토글 실패: $e');
    }
  }

  void _handleSendComment() {
    if (_commentController.text.trim().isEmpty) return;

    // TODO: 댓글 작성 API 호출
    print('댓글 작성: ${_commentController.text}');
    _commentController.clear();
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
            // TODO: 게시글 수정 화면으로 이동
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
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          print('🔙 [Detail PopScope] 뒤로가기 (전역 상태로 이미 동기화됨)');
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
                    ? Center(
                  child: Column(
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
                        onPressed: _loadRecordDetail,
                        child: Text('다시 시도'),
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  child: _buildContent(),
                ),
              ),
              _buildCommentInputArea(),
            ],
          ),
        ),
      ),
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
              Navigator.pop(context);
            },
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
                onTap: () {
                  print('공유하기');
                },
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
                onTap: () {
                  _showMoreOptions();
                },
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
            onTap: () {
              print('공유하기');
            },
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
    final companions = _recordDetail!['companions'] as List<dynamic>? ?? [];
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
    final commentCount = _recordDetail!['commentCount'] ?? 0;

    final bool hasLongContent = longContent.trim().isNotEmpty;
    final homeTeamShort = _extractShortTeamName(homeTeam);
    final awayTeamShort = _extractShortTeamName(awayTeam);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필 영역
        Container(
          padding: EdgeInsets.only(
            top: scaleHeight(12),
            left: scaleWidth(20),
          ),
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
                    style: AppFonts.pretendard.body_sm_500(context).copyWith(
                      color: AppColors.gray950,
                    ),
                  ),
                  SizedBox(height: scaleHeight(2)),
                  FixedText(
                    '$favTeam 팬',
                    style: AppFonts.pretendard.caption_md_400(context).copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: scaleHeight(12)),

        // longContent
        if (hasLongContent) ...[
          Padding(
            padding: EdgeInsets.only(left: scaleWidth(20), right: scaleWidth(20)),
            child: FixedText(
              longContent,
              style: AppFonts.pretendard.body_sm_400(context).copyWith(
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: scaleHeight(12)),
        ],

        // 경기 정보 카드
        GestureDetector(
          onTap: () {
            setState(() {
              _isGameCardExpanded = !_isGameCardExpanded;
            });
          },
          child: AnimatedSize( // 카드의 높이가 내용에 따라 부드럽게 변하도록
            duration: Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
              padding: EdgeInsets.only(
                top: scaleHeight(12),
                left: scaleWidth(20),
                right: scaleWidth(16),
                bottom: scaleHeight(12),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(scaleHeight(12)),
                border: Border.all(color: AppColors.gray50, width: 1),
              ),
              child: IntrinsicHeight( // Row 내부의 위젯들이 가장 큰 위젯의 높이에 맞춰지도록 (특히 구분선)
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 감정 이미지 & 텍스트 (세로 중앙으로 표시되도록)
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _getEmotionImage(emotionCode),
                        FixedText(
                          emotionLabel,
                          style: AppFonts.suite.caption_md_500(context).copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: scaleWidth(17)),
                    // 구분선 (동적 크기에 맞춰 길어지도록)
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: AppColors.gray50,
                      margin: EdgeInsets.symmetric(vertical: scaleHeight(4)),
                    ),
                    SizedBox(width: scaleWidth(20)),
                    // 경기 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FixedText(
                                _formatGameDateTime(gameDate, gameTime),
                                style: AppFonts.suite.caption_re_400(context).copyWith(
                                  color: AppColors.gray300,
                                  fontSize: scaleFont(10),
                                  height: 14 / 10,
                                ),
                              ),
                              SizedBox(width: scaleWidth(4)),
                              SvgPicture.asset(
                                AppImages.ellipse,
                                width: scaleWidth(2),
                                height: scaleHeight(2),
                              ),
                              SizedBox(width: scaleWidth(3)),
                              FixedText(
                                stadium,
                                style: AppFonts.suite.caption_re_400(context).copyWith(
                                  color: AppColors.gray300,
                                  fontSize: scaleFont(10),
                                  height: 14 / 10,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: scaleHeight(7)),
                          Row(
                            children: [
                              SizedBox(width: scaleWidth(2)),
                              _getTeamLogo(homeTeamShort, size: 35),
                              SizedBox(width: scaleWidth(13)),
                              FixedText(
                                homeScore?.toString() ?? '0',
                                style: AppFonts.suite.title_lg_700(context).copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                              SizedBox(width: scaleWidth(10)),
                              FixedText(
                                ':',
                                style: AppFonts.suite.title_lg_700(context).copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                              SizedBox(width: scaleWidth(13)),
                              FixedText(
                                awayScore?.toString() ?? '0',
                                style: AppFonts.suite.title_lg_700(context).copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                              SizedBox(width: scaleWidth(11)),
                              _getTeamLogo(awayTeamShort, size: 35),
                            ],
                          ),
                          // 확장된 정보
                          if (_isGameCardExpanded) ...[
                            SizedBox(height: scaleHeight(10)),
                            _buildExpandedInfo(_recordDetail!),
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
        ),

        // 미디어 영역
        if (mediaUrls.isNotEmpty) ...[
          SizedBox(height: scaleHeight(16)),
          _buildMediaSection(mediaUrls),
        ],

        // 좋아요 & 댓글
        SizedBox(height: scaleHeight(16)),
        Padding(
          padding: EdgeInsets.only(left: scaleWidth(20), bottom: scaleHeight(20)),
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
                      style: AppFonts.suite.caption_re_400(context).copyWith(
                        color: AppColors.gray300,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scaleWidth(18)),
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.comment_detail,
                    width: scaleWidth(24),
                    height: scaleHeight(24),
                  ),
                  SizedBox(width: scaleWidth(6)),
                  FixedText(
                    commentCount.toString(),
                    style: AppFonts.suite.caption_re_400(context).copyWith(
                      color: AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            image: NetworkImage(mediaUrls[0]),
            fit: BoxFit.cover,
          ),
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
                    image: NetworkImage(mediaUrls[0]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(mediaUrls[1]),
                    fit: BoxFit.cover,
                  ),
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
                  image: NetworkImage(mediaUrls[index]),
                  fit: BoxFit.cover,
                ),
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

  // 확장된 정보 빌드
  Widget _buildExpandedInfo(Map<String, dynamic> recordDetail) {
    final seatInfo = recordDetail['seatInfo'] ?? '';
    final bestPlayer = recordDetail['bestPlayer'];
    final companions = recordDetail['companions'] as List<dynamic>?;

    final hasBestPlayer = bestPlayer != null && bestPlayer.toString().trim().isNotEmpty;
    final hasCompanions = companions != null && companions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌석 (항상 표시)
        _buildInfoRow('좌석', seatInfo, AppColors.gray400),

        // MVP (있는 경우만 표시)
        if (hasBestPlayer) ...[
          SizedBox(height: scaleHeight(6)),
          _buildInfoRow('MVP', bestPlayer.toString(), AppColors.gray400),
        ],

        // 직관친구 (있는 경우만 표시)
        if (hasCompanions) ...[
          SizedBox(height: scaleHeight(6)),
          _buildInfoRow(
            '직관친구', // 띄어쓰기 제거
            companions!.map((c) => '@${c is Map ? c['nickname'] ?? '' : c}').join(' '),
            AppColors.pri600,
          ),
        ],
      ],
    );
  }

  // 정보 행 빌드
  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: scaleWidth(40),
          child: Center(
            child: FixedText(
              label,
              style: AppFonts.suite.caption_re_400(context).copyWith(
                color: AppColors.gray300,
              ),
            ),
          ),
        ),
        SizedBox(width: scaleWidth(8)),
        Expanded(
          child: FixedText(
            value,
            style: AppFonts.suite.caption_re_400(context).copyWith(
              color: valueColor,
            ),
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
                style: AppFonts.pretendard.body_sm_400(context).copyWith(
                  color: AppColors.gray900,
                ),
                decoration: InputDecoration(
                  hintText: '댓글을 작성해 보세요',
                  hintStyle: AppFonts.pretendard.body_sm_400(context).copyWith(
                    color: AppColors.gray200,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: scaleWidth(16),
                    top: scaleHeight(14),
                    bottom: scaleHeight(14),
                  ),
                ),
                maxLines: 1,
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