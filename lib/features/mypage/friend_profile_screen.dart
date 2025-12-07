import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';
import 'package:frontend/features/mypage/follower_screen.dart';
import 'package:frontend/features/mypage/following_screen.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/features/feed/detail_feed_screen.dart';
import 'package:frontend/features/feed/feed_item_widget.dart';
import 'package:frontend/utils/feed_count_manager.dart';
import 'package:frontend/components/custom_action_sheet.dart';
import 'dart:async';
import 'package:frontend/components/custom_toast.dart';

class FriendProfileScreen extends StatefulWidget {
  final int userId;
  final String? initialFollowStatus;

  const FriendProfileScreen({
    Key? key,
    required this.userId,
    this.initialFollowStatus,
  }) : super(key: key);

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen>
    with SingleTickerProviderStateMixin {
  int selectedTabIndex = 2; // 0: 캘린더, 1: 리스트, 2: 모아보기
  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  int postCount = 0;
  int followingCount = 0;
  int followerCount = 0;
  bool isPrivate = false;
  String? followStatus;
  bool isBlocked = false;
  final _likeManager = FeedCountManager();
  bool _showStickyHeader = false;
  bool _unfollowPending = false;
  bool _unfollowCancelled = false;
  Timer? _unfollowTimer;

  bool isMutualFollow = false;
  bool _hasStateChanged = false;

  late AnimationController _tabAnimationController;
  late PageController _tabPageController;
  double _currentTabPageValue = 0.0;
  bool _isTabPageScrolling = false;

  List<Map<String, dynamic>> feedList = [];
  Map<String, dynamic> calendarData = {};
  bool isLoading = true;
  bool isLoadingRecords = true;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    final List<dynamic> records = calendarData['records'] ?? [];
    return records.where((record) {
      return record['gameDate'] == formattedDay;
    }).toList().cast<Map<String, dynamic>>();
  }

  @override
  void initState() {
    super.initState();
    followStatus = widget.initialFollowStatus;
    _selectedDay = _focusedDay;
    _likeManager.addListener(_onGlobalStateChanged);

    _tabAnimationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );

    _tabPageController = PageController(initialPage: 2);
    _currentTabPageValue = 2.0;
    _tabPageController.addListener(() {
      if (_tabPageController.hasClients) {
        setState(() {
          _currentTabPageValue = _tabPageController.page ?? 2.0;
          _isTabPageScrolling = true;
        });
      }
    });

