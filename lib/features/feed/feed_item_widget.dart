import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:intl/intl.dart';
import 'package:frontend/utils/like_state_manager.dart';

/// 피드/검색 화면에서 공통으로 사용하는 피드 아이템 위젯
class FeedItemWidget extends StatefulWidget {
  final Map<String, dynamic> feedData;
  final VoidCallback? onTap;

  const FeedItemWidget({
    Key? key,
    required this.feedData,
    this.onTap,
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
    '잠실': '잠실야구장',
    '고척': '고척스카이돔',
    '수원': '수원KT위즈파크',
    '대구': '대구삼성라이온즈파크',
    '광주': '광주-기아챔피언스필드',
    '창원': '창원NC파크',
    '사직': '사직야구장',
    '대전': '대전한화생명이글스파크',
    '인천': '인천SSG랜더스필드',
  };

  final _likeManager = LikeStateManager();

  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();

    final recordId = widget.feedData['recordId'] as int?;
    if (recordId != null) {
      // 🔥 전역 상태 우선 확인
      _isLiked = _likeManager.getLikedStatus(recordId) ?? widget.feedData['isLiked'] ?? false;
      _likeCount = _likeManager.getLikeCount(recordId) ?? widget.feedData['likeCount'] ?? 0;

      // 초기값 전역 상태에 등록
      _likeManager.setInitialState(recordId, _isLiked, _likeCount);
    } else {
      _isLiked = widget.feedData['isLiked'] ?? false;
      _likeCount = widget.feedData['likeCount'] ?? 0;
    }

    // 🔥 전역 상태 변경 리스닝
    _likeManager.addListener(_onGlobalLikeStateChanged);
  }

  @override
  void dispose() {
    _likeManager.removeListener(_onGlobalLikeStateChanged);
    super.dispose();
  }

