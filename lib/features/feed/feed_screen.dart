import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/features/feed/search_screen.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:intl/intl.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _indicatorAnimation;
  late PageController _pageController;

  late ScrollController _recommendScrollController;
  late ScrollController _followingScrollController;

  double _currentPageValue = 0.0;
  bool _isPageViewScrolling = false;
  int _selectedTabIndex = 0;

  List<Map<String, dynamic>> _recommendFeedItems = [];
  List<Map<String, dynamic>> _followingFeedItems = [];
  bool _isLoadingRecommend = true;
  bool _isLoadingFollowing = true;

  int _recommendCurrentPage = 0;
  int _followingCurrentPage = 0;
  bool _isLoadingMoreRecommend = false;
  bool _isLoadingMoreFollowing = false;
  bool _hasMoreRecommend = true;
  bool _hasMoreFollowing = true;

  Map<String, bool> _likedStatus = {};
  Map<String, int> _likeCounts = {};

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );

    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pageController = PageController(initialPage: 0);
    _currentPageValue = 0.0;

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPageValue = _pageController.page ?? 0.0;
          _isPageViewScrolling = true;
        });
      }
    });

    _loadRecommendFeed();
    _loadFollowingFeed();
  }

  //추천 피드 로드
  Future<void> _loadRecommendFeed() async {
    try {
      final feeds = await FeedApi.getAllFeed(page: 0, size: 20);
      setState(() {
        _recommendFeedItems = feeds;
        _isLoadingRecommend = false;
        _recommendCurrentPage = 0;
        _hasMoreRecommend = feeds.length >= 20;
      });

      for (var feed in feeds) {
        if (feed['recordId'] != null) {
          final recordId = feed['recordId'].toString();
          _likedStatus[recordId] = feed['isLiked'] ?? false;
          _likeCounts[recordId] = feed['likeCount'] ?? 0;
        }
      }
    } catch (e) {
      print('추천 피드 로드 실패: $e');
      setState(() {
        _isLoadingRecommend = false;
      });
    }
  }

  Future<void> _loadMoreRecommendFeed() async {
    if (_isLoadingMoreRecommend || !_hasMoreRecommend) return;

    setState(() {
      _isLoadingMoreRecommend = true;
    });

    try {
      final nextPage = _recommendCurrentPage + 1;
      final feeds = await FeedApi.getAllFeed(page: nextPage, size: 20);

      setState(() {
        if (feeds.isEmpty) {
          _hasMoreRecommend = false;
        } else {
          _recommendFeedItems.addAll(feeds);
          _recommendCurrentPage = nextPage;
          _hasMoreRecommend = feeds.length >= 20;

          for (var feed in feeds) {
            if (feed['recordId'] != null) {
              final recordId = feed['recordId'].toString();
              _likedStatus[recordId] = feed['isLiked'] ?? false;
              _likeCounts[recordId] = feed['likeCount'] ?? 0;
            }
          }
        }
        _isLoadingMoreRecommend = false;
      });
    } catch (e) {
      print('추천 피드 추가 로드 실패: $e');
      setState(() {
        _isLoadingMoreRecommend = false;
      });
    }
  }

  //팔로잉 피드 로드
  Future<void> _loadFollowingFeed() async {
    try {
      final feeds = await FeedApi.getFollowingFeed(page: 0, size: 20);
      setState(() {
        _followingFeedItems = feeds;
        _isLoadingFollowing = false;
        _followingCurrentPage = 0;
        _hasMoreFollowing = feeds.length >= 20;
      });

      for (var feed in feeds) {
        if (feed['recordId'] != null) {
          final recordId = feed['recordId'].toString();
          _likedStatus[recordId] = feed['isLiked'] ?? false;
          _likeCounts[recordId] = feed['likeCount'] ?? 0;
        }
      }
    } catch (e) {
      print('팔로잉 피드 로드 실패: $e');
      setState(() {
        _isLoadingFollowing = false;
      });
    }
  }

  Future<void> _loadMoreFollowingFeed() async {
    if (_isLoadingMoreFollowing || !_hasMoreFollowing) return;

    setState(() {
      _isLoadingMoreFollowing = true;
    });

    try {
      final nextPage = _followingCurrentPage + 1;
      final feeds = await FeedApi.getFollowingFeed(page: nextPage, size: 20);

      setState(() {
        if (feeds.isEmpty) {
          _hasMoreFollowing = false;
        } else {
          _followingFeedItems.addAll(feeds);
          _followingCurrentPage = nextPage;
          _hasMoreFollowing = feeds.length >= 20;

          for (var feed in feeds) {
            if (feed['recordId'] != null) {
              final recordId = feed['recordId'].toString();
              _likedStatus[recordId] = feed['isLiked'] ?? false;
              _likeCounts[recordId] = feed['likeCount'] ?? 0;
            }
          }
        }
        _isLoadingMoreFollowing = false;
      });
    } catch (e) {
      print('팔로잉 피드 추가 로드 실패: $e');
      setState(() {
        _isLoadingMoreFollowing = false;
      });
    }
  }

  // 좋아요 토글 처리
  Future<void> _toggleLike(String recordId) async {
    try {
      print('🔍 [시작] recordId: $recordId');
      print('📊 [현재상태] isLiked: ${_likedStatus[recordId]}, count: ${_likeCounts[recordId]}');

      final result = await FeedApi.toggleLike(recordId);

      final isLiked = result['isLiked'] as bool;
      final likeCountRaw = result['likeCount'];
      final likeCount = likeCountRaw is int ? likeCountRaw : (likeCountRaw as num).toInt();

      print('✅ [파싱완료] isLiked: $isLiked, likeCount: $likeCount');

      setState(() {
        _likedStatus[recordId] = isLiked;
        _likeCounts[recordId] = likeCount;
      });

      print('🎯 [최종상태] isLiked: ${_likedStatus[recordId]}, count: ${_likeCounts[recordId]}');
    } catch (e, stackTrace) {
      print('❌ [에러] $e');
      print('📚 [스택] $stackTrace');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  ///===================================================
  /// 탭 처리
  ///===================================================
  void _onPageChanged(int index) {
    setState(() {
      _isPageViewScrolling = false;
      _selectedTabIndex = index;
    });

    if (index == 1) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _isPageViewScrolling = false;
    });

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (index == 1) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Color _getTabColor(int tabIndex) {
    final progress = (_currentPageValue - tabIndex).abs();
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    if (tabIndex == 0) {
      return Color.lerp(AppColors.gray300, AppColors.gray600, opacity) ?? AppColors.gray600;
    } else {
      return Color.lerp(AppColors.gray300, AppColors.gray600, opacity) ?? AppColors.gray600;
    }
  }

  Widget _buildRealtimeIndicator() {
    final screenWidth = MediaQuery.of(context).size.width - scaleWidth(40);
    final tabWidth = screenWidth / 2;

    final scrollProgress = _currentPageValue.clamp(0.0, 1.0);
    final indicatorOffset = scrollProgress * tabWidth;

    return Container(
      width: double.infinity,
      height: scaleHeight(2),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: _isPageViewScrolling ? Duration.zero : Duration(milliseconds: 250),
            left: indicatorOffset,
            bottom: 0,
            child: Container(
              width: tabWidth,
              height: scaleHeight(2),
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Column(
      children: [
        Container(
          height: scaleHeight(36),
          margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabTapped(0),
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: FixedText(
                              '추천',
                              style: AppFonts.suite.body_sm_500(context).copyWith(
                                color: _getTabColor(0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabTapped(1),
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: FixedText(
                              '팔로잉',
                              style: AppFonts.suite.body_sm_500(context).copyWith(
                                color: _getTabColor(1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildRealtimeIndicator(),
            ],
          ),
        ),
        Container(
          height: 1.0,
          width: double.infinity,
          color: AppColors.gray50,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: false,
                floating: false,
                expandedHeight: scaleHeight(60),
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: EdgeInsets.only(
                      top: scaleHeight(22),
                      left: scaleWidth(20),
                      right: scaleWidth(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(top: scaleHeight(2)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FixedText(
                            '피드',
                            style: AppFonts.suite.h3_b(context).copyWith(color: Colors.black),
                          ),
                          SizedBox(width: scaleWidth(11)),
                          SvgPicture.asset(
                            AppImages.filter,
                            width: scaleWidth(28),
                            height: scaleHeight(28),
                            fit: BoxFit.contain,
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(top: scaleHeight(2)),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => const SearchScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              },
                              child: SvgPicture.asset(
                                AppImages.search,
                                width: scaleWidth(24),
                                height: scaleHeight(24),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  child: Container(
                    color: Colors.white,
                    child: _buildTabBar(),
                  ),
                  height: scaleHeight(39),
                ),
              ),
            ];
          },
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildRecommendTab(),
              _buildFollowingTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildRecommendTab() {
    if (_isLoadingRecommend) {
      return Center(child: CircularProgressIndicator());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          if (!_isLoadingMoreRecommend && _hasMoreRecommend) {
            _loadMoreRecommendFeed();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.only(top: scaleHeight(21)),
        itemCount: _recommendFeedItems.length + (_hasMoreRecommend ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _recommendFeedItems.length) {
            return _buildLoadingIndicator();
          }
          return _buildFeedItem(_recommendFeedItems[index]);
        },
      ),
    );
  }

  Widget _buildFollowingTab() {
    if (_isLoadingFollowing) {
      return Center(child: CircularProgressIndicator());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          if (!_isLoadingMoreFollowing && _hasMoreFollowing) {
            _loadMoreFollowingFeed();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.only(top: scaleHeight(21)),
        itemCount: _followingFeedItems.length + (_hasMoreFollowing ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _followingFeedItems.length) {
            return _buildLoadingIndicator();
          }
          return _buildFeedItem(_followingFeedItems[index]);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(20)),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }

  ///===================================================
  /// 피드 아이템에 대한 처리
  ///===================================================
  Widget _buildFeedItem(Map<String, dynamic> feedData) {
    final recordId = feedData['recordId']?.toString() ?? '';
    final isLiked = _likedStatus[recordId] ?? feedData['isLiked'] ?? false;
    final likeCount = _likeCounts[recordId] ?? feedData['likeCount'] ?? 0;
    final commentCount = feedData['commentCount'] ?? 0;

    return Container(
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
          _buildProfileSection(feedData),
          _buildContentSection(feedData),
          _buildGameInfo(feedData),
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
          _buildBottomInfo(feedData, recordId, isLiked, likeCount, commentCount),
        ],
      ),
    );
  }

  //프로필 세션
  Widget _buildProfileSection(Map<String, dynamic> feedData) {
    final profileImageUrl = feedData['profileImageUrl'] ?? '';
    final nickname = feedData['nickname'] ?? '';
    final favTeam = feedData['favTeam'] ?? '';
    final favTeamWithFan = favTeam.isNotEmpty ? '$favTeam 팬' : '';

    return Padding(
      padding: EdgeInsets.only(
        top: scaleHeight(16),
        left: scaleWidth(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: scaleWidth(36),
            height: scaleHeight(36),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gray100,
              image: profileImageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(profileImageUrl),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: profileImageUrl.isEmpty
                ? Icon(Icons.person, color: AppColors.gray400, size: scaleWidth(20))
                : null,
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
    );
  }

  // 콘텐츠 세션
  Widget _buildContentSection(Map<String, dynamic> feedData) {
    final photos = feedData['mediaUrls'] as List<dynamic>? ?? [];
    final longContent = feedData['longContent'] ?? '';
    final emotionLabel = feedData['emotionLabel'] ?? '';

    // 사진이 있을 경우 (총 간격: 프로필-사진 12px + 사진-텍스트 10px)
    if (photos.isNotEmpty) {
      // 텍스트/감정 위젯의 상단 패딩을 0으로
      final contentWidget = longContent.isNotEmpty
          ? _buildLongContent(longContent, isPhotoPresent: true)
          : _buildEmotionContent(emotionLabel, isPhotoPresent: true);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoSection(photos), // 사진 섹션
          // 사진과 텍스트/감정 사이 간격 (10px)
          if (longContent.isNotEmpty || emotionLabel.isNotEmpty)
            SizedBox(height: scaleHeight(10)),
          contentWidget,
        ],
      );
    }
    // 사진이 없을 경우 (총 간격: 프로필-텍스트/감정 16px)
    else if (longContent.isNotEmpty) {
      return _buildLongContent(longContent);
    } else {
      return _buildEmotionContent(emotionLabel);
    }
  }

  //사진 세션
  Widget _buildPhotoSection(List<dynamic> photos) {
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
          top: scaleHeight(16),
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
          top: scaleHeight(16),
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

  // 감정 라벨
  Widget _buildEmotionContent(String emotionLabel, {bool isPhotoPresent = false}) {
    if (emotionLabel.isEmpty) return SizedBox.shrink();

    // 사진이 있으면 0px (10px은 위에서 줌), 없으면 16px
    final topPadding = isPhotoPresent ? scaleHeight(0) : scaleHeight(16);

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding, // 상단 간격 설정
        left: scaleWidth(16),
        right: scaleWidth(16),
      ),
      child: FixedText(
        emotionLabel,
        style: AppFonts.pretendard.body_sm_400(context).copyWith(
          color: Colors.black,
        ),
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

  //게임 정보
  Widget _buildGameInfo(Map<String, dynamic> feedData) {
    final homeTeam = feedData['homeTeam'] ?? '';
    final awayTeam = feedData['awayTeam'] ?? '';

    if (homeTeam.isEmpty || awayTeam.isEmpty) return SizedBox.shrink();

    final homeTeamFull = _teamFullNames[homeTeam] ?? homeTeam;
    final awayTeamFull = _teamFullNames[awayTeam] ?? awayTeam;

    return Padding(
      padding: EdgeInsets.only(top: scaleHeight(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getTeamLogo(homeTeam),
          SizedBox(width: scaleWidth(4)),
          FixedText(
            '$homeTeamFull VS $awayTeamFull',
            style: AppFonts.suite.caption_md_500(context).copyWith(
              color: AppColors.gray400,
            ),
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

    return Image.asset(
      logoPath,
      width: scaleWidth(18),
      height: scaleHeight(18),
      fit: BoxFit.contain,
    );
  }

  Widget _buildBottomInfo(
      Map<String, dynamic> feedData,
      String recordId,
      bool isLiked,
      int likeCount,
      int commentCount,
      ) {
    final stadium = feedData['stadium'] ?? '';
    final gameDate = feedData['gameDate'] ?? '';

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
            onTap: () => _toggleLike(recordId),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: scaleHeight(4),
                horizontal: scaleWidth(4),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    isLiked ? AppImages.heart_filled : AppImages.heart_outlined,
                    width: scaleWidth(16),
                    height: scaleHeight(16),
                  ),
                  SizedBox(width: scaleWidth(4)),
                  FixedText(
                    likeCount.toString(),
                    style: AppFonts.suite.caption_re_400(context).copyWith(
                      color: AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: scaleWidth(8)),
          Row(
            children: [
              SvgPicture.asset(
                AppImages.comment,
                width: scaleWidth(16),
                height: scaleHeight(16),
              ),
              SizedBox(width: scaleWidth(4)),
              FixedText(
                commentCount.toString(),
                style: AppFonts.suite.caption_re_400(context).copyWith(
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
                stadiumFull,
                style: AppFonts.suite.caption_re_400(context).copyWith(
                  color: AppColors.gray300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStadiumFullName(String stadium) {
    return _stadiumFullNames[stadium] ?? stadium;
  }

  String _formatGameDate(String gameDate) {
    if (gameDate.isEmpty) return '';

    try {
      // 백엔드에서 "2025년 03월 23일 (Sun)요일" 형식으로 오는 경우
      if (gameDate.contains('년')) {
        // "2025년 03월 23일 (Sun)요일" -> "2025년 3월 23일"
        final dateOnly = gameDate.split('(')[0].trim();

        // 정규식으로 0으로 시작하는 월 변환
        final formatted = dateOnly.replaceAllMapped(
          RegExp(r'년 0(\d)월'),
              (match) => '년 ${match.group(1)}월',
        );

        return formatted;
      }

      // ISO 형식인 경우
      final date = DateTime.parse(gameDate);
      return DateFormat('yyyy년 M월 d일').format(date);
    } catch (e) {
      return gameDate;
    }
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyTabBarDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }
  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}