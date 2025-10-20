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
import 'package:frontend/features/feed/detail_feed_screen.dart';
import 'package:frontend/features/feed/feed_item_widget.dart';
import 'package:frontend/utils/like_state_manager.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _indicatorAnimation;
  late PageController _pageController;

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

  // 전역 상태 매니저
  final _likeManager = LikeStateManager();

  // 필터링 관련 - 다중 선택
  Set<String> _selectedTeamFilters = {};

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

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
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

      _likeManager.setInitialStates(feeds); //전역 상태에 일괄 등록
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

          _likeManager.setInitialStates(feeds); //전역 상태에 일괄 등록
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

      _likeManager.setInitialStates(feeds);
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

          _likeManager.setInitialStates(feeds);
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


  // 필터링된 추천 피드 가져오기
  List<Map<String, dynamic>> _getFilteredRecommendItems() {
    // ALL이 선택되었거나 아무것도 선택되지 않은 경우
    if (_selectedTeamFilters.isEmpty || _selectedTeamFilters.contains('ALL')) {
      return _recommendFeedItems;
    }

    // 선택된 팀들로 필터링
    return _recommendFeedItems.where((item) {
      final homeTeam = item['homeTeam'] ?? '';
      return _selectedTeamFilters.contains(homeTeam);
    }).toList();
  }

  // 필터 액션시트 표시
  Future<void> _showFilterSheet() async {
    final teams = [
      {'name': 'ALL', 'image': AppImages.logo_dodada},
      {'name': '두산', 'image': AppImages.bears},
      {'name': '롯데', 'image': AppImages.giants},
      {'name': '삼성', 'image': AppImages.lions},
      {'name': '키움', 'image': AppImages.kiwoom},
      {'name': '한화', 'image': AppImages.eagles},
      {'name': 'KIA', 'image': AppImages.tigers},
      {'name': 'KT', 'image': AppImages.ktwiz},
      {'name': 'LG', 'image': AppImages.twins},
      {'name': 'NC', 'image': AppImages.dinos},
      {'name': 'SSG', 'image': AppImages.landers},
    ];

    final allTeamsExceptAll = teams.where((t) => t['name'] != 'ALL').map((t) => t['name']!).toSet();

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        Set<String> selected = Set.from(_selectedTeamFilters);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                child: Container(
                  height: scaleHeight(401),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(scaleHeight(20)),
                  ),
                  padding: EdgeInsets.all(scaleWidth(18)),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: scaleWidth(54),
                          height: scaleHeight(5),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(scaleHeight(6)),
                          ),
                        ),
                      ),
                      SizedBox(height: scaleHeight(16)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FixedText(
                          '구단',
                          style: AppFonts.suite.head_sm_700(context).copyWith(
                            color: AppColors.gray800,
                          ),
                        ),
                      ),
                      SizedBox(height: scaleHeight(8)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: scaleWidth(31),
                          height: scaleHeight(2),
                          color: AppColors.gray800,
                        ),
                      ),
                      SizedBox(height: scaleHeight(16)),
                      Expanded(
                        child: GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: scaleWidth(8),
                            mainAxisSpacing: scaleHeight(12),
                            childAspectRatio: (scaleWidth(88) / scaleHeight(44)),
                          ),
                          itemCount: teams.length,
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            final teamName = team['name']!;
                            final teamImage = team['image']!;
                            final isSelected = selected.contains(teamName);

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (teamName == 'ALL') {
                                    // ALL 선택: 다른 모든 선택 취소하고 ALL만 선택
                                    if (selected.contains('ALL')) {
                                      selected.remove('ALL');
                                    } else {
                                      selected.clear();
                                      selected.add('ALL');
                                    }
                                  } else {
                                    // 일반 팀 선택
                                    if (selected.contains(teamName)) {
                                      selected.remove(teamName);
                                    } else {
                                      // ALL이 선택되어 있으면 먼저 제거
                                      selected.remove('ALL');
                                      selected.add(teamName);

                                      // 모든 팀을 선택했는지 확인
                                      if (selected.containsAll(allTeamsExceptAll)) {
                                        selected.clear();
                                        selected.add('ALL');
                                      }
                                    }
                                  }
                                });
                              },
                              child: Container(
                                height: scaleHeight(44),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.gray700 : AppColors.gray50,
                                  borderRadius: BorderRadius.circular(scaleHeight(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      teamImage,
                                      width: scaleWidth(28),
                                      height: scaleHeight(28),
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(width: scaleWidth(4)),
                                    FixedText(
                                      teamName,
                                      style: AppFonts.suite.body_sm_500(context).copyWith(
                                        color: isSelected ? AppColors.gray20 : AppColors.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: scaleHeight(16)),
                      Row(
                        children: [
                          Expanded(
                            flex: 12,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, <String>{});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gray50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(scaleHeight(16)),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: scaleHeight(14)),
                              ),
                              child: Center(
                                child: FixedText(
                                  '초기화',
                                  style: AppFonts.suite.body_sm_500(context).copyWith(
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: scaleWidth(8)),
                          Expanded(
                            flex: 27,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, selected);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pri900,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(scaleHeight(16)),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: scaleHeight(14)),
                              ),
                              child: Center(
                                child: FixedText(
                                  '적용하기',
                                  style: AppFonts.suite.body_sm_500(context).copyWith(
                                    color: AppColors.gray20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedTeamFilters = result;
      });
    }
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
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: SvgPicture.asset(
                              AppImages.filter,
                              width: scaleWidth(28),
                              height: scaleHeight(28),
                              fit: BoxFit.contain,
                            ),
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

    final filteredItems = _getFilteredRecommendItems();

    return RefreshIndicator(
      onRefresh: _refreshRecommendFeed,
      color: AppColors.pri900,
      child: NotificationListener<ScrollNotification>(
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
          itemCount: filteredItems.length + (_hasMoreRecommend ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredItems.length) {
              return _buildLoadingIndicator();
            }
            return _buildFeedItem(filteredItems[index]);
          },
        ),
      ),
    );
  }

  Widget _buildFollowingTab() {
    if (_isLoadingFollowing) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshFollowingFeed,
      color: AppColors.pri900,
      child: NotificationListener<ScrollNotification>(
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
      ),
    );
  }

  Future<void> _refreshRecommendFeed() async {
    try {
      final feeds = await FeedApi.getAllFeed(page: 0, size: 20);
      _likeManager.clear();

      setState(() {
        _recommendFeedItems = feeds;
        _recommendCurrentPage = 0;
        _hasMoreRecommend = feeds.length >= 20;
      });

      // 새로운 데이터로 전역 상태 재설정
      _likeManager.setInitialStates(feeds);

      print('✅ 추천 피드 새로고침 완료');
      print('📊 첫 번째 아이템 - likeCount: ${feeds.isNotEmpty ? feeds[0]['likeCount'] : 'N/A'}');
    } catch (e) {
      print('❌ 추천 피드 새로고침 실패: $e');
    }
  }

  Future<void> _refreshFollowingFeed() async {
    try {
      final feeds = await FeedApi.getFollowingFeed(page: 0, size: 20);
      _likeManager.clear();

      setState(() {
        _followingFeedItems = feeds;
        _followingCurrentPage = 0;
        _hasMoreFollowing = feeds.length >= 20;
      });

      // 새로운 데이터로 전역 상태 재설정
      _likeManager.setInitialStates(feeds);

      print('✅ 팔로잉 피드 새로고침 완료');
    } catch (e) {
      print('❌ 팔로잉 피드 새로고침 실패: $e');
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(20)),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }

  /// 피드 아이템 빌드 - FeedItemWidget 사용
  Widget _buildFeedItem(Map<String, dynamic> feedData) {
    return FeedItemWidget(
      feedData: feedData,
      onTap: () async {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => DetailFeedScreen(
              recordId: feedData['recordId'],
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );

        // 삭제되었으면 해당 게시글 제거
        if (result != null && result is Map && result['deleted'] == true) {
          final deletedRecordId = result['recordId'];
          setState(() {
            _recommendFeedItems.removeWhere((item) => item['recordId'] == deletedRecordId);
            _followingFeedItems.removeWhere((item) => item['recordId'] == deletedRecordId);
          });
          print('게시글 ${deletedRecordId}번 삭제됨 - 스크롤 위치 유지');
        } else {
          print('[Feed] Detail에서 돌아옴 (전역 상태로 동기화됨)');
        }
      },
    );
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