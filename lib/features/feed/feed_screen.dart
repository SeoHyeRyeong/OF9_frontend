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
import 'package:frontend/utils/feed_count_manager.dart';
import 'package:frontend/features/report/report_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  String selectedFeedType = '추천'; // '추천' 또는 '팔로잉'
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
  final _likeManager = FeedCountManager();

  // 필터링 관련 - 다중 선택
  Set<String> _selectedTeamFilters = {};

  @override
  void initState() {
    super.initState();
    _loadRecommendFeed();
    _loadFollowingFeed();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const ReportScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 1. 피드 제목 + 검색 아이콘
              Container(
                padding: EdgeInsets.only(
                  top: scaleHeight(24),
                  left: scaleWidth(20),
                  right: scaleWidth(20),
                ),
                height: scaleHeight(60),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FixedText(
                        '피드',
                        style: AppFonts.pretendard.title_md_600(context).copyWith(
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) =>
                              const SearchScreen(),
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
                    ],
                  ),
                ),
              ),

              // 2. 추천/팔로잉 버튼 + 필터
              Padding(
                padding: EdgeInsets.only(
                  top: scaleHeight(11),
                  left: scaleWidth(20),
                  right: scaleWidth(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 왼쪽: 추천/팔로잉 버튼
                    Row(
                      children: ['추천', '팔로잉'].map((type) {
                        final isSelected = selectedFeedType == type;
                        return Padding(
                          padding: EdgeInsets.only(right: scaleWidth(8)),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFeedType = type;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: scaleWidth(14),
                                vertical: scaleHeight(4),
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.gray30 : AppColors.gray20,
                                borderRadius: BorderRadius.circular(scaleHeight(8)),
                              ),
                              child: FixedText(
                                type,
                                style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                  color: isSelected ? AppColors.gray600 : AppColors.gray300,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // 오른쪽: 필터 아이콘
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: SvgPicture.asset(
                        AppImages.filter,
                        width: scaleWidth(28),
                        height: scaleHeight(28),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: scaleHeight(10)),

              // 3. 피드 리스트
              Expanded(
                child: _buildScrollableFeedList(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(currentIndex: 1),
      ),
    );
  }

// 새로운 메서드: ListView로 스크롤 가능한 리스트 생성
  Widget _buildScrollableFeedList() {
    if (selectedFeedType == '추천') {
      if (_isLoadingRecommend) {
        return Center(child: CircularProgressIndicator());
      }

      final filteredItems = _getFilteredRecommendItems();

      return ListView.builder(
        padding: EdgeInsets.only(top: scaleHeight(10)),
        itemCount: filteredItems.length + (_hasMoreRecommend ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredItems.length) {
            if (_hasMoreRecommend && !_isLoadingMoreRecommend) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMoreRecommendFeed();
              });
            }
            return _buildLoadingIndicator();
          }

          return Column(
            children: [
              _buildFeedItem(filteredItems[index]),
              if (index < filteredItems.length - 1)
                SizedBox(height: scaleHeight(20)),
            ],
          );
        },
      );
    } else {
      // 팔로잉
      if (_isLoadingFollowing) {
        return Center(child: CircularProgressIndicator());
      }

      // 팔로잉 피드가 비어있을 때
      if (_followingFeedItems.isEmpty) {
        return Center(
          child: Text(
            '팔로우 한 친구가 없어요',
            style: AppFonts.pretendard.head_sm_600(context).copyWith(
              color: AppColors.gray400,
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.only(top: scaleHeight(10)),
        itemCount: _followingFeedItems.length + (_hasMoreFollowing ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _followingFeedItems.length) {
            if (_hasMoreFollowing && !_isLoadingMoreFollowing) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMoreFollowingFeed();
              });
            }
            return _buildLoadingIndicator();
          }

          return Column(
            children: [
              _buildFeedItem(_followingFeedItems[index]),
              if (index < _followingFeedItems.length - 1)
                SizedBox(height: scaleHeight(20)),
            ],
          );
        },
      );
    }
  }

  // 로딩 인디케이터
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
        if (result != null && result is Map) {
          if (result['deleted'] == true) {
            final deletedRecordId = result['recordId'];
            setState(() {
              _recommendFeedItems.removeWhere((item) => item['recordId'] == deletedRecordId);
              _followingFeedItems.removeWhere((item) => item['recordId'] == deletedRecordId);
            });
            print('게시글 ${deletedRecordId}번 삭제됨 - 스크롤 위치 유지');
          } else if (result['updated'] == true) {
            final updatedRecordId = result['recordId'];
            final updatedData = result['updatedData'] as Map<String, dynamic>;

            setState(() {
              // 추천 피드 업데이트
              final recommendIndex = _recommendFeedItems.indexWhere(
                      (item) => item['recordId'] == updatedRecordId
              );
              if (recommendIndex != -1) {
                _recommendFeedItems[recommendIndex] = {
                  ..._recommendFeedItems[recommendIndex],
                  ...updatedData,
                };
              }

              // 팔로잉 피드 업데이트
              final followingIndex = _followingFeedItems.indexWhere(
                      (item) => item['recordId'] == updatedRecordId
              );
              if (followingIndex != -1) {
                _followingFeedItems[followingIndex] = {
                  ..._followingFeedItems[followingIndex],
                  ...updatedData,
                };
              }
            });
          }
        } else {
          print('[Feed] Detail에서 돌아옴 (전역 상태로 동기화됨)');
        }
      },
    );
  }
}