  // 🔥 전역 상태 변경 감지
  void _onGlobalLikeStateChanged() {
    final recordId = widget.feedData['recordId'] as int?;
    if (recordId != null) {
      final newIsLiked = _likeManager.getLikedStatus(recordId);
      final newLikeCount = _likeManager.getLikeCount(recordId);

      if (newIsLiked != null && newLikeCount != null) {
        if (_isLiked != newIsLiked || _likeCount != newLikeCount) {
          setState(() {
            _isLiked = newIsLiked;
            _likeCount = newLikeCount;
          });
          print('✅ [FeedItemWidget] 전역 상태 동기화: recordId=$recordId');
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant FeedItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // feedData가 변경되어도 전역 상태 우선
    final recordId = widget.feedData['recordId'] as int?;
    if (recordId != null) {
      final globalIsLiked = _likeManager.getLikedStatus(recordId);
      final globalLikeCount = _likeManager.getLikeCount(recordId);

      if (globalIsLiked != null && globalLikeCount != null) {
        if (_isLiked != globalIsLiked || _likeCount != globalLikeCount) {
          setState(() {
            _isLiked = globalIsLiked;
            _likeCount = globalLikeCount;
          });
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
    final commentCount = widget.feedData['commentCount'] ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: scaleWidth(20),
          right: scaleWidth(20),
          bottom: scaleHeight(12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.gray50, width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            _buildContentSection(),
            _buildGameInfo(),
            Container(
              margin: EdgeInsets.only(
                top: scaleHeight(10),
                left: scaleWidth(16),
                right: scaleWidth(16),
              ),
              height: 1,
              color: AppColors.gray50,
              width: double.infinity,
            ),
            _buildBottomInfo(commentCount),
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
    final favTeamWithFan = favTeam.isNotEmpty ? '$favTeam 팬' : '';

    return GestureDetector(
      onTap: () {
        print('프로필 클릭: $nickname');
      },
      behavior: HitTestBehavior.opaque, //프로필 섹션 - 이벤트 전파 차단 (클릭되면 프로필 들어가야 하니까)
      child: Padding(
        padding: EdgeInsets.only(
          top: scaleHeight(16),
          left: scaleWidth(16),
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
                  favTeamWithFan,
                  style: AppFonts.pretendard.caption_md_400(context).copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 콘텐츠 섹션
  Widget _buildContentSection() {
    final photos = widget.feedData['mediaUrls'] as List<dynamic>? ?? [];
    final longContent = widget.feedData['longContent'] ?? '';
    final emotionLabel = widget.feedData['emotionLabel'] ?? _getEmotionLabel(widget.feedData['emotionCode'] ?? 0);

    if (photos.isNotEmpty) {
      final contentWidget = longContent.isNotEmpty
          ? _buildLongContent(longContent, isPhotoPresent: true)
          : _buildEmotionContent(emotionLabel, isPhotoPresent: true);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoSection(photos.cast<String>()),
          if (longContent.isNotEmpty || emotionLabel.isNotEmpty)
            SizedBox(height: scaleHeight(10)),
          contentWidget,
        ],
      );
    } else if (longContent.isNotEmpty) {
      return _buildLongContent(longContent);
    } else {
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
          left: scaleWidth(16),
          right: scaleWidth(16),
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
          left: scaleWidth(16),
          right: scaleWidth(16),
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
          left: scaleWidth(16),
        ),
        height: scaleHeight(153),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return Container(
              width: scaleWidth(118),
              margin: EdgeInsets.only(
                right: index < photos.length - 1 ? scaleWidth(8) : scaleWidth(16),
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
    final topPadding = isPhotoPresent ? scaleHeight(0) : scaleHeight(16);

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        left: scaleWidth(16),
        right: scaleWidth(16),
      ),
      child: FixedText(
        emotionLabel,
        style: AppFonts.pretendard.body_sm_400(context).copyWith(color: Colors.black),
      ),
    );
  }

  // 야구 일기
  Widget _buildLongContent(String longContent, {bool isPhotoPresent = false}) {
    if (longContent.isEmpty) return SizedBox.shrink();

    final topPadding = isPhotoPresent ? scaleHeight(0) : scaleHeight(16);

    return Container(
      padding: EdgeInsets.only(
        top: topPadding,
        left: scaleWidth(16),
        right: scaleWidth(16),
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
          if (firstLineWidthPainter.width > constraints.maxWidth) {
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
              Offset(constraints.maxWidth - ellipsisPainter.width, 0),
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

    return Padding(
      padding: EdgeInsets.only(top: scaleHeight(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getTeamLogo(homeTeam),
          SizedBox(width: scaleWidth(4)),
          FixedText(
            '$homeTeamFull VS $awayTeamFull',
            style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray400),
          ),
          SizedBox(width: scaleWidth(4)),
          _getTeamLogo(awayTeam),
        ],
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
    if (logoPath == null) return SizedBox(width: scaleWidth(18), height: scaleHeight(18));

    return Image.asset(logoPath, width: scaleWidth(18), height: scaleHeight(18), fit: BoxFit.contain);
  }

  Widget _buildBottomInfo(int commentCount) {
    final stadium = _extractShortStadiumName(widget.feedData['stadium'] ?? '');
    final gameDate = widget.feedData['gameDate'] ?? '';

    final stadiumFull = _getStadiumFullName(stadium);
    final formattedDate = _formatGameDate(gameDate);

    return Container(
      padding: EdgeInsets.only(
        top: scaleHeight(9),
        bottom: scaleHeight(16),
        left: scaleWidth(16),
        right: scaleWidth(17),
      ),
      child: Row(
        children: [
          GestureDetector(
            // 좋아요 버튼 - 이벤트 전파 차단
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
                    style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: scaleWidth(8)),
          Row(
            children: [
              SvgPicture.asset(AppImages.comment, width: scaleWidth(16), height: scaleHeight(16)),
              SizedBox(width: scaleWidth(4)),
              FixedText(
                commentCount.toString(),
                style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
              ),
            ],
          ),
          Spacer(),
          Row(
            children: [
              FixedText(
                formattedDate,
                style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
              ),
              SizedBox(width: scaleWidth(4)),
              SvgPicture.asset(AppImages.ellipse, width: scaleWidth(2), height: scaleHeight(2)),
              SizedBox(width: scaleWidth(4)),
              FixedText(
                stadiumFull,
                style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
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
      case 1: return '짜릿해요';
      case 2: return '만족해요';
      case 3: return '감동이에요';
      case 4: return '놀라워요';
      case 5: return '행복해요';
      case 6: return '답답해요';
      case 7: return '아쉬워요';
      case 8: return '화났어요';
      case 9: return '지쳤어요';
      default: return '';
    }
  }
}