    _checkAndLoadUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserInfo();
  }

  Future<void> _checkAndLoadUserInfo() async {
    try {
      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];

      if (myUserId == widget.userId) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MyPageScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
        return;
      }

      await _loadUserInfo();
      await _loadMyRecords();
    } catch (e) {
      print('❌ 사용자 확인 실패: $e');
      await _loadUserInfo();
      await _loadMyRecords();
    }
  }

  @override
  void dispose() {
    _likeManager.removeListener(_onGlobalStateChanged);
    _tabAnimationController.dispose();
    _tabPageController.dispose();
    _unfollowTimer?.cancel();
    super.dispose();
  }

  void _onGlobalStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _isTabPageScrolling = false;
    });
    _tabPageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onTabPageChanged(int index) {
    setState(() {
      _isTabPageScrolling = false;
      selectedTabIndex = index;
    });
    _loadMyRecords();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await FeedApi.getUserFeed(widget.userId);
      final newFollowStatus = response['followStatus'] ?? 'NOT_FOLLOWING';

      // 차단 체크
      bool blocked = false;
      try {
        final blockedResponse = await UserApi.getBlockedUsers();
        final blockedData = blockedResponse['data'] as List? ?? [];
        blocked = blockedData.any((user) => user['userId'] == widget.userId);
      } catch (e) {
        print('차단 확인 에러: $e');
      }

      bool mutual = false;
      if (newFollowStatus == 'NOT_FOLLOWING' && !blocked) {
        try {
          final myProfile = await UserApi.getMyProfile();
          final myUserId = myProfile['data']['id'];

          final myFollowers = await UserApi.getFollowers(myUserId);
          final followerIds = myFollowers['data']?.map((u) => u['id']).toSet() ?? <int>{};

          // 상대가 나를 팔로우 중이면 맞팔
          mutual = followerIds.contains(widget.userId);
        } catch (e) {
          print('❌ 맞팔 체크 실패: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        nickname = response['nickname'] ?? '알 수 없음';
        favTeam = response['favTeam'] ?? '';
        profileImageUrl = response['profileImageUrl'];
        postCount = response['recordCount'] ?? 0;
        followerCount = response['followerCount'] ?? 0;
        followingCount = response['followingCount'] ?? 0;
        isPrivate = response['isPrivate'] ?? false;
        followStatus = newFollowStatus;
        isBlocked = blocked;
        isMutualFollow = mutual;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('❌ 사용자 정보 로드 실패: $e');
      setState(() {
        nickname = '로딩 실패';
        favTeam = '-';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMyRecords({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      setState(() {
        isLoadingRecords = true;
      });
    }
    try {
      if (selectedTabIndex == 0) { // 캘린더
        await _loadCalendarData();
      } else if (selectedTabIndex == 1) { // 리스트
        await _loadListData();
      } else { // 모아보기 (Tab 2)
        await _loadGridData();
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ 데이터 로드 실패: $e');
      setState(() {
        feedList = [];
        calendarData = {};
        isLoadingRecords = false;
      });
    }

    if (showLoadingIndicator && mounted) {
      setState(() {
        isLoadingRecords = false;
      });
    }
  }

  /// 그리드뷰 데이터 로드 (getUserFeed 사용)
  Future<void> _loadGridData() async {
    try {
      final response = await FeedApi.getUserFeed(widget.userId);
      final items = response['feedItems'] as List? ?? [];

      if (!mounted) return;

      setState(() {
        feedList = items.map((item) {
          return {
            'recordId': item['recordId'],
            'gameDate': item['gameDate'],
            'mediaUrls': item['imageUrl'] != null ? [item['imageUrl']] : [],
            'likeCount': item['likeCount'] ?? 0,
          };
        }).toList();
        isLoadingRecords = false;
      });
      print('✅ 그리드뷰 데이터 로드 완료: ${feedList.length}개');
    } catch (e) {
      print('❌ 그리드뷰 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          feedList = [];
          isLoadingRecords = false;
        });
      }
    }
  }

  /// 리스트뷰 데이터 로드 (getUserList 사용)
  Future<void> _loadListData() async {
    try {
      final List<Map<String, dynamic>> items = await FeedApi.getUserList(widget.userId);

      if (!mounted) return;

      setState(() {
        feedList = items.map((item) {
          return {
            'recordId': item['recordId'],
            'userId': widget.userId,
            'profileImageUrl': profileImageUrl,
            'nickname': nickname,
            'favTeam': favTeam,
            'createdAt': item['createdAt'] ?? '',
            'gameDate': item['gameDate'] ?? '',
            'gameTime': item['gameTime'] ?? '',
            'homeTeam': item['homeTeam'] ?? '',
            'awayTeam': item['awayTeam'] ?? '',
            'homeScore': item['homeScore'],
            'awayScore': item['awayScore'],
            'stadium': item['stadium'] ?? '',
            'emotionCode': item['emotionCode'],
            'emotionLabel': item['emotionLabel'] ?? '',
            'longContent': item['longContent'] ?? '',
            'mediaUrls': item['mediaUrls'] ?? [],
            'likeCount': item['likeCount'] ?? 0,
            'isLiked': item['isLiked'] ?? false,
            'commentCount': item['commentCount'] ?? 0,
          };
        }).toList();
        isLoadingRecords = false;
      });
      print('✅ 리스트뷰 데이터 로드 완료: ${feedList.length}개');
    } catch (e) {
      print('❌ 리스트뷰 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          feedList = [];
          isLoadingRecords = false;
        });
      }
    }
  }

  /// 캘린더뷰 데이터 로드 (getUserCalendar 사용)
  Future<void> _loadCalendarData() async {
    try {
      final int year = _focusedDay.year;
      final int month = _focusedDay.month;

      final Map<String, dynamic> response = await FeedApi.getUserCalendar(
        userId: widget.userId,
        year: year,
        month: month,
      );

      if (!mounted) return;

      setState(() {
        calendarData = response;
        isLoadingRecords = false;
      });
      print('✅ 캘린더 데이터 로드 완료: $year-$month');
    } catch (e) {
      print('❌ 캘린더 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          calendarData = {};
          isLoadingRecords = false;
        });
      }
    }
  }

  /// 캘린더 월 변경 시 데이터 재로드
  void _onCalendarPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    if (selectedTabIndex == 0) {
      _loadCalendarData();
    }
  }


  Future<void> _refreshData() async {
    await Future.wait([_loadUserInfo(), _loadMyRecords()]);
  }

  Future<void> _handleFollow() async {
    try {
      if (followStatus == 'FOLLOWING') {
        // 언팔로우 로직 (토스트 포함)
        if (_unfollowPending) {
          print('$nickname - 이미 언팔로우 대기 중');
          return;
        }
        _unfollowPending = true;
        _unfollowCancelled = false;

        // UI 즉시 업데이트 (NOT_FOLLOWING으로)
        setState(() {
          followStatus = 'NOT_FOLLOWING';
          followerCount = followerCount > 0 ? followerCount - 1 : 0;
        });

        _hasStateChanged = true;

        // 🔑 실제 API 먼저 호출
        try {
          await UserApi.unfollowUser(widget.userId);
          print('$nickname - 언팔로우 완료');
        } catch (e) {
          print('언팔로우 API 에러: $e');
          // 에러 시 다시 팔로잉으로 복구
          if (mounted) {
            setState(() {
              followStatus = 'FOLLOWING';
              followerCount = followerCount + 1;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('팔로우 취소에 실패했습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          _unfollowPending = false;
          _unfollowCancelled = false;
          return;
        }

        // 토스트 표시
        CustomToast.showWithProfile(
          context: context,
          profileImageUrl: profileImageUrl,
          defaultIconAsset: AppImages.profile,
          nickname: nickname,
          message: '팔로우를 취소하시겠어요?',
          duration: Duration(seconds: 2),
          onCancel: () async {
            print('$nickname - 언팔로우 취소 (다시 팔로우)');
            _unfollowTimer?.cancel();
            _unfollowTimer = null;

            // 다시 팔로우 API 호출
            try {
              await UserApi.followUser(widget.userId);
              // 다시 팔로잉으로 복구
              setState(() {
                followStatus = 'FOLLOWING';
                followerCount = followerCount + 1;
              });
            } catch (e) {
              print('재팔로우 API 에러: $e');
            }
          },
        );

        _unfollowPending = false;
        _unfollowCancelled = false;

      } else if (followStatus == 'NOT_FOLLOWING' || isMutualFollow) {
        final response = await UserApi.followUser(widget.userId);
        final responseData = response['data'];

        setState(() {
          if (responseData['pending'] == true) {
            followStatus = 'REQUESTED';
            isMutualFollow = false;
          } else {
            followStatus = 'FOLLOWING';
            followerCount++;
            isMutualFollow = false;
            _hasStateChanged = true;
          }
        });
      } else if (followStatus == 'REQUESTED') {
        // 요청 취소 (기존)
        await UserApi.unfollowUser(widget.userId);
        setState(() {
          followStatus = 'NOT_FOLLOWING';
          isMutualFollow = true;
        });
      }
    } catch (e) {
      print('팔로우 처리 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleBlock() async {
    try {
      if (isBlocked) {
        // 차단 해제
        await UserApi.unblockUser(widget.userId);

        try {
          final response = await FeedApi.getUserFeed(widget.userId);

          if (mounted) {
            setState(() {
              isBlocked = false;
              followerCount = response['followerCount'] ?? followerCount;
              followingCount = response['followingCount'] ?? followingCount;
              postCount = response['recordCount'] ?? postCount;
            });
          }
        } catch (e) {
          print('❌ 프로필 정보 갱신 실패: $e');
          if (mounted) {
            setState(() {
              isBlocked = false;
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nickname님의 차단을 해제했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        //차단하기
        await UserApi.blockUser(widget.userId);

        try {
          final response = await FeedApi.getUserFeed(widget.userId);

          if (mounted) {
            setState(() {
              isBlocked = true;
              followStatus = 'NOT_FOLLOWING';
              followerCount = response['followerCount'] ?? followerCount;
              followingCount = response['followingCount'] ?? followingCount;
              postCount = response['recordCount'] ?? postCount;
              isMutualFollow = false;
            });
          }
        } catch (e) {
          print('❌ 프로필 정보 갱신 실패: $e');
          // 실패해도 차단 상태는 유지
          if (mounted) {
            setState(() {
              isBlocked = true;
              followStatus = 'NOT_FOLLOWING';
              isMutualFollow = false;
            });
          }
        }
        _hasStateChanged = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nickname님을 차단했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 차단 처리 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단 처리에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMediaImage(dynamic mediaData, double width, double height) {
    try {
      if (mediaData is String) {
        if (mediaData.startsWith('http://') || mediaData.startsWith('https://')) {
          return Image.network(
            mediaData,
            width: width,
            height: height,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: AppColors.gray50,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: AppColors.pri400,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('🖼️ Image.network 로드 실패: $error');
              return _buildImageErrorWidget(width, height);
            },
          );
        }

        try {
          final Uint8List imageBytes = base64Decode(mediaData);
          return Image.memory(
            imageBytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        } catch (e) {
          print('🖼️ Base64 디코딩 실패: $e');
          return _buildImageErrorWidget(width, height);
        }
      }

      return _buildImageErrorWidget(width, height);
    } catch (e) {
      print('🖼️ 미디어 이미지 처리 실패: $e');
      return _buildImageErrorWidget(width, height);
    }
  }

  Widget _buildImageErrorWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.gray50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: scaleWidth(32),
            color: AppColors.gray300,
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            '이미지 로드 실패',
            style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> record) {
    final String gameDate = record['gameDate'] ?? '날짜 없음';
    final int likeCount = record['likeCount'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => DetailFeedScreen(recordId: record['recordId']),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(scaleWidth(10)),
        child: Container(
          color: AppColors.gray50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (record['mediaUrls'] != null && record['mediaUrls'].isNotEmpty)
                _buildMediaImage(
                  record['mediaUrls'][0],
                  double.infinity,
                  double.infinity,
                )
              else
                _buildImageErrorWidget(double.infinity, double.infinity),

              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: scaleHeight(9)),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(6), vertical: scaleHeight(3)),
                    decoration: BoxDecoration(
                      color: AppColors.trans500,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      gameDate,
                      textAlign: TextAlign.center,
                      style: AppFonts.suite.c3_sb(context).copyWith(
                        color: Colors.white,
                        letterSpacing: -0.16,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: scaleHeight(6),
                    right: scaleWidth(6),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(6), vertical: scaleHeight(2)),
                    decoration: BoxDecoration(
                      color: AppColors.trans300,
                      borderRadius: BorderRadius.circular(scaleWidth(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          AppImages.heart_white,
                          width: scaleWidth(14),
                          height: scaleHeight(14),
                        ),
                        SizedBox(width: scaleWidth(2)),
                        Text(
                          likeCount.toString(),
                          style: AppFonts.suite.c2_sb(context).copyWith(
                            color: AppColors.gray30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final navigator = Navigator.of(context);
          navigator.pop({
            'isMutualFollow': isMutualFollow,
            'needsRefresh': true,
            'followStatus': followStatus,
            'followerCount': followerCount,
            'followingCount': followingCount,
            'isBlocked': isBlocked,
            'needsRefresh': _hasStateChanged,
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: NestedScrollView(
            physics: const ClampingScrollPhysics(),
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverPersistentHeader(
                  key: ValueKey('header-$isBlocked'),
                  pinned: true,
                  floating: false,
                  delegate: _FriendProfileHeaderDelegate(
                    height: scaleHeight(60),
                    nickname: nickname,
                    isScrolled: _showStickyHeader,
                    followStatus: followStatus,
                    onBackPressed: () {
                      Navigator.pop(context, {
                        'isMutualFollow': isMutualFollow,
                        'followStatus': followStatus,
                        'followerCount': followerCount,
                        'followingCount': followingCount,
                        'isBlocked': isBlocked,
                        'needsRefresh': _hasStateChanged,
                      });
                    },
                    onFollowPressed: _handleFollow,
                    isBlocked: isBlocked,
                    onBlockTap: _handleBlock,
                    isMutualFollow: isMutualFollow,
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileSection(),
                    SizedBox(height: scaleHeight(20)),
                    _buildFollowButton(),
                    SizedBox(height: scaleHeight(30)),
                  ]),
                ),
                SliverPersistentHeader(
                  pinned: false,
                  floating: false,
                  delegate: _StickyDetectorDelegate(
                    height: 1,
                    onSticky: (isSticky) {
                      if (_showStickyHeader != isSticky && mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _showStickyHeader = isSticky;
                            });
                          }
                        });
                      }
                    },
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _FriendProfileTabBarDelegate(
                    height: scaleHeight(36) + 1.0,
                    child: _buildTabBar(),
                  ),
                ),
              ];
            },
            body: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.pri500,
              child: PageView(
                controller: _tabPageController,
                onPageChanged: _onTabPageChanged,
                children: [
                  _buildCalendarTab(),
                  _buildListTab(),
                  _buildGridTab(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
      ),
    );
  }

  // 프로필 섹션
  Widget _buildProfileSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(30)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(scaleWidth(34.91)),
            child: Container(
              width: scaleWidth(96),
              height: scaleHeight(96),
              color: AppColors.gray100,
              child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.pri400,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => SvgPicture.asset(
                  AppImages.profile,
                  fit: BoxFit.cover,
                ),
              )
                  : SvgPicture.asset(AppImages.profile, fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: scaleWidth(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: scaleHeight(2)),
                if (!isLoading && favTeam.isNotEmpty && favTeam != "응원팀 없음") ...[
                  IntrinsicWidth(
                    child: Container(
                      height: scaleHeight(22),
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(12)),
                      decoration: BoxDecoration(
                        color: AppColors.gray30,
                        borderRadius: BorderRadius.circular(scaleWidth(20)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$favTeam 팬",
                        style: AppFonts.suite.caption_md_500(context).copyWith(
                          color: AppColors.pri800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),
                ],
                isLoading
                    ? Text("...", style: AppFonts.pretendard.head_sm_600(context))
                    : Text(
                  nickname,
                  style: AppFonts.pretendard.head_sm_600(context).copyWith(
                    color: AppColors.black,
                    letterSpacing: -0.36,
                  ),
                ),
                SizedBox(height: scaleHeight(12)),
                Row(
                  children: [
                    _buildStatItem("게시글", postCount),
                    SizedBox(width: scaleWidth(10)),
                    _buildStatItem("팔로잉", followingCount, onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => FollowingScreen(targetUserId: widget.userId),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }),
                    SizedBox(width: scaleWidth(10)),
                    _buildStatItem("팔로워", followerCount, onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => FollowerScreen(targetUserId: widget.userId),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, {VoidCallback? onTap}) {
    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: AppFonts.suite.caption_re_400(context).copyWith(
            color: AppColors.gray500,
          ),
        ),
        SizedBox(width: scaleWidth(2)),
        Text(
          count.toString(),
          style: AppFonts.suite.caption_md_500(context).copyWith(
            color: AppColors.gray900,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  // 팔로우 버튼 (프로필 수정 버튼 위치)
  Widget _buildFollowButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: SizedBox(
        width: double.infinity,
        height: scaleHeight(42),
        child: ElevatedButton(
          onPressed: isBlocked ? _handleBlock : _handleFollow,
          style: ElevatedButton.styleFrom(
            backgroundColor: getButtonBackgroundColor(),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleHeight(8)),
            ),
            elevation: 0,
          ),
          child: Text(
            _getButtonText(),
            style: AppFonts.suite.caption_md_500(context).copyWith(color: _getButtonTextColor()),
          ),
        ),
      ),
    );
  }

  Color getButtonBackgroundColor() {
    if (isBlocked) return AppColors.gray600;
    if (isMutualFollow) return AppColors.gray600;

    switch (followStatus) {
      case 'FOLLOWING':
      case 'REQUESTED':
        return AppColors.gray50;
      default:
        return AppColors.gray600;
    }
  }

  String _getButtonText() {
    if (isBlocked) return '차단 해제';
    if (isMutualFollow) return '맞팔로우';

    switch (followStatus) {
      case 'FOLLOWING': return '팔로잉';
      case 'REQUESTED': return '요청됨';
      default: return '팔로우';
    }
  }

  Color _getButtonTextColor() {
    if (isBlocked) return AppColors.gray20;
    if (isMutualFollow) return AppColors.gray20;

    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray600;
      case 'REQUESTED':
        return AppColors.gray600;
      default:
        return AppColors.gray20;
    }
  }

  // 탭바
  Widget _buildTabBar() {
    final double tabAreaHeight = scaleHeight(36);
    final double dividerHeight = 1.0;
    final double totalHeight = tabAreaHeight + dividerHeight;

    return Container(
      height: totalHeight,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: tabAreaHeight,
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(43.5)),
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    final images = [AppImages.calendar, AppImages.list, AppImages.gallery];
                    final isSelected = selectedTabIndex == index;
                    return GestureDetector(
                      onTap: () => _onTabTapped(index),
                      child: Container(
                        width: scaleWidth(51),
                        height: tabAreaHeight,
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              images[index],
                              width: scaleWidth(28),
                              height: scaleHeight(28),
                              color: isSelected ? AppColors.gray600 : AppColors.trans200,
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                _buildRealtimeTabIndicator(),
              ],
            ),
          ),
          Divider(
            color: AppColors.gray50,
            thickness: dividerHeight,
            height: dividerHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeTabIndicator() {
    final screenWidth = MediaQuery.of(context).size.width - scaleWidth(43.5 * 2);
    final tabWidth = scaleWidth(51);
    final scrollProgress = _currentTabPageValue.clamp(0.0, 2.0);

    double indicatorOffset;
    if (scrollProgress <= 1.0) {
      // 0 -> 1 (캘린더 -> 리스트)
      final centerPosition = (screenWidth - tabWidth) / 2;
      indicatorOffset = scrollProgress * centerPosition;
    } else {
      // 1 -> 2 (리스트 -> 모아보기)
      final centerPosition = (screenWidth - tabWidth) / 2;
      final rightPosition = screenWidth - tabWidth;
      indicatorOffset = centerPosition + (scrollProgress - 1.0) * (rightPosition - centerPosition);
    }

    return Positioned(
      bottom: 0,
      left: indicatorOffset,
      child: AnimatedContainer(
        duration: _isTabPageScrolling ? Duration.zero : Duration(milliseconds: 250),
        width: tabWidth,
        height: 2.0,
        color: AppColors.gray600,
      ),
    );
  }

  // 캘린더 탭
  Widget _buildCalendarTab() {
    return _KeepAliveWrapper(
      child: isLoadingRecords
          ? Center(child: CircularProgressIndicator(color: AppColors.pri500))
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
        child: Column(
          children: [
            _buildCalendarHeader(),
            _buildTableCalendar(),
            SizedBox(height: scaleHeight(25)),
            _buildStatsPanel(),
            SizedBox(height: scaleHeight(15)),
          ],
        ),
      ),
    );
  }

  /// 캘린더 헤더
  Widget _buildCalendarHeader() {
    final isFirstMonth = _focusedDay.year == 2025 && _focusedDay.month == 1;
    final isLastMonth = _focusedDay.year == 2025 && _focusedDay.month == 12;

    return Padding(
      padding: EdgeInsets.only(top: scaleHeight(20), bottom: scaleHeight(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: scaleWidth(44)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFirstMonth)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                    _loadMyRecords(showLoadingIndicator: false);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: scaleWidth(10)),
                    child: SvgPicture.asset(
                      AppImages.polygon_left,
                      width: scaleWidth(14),
                      height: scaleHeight(12),
                    ),
                  ),
                )
              else
                SizedBox(width: scaleWidth(24)),
              Text(
                DateFormat('yyyy년  M월', 'ko_KR').format(_focusedDay),
                style: AppFonts.pretendard.head_sm_600(context).copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w500,
                  fontSize: scaleFont(16.8),
                ),
              ),
              if (!isLastMonth)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                    _loadMyRecords(showLoadingIndicator: false);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: scaleWidth(10)),
                    child: SvgPicture.asset(
                      AppImages.polygon_right,
                      width: scaleWidth(14),
                      height: scaleHeight(12),
                    ),
                  ),
                )
              else
                SizedBox(width: scaleWidth(24)),
            ],
          ),
          GestureDetector(
            onTap: () {
              final now = DateTime.now();
              if (_focusedDay.year == now.year && _focusedDay.month == now.month) {
                return;
              }
              setState(() {
                _focusedDay = now;
                _selectedDay = now;
              });
              _loadMyRecords(showLoadingIndicator: false);
            },
            child: Container(
              width: scaleWidth(44),
              height: scaleHeight(24),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(scaleWidth(6)),
              ),
              alignment: Alignment.center,
              child: Text(
                '오늘',
                style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.pri800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TableCalendar 위젯
  Widget _buildTableCalendar() {
    return TableCalendar(
      locale: 'ko_KR',
      focusedDay: _focusedDay,
      firstDay: DateTime(2025, 1, 1),
      lastDay: DateTime(2025, 12, 31),
      calendarFormat: _calendarFormat,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerVisible: false,
      sixWeekMonthsEnforced: false,
      rowHeight: scaleHeight(75),
      daysOfWeekHeight: scaleHeight(33),
      calendarStyle: CalendarStyle(
        cellMargin: EdgeInsets.zero,
        // 기본 날짜 셀 스타일 (gray30)
        defaultDecoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleWidth(6)),
        ),
        weekendDecoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleWidth(6)),
        ),
        outsideDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scaleWidth(6)),
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.pri100,
          borderRadius: BorderRadius.circular(scaleWidth(6)),
          border: Border.all(color: AppColors.pri300, width: 1),
        ),
        todayTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.pri700),
        // 텍스트 스타일
        defaultTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray200),
        weekendTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray200),
        outsideTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray200),
      ),
      // 요일 헤더 스타일
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray700),
        weekendStyle: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray700),
      ),
      calendarBuilders: CalendarBuilders(
        // 비활성화된 날짜 (2025년 범위 밖)
        disabledBuilder: (context, day, focusedDay) {
          return Container(
            constraints: const BoxConstraints.expand(),
            margin: EdgeInsets.symmetric(
              horizontal: scaleWidth(2.145),
              vertical: scaleHeight(7),
            ),
            color: Colors.transparent,
          );
        },

        // 오늘 날짜 UI
        todayBuilder: (context, day, focusedDay) {
          final now = DateTime.now();
          final events = _getEventsForDay(day);
          if (focusedDay.year != now.year || focusedDay.month != now.month) {
            return Container(
              constraints: const BoxConstraints.expand(),
              margin: EdgeInsets.symmetric(
                horizontal: scaleWidth(2.145),
                vertical: scaleHeight(7),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(scaleWidth(6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: scaleHeight(4)),
                  Text(
                    '${day.day}',
                    style: AppFonts.suite.caption_md_500(context).copyWith(
                        color: AppColors.gray200),
                  ),
                ],
              ),
            );
          }

          // 오늘 달력에서는 오늘 스타일
          return Container(
            constraints: const BoxConstraints.expand(),
            margin: EdgeInsets.symmetric(
              horizontal: scaleWidth(2.145),
              vertical: scaleHeight(7),
            ),
            decoration: BoxDecoration(
              color: AppColors.pri100,
              borderRadius: BorderRadius.circular(scaleWidth(6)),
              border: Border.all(color: AppColors.pri300, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: scaleHeight(4)),
                Text(
                  '${day.day}',
                  style: AppFonts.suite.caption_md_500(context).copyWith(
                      color: AppColors.pri700),
                ),
                SizedBox(height: scaleHeight(10)),
                Text(
                  '오늘',
                  style: AppFonts.suite.caption_md_500(context).copyWith(
                    color: AppColors.pri600,
                    fontSize: 10.sp,
                  ),
                ),
                if (events.isNotEmpty) ...[
                  const Spacer(),
                  _buildMarkerContent(events.first['result'], context),
                  SizedBox(height: scaleHeight(4)),
                ],
              ],
            ),
          );
        },

        // 기본 날짜 커스텀 UI
        defaultBuilder: (context, day, focusedDay) {
          final events = _getEventsForDay(day);
          if (events.isNotEmpty) {
            final gameResult = events.first['result'];
            return Container(
              constraints: const BoxConstraints.expand(),
              margin: EdgeInsets.symmetric(
                horizontal: scaleWidth(2.145),
                vertical: scaleHeight(7),
              ),
              decoration: BoxDecoration(
                color: AppColors.gray20,
                borderRadius: BorderRadius.circular(scaleWidth(6)),
                border: Border.all(color: AppColors.gray100, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: scaleHeight(4)),
                  Text(
                    '${day.day}',
                    style: AppFonts.suite.caption_md_500(context).copyWith(
                        color: AppColors.gray700),
                  ),
                  _buildMarkerContent(gameResult, context),
                ],
              ),
            );
          }
          // 마커 없는 날
          return Container(
            constraints: const BoxConstraints.expand(),
            margin: EdgeInsets.symmetric(
              horizontal: scaleWidth(2.145),
              vertical: scaleHeight(7),
            ),
            decoration: BoxDecoration(
              color: AppColors.gray30,
              borderRadius: BorderRadius.circular(scaleWidth(6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: scaleHeight(4)),
                Text(
                  '${day.day}',
                  style: AppFonts.suite.caption_md_500(context).copyWith(
                      color: AppColors.gray200),
                ),
              ],
            ),
          );
        },
        // 외부 날짜 커스텀 UI
        outsideBuilder: (context, day, focusedDay) {
          return Container(
            constraints: const BoxConstraints.expand(),
            margin: EdgeInsets.symmetric(
              horizontal: scaleWidth(2.145),
              vertical: scaleHeight(7),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(scaleWidth(6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: scaleHeight(4)),
                Text(
                  '${day.day}',
                  style: AppFonts.suite.caption_md_500(context).copyWith(
                      color: AppColors.gray200),
                ),
              ],
            ),
          );
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        print('Selected day: $selectedDay, Events: ${_getEventsForDay(selectedDay)}');
      },
      onPageChanged: _onCalendarPageChanged,
    );
  }


  // '승/패/무/ETC' 마커 위젯 (SVG 아이콘 사용)
  Widget _buildMarkerContent(String? gameResult, BuildContext context) {
    String text;
    String imagePath;
    Color textColor;

    switch (gameResult?.toUpperCase()) {
      case 'WIN':
        text = '승';
        imagePath = AppImages.win;
        textColor = const Color(0xFFFFC200);
        break;
      case 'LOSE':
        text = '패';
        imagePath = AppImages.lose;
        textColor = const Color(0xFFBF6F2D);
        break;
      case 'TIE':
        text = '무';
        imagePath = AppImages.tie;
        textColor = const Color(0xFF7D7D86);
        break;
      case 'ETC':
        text = 'ETC';
        imagePath = AppImages.etc;
        textColor = const Color(0xFF5E9EFF);
        break;
      default:
        text = '기록';
        imagePath = AppImages.calendar;
        textColor = AppColors.gray700;
    }

    if (!imagePath.endsWith('.svg')) {
      imagePath += '.svg';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 마커 아이콘
        SvgPicture.asset(
          imagePath,
          width: scaleWidth(22),
          height: scaleHeight(22),
        ),
        SizedBox(height: scaleHeight(1)),

        // 승/패/무/ETC 텍스트
        Text(
          text,
          style: AppFonts.suite.c3_sb(context).copyWith(
            color: textColor,
            fontSize: 8.sp,
          ),
        ),
      ],
    );
  }


  /// 통계 패널
  Widget _buildStatsPanel() {
    final stats = calendarData['monthlyStats'];
    bool hasData = stats != null && (stats['recordCount'] ?? 0) > 0;

    return Container(
      width: double.infinity,
      height: scaleHeight(122),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleWidth(16)),
        border: Border.all(color: AppColors.gray50, width: 1),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A9397A1),
            offset: Offset(0, 0),
            blurRadius: scaleWidth(10),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: scaleHeight(18),
        left: scaleWidth(32),
        right: scaleWidth(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_focusedDay.month}월 직관 분석',
                style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray900),
              ),
              SizedBox(width: scaleWidth(6)),
              Container(
                height: scaleHeight(20),
                padding: EdgeInsets.symmetric(horizontal: scaleWidth(8)),
                decoration: BoxDecoration(
                  color: AppColors.pri100,
                  borderRadius: BorderRadius.circular(scaleWidth(4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '리포트',
                  style: AppFonts.suite.caption_md_500(context).copyWith(
                    color: AppColors.pri700,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: hasData ? scaleHeight(13) : scaleHeight(25)),

          if (!hasData)
            Center(
              child: Text(
                '업로드한 기록이 아직 없어요',
                style: AppFonts.suite.body_md_500(context).copyWith(color: AppColors.gray300),
              ),
            )
          else
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 직관 승률
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '직관 승률',
                        style: AppFonts.suite.caption_md_500(context).copyWith(
                          color: AppColors.gray500,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${_formatWinRate(stats!['winRate'] ?? 0.0)} %',
                        style: AppFonts.pretendard.title_sm_600(context).copyWith(color: AppColors.gray900),
                      ),
                    ],
                  ),
                  // 기록 횟수
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기록 횟수',
                        style: AppFonts.suite.caption_md_500(context).copyWith(
                          color: AppColors.gray500,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${stats!['recordCount'] ?? 0} 회',
                        style: AppFonts.pretendard.title_sm_600(context).copyWith(color: AppColors.gray900),
                      ),
                    ],
                  ),
                  // 공감 받은 횟수
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '공감 받은 횟수',
                        style: AppFonts.suite.caption_md_500(context).copyWith(
                          color: AppColors.gray500,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${stats!['totalLikes'] ?? 0} 회',
                        style: AppFonts.pretendard.title_sm_600(context).copyWith(color: AppColors.gray900),
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

  // 승률 포맷팅 (0~100% 범위)
  String _formatWinRate(double winRate) {
    // 소수점 이하가 0이면 정수로 표시
    if (winRate % 1 == 0) {
      return winRate.toInt().toString();
    }
    // 아니면 소수점 한 자리까지
    return winRate.toStringAsFixed(1);
  }

  ///리스트 탭
  Widget _buildListTab() {
    return _KeepAliveWrapper(
      child: isLoadingRecords
          ? Center(child: CircularProgressIndicator(color: AppColors.pri500))
          : feedList.isEmpty
          ? Center(
        child: Text(
          '업로드한 기록이 아직 없어요',
          style: AppFonts.suite.head_sm_700(context).copyWith(
              color: AppColors.gray300),
        ),
      )
          : Container(
        color: AppColors.white,
        child: ListView.builder(
          padding: EdgeInsets.only(top: scaleHeight(19)),
          itemCount: feedList.length,
          itemBuilder: (context, index) {
            final record = feedList[index];
            final isLiked = _likeManager.getLikedStatus(record['recordId']) ?? record['isLiked'] ?? false;
            final likeCount = _likeManager.getLikeCount(record['recordId']) ?? record['likeCount'] ?? 0;
            final commentCount = _likeManager.getCommentCount(record['recordId']) ?? record['commentCount'] ?? 0;

            final feedData = {
              'recordId': record['recordId'],
              'profileImageUrl': record['profileImageUrl'],
              'nickname': record['nickname'],
              'favTeam': record['favTeam'],
              'mediaUrls': record['mediaUrls'] ?? [],
              'longContent': record['longContent'] ?? '',
              'emotionCode': record['emotionCode'],
              'emotionLabel': record['emotionLabel'] ?? '',
              'homeTeam': record['homeTeam'] ?? '',
              'awayTeam': record['awayTeam'] ?? '',
              'stadium': record['stadium'] ?? '',
              'gameDate': record['gameDate'] ?? '',
              'isLiked': isLiked,
              'likeCount': likeCount,
              'commentCount': commentCount,
            };

            return FeedItemWidget(
              feedData: feedData,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        DetailFeedScreen(recordId: record['recordId']),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
                if (result != null && result is Map &&
                    result['deleted'] == true) {
                  final deletedRecordId = result['recordId'];
                  setState(() {
                    feedList.removeWhere((r) =>
                    r['recordId'] == deletedRecordId);
                  });
                }
              },
              onProfileNavigated: () {
              },
            );
          },
        ),
      ),
    );
  }

  ///모아보기 탭
  Widget _buildGridTab() {
    return _KeepAliveWrapper(
      child: isLoadingRecords
          ? Center(child: CircularProgressIndicator(color: AppColors.pri500))
          : feedList.isEmpty
          ? Center(
        child: Text(
          '업로드한 기록이 아직 없어요',
          style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray300),
        ),
      )
          : GridView.builder(
        padding: EdgeInsets.only(
          left: scaleWidth(20),
          right: scaleWidth(20),
          top: scaleHeight(24),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: scaleWidth(6),
          mainAxisSpacing: scaleHeight(9),
          childAspectRatio: 102 / 142,
        ),
        itemCount: feedList.length,
        itemBuilder: (context, index) {
          final record = feedList[index];
          return _buildGridItem(record);
        },
      ),
    );
  }
}

