import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/features/mypage/friend_profile_screen.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:intl/intl.dart';
import 'package:frontend/utils/feed_count_manager.dart';
import 'package:frontend/utils/team_utils.dart';
import 'package:frontend/utils/time_utils.dart';

/// 피드/검색 화면에서 공통으로 사용하는 피드 아이템 위젯
class FeedItemWidget extends StatefulWidget {
  final Map<String, dynamic> feedData;
  final VoidCallback? onTap;
  final VoidCallback? onProfileNavigated;

  const FeedItemWidget({
    Key? key,
    required this.feedData,
    this.onTap,
    this.onProfileNavigated,
  }) : super(key: key);

  @override
  State<FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends State<FeedItemWidget> {
  // 팀 이름 매핑
  final Map<String, String> _teamFullNames = {
    'LG': 'LG 트윈스',
    'KT': 'KT 위즈',
    '두산': '두산 베어스',
    '삼성': '삼성 라이온즈',
    'SSG': 'SSG 랜더스',
    'NC': 'NC 다이노스',
    '롯데': '롯데 자이언츠',
    'KIA': 'KIA 타이거즈',
    '한화': '한화 이글스',
    '키움': '키움 히어로즈',
  };

  // 구장 이름 매핑
  final Map<String, String> _stadiumFullNames = {
    '잠실': '잠실 야구장',
    '광주': '기아 챔피언스 필드',
    '수원': '수원 케이티 위즈 파크',
    '고척': '고척 SKYDOME',
    '대구': '대구삼성라이온즈파크',
    '대전': '한화생명 볼파크',
    '대전(신)': '한화생명 볼파크',
    '사직': '사직 야구장',
    '문학': '인천 SSG 랜더스 필드',
    '창원': '창원 NC 파크',
  };

  final _likeManager = FeedCountManager();

  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;

  @override
  void initState() {
    super.initState();

    final recordId = widget.feedData['recordId'] as int?;
    if (recordId != null) {
      // 전역 상태 우선 사용 (최신 값)
      _isLiked = _likeManager.getLikedStatus(recordId)
          ?? widget.feedData['isLiked']
          ?? false;
      _likeCount = _likeManager.getLikeCount(recordId)
          ?? widget.feedData['likeCount']
          ?? 0;
      _commentCount = _likeManager.getCommentCount(recordId)
          ?? widget.feedData['commentCount']
          ?? 0;

      // 전역 상태 없으면 feedData로 초기화
      if (_likeManager.getLikedStatus(recordId) == null) {
        _likeManager.setInitialState(
          recordId,
          _isLiked,
          _likeCount,
          commentCount: _commentCount,
        );
      }
    } else {
      _isLiked = widget.feedData['isLiked'] ?? false;
      _likeCount = widget.feedData['likeCount'] ?? 0;
      _commentCount = widget.feedData['commentCount'] ?? 0;
    }

    // 전역 상태 변경 리스너 등록 (좋아요 + 댓글)
    _likeManager.addListener(_onGlobalStateChanged);
  }

  @override
  void dispose() {
    _likeManager.removeListener(_onGlobalStateChanged);
    super.dispose();
  }

  // 전역 상태 변경 감지 (좋아요 + 댓글 개수)
  void _onGlobalStateChanged() {
    final recordId = widget.feedData['recordId'] as int?;
    if (recordId != null) {
      final newIsLiked = _likeManager.getLikedStatus(recordId);
      final newLikeCount = _likeManager.getLikeCount(recordId);
      final newCommentCount = _likeManager.getCommentCount(recordId);

      if (newIsLiked != null && newLikeCount != null && newCommentCount != null) {
        if (_isLiked != newIsLiked || _likeCount != newLikeCount || _commentCount != newCommentCount) {
          setState(() {
            _isLiked = newIsLiked;
            _likeCount = newLikeCount;
            _commentCount = newCommentCount;
          });
          print('✅ [FeedItemWidget] 전역 상태 동기화: recordId=$recordId, commentCount=$newCommentCount');
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant FeedItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final recordId = widget.feedData['recordId'] as int?;
    if (recordId != null) {
      // 전역 상태 우선 확인
      final globalIsLiked = _likeManager.getLikedStatus(recordId);
      final globalLikeCount = _likeManager.getLikeCount(recordId);
      final globalCommentCount = _likeManager.getCommentCount(recordId);

      if (globalIsLiked != null && globalLikeCount != null && globalCommentCount != null) {
        // 전역 상태 사용 (더 최신)
        if (_isLiked != globalIsLiked || _likeCount != globalLikeCount || _commentCount != globalCommentCount) {
          setState(() {
            _isLiked = globalIsLiked;
            _likeCount = globalLikeCount;
            _commentCount = globalCommentCount;
          });
          print('📱 [FeedItem] 전역 상태 사용: recordId=$recordId, commentCount=$globalCommentCount');
        }
      } else {
        // 전역 상태 없으면 feedData 사용
        final newIsLiked = widget.feedData['isLiked'];
        final newLikeCount = widget.feedData['likeCount'];
        final newCommentCount = widget.feedData['commentCount'];

        if (newIsLiked != null && newLikeCount != null && newCommentCount != null) {
          if (_isLiked != newIsLiked || _likeCount != newLikeCount || _commentCount != newCommentCount) {
            setState(() {
              _isLiked = newIsLiked;
              _likeCount = newLikeCount;
              _commentCount = newCommentCount;
            });
            _likeManager.setInitialState(
              recordId,
              newIsLiked,
              newLikeCount,
              commentCount: newCommentCount,
            );
            print('📱 [FeedItem] feedData 사용: recordId=$recordId, commentCount=$newCommentCount');
          }
        }
      }
    }
  }

  Future<void> _toggleLike() async {
    final recordId = widget.feedData['recordId']?.toString();
    if (recordId == null) return;

    try {
      final result = await FeedApi.toggleLike(recordId);
      final isLiked = result['isLiked'] as bool;
      final likeCountRaw = result['likeCount'];
      final likeCount = likeCountRaw is int ? likeCountRaw : (likeCountRaw as num).toInt();

      // 🔥 전역 상태 업데이트 (모든 화면에 전파됨)
      _likeManager.updateLikeState(int.parse(recordId), isLiked, likeCount);

      // 로컬 상태도 업데이트 (즉각 반영)
      setState(() {
        _isLiked = isLiked;
        _likeCount = likeCount;
      });
    } catch (e) {
      print('❌ 좋아요 토글 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(
          left: scaleWidth(20),
          right: scaleWidth(20),
          bottom: scaleHeight(12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A9397A1),
              offset: Offset(0, 0),
              blurRadius: scaleWidth(16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            _buildContentSection(),
            _buildGameInfo(),
            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  // 프로필 섹션
  Widget _buildProfileSection() {
    final profileImageUrl = widget.feedData['profileImageUrl'] ?? widget.feedData['authorProfileImage'] ?? '';
    final nickname = widget.feedData['nickname'] ?? widget.feedData['authorNickname'] ?? '';
    final favTeam = widget.feedData['favTeam'] ?? widget.feedData['authorFavTeam'] ?? '';
    final userId = widget.feedData['userId'] ?? widget.feedData['authorId'];
    final createdAt = widget.feedData['createdAt'] ?? widget.feedData['gameDate'] ?? '';

    return Padding(
      padding: EdgeInsets.only(
        top: scaleHeight(20),
        left: scaleWidth(20),
        right: scaleWidth(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              try {
                final myProfile = await UserApi.getMyProfile();
                final myUserId = myProfile['data']['id'];

                if (userId == myUserId) {
                  // 이미 MyPageScreen에 있는지 확인
                  final currentRoute = ModalRoute.of(context);
                  final isOnMyPage = currentRoute?.settings.name == null &&
                      context.findAncestorWidgetOfExactType<MyPageScreen>() != null;

                  // 이미 마이페이지에 있으면 클릭 무시
                  if (isOnMyPage) {
                    return;
                  }

                  await Navigator.push(
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
                  widget.onProfileNavigated?.call();
                } else {
                  // 이미 FriendProfileScreen에 있는지 확인
                  final isOnFriendProfile = context.findAncestorWidgetOfExactType<FriendProfileScreen>() != null;

                  // 이미 친구 프로필 화면에 있으면 클릭 무시
                  if (isOnFriendProfile) {
                    return;
                  }

                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          FriendProfileScreen(userId: userId),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );

                  if (result != null && result is String) {
                    setState(() {
                      widget.feedData['followStatus'] = result;
                    });
                    widget.onProfileNavigated?.call();
                  }
                }
              } catch (e) {
                print('프로필 이동 실패: $e');
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 이미지
                Container(
                  width: scaleWidth(38),
                  height: scaleHeight(38),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray50, width: 1),
                    borderRadius: BorderRadius.circular(scaleWidth(19)),
                  ),
                  child: ClipRRect(
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
                ),
                SizedBox(width: scaleWidth(10)),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 닉네임 + 팀 배지
                    Row(
                      children: [
                        FixedText(
                          nickname,
                          style: AppFonts.pretendard.body_sm_500(context).copyWith(
                            color: AppColors.gray950,
                          ),
                        ),
                        if (favTeam.isNotEmpty && favTeam != '-' && favTeam != '응원팀 없음') ...[
                          SizedBox(width: scaleWidth(6)),
                          TeamUtils.buildTeamBadge(
                            context: context,
                            teamName: favTeam,
                            textStyle: AppFonts.pretendard.caption_sm_500(context),
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(7)),
                            borderRadius: scaleWidth(4),
                            height: scaleHeight(18),
                            suffix: ' 팬',
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: scaleHeight(2)),

                    // 작성 시간
                    FixedText(
                      TimeUtils.getTimeAgo(createdAt),
                      style: AppFonts.pretendard.caption_md_500(context).copyWith(
                        color: AppColors.gray300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 콘텐츠 섹션
  Widget _buildContentSection() {
    final photos = widget.feedData['mediaUrls'] as List? ?? [];
    final longContent = widget.feedData['longContent'] ?? '';
    final emotionLabel = widget.feedData['emotionLabel'] ?? _getEmotionLabel(widget.feedData['emotionCode'] ?? 0);

    if (photos.isNotEmpty) {
      // 사진이 있을 때
      if (longContent.isNotEmpty) {
        // 사진 + 야구일기
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(photos.cast<String>()),
            SizedBox(height: scaleHeight(10)),
            _buildLongContent(longContent, isPhotoPresent: true),
          ],
        );
      } else {
        // 사진만 (감정 표시 안 함)
        return _buildPhotoSection(photos.cast<String>());
      }
    } else if (longContent.isNotEmpty) {
      // 야구일기만
      return _buildLongContent(longContent);
    } else {
      // 감정만
      return _buildEmotionContent(emotionLabel);
    }
  }

  // 이미지 섹션
  Widget _buildPhotoSection(List<String> photos) {
    final photoCount = photos.length;

    if (photoCount == 1) {
      return Container(
        margin: EdgeInsets.only(
          top: scaleHeight(12),
          left: scaleWidth(20),
          right: scaleWidth(20),
        ),
        height: scaleHeight(153),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(photos[0]),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (photoCount == 2) {
      return Container(
        margin: EdgeInsets.only(
          top: scaleHeight(12),
          left: scaleWidth(20),
          right: scaleWidth(20),
        ),
        height: scaleHeight(153),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(photos[0]),
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
                    image: NetworkImage(photos[1]),
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
        margin: EdgeInsets.only(
          top: scaleHeight(12),
          left: scaleWidth(20),
        ),
        height: scaleHeight(153),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return Container(
              width: scaleWidth(118),
              margin: EdgeInsets.only(
                right: index < photos.length - 1 ? scaleWidth(8) : scaleWidth(20),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(photos[index]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  // 이모지
  Widget _buildEmotionContent(String emotionLabel, {bool isPhotoPresent = false}) {
    if (emotionLabel.isEmpty) return SizedBox.shrink();

    final topPadding = isPhotoPresent ? scaleHeight(0) : scaleHeight(12);
    final emotionCode = widget.feedData['emotionCode'] ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        left: scaleWidth(20),
        right: scaleWidth(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _getEmotionIcon(emotionCode),
          SizedBox(width: scaleWidth(8)),
          FixedText(
            emotionLabel,
            style: AppFonts.pretendard.body_sm_400(context).copyWith(
              color: Colors.black,
              fontSize: scaleFont(14),
            ),
          ),
        ],
      ),
    );
  }

// 감정 아이콘 가져오기
  Widget _getEmotionIcon(int emotionCode) {
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

    final iconPath = emotionImages[emotionCode];

    if (iconPath == null) {
      return SizedBox(
        width: scaleWidth(32),
        height: scaleHeight(32),
      );
    }

    return SvgPicture.asset(
      iconPath,
      width: scaleWidth(32),
      height: scaleHeight(32),
      fit: BoxFit.contain,
    );
  }

  // 야구 일기
  Widget _buildLongContent(String longContent, {bool isPhotoPresent = false}) {
    if (longContent.isEmpty) return SizedBox.shrink();

    final topPadding = isPhotoPresent ? scaleHeight(0) : scaleHeight(12);

    return Container(
      padding: EdgeInsets.only(
        top: topPadding,
        left: scaleWidth(20),
        right: scaleWidth(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final TextStyle textStyle = AppFonts.pretendard.body_sm_400(context).copyWith(
            color: Colors.black,
          );

          const String ellipsis = '...';
          final textDirection = Directionality.of(context);

          // 첫 줄의 실제 텍스트만 추출 (줄바꿈 기준)
          final firstNewlineIndex = longContent.indexOf('\n');
          final String firstLineText = firstNewlineIndex != -1
              ? longContent.substring(0, firstNewlineIndex)
              : longContent;

          // 첫 줄 텍스트의 실제 너비 측정
          final TextPainter firstLineWidthPainter = TextPainter(
            text: TextSpan(text: firstLineText, style: textStyle),
            textDirection: textDirection,
          );
          firstLineWidthPainter.layout(maxWidth: double.infinity);

          // 첫 줄이 실제로 길어서 넘치는 경우만 1줄 처리
          if (firstLineWidthPainter.width > constraints.maxWidth - scaleWidth(20)) {
            final TextPainter ellipsisPainter = TextPainter(
              text: TextSpan(text: ellipsis, style: textStyle),
              textDirection: textDirection,
            );
            ellipsisPainter.layout();

            final TextPainter firstLinePainter = TextPainter(
              text: TextSpan(text: firstLineText, style: textStyle),
              textDirection: textDirection,
            );
            firstLinePainter.layout(maxWidth: constraints.maxWidth);

            final int endIndex = firstLinePainter.getPositionForOffset(
              Offset(constraints.maxWidth - ellipsisPainter.width - scaleWidth(20), 0),
            ).offset;

            final String truncatedText = firstLineText.substring(0, endIndex).trimRight();

            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: truncatedText, style: textStyle),
                  TextSpan(text: ellipsis, style: textStyle),
                ],
              ),
              maxLines: 1,
            );
          }

          // 첫 줄이 안 넘치면 2줄로 체크
          final TextPainter twoLinePainter = TextPainter(
            text: TextSpan(text: longContent, style: textStyle),
            maxLines: 2,
            textDirection: textDirection,
          );
          twoLinePainter.layout(maxWidth: constraints.maxWidth);

          // 전체 텍스트를 무제한으로 렌더링하여 실제 줄 수 확인
          final TextPainter fullPainter = TextPainter(
            text: TextSpan(text: longContent, style: textStyle),
            textDirection: textDirection,
          );
          fullPainter.layout(maxWidth: constraints.maxWidth);

          // 2줄을 초과하지 않으면 그대로 표시
          if (fullPainter.height <= twoLinePainter.height + 1.0) {
            return Text(
              longContent,
              style: textStyle,
            );
          }

          // 2줄을 초과하므로 ... 처리
          final TextPainter ellipsisPainter = TextPainter(
            text: TextSpan(text: ellipsis, style: textStyle),
            textDirection: textDirection,
          );
          ellipsisPainter.layout();

          // 2줄 레이아웃에서 마지막에 표시할 수 있는 문자 위치 찾기
          final double secondLineY = twoLinePainter.height - (textStyle.fontSize ?? 14) / 2;

          final int endIndex = twoLinePainter.getPositionForOffset(
            Offset(
              constraints.maxWidth - ellipsisPainter.width,
              secondLineY,
            ),
          ).offset;

          String truncatedText = longContent.substring(0, endIndex).trimRight();

          // 혹시 truncatedText가 비어있으면 첫 줄만 표시
          if (truncatedText.isEmpty || truncatedText == firstLineText.trimRight()) {
            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: firstLineText, style: textStyle),
                  TextSpan(text: '\n$ellipsis', style: textStyle),
                ],
              ),
              maxLines: 2,
            );
          }

          return RichText(
            text: TextSpan(
              children: [
                TextSpan(text: truncatedText, style: textStyle),
                TextSpan(text: ellipsis, style: textStyle),
              ],
            ),
            maxLines: 2,
          );
        },
      ),
    );
  }

  // 경기 정보
  Widget _buildGameInfo() {
    final homeTeam = _extractShortTeamName(widget.feedData['homeTeam'] ?? '');
    final awayTeam = _extractShortTeamName(widget.feedData['awayTeam'] ?? '');

    if (homeTeam.isEmpty || awayTeam.isEmpty) return SizedBox.shrink();

    final homeTeamFull = _teamFullNames[homeTeam] ?? widget.feedData['homeTeam'];
    final awayTeamFull = _teamFullNames[awayTeam] ?? widget.feedData['awayTeam'];

    final photos = widget.feedData['mediaUrls'] as List? ?? [];
    final longContent = widget.feedData['longContent'] ?? '';
    final emotionLabel = widget.feedData['emotionLabel'] ?? _getEmotionLabel(widget.feedData['emotionCode'] ?? 0);

    double topSpacing;
    if (photos.isNotEmpty && longContent.isEmpty && emotionLabel.isEmpty) {
      // 사진만 있을 때
      topSpacing = scaleHeight(14);
    } else {
      // 나머지 모든 경우
      topSpacing = scaleHeight(10);
    }

    return Padding(
      padding: EdgeInsets.only(
        top: topSpacing,
        left: scaleWidth(20),
        right: scaleWidth(20),
      ),
      child: Container(
        width: double.infinity,
        height: scaleHeight(40),
        decoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleWidth(6)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getTeamLogo(homeTeam),
            SizedBox(width: scaleWidth(8)),
            FixedText(
              '$homeTeamFull VS $awayTeamFull',
              style: AppFonts.pretendard.caption_md_500(context).copyWith(
                color: AppColors.gray500,
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            _getTeamLogo(awayTeam),
          ],
        ),
      ),
    );
  }

  Widget _getTeamLogo(String team) {
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
    if (logoPath == null) return SizedBox(width: scaleWidth(24), height: scaleHeight(24));

    return Image.asset(logoPath, width: scaleWidth(24), height: scaleHeight(24), fit: BoxFit.contain);
  }


  // 좋아요, 댓글, 구장명 등
  Widget _buildBottomInfo() {
    final stadium = _extractShortStadiumName(widget.feedData['stadium'] ?? '');
    final gameDate = widget.feedData['gameDate'] ?? '';
    final stadiumFull = _getStadiumFullName(stadium);
    final formattedDate = _formatGameDate(gameDate);

    return Container(
      padding: EdgeInsets.only(
        top: scaleHeight(10),
        bottom: scaleHeight(16),
        left: scaleWidth(20),
        right: scaleWidth(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: scaleHeight(4),
                horizontal: scaleWidth(4),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    _isLiked ? AppImages.heart_filled : AppImages.heart_outlined,
                    width: scaleWidth(16),
                    height: scaleHeight(16),
                  ),
                  SizedBox(width: scaleWidth(4)),
                  FixedText(
                    _likeCount.toString(),
                    style: AppFonts.pretendard.caption_md_400(context).copyWith(
                      color: AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: scaleWidth(12)),
          Row(
            children: [
              SvgPicture.asset(
                AppImages.comment,
                width: scaleWidth(16),
                height: scaleHeight(16),
              ),
              SizedBox(width: scaleWidth(4)),
              FixedText(
                _commentCount.toString(),
                style: AppFonts.pretendard.caption_md_400(context).copyWith(
                  color: AppColors.gray300,
                ),
              ),
            ],
          ),
          Spacer(),
          Row(
            children: [
              FixedText(
                formattedDate,
                style: AppFonts.pretendard.caption_re_400(context).copyWith(
                  color: AppColors.gray400,
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
                stadiumFull,
                style: AppFonts.pretendard.caption_re_400(context).copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ],
      ),
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

  String _extractShortStadiumName(String fullStadiumName) {
    if (fullStadiumName.contains('잠실')) return '잠실';
    if (fullStadiumName.contains('고척')) return '고척';
    if (fullStadiumName.contains('수원')) return '수원';
    if (fullStadiumName.contains('대구')) return '대구';
    if (fullStadiumName.contains('광주')) return '광주';
    if (fullStadiumName.contains('창원')) return '창원';
    if (fullStadiumName.contains('사직')) return '사직';
    if (fullStadiumName.contains('대전')) return '대전';
    if (fullStadiumName.contains('인천')) return '인천';
    return fullStadiumName;
  }

  String _getStadiumFullName(String stadium) {
    return _stadiumFullNames[stadium] ?? stadium;
  }

  String _formatGameDate(String gameDate) {
    if (gameDate.isEmpty) return '';
    try {
      if (gameDate.contains('년')) {
        final dateOnly = gameDate.split('(')[0].trim();
        return dateOnly.replaceAllMapped(
          RegExp(r'년 0(\d)월'),
              (match) => '년 ${match.group(1)}월',
        );
      }
      final date = DateTime.parse(gameDate);
      return DateFormat('yyyy년 M월 d일').format(date);
    } catch (e) {
      return gameDate;
    }
  }

  String _getEmotionLabel(int emotionCode) {
    switch (emotionCode) {
      case 1: return '행복해요';
      case 2: return '놀랐어요';
      case 3: return '짜릿해요';
      case 4: return '벅차요';
      case 5: return '통쾌해요';
      case 6: return '만족해요';
      case 7: return '지루해요';
      case 8: return '무난해요';
      case 9: return '긴장돼요';
      case 10: return '질투나요';
      case 11: return '답답해요';
      case 12: return '아쉬워요';
      case 13: return '지쳤어요';
      case 14: return '허탈해요';
      case 15: return '짜증나요';
      case 16: return '화나요';
      default: return '';
    }
  }
}