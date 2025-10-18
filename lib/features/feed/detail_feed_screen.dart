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

  @override
  void initState() {
    super.initState();
    _likeManager.addListener(_onGlobalLikeStateChanged);
    _loadRecordDetail();
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

      // 백엔드 API 호출
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
      print('📊 데이터: $data');
    } catch (e) {
      print('❌ 직관 기록 조회 실패: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '직관 기록을 불러올 수 없습니다.';
      });
    }
  }

  // 좋아요 토글
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
              // 1. 헤더 영역
              _buildHeader(),

              // 2. 스크롤 가능한 본문 영역
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

              // 3. 댓글 입력 영역 (하단 고정)
              _buildCommentInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. 헤더 영역
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: scaleHeight(40),
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 뒤로가기 버튼
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

          // 오른쪽: Share & Dots
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: 공유 기능
                  print('공유하기');
                },
                child: SvgPicture.asset(
                  AppImages.Share,
                  width: scaleWidth(24),
                  height: scaleHeight(24),
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: scaleWidth(12)),
              GestureDetector(
                onTap: () {
                  // TODO: 더보기 메뉴 (신고, 차단 등)
                  print('더보기');
                },
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

  // 2. 본문 영역
  Widget _buildContent() {
    if (_recordDetail == null) return SizedBox.shrink();

    final nickname = _recordDetail!['nickname'] ?? '';
    final profileImageUrl = _recordDetail!['profileImageUrl'] ?? '';
    final favTeam = _recordDetail!['favTeam'] ?? '';
    final longContent = _recordDetail!['longContent'] ?? '';
    final companions = _recordDetail!['companions'] as List<dynamic>? ?? [];
    final gameDate = _recordDetail!['gameDate'] ?? '';
    final stadium = _recordDetail!['stadium'] ?? '';
    final homeTeam = _recordDetail!['homeTeam'] ?? '';
    final awayTeam = _recordDetail!['awayTeam'] ?? '';
    final homeScore = _recordDetail!['homeScore'];
    final awayScore = _recordDetail!['awayScore'];
    final emotionCode = _recordDetail!['emotionCode'];
    final emotionLabel = _recordDetail!['emotionLabel'] ?? '';
    final mediaUrls = _recordDetail!['mediaUrls'] as List<dynamic>? ?? [];
    final commentCount = _recordDetail!['commentCount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 프로필 영역
        Container(
          padding: EdgeInsets.only(
            top: scaleHeight(12),
            left: scaleWidth(20),
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
              // 닉네임 & 팬 정보
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

        // 4-1. longContent
        if (longContent.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: scaleWidth(20), right: scaleWidth(20)),
            child: FixedText(
              longContent,
              style: AppFonts.pretendard.body_md_400(context).copyWith(
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: scaleHeight(8)),
        ],

        // 4-2. companions
        if (companions.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: scaleWidth(20), right: scaleWidth(20)),
            child: Wrap(
              spacing: scaleWidth(8),
              children: companions.map((companion) {
                final companionNickname = companion['nickname'] ?? '';
                return FixedText(
                  '@$companionNickname',
                  style: AppFonts.pretendard.caption_md_400(context).copyWith(
                    color: AppColors.pri600,
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: scaleHeight(8)),
        ],

        // 4-3. 경기 정보 및 감정 이모지 영역
        Container(
          margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          height: scaleHeight(83),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(scaleHeight(12)),
            border: Border.all(color: AppColors.gray50, width: 1),
          ),
          child: Stack(
            children: [
              // 왼쪽: 경기 정보
              Positioned(
                top: scaleHeight(12),
                left: scaleWidth(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 & 경기장
                    Row(
                      children: [
                        FixedText(
                          _formatGameDate(gameDate),
                          style: AppFonts.suite.caption_re_400(context).copyWith(
                            color: AppColors.gray300,
                          ),
                        ),
                        SizedBox(width: scaleWidth(4)),
                        SvgPicture.asset(
                          AppImages.ellipse,
                          width: scaleWidth(2),
                          height: scaleHeight(2),
                        ),
                        SizedBox(width: scaleWidth(4)),
                        FixedText(
                          stadium,
                          style: AppFonts.suite.caption_re_400(context).copyWith(
                            color: AppColors.gray300,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: scaleHeight(2)),
                    // 경기 스코어
                    Row(
                      children: [
                        _getTeamLogo(homeTeam, size: 35),
                        SizedBox(width: scaleWidth(11)),
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
                        SizedBox(width: scaleWidth(10)),
                        FixedText(
                          awayScore?.toString() ?? '0',
                          style: AppFonts.suite.title_lg_700(context).copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        SizedBox(width: scaleWidth(11)),
                        _getTeamLogo(awayTeam, size: 35),
                      ],
                    ),
                  ],
                ),
              ),

              // 중앙: 구분선
              Positioned(
                top: scaleHeight(20),
                right: scaleWidth(88),
                child: Container(
                  width: 1,
                  height: scaleHeight(46),
                  color: AppColors.gray50,
                ),
              ),

              // 오른쪽: 감정 이모지
              Positioned(
                top: scaleHeight(12),
                right: scaleWidth(30),
                child: Column(
                  children: [
                    _getEmotionImage(emotionCode),
                    SizedBox(height: scaleHeight(4)),
                    FixedText(
                      emotionLabel,
                      style: AppFonts.suite.caption_md_500(context).copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: mediaUrls.isNotEmpty ? scaleHeight(16) : scaleHeight(12)),

        // 5. 미디어 영역
        if (mediaUrls.isNotEmpty) ...[
          _buildMediaSection(mediaUrls),
          SizedBox(height: scaleHeight(12)),
        ],

        // 6. 좋아요 & 댓글
        Padding(
          padding: EdgeInsets.only(left: scaleWidth(20), bottom: scaleHeight(20)),
          child: Row(
            children: [
              // 좋아요
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
              // 댓글
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

  // 미디어 섹션
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

  // 팀 로고
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

  // 감정 이미지
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
      return SizedBox(width: scaleWidth(38), height: scaleHeight(38));
    }

    return SvgPicture.asset(
      imagePath,
      width: scaleWidth(38),
      height: scaleHeight(38),
    );
  }

  // 날짜 포맷
  String _formatGameDate(String gameDate) {
    if (gameDate.isEmpty) return '';

    try {
      if (gameDate.contains('년')) {
        final dateOnly = gameDate.split('(')[0].trim();
        final formatted = dateOnly.replaceAllMapped(
          RegExp(r'년 0(\d)월'),
              (match) => '년 ${match.group(1)}월',
        );
        return formatted;
      }
      return gameDate;
    } catch (e) {
      return gameDate;
    }
  }

  // 3. 댓글 입력 영역
  Widget _buildCommentInputArea() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: scaleWidth(20),
        vertical: scaleHeight(10),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.gray50,
            width: 1,
          ),
        ),
      ),
      child: Container(
        height: scaleHeight(48),
        decoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleHeight(10)),
        ),
        child: Row(
          children: [
            // 텍스트 입력 필드
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

            // 전송 버튼
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