class _FriendProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _FriendProfileTabBarDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: 0,
      child: Container(
        color: Colors.white,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FriendProfileTabBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

// 고정 헤더 Delegate
class _FriendProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final String nickname;
  final bool isScrolled;
  final String? followStatus;
  final VoidCallback onBackPressed;
  final VoidCallback onFollowPressed;
  final bool isBlocked;
  final VoidCallback onBlockTap;
  final bool isMutualFollow;

  _FriendProfileHeaderDelegate({
    required this.height,
    required this.nickname,
    required this.isScrolled,
    required this.followStatus,
    required this.onBackPressed,
    required this.onFollowPressed,
    required this.isBlocked,
    required this.onBlockTap,
    required this.isMutualFollow,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool showHeaderContent = isScrolled;
    final bool isFollowing = followStatus == 'FOLLOWING';

    return Container(
      color: Colors.white,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Row(
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: onBackPressed,
            child: Container(
              alignment: Alignment.center,
              child: SvgPicture.asset(
                AppImages.backBlack,
                width: scaleHeight(24),
                height: scaleHeight(24),
                fit: BoxFit.contain,
              ),
            ),
          ),

          if (showHeaderContent) ...[
            SizedBox(width: scaleWidth(20)),
            Expanded(
              child: Text(
                nickname,
                style: AppFonts.suite.head_sm_700(context).copyWith(color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 팔로잉 중이면 dots, 아니면 버튼
            if (isFollowing)
              GestureDetector(
                onTap: () {
                  showCustomActionSheet(
                    context: context,
                    options: [
                      ActionSheetOption(
                        text: isBlocked ? '차단 해제' : '차단하기',
                        textColor: AppColors.gray900,
                        onTap: () {
                          Navigator.pop(context);
                          onBlockTap();
                        },
                      ),
                      ActionSheetOption(
                        text: '신고하기',
                        textColor: AppColors.error,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
                child: SvgPicture.asset(
                  AppImages.dots_horizontal,
                  width: scaleHeight(24),
                  height: scaleHeight(24),
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                width: scaleWidth(88),
                height: scaleHeight(32),
                child: ElevatedButton(
                  onPressed: isBlocked ? onBlockTap : onFollowPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBlocked
                        ? AppColors.gray600 : isMutualFollow
                        ? AppColors.gray600 : (followStatus == 'FOLLOWING' || followStatus == 'REQUESTED')
                        ? AppColors.gray50 : AppColors.gray600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleHeight(8)),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(scaleWidth(88), scaleHeight(32)),
                  ),
                  child: Center(
                    child: Text(
                      isBlocked ? '차단 해제' : _getButtonText(followStatus ?? 'NOT_FOLLOWING'),
                      style: AppFonts.pretendard.caption_md_500(context).copyWith(
                        color: isBlocked
                            ? AppColors.gray20 : isMutualFollow
                            ? AppColors.gray20 : (followStatus == 'FOLLOWING' || followStatus == 'REQUESTED')
                            ? AppColors.gray600 : AppColors.gray20,
                      ),
                    ),
                  ),
                ),
              ),
          ] else ...[
            // 평상시: dots만
            Spacer(),
            GestureDetector(
              onTap: () {
                showCustomActionSheet(
                  context: context,
                  options: [
                    ActionSheetOption(
                      text: isBlocked ? '차단 해제' : '차단하기',
                      textColor: AppColors.gray900,
                      onTap: () {
                        Navigator.pop(context);
                        onBlockTap();
                      },
                    ),
                    ActionSheetOption(
                      text: '신고하기',
                      textColor: AppColors.error,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
              child: SvgPicture.asset(
                AppImages.dots_horizontal,
                width: scaleHeight(24),
                height: scaleHeight(24),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Color getButtonBackgroundColor() {
    if (isBlocked) return AppColors.gray600;
    if (isMutualFollow) return AppColors.gray600;

    switch (followStatus) {
      case 'FOLLOWING':
      case 'REQUESTED':
        return AppColors.gray50;
      default:
        return AppColors.gray600;
    }
  }

  String _getButtonText(String status) {
    if (isMutualFollow) return '맞팔로우';

    switch (status) {
      case 'FOLLOWING':
        return '팔로잉';
      case 'REQUESTED':
        return '요청됨';
      default:
        return '팔로우';
    }
  }

  Color _getButtonTextColor() {
    if (isBlocked) return AppColors.gray20;
    if (isMutualFollow) return AppColors.gray20;

    switch (followStatus) {
      case 'FOLLOWING':
      case 'REQUESTED':
        return AppColors.gray600;
      default:
        return AppColors.gray20;
    }
  }

  @override
  bool shouldRebuild(_FriendProfileHeaderDelegate oldDelegate) {
    return nickname != oldDelegate.nickname ||
        isScrolled != oldDelegate.isScrolled ||
        followStatus != oldDelegate.followStatus ||
        isMutualFollow != oldDelegate.isMutualFollow;
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _StickyDetectorDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Function(bool) onSticky;

  _StickyDetectorDelegate({
    required this.height,
    required this.onSticky,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isSticky = shrinkOffset >= maxExtent;
    onSticky(isSticky);
    return SizedBox(height: height);
  }

  @override
  bool shouldRebuild(_StickyDetectorDelegate oldDelegate) => false;
}
