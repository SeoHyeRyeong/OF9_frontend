import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/api/record_api.dart';
import 'package:frontend/features/mypage/settings_screen.dart';
import 'package:frontend/features/mypage/follower_screen.dart';
import 'package:frontend/features/mypage/following_screen.dart';
import 'package:frontend/features/mypage/edit_profile_screen.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/features/feed/detail_feed_screen.dart';
import 'package:frontend/features/feed/feed_item_widget.dart';
import 'package:frontend/utils/feed_count_manager.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> with SingleTickerProviderStateMixin{
  int selectedTabIndex = 2; // 0: 캘린더, 1: 리스트, 2: 모아보기(그리드)

  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  int postCount = 0;
  int followingCount = 0;
  int followerCount = 0;
  bool isPrivate = false;
  final _likeManager = FeedCountManager();

  // 탭 애니메이션 관련 변수
  late AnimationController _tabAnimationController;
  late PageController _tabPageController;
  double _currentTabPageValue = 0.0;
  bool _isTabPageScrolling = false;

  List<Map<String, dynamic>> feedList = [];
  Map<String, dynamic> calendarData = {}; // 캘린더 데이터 (Map)
  bool isLoading = true;
  bool isLoadingRecords = true;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    final List<dynamic> records = calendarData['records'] ?? [];

    // API 응답의 'records' 리스트에서 'gameDate'가 일치하는 것만 필터링
    return records.where((record) {
      return record['gameDate'] == formattedDay;
    }).toList().cast<Map<String, dynamic>>();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; //캘린더 선택된 날짜 초기화
    _likeManager.addListener(_onGlobalStateChanged);

    _tabAnimationController = AnimationController(     // 탭 애니메이션 초기화
      duration: Duration(milliseconds: 250),
      vsync: this,
    );

    _tabPageController = PageController(initialPage: 2); // 초기 페이지 설정: 모아보기
    _currentTabPageValue = 2.0;

    _tabPageController.addListener(() {
      if (_tabPageController.hasClients) {
        setState(() {
          _currentTabPageValue = _tabPageController.page ?? 2.0;
          _isTabPageScrolling = true;
        });
      }
    });

    _loadUserInfo();
    _loadMyRecords();
  }

  @override
  void dispose() {
    _likeManager.removeListener(_onGlobalStateChanged);
    _tabAnimationController.dispose();
    _tabPageController.dispose();
    super.dispose();
  }

  void _onGlobalStateChanged() {
    setState(() {
    });

  }

  //탭 관련 함수 추가
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
    setState(() => isLoading = true);
    try {
      final response = await UserApi.getMyProfile();
      if (!mounted) return;
      final userInfo = response['data'];
      setState(() {
        nickname = userInfo['nickname'] ?? '알 수 없음';
        favTeam = userInfo['favTeam'] ?? '응원팀 없음';
        profileImageUrl = userInfo['profileImageUrl'];
        postCount = userInfo['recordCount'] ?? 0;
        followingCount = userInfo['followingCount'] ?? 0;
        followerCount = userInfo['followerCount'] ?? 0;
        isPrivate = userInfo['isPrivate'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('❌ 사용자 정보 불러오기 실패: $e');
      setState(() {
        nickname = "정보 로딩 실패";
        favTeam = "-";
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 정보를 불러오는데 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMyRecords() async {
    setState(() => isLoadingRecords = true);
    try {
      if (selectedTabIndex == 0) {
        final dayToFetch = _focusedDay;
        final data = await RecordApi.getMyRecordsCalendar(
          year: dayToFetch.year,
          month: dayToFetch.month,
        );
        if (!mounted) return;
        setState(() {
          calendarData = data;
          isLoadingRecords = false;
        });
      } else if (selectedTabIndex == 1) {
        // 리스트
        final records = await RecordApi.getMyRecordsList();
        if (!mounted) return;
        setState(() {
          feedList = records;
          isLoadingRecords = false;
        });
      } else {
        // 모아보기 (Tab 2)
        final records = await RecordApi.getMyRecordsFeed();
        if (!mounted) return;
        setState(() {
          feedList = records;
          isLoadingRecords = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ 기록 불러오기 실패 (탭: $selectedTabIndex): $e');
      setState(() {
        feedList = [];
        calendarData = {}; // 캘린더 데이터도 초기화
        isLoadingRecords = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기록을 불러오는데 실패했습니다 (탭: ${_getTabName(selectedTabIndex)}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTabName(int index) {
    switch (index) {
      case 0: return '캘린더';
      case 1: return '리스트';
      case 2: return '모아보기';
      default: return '';
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadUserInfo(), _loadMyRecords()]);
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
              print('❌ Image.network 에러: $error');
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
          print('❌ Base64 디코딩 실패: $e');
          return _buildImageErrorWidget(width, height);
        }
      }
      return _buildImageErrorWidget(width, height);
    } catch (e) {
      print('❌ 이미지 처리 실패: $e');
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
          Icon(Icons.image_not_supported_outlined, size: scaleWidth(32), color: AppColors.gray300),
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
      onTap: () => print('기록 상세보기: ${record['recordId']}'),
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

              // 날짜 배지
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

              // 좋아요 배지
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
                        SvgPicture.asset(AppImages.heart_white, width: scaleWidth(14), height: scaleHeight(14)),
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
      onPopInvoked: (didPop) {
        if (!didPop) {
          print("뒤로가기 버튼 비활성화 (마이페이지)");
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                // 프로필 영역
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTopActionsBar(),
                    _buildProfileSection(),
                    SizedBox(height: scaleHeight(20)),
                    _buildEditProfileButton(),
                    SizedBox(height: scaleHeight(30)),
                  ]),
                ),
                // 탭바
                SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _MyPageTabBarDelegate(
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

  // 새로 추가된 함수: 상단 액션 바 (Share, Settings 아이콘)
  Widget _buildTopActionsBar() {
    return Container(
      height: scaleHeight(60),
      padding: EdgeInsets.only(right: scaleWidth(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () { print("공유 버튼 클릭"); },
            child: SvgPicture.asset(
              AppImages.Share,
              width: scaleWidth(24),
              height: scaleHeight(24),
              color: AppColors.gray600,
            ),
          ),
          SizedBox(width: scaleWidth(20)),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            child: SvgPicture.asset(
              AppImages.Setting,
              width: scaleWidth(24),
              height: scaleHeight(24),
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  // 프로필 세션
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
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.pri400,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    SvgPicture.asset(
                      AppImages.profile,
                      fit: BoxFit.cover,
                    ),)
                  : SvgPicture.asset(AppImages.profile, fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: scaleWidth(16)),
          // 팀 정보 + 닉네임 + 통계
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: scaleHeight(2)),
                // 팀 정보 (조건부 표시)
                if (!isLoading && favTeam.isNotEmpty && favTeam != "응원팀 없음") ...[
                  IntrinsicWidth( // 텍스트 크기에 맞게 가로 크기 조정
                    child: Container(
                      height: scaleHeight(22),
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(12)),
                      decoration: BoxDecoration(
                        color: AppColors.gray30,
                        borderRadius: BorderRadius.circular(scaleWidth(20)),
                      ),
                      alignment: Alignment.center, // 세로 기준 센터 정렬
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
                // 닉네임
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
                // 통계 정보 (게시글, 팔로잉, 팔로워)
                Row(
                  children: [
                    _buildStatItem("게시글", postCount),
                    SizedBox(width: scaleWidth(10)),
                    _buildStatItem("팔로잉", followingCount, onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const FollowingScreen(),
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
                          pageBuilder: (context, animation, secondaryAnimation) => const FollowerScreen(),
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

  //프로필 수정
  Widget _buildEditProfileButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: SizedBox(
        width: double.infinity,
        height: scaleHeight(42),
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const EditProfileScreen(
                  previousRoute: 'mypage',
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
            if (result == true) {
              _loadUserInfo();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gray600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleHeight(8)),
            ),
            elevation: 0,
          ),
          child: Text(
            '프로필 수정',
            style: AppFonts.suite.caption_md_500(context).copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  ///탭 바
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
                // 탭 아이콘들
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
      // 0 -> 1 (왼쪽에서 중앙으로)
      final centerPosition = (screenWidth - tabWidth) / 2;
      indicatorOffset = scrollProgress * centerPosition;
    } else {
      // 1 -> 2 (중앙에서 오른쪽으로)
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


  ///캘린더
  Widget _buildCalendarTab() {
    if (isLoadingRecords) {
      return Center(child: CircularProgressIndicator(color: AppColors.pri500));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Column(
        children: [
          _buildCalendarHeader(),
          _buildTableCalendar(),
          SizedBox(height: scaleHeight(24)),
          _buildStatsPanel(),
        ],
      ),
    );
  }

  ///리스트
  Widget _buildListTab() {
    if (isLoadingRecords) {
      return Center(child: CircularProgressIndicator(color: AppColors.pri500));
    }
    if (feedList.isEmpty) {
      return Center(
        child: Text(
          '업로드한 기록이 아직 없어요',
          style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray300),
        ),
      );
    }

    // FeedItemWidget 사용
    return Container(
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
                  pageBuilder: (context, animation1, animation2) => DetailFeedScreen(recordId: record['recordId']),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );

              // 삭제되었으면 리스트 업데이트
              if (result != null && result is Map && result['deleted'] == true) {
                final deletedRecordId = result['recordId'];
                setState(() {
                  feedList.removeWhere((r) => r['recordId'] == deletedRecordId);
                });
              }
            },
          );
        },
      ),
    );
  }

  ///모아보기
  Widget _buildGridTab() {
    if (isLoadingRecords) {
      return Center(child: CircularProgressIndicator(color: AppColors.pri500));
    }
    if (feedList.isEmpty) {
      return Center(
        child: Text(
          '업로드한 기록이 아직 없어요',
          style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray300),
        ),
      );
    }
    return GridView.builder(
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
    );
  }


  // 캘린더 커스텀 헤더 (날짜 + 오늘 버튼)
  Widget _buildCalendarHeader() {
    return Padding(
      // 캘린더 헤더는 좌우 패딩 0 (디자인 일치)
      padding: EdgeInsets.symmetric(vertical: scaleHeight(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(Icons.chevron_left, color: AppColors.gray900, size: scaleWidth(24)),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                  _loadMyRecords(); // 이전 달 데이터 다시 로드
                },
              ),
              SizedBox(width: scaleWidth(8)),
              Text(
                DateFormat('yyyy년 M월', 'ko_KR').format(_focusedDay),
                style: AppFonts.suite.h4_b(context).copyWith(color: Colors.black),
              ),
              SizedBox(width: scaleWidth(8)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(Icons.chevron_right, color: AppColors.gray900, size: scaleWidth(24)),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                  _loadMyRecords(); // 다음 달 데이터 다시 로드
                },
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              // '오늘'이 속한 달/연도와 이미 같은지 확인
              final now = DateTime.now();
              // [수정] isSameMonth 대신 연/월 직접 비교
              if (_focusedDay.year == now.year && _focusedDay.month == now.month) return;

              setState(() {
                _focusedDay = now;
                _selectedDay = now;
              });
              _loadMyRecords(); // 오늘이 속한 달 데이터 다시 로드
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(12), vertical: scaleHeight(4)),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(scaleWidth(6)),
              ),
              child: Text(
                '오늘',
                style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray700),
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
      firstDay: DateTime.utc(2000),
      lastDay: DateTime.utc(2100),
      calendarFormat: _calendarFormat,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerVisible: false, // 커스텀 헤더를 사용하므로 기본 헤더 숨김
      eventLoader: _getEventsForDay, // 날짜별 이벤트 로더 연결
      sixWeekMonthsEnforced: true, // 6주 고정
      rowHeight: scaleHeight(60), // 셀 높이

      // '오늘' 날짜 스타일
      calendarStyle: CalendarStyle(
        cellMargin: EdgeInsets.all(scaleWidth(2)),
        defaultDecoration: BoxDecoration(
          color: AppColors.gray30, // 기록 없는 날 회색 배경
          borderRadius: BorderRadius.circular(scaleWidth(6)),
        ),
        weekendDecoration: BoxDecoration(
          color: AppColors.gray30, // 주말도 동일한 회색 배경
          borderRadius: BorderRadius.circular(scaleWidth(6)),
        ),
        outsideDecoration: BoxDecoration(
          color: Colors.white, // 바깥 날짜는 흰색 배경
          borderRadius: BorderRadius.circular(scaleWidth(6)),
        ),
        // '오늘' 날짜 기본 스타일 (기록이 없을 때)
        todayDecoration: BoxDecoration(
          color: AppColors.pri50, // 오늘 날짜 파란 배경
          borderRadius: BorderRadius.circular(scaleWidth(6)),
          border: Border.all(color: AppColors.pri200, width: 1),
        ),
        todayTextStyle: AppFonts.suite.c1_m(context).copyWith(color: AppColors.pri500),
        defaultTextStyle: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray800),
        weekendTextStyle: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray800),
        outsideTextStyle: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray200),
      ),

      // '일, 월, 화...' 요일 스타일
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray800),
        weekendStyle: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400), // 토, 일
      ),

      // 캘린더 셀 커스텀 빌더
      calendarBuilders: CalendarBuilders(
        // '오늘' 날짜 밑에 '오늘' 텍스트 추가
        todayBuilder: (context, day, focusedDay) {
          final events = _getEventsForDay(day);
          // '오늘' 날짜 UI
          return Container(
            margin: EdgeInsets.all(scaleWidth(2)),
            decoration: BoxDecoration(
              color: AppColors.pri50, // 오늘 날짜 파란 배경
              borderRadius: BorderRadius.circular(scaleWidth(6)),
              border: Border.all(color: AppColors.pri200, width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.pri500),
                    ),
                    Text(
                      '오늘',
                      // ▼▼▼ [수정] c3_m -> c3_sb
                      style: AppFonts.suite.c3_sb(context).copyWith(color: AppColors.pri400),
                    )
                  ],
                ),
                if (events.isNotEmpty)
                  _buildCalendarDayMarker(events.first['gameResult']),
              ],
            ),
          );
        },
        // '오늘'을 제외한 날짜 (기본)
        defaultBuilder: (context, day, focusedDay) {
          final events = _getEventsForDay(day);
          if (events.isNotEmpty) {
            // 기록이 있으면 흰색 배경 + 테두리
            final gameResult = events.first['gameResult'];
            return Container(
              margin: EdgeInsets.all(scaleWidth(2)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(scaleWidth(6)),
                border: Border.all(color: AppColors.gray100, width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray800),
                  ),
                  _buildCalendarDayMarker(gameResult), // 마커 오버레이
                ],
              ),
            );
          }
          // 기록 없으면 null 반환 (calendarStyle의 defaultDecoration 적용)
          return null;
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay; // focusedDay도 함께 업데이트
        });
        // TODO: 선택된 날짜의 기록을 아래에 표시하는 로직
        print('Selected day: $selectedDay');
      },
      onPageChanged: (focusedDay) {
        // 캘린더를 스와이프했을 때
        // ▼▼▼ [수정] !isSameMonth(...) -> 연/월 직접 비교
        if (_focusedDay.year != focusedDay.year || _focusedDay.month != focusedDay.month) {
          setState(() {
            _focusedDay = focusedDay;
          });
          _loadMyRecords();
        }
      },
    );
  }

  // '승/패/무' 마커 위젯
  Widget _buildCalendarDayMarker(String? gameResult) {
    String text;
    Color color;
    // TODO: 승/패/무 아이콘 SVG로 교체 필요
    IconData icon; // 임시 아이콘

    switch (gameResult) {
      case 'WIN':
        text = '승';
        color = const Color(0xFFFFC200); // Yellow
        icon = Icons.star;
        break;
      case 'LOSE':
        text = '패';
        color = AppColors.gray400; // Gray
        icon = Icons.star_border; // 임시
        break;
      case 'DRAW':
        text = '무';
        color = const Color(0xFF5B96F0); // Blue
        icon = Icons.star_half; // 임시
        break;
      default:
      // gameResult가 null이거나 예상 못한 값일 때 (예: 'SCHEDULED')
        text = '기록';
        color = AppColors.gray700;
        icon = Icons.bookmark; // 임시
    }

    return Positioned(
      bottom: scaleHeight(4), // 셀 하단에 위치
      left: 0,
      right: 0,
      child: Column(
        children: [
          Icon(icon, color: color, size: scaleWidth(16.5)),
          SizedBox(height: scaleHeight(1)),
          Text(
            text,
            style: AppFonts.suite.c3_sb(context).copyWith(
              color: color,
              fontSize: 8.sp, // 8pt
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  // 하단 통계 패널
  Widget _buildStatsPanel() {
    final stats = calendarData['monthlyStats'];
    bool hasData = (stats != null && (stats['recordCount'] ?? 0) > 0);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: scaleHeight(122)), // 최소 높이
      padding: EdgeInsets.all(scaleWidth(24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleWidth(16)),
        border: Border.all(color: AppColors.gray50, width: 1),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A9497A1), // 10% opacity
            blurRadius: 16,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsPanelHeader(),
          if (!hasData) ...[
            // 데이터가 없는 경우 (image_2cdeff.png)
            SizedBox(height: scaleHeight(16)), // 헤더와의 간격
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: scaleHeight(10)), // 높이 확보
                child: Text(
                  '업로드한 기록이 아직 없어요',
                  // ▼▼▼ [수정] b1_m -> h5_b
                  style: AppFonts.suite.h5_b(context).copyWith(color: AppColors.gray300),
                ),
              ),
            )
          ] else ...[
            // 데이터가 있는 경우
            SizedBox(height: scaleHeight(16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("직관 승률", ((stats!['winRate'] ?? 0.0) * 100).toInt().toString(), "%"),
                _buildStatColumn("기록 횟수", (stats['recordCount'] ?? 0).toString(), "회"),
                _buildStatColumn("공감 받은 횟수", (stats['totalLikes'] ?? 0).toString(), "회"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 통계 패널 헤더 (O월 직관 분석 [리포트])
  Widget _buildStatsPanelHeader() {
    return Row(
      children: [
        Text(
          '${_focusedDay.month}월 직관 분석',
          style: AppFonts.suite.b1_sb(context).copyWith(color: AppColors.gray900),
        ),
        SizedBox(width: scaleWidth(6)),
        GestureDetector(
          onTap: () {
            // TODO: 리포트 페이지로 이동
            print("리포트 버튼 클릭");
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(8), vertical: scaleHeight(2)),
            decoration: BoxDecoration(
              color: AppColors.pri50, // Light blue
              borderRadius: BorderRadius.circular(scaleWidth(4)),
            ),
            child: Text(
              '리포트',
              style: AppFonts.suite.c3_sb(context).copyWith(color: AppColors.pri500),
            ),
          ),
        ),
      ],
    );
  }

  // 통계 항목 (승률, 횟수 등)
  Widget _buildStatColumn(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray500),
        ),
        SizedBox(height: scaleHeight(4)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.padLeft(2, '0'), // 2자리로 패딩 (예: 9% -> 09%)
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray950,
                height: 1.0,
              ),
            ),
            SizedBox(width: scaleWidth(2)),
            Text(
              unit,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18.sp, // 단위는 조금 더 작게
                fontWeight: FontWeight.w600,
                color: AppColors.gray950,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MyPageTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _MyPageTabBarDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: shrinkOffset > 0 ? 1.0 : 0.0,
      child: Container(
        color: Colors.white,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_MyPageTabBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}