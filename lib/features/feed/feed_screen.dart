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
import 'package:frontend/api/user_api.dart';
import 'package:frontend/utils/stadium_seat_utils.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  String selectedFeedType = '추천';
  String selectedFilterTab = '구단';
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

  String? _selectedTeamFilter;
  String? _currentUserFavTeam;
  String? _selectedStadiumFilter; // 선택된 구장
  String? _selectedSeatFilter;    // 선택된 구역

  String _convertToShortName(String fullName) {
    final Map<String, String> teamMap = {
      '두산 베어스': '두산',
      '롯데 자이언츠': '롯데',
      '삼성 라이온즈': '삼성',
      '키움 히어로즈': '키움',
      '한화 이글스': '한화',
      'KIA 타이거즈': 'KIA',
      'KT 위즈': 'KT',
      'LG 트윈스': 'LG',
      'NC 다이노스': 'NC',
      'SSG 랜더스': 'SSG',
    };
    return teamMap[fullName] ?? fullName;
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadRecommendFeed();
    _loadFollowingFeed();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final response = await UserApi.getMyProfile();
      if (response['success'] == true && mounted) {
        final userInfo = response['data'];
        setState(() {
          _currentUserFavTeam = userInfo['favTeam'];
        });
        print('✅ 사용자 favTeam 로드 성공: $_currentUserFavTeam');
      }
    } catch (e) {
      print('❌ 사용자 정보 로드 실패: $e');
    }
  }

  String _getFilterAssetPath(String? favTeam) {
    // 필터가 선택되지 않은 경우 기본 필터 아이콘
    if (_selectedTeamFilter == null && _selectedStadiumFilter == null) {
      return AppImages.filter;
    }

    // 필터가 적용된 경우에만 사용자의 favTeam 색상 필터 사용
    if (favTeam == null || favTeam.isEmpty) {
      return AppImages.filter; // favTeam이 없으면 기본 아이콘
    }

    final teamMap = {
      '두산 베어스': AppImages.filter_doosan,
      '한화 이글스': AppImages.filter_hanwha,
      'KIA 타이거즈': AppImages.filter_kia,
      '키움 히어로즈': AppImages.filter_kiwoom,
      'KT 위즈': AppImages.filter_kt,
      'LG 트윈스': AppImages.filter_lg,
      '롯데 자이언츠': AppImages.filter_lotte,
      'NC 다이노스': AppImages.filter_nc,
      '삼성 라이온즈': AppImages.filter_samsung,
      'SSG 랜더스': AppImages.filter_ssg,
    };

    // 매칭되는 팀이 있으면 해당 필터, 없으면 기본 아이콘
    return teamMap[favTeam] ?? AppImages.filter;
  }

  //추천 피드 로드
  Future<void> _loadRecommendFeed() async {
    try {
      final feeds = await FeedApi.getAllFeed(
        page: 0,
        size: 20,
        team: _selectedTeamFilter != null ? _convertToShortName(_selectedTeamFilter!) : null,  // ✅ 구단 필터 추가
        stadium: _selectedStadiumFilter,
        seatInfo: _selectedSeatFilter,
      );

      setState(() {
        _recommendFeedItems = feeds;
        _isLoadingRecommend = false;
        _recommendCurrentPage = 0;
        _hasMoreRecommend = feeds.length >= 20;
      });

      _likeManager.setInitialStates(feeds);
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
      final feeds = await FeedApi.getAllFeed(
        page: nextPage,
        size: 20,
        team: _selectedTeamFilter != null ? _convertToShortName(_selectedTeamFilter!) : null,  // ✅ 구단 필터 추가
        stadium: _selectedStadiumFilter,
        seatInfo: _selectedSeatFilter,
      );

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
      final feeds = await FeedApi.getFollowingFeed(
        page: 0,
        size: 20,
        team: _selectedTeamFilter != null ? _convertToShortName(_selectedTeamFilter!) : null,  // ✅ 구단 필터 추가
        stadium: _selectedStadiumFilter,
        seatInfo: _selectedSeatFilter,
      );
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
      final feeds = await FeedApi.getFollowingFeed(
        page: nextPage,
        size: 20,
        team: _selectedTeamFilter != null ? _convertToShortName(_selectedTeamFilter!) : null,  // ✅ 구단 필터 추가
        stadium: _selectedStadiumFilter,
        seatInfo: _selectedSeatFilter,
      );

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


  // 필터 액션시트 표시
  Future<void> _showFilterSheet() async {
    final teams = [
      {'name': '두산 베어스', 'image': AppImages.bears},
      {'name': '롯데 자이언츠', 'image': AppImages.giants},
      {'name': '삼성 라이온즈', 'image': AppImages.lions},
      {'name': '키움 히어로즈', 'image': AppImages.kiwoom},
      {'name': '한화 이글스', 'image': AppImages.eagles},
      {'name': 'KIA 타이거즈', 'image': AppImages.tigers},
      {'name': 'KT 위즈', 'image': AppImages.ktwiz},
      {'name': 'LG 트윈스', 'image': AppImages.twins},
      {'name': 'NC 다이노스', 'image': AppImages.dinos},
      {'name': 'SSG 랜더스', 'image': AppImages.landers},
    ];

    final List<Map<String, dynamic>> stadiumListWithImages = [
      {'name': '잠실 야구장', 'images': [AppImages.bears, AppImages.twins]},
      {'name': '사직 야구장', 'images': [AppImages.giants]},
      {'name': '대구삼성라이온즈파크', 'images': [AppImages.lions]},
      {'name': '고척 SKYDOME', 'images': [AppImages.kiwoom]},
      {'name': '한화생명 볼파크', 'images': [AppImages.eagles]},
      {'name': '기아 챔피언스 필드', 'images': [AppImages.tigers]},
      {'name': '수원 케이티 위즈 파크', 'images': [AppImages.ktwiz]},
      {'name': '창원 NC 파크', 'images': [AppImages.dinos]},
      {'name': '인천 SSG 랜더스필드', 'images': [AppImages.landers]},
    ];

    final result = await showModalBottomSheet<Map<String, String?>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String? selectedTeam = _selectedTeamFilter;
        String? selectedStadium = _selectedStadiumFilter;
        String? selectedSeat = _selectedSeatFilter;
        String filterTab = selectedFilterTab;
        bool showZoneView = false;
        String? selectedStadiumName = _selectedStadiumFilter;
        List<String>? selectedStadiumImages;
        List<String> zones = [];

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return PopScope(
              canPop: !showZoneView,
              onPopInvoked: (didPop) {
                if (!didPop && showZoneView) {
                  // 구역 뷰에서 뒤로가기 누르면 구장 선택으로 돌아감
                  setModalState(() {
                    showZoneView = false;
                  });
                }
              },
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                  child: Container(
                    height: scaleHeight(540),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(scaleHeight(20)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: scaleWidth(20),
                            right: scaleWidth(20),
                            top: scaleHeight(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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

                              // 구단/구장 탭
                              Row(
                                children: ['구단', '구장'].map((tab) {
                                  final isSelected = filterTab == tab;
                                  return Padding(
                                    padding: EdgeInsets.only(right: scaleWidth(13)),
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          filterTab = tab;
                                          if (showZoneView) {
                                            showZoneView = false;
                                          }
                                        });
                                      },
                                      child: IntrinsicWidth(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(2)),
                                              child: FixedText(
                                                tab,
                                                style: AppFonts.pretendard.body_md_400(context).copyWith(
                                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                                  color: isSelected ? AppColors.gray800 : AppColors.gray100,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: scaleHeight(8)),
                                            Container(
                                              height: scaleHeight(2),
                                              color: isSelected ? AppColors.gray800 : Colors.transparent,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        // 그리드 영역
                        showZoneView
                            ? Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: scaleHeight(16),
                                  left: scaleWidth(20),
                                  right: scaleWidth(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          showZoneView = false;
                                          // ✅ selectedStadiumName은 항상 유지
                                        });
                                      },
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Transform.rotate(
                                            angle: 3.14159,
                                            child: SvgPicture.asset(
                                              AppImages.arrow,
                                              width: scaleWidth(16),
                                              height: scaleHeight(16),
                                              color: AppColors.gray900,
                                            ),
                                          ),
                                          SizedBox(width: scaleWidth(12)),
                                          // 구장 로고들
                                          if (selectedStadiumImages != null)
                                            ...selectedStadiumImages!.asMap().entries.map((entry) {
                                              final imageIndex = entry.key;
                                              final imagePath = entry.value;
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  right: imageIndex < selectedStadiumImages!.length - 1
                                                      ? scaleWidth(4)
                                                      : 0,
                                                ),
                                                child: Image.asset(
                                                  imagePath,
                                                  width: scaleWidth(28),
                                                  height: scaleHeight(28),
                                                  fit: BoxFit.contain,
                                                ),
                                              );
                                            }).toList(),
                                          SizedBox(width: scaleWidth(4)),
                                          // 구장명
                                          if (selectedStadiumName != null)
                                            FixedText(
                                              selectedStadiumName!,
                                              style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                                color: AppColors.gray900,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: scaleHeight(6)),

                              // 구역 그리드 (스크롤 영역)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                                  child: GridView.builder(
                                    physics: BouncingScrollPhysics(),
                                    padding: EdgeInsets.only(top: scaleHeight(6)),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: scaleWidth(12),
                                      mainAxisSpacing: scaleHeight(10),
                                      childAspectRatio: 3.5,
                                    ),
                                    itemCount: zones.length,
                                    itemBuilder: (context, index) {
                                      final zone = zones[index];
                                      final isSelected = selectedSeat == zone;

                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            if (selectedSeat == zone) {
                                              // ✅ 구역 선택 해제 (구장명은 유지)
                                              selectedSeat = null;
                                              selectedStadium = null;
                                            } else {
                                              selectedSeat = zone;
                                              selectedStadium = selectedStadiumName;
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: scaleHeight(10)),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.gray700 : Colors.transparent,
                                            border: Border.all(
                                              color: AppColors.gray100,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(scaleHeight(60)),
                                          ),
                                          child: Center(
                                            child: FixedText(
                                              zone,
                                              style: AppFonts.pretendard.body_sm_400(context).copyWith(
                                                color: isSelected ? AppColors.gray20 : AppColors.gray600,
                                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            : Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: filterTab == '구단'
                                ? GridView.builder(
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.only(top: scaleHeight(16)),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: scaleWidth(12),
                                mainAxisSpacing: scaleHeight(10),
                                childAspectRatio: ((MediaQuery.of(context).size.width -
                                    scaleWidth(40) - scaleWidth(36) - scaleWidth(12)) / 2) / (scaleHeight(28) + scaleHeight(24)),
                              ),
                              itemCount: teams.length,
                              itemBuilder: (context, index) {
                                final team = teams[index];
                                final teamName = team['name']!;
                                final teamImage = team['image']!;
                                final isSelected = selectedTeam == teamName;

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      if (selectedTeam == teamName) {
                                        selectedTeam = null;
                                      } else {
                                        selectedTeam = teamName;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: scaleHeight(12)),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.gray700 : AppColors.gray30,
                                      borderRadius: BorderRadius.circular(scaleHeight(8)),
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
                                          style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                            color: isSelected ? AppColors.gray20 : AppColors.gray900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                                : Column(
                              children: [
                                SizedBox(height: scaleHeight(5)),
                                Expanded(
                                  child: ListView.builder(
                                    physics: BouncingScrollPhysics(),
                                    padding: EdgeInsets.only(top: scaleHeight(11)),
                                    itemCount: stadiumListWithImages.length,
                                    itemBuilder: (context, index) {
                                      final stadium = stadiumListWithImages[index];
                                      final stadiumName = stadium['name'] as String;
                                      final stadiumImages = stadium['images'] as List<String>;
                                      final isStadiumSelected = selectedStadium == stadiumName && selectedSeat != null;

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index < stadiumListWithImages.length - 1
                                              ? scaleHeight(10)
                                              : 0,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              showZoneView = true;
                                              selectedStadiumName = stadiumName;
                                              selectedStadiumImages = stadiumImages;
                                              zones = StadiumSeatInfo.getZones(stadiumName);
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.only(
                                              top: scaleHeight(12),
                                              right: scaleWidth(16),
                                              bottom: scaleHeight(12),
                                              left: scaleWidth(16),
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.gray30,
                                              borderRadius: BorderRadius.circular(scaleHeight(8)),
                                            ),
                                            child: Row(
                                              children: [
                                                // 팀 로고들
                                                ...stadiumImages.asMap().entries.map((entry) {
                                                  final imageIndex = entry.key;
                                                  final imagePath = entry.value;
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      right: imageIndex < stadiumImages.length - 1
                                                          ? scaleWidth(4)
                                                          : 0,
                                                    ),
                                                    child: Image.asset(
                                                      imagePath,
                                                      width: scaleWidth(28),
                                                      height: scaleHeight(28),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  );
                                                }).toList(),
                                                SizedBox(width: scaleWidth(4)),
                                                // 구장 이름
                                                Expanded(
                                                  child: FixedText(
                                                    stadiumName,
                                                    style: AppFonts.pretendard.body_sm_500(context).copyWith(
                                                      color: AppColors.gray900,
                                                    ),
                                                  ),
                                                ),
                                                // 선택된 구장이면 체크, 아니면 화살표
                                                isStadiumSelected
                                                    ? Container(
                                                  width: scaleWidth(24),
                                                  height: scaleWidth(24),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.gray700,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      AppImages.check,
                                                      width: scaleWidth(13),
                                                      height: scaleHeight(11),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                )
                                                    : SvgPicture.asset(
                                                  AppImages.arrow,
                                                  width: scaleWidth(16),
                                                  height: scaleHeight(16),
                                                  color: AppColors.gray300,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 버튼 영역
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: scaleWidth(18),
                            vertical: scaleHeight(20),
                          ),
                          child: Row(
                            children: [
                              // 초기화 버튼 (1)
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: scaleHeight(46),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, {
                                        'team': null,
                                        'stadium': null,
                                        'seat': null,
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(scaleHeight(16)),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Center(
                                      child: FixedText(
                                        '초기화',
                                        style: AppFonts.suite.body_sm_500(context).copyWith(
                                          color: (selectedTeam != null || selectedStadium != null)
                                              ? AppColors.gray700
                                              : AppColors.gray200,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: scaleWidth(8)),
                              // 적용하기 버튼 (4)
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: scaleHeight(46),
                                  decoration: BoxDecoration(
                                    color: (selectedTeam != null || selectedStadium != null)
                                        ? AppColors.pri900
                                        : AppColors.gray50,
                                    borderRadius: BorderRadius.circular(scaleHeight(16)),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, {
                                        'team': selectedTeam,
                                        'stadium': selectedStadium,
                                        'seat': selectedSeat,
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(scaleHeight(16)),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Center(
                                      child: FixedText(
                                        '적용하기',
                                        style: AppFonts.suite.body_sm_500(context).copyWith(
                                          color: (selectedTeam != null || selectedStadium != null)
                                              ? AppColors.gray20
                                              : AppColors.gray300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // 바텀시트가 닫힐 때 결과 적용
    if (result != null) {
      setState(() {
        _selectedTeamFilter = result['team'];
        _selectedStadiumFilter = result['stadium'];
        _selectedSeatFilter = result['seat'];

        // 필터가 변경되면 피드 새로 로드
        _isLoadingRecommend = true;
        _isLoadingFollowing = true;
        _recommendCurrentPage = 0;
        _followingCurrentPage = 0;
      });

      // 피드 새로 로드
      _loadRecommendFeed();
      _loadFollowingFeed();
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
                    // 오른쪽: 필터 아이콘 (사용자의 favTeam 색상으로 표시)
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: SvgPicture.asset(
                        _getFilterAssetPath(_currentUserFavTeam),
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

      final filteredItems = _recommendFeedItems;

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