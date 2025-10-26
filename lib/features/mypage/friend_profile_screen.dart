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

class FriendProfileScreen extends StatefulWidget {
  final int userId;

  const FriendProfileScreen({
    Key? key,
    required this.userId,
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
  final _likeManager = FeedCountManager();

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

      if (!mounted) return;
      final newFollowStatus = response['followStatus'] ?? 'NOT_FOLLOWING';

      setState(() {
        nickname = response['nickname'] ?? '알 수 없음';
        favTeam = response['favTeam'] ?? '응원팀 없음';
        profileImageUrl = response['profileImageUrl'];
        postCount = response['recordCount'] ?? 0;
        followerCount = response['followerCount'] ?? 0;
        followingCount = response['followingCount'] ?? 0;
        isPrivate = response['isPrivate'] ?? false;
        followStatus = newFollowStatus;
        isLoading = false;
      });
      print('✅ setState 완료 - 현재 followStatus: $followStatus');
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

  Future<void> _loadMyRecords() async {
    setState(() {
      isLoadingRecords = true;
    });

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
        await UserApi.unfollowUser(widget.userId);
        setState(() {
          followStatus = 'NOT_FOLLOWING';
          followerCount = followerCount > 0 ? followerCount - 1 : 0;
        });
      } else if (followStatus == 'NOT_FOLLOWING') {
        final response = await UserApi.followUser(widget.userId);
        final responseData = response['data'];
        setState(() {
          if (responseData['pending'] == true) {
            followStatus = 'REQUESTED';
          } else {
            followStatus = 'FOLLOWING';
            followerCount++;
          }
        });
      } else if (followStatus == 'REQUESTED') {
        await UserApi.unfollowUser(widget.userId);
        setState(() {
          followStatus = 'NOT_FOLLOWING';
        });
      }

    } catch (e) {
      print('❌ 팔로우 처리 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로우 처리에 실패했습니다.'),
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
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                // 상단 액션바를 고정 헤더로 변경
                SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _FriendProfileHeaderDelegate(
                    height: scaleHeight(60),
                    nickname: nickname,
                    isScrolled: innerBoxIsScrolled,
                    followStatus: followStatus,
                    onBackPressed: () => Navigator.pop(context),
                    onFollowPressed: _handleFollow,
                  ),
                ),
                // 프로필 영역
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileSection(),
                    SizedBox(height: scaleHeight(20)),
                    _buildFollowButton(),
                    SizedBox(height: scaleHeight(30)),
                  ]),
                ),
                // 탭바
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
          onPressed: followStatus == null ? null : _handleFollow,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonBackgroundColor(),
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

  Color _getButtonBackgroundColor() {
    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray50;
      case 'REQUESTED':
        return AppColors.gray50;
      default:
        return AppColors.gray600;
    }
  }

  String _getButtonText() {
    switch (followStatus) {
      case 'FOLLOWING':
        return '팔로잉';
      case 'REQUESTED':
        return '요청됨';
      default:
        return '팔로우';
    }
  }

  Color _getButtonTextColor() {
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

  /// 캘린더 헤더
  Widget _buildCalendarHeader() {
    return Padding(
      padding: EdgeInsets.only(top: scaleHeight(20), bottom: scaleHeight(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: scaleWidth(44)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                  _loadMyRecords();
                },
                child: Padding(
                  padding: EdgeInsets.only(right: scaleWidth(10)),
                  child: SvgPicture.asset(
                    AppImages.polygon_left,
                    width: scaleWidth(14),
                    height: scaleHeight(12),
                  ),
                ),
              ),
              Text(
                DateFormat('yyyy년 M월', 'ko_KR').format(_focusedDay),
                style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray900),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                  _loadMyRecords();
                },
                child: Padding(
                  padding: EdgeInsets.only(left: scaleWidth(10)),
                  child: SvgPicture.asset(
                    AppImages.polygon_right,
                    width: scaleWidth(14),
                    height: scaleHeight(12),
                  ),
                ),
              ),
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
              _loadMyRecords();
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
                style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.pri800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 캘린더
  Widget _buildTableCalendar() {
    return TableCalendar(
      locale: 'ko_KR',
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(2024),
      lastDay: DateTime.utc(2026),
      calendarFormat: _calendarFormat,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerVisible: false,
      sixWeekMonthsEnforced: true, // 6주 달력 고정
      rowHeight: scaleHeight(60),
      daysOfWeekHeight: scaleHeight(45),
      calendarStyle: CalendarStyle(
        cellMargin: EdgeInsets.all(scaleWidth(4)),
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
          color: AppColors.pri100, // pri300 -> pri100로 변경
          borderRadius: BorderRadius.circular(scaleWidth(6)),
          border: Border.all(color: AppColors.pri300, width: 1),
        ),
        todayTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.pri700),
        // 텍스트 스타일
        defaultTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray200), // gray200
        weekendTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray200), // gray200
        outsideTextStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray200), // 텍스트도 gray200
      ),
      // 요일 헤더 스타일 - gray700
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray700), // gray700
        weekendStyle: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray700), // gray700
      ),
      calendarBuilders: CalendarBuilders(
        // 오늘 날짜 커스텀 UI
        todayBuilder: (context, day, focusedDay) {
          final events = _getEventsForDay(day);
          return Container(
            constraints: BoxConstraints.expand(),
            margin: EdgeInsets.all(scaleWidth(2)),
            decoration: BoxDecoration(
              color: AppColors.pri100,
              borderRadius: BorderRadius.circular(scaleWidth(6)),
              border: Border.all(color: AppColors.pri300, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '${day.day}',
                      style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.pri700),
                    ),
                    if (events.isNotEmpty) _buildMarkerContent(events.first['result'], context),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(bottom: scaleHeight(8)),
                  child: Text(
                    '오늘',
                    style: AppFonts.suite.caption_md_500(context).copyWith(
                      color: AppColors.pri600,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
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
              constraints: BoxConstraints.expand(),
              margin: EdgeInsets.all(scaleWidth(2)),
              decoration: BoxDecoration(
                color: AppColors.gray20,
                borderRadius: BorderRadius.circular(scaleWidth(6)),
                border: Border.all(color: AppColors.gray100, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray700),
                  ),
                  _buildMarkerContent(gameResult, context),
                ],
              ),
            );
          }

          return Container(
            constraints: BoxConstraints.expand(),
            margin: EdgeInsets.all(scaleWidth(2)),
            decoration: BoxDecoration(
              color: AppColors.gray30,
              borderRadius: BorderRadius.circular(scaleWidth(6)),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: scaleHeight(4)),
                child: Text(
                  '${day.day}',
                  style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray200),
                ),
              ),
            ),
          );
        },
        // 외부 날짜 커스텀 UI
        outsideBuilder: (context, day, focusedDay) {
          return Container(
            constraints: BoxConstraints.expand(),
            margin: EdgeInsets.all(scaleWidth(2)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(scaleWidth(6)),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: scaleHeight(4)),
                child: Text(
                  '${day.day}',
                  style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray200),
                ),
              ),
            ),
          );
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        // TODO: 선택한 날짜 처리
        print('Selected day: $selectedDay, Events: ${_getEventsForDay(selectedDay)}');
      },
      onPageChanged: _onCalendarPageChanged,
    );
  }

  // 경기 결과 마커 - SVG 아이콘 사용
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
        text = '관람';
        imagePath = AppImages.calendar;
        textColor = AppColors.gray700;
    }

    // SVG 확장자 확인
    if (!imagePath.endsWith('.svg')) {
      imagePath += '.svg';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 22x22 크기 SVG
        SvgPicture.asset(
          imagePath,
          width: scaleWidth(22),
          height: scaleHeight(22),
        ),
        SizedBox(height: scaleHeight(1)),
        Text(
          text,
          style: AppFonts.suite.c3_sb(context).copyWith(
            color: textColor,
            fontSize: 8.sp,
            height: 1.25,
            letterSpacing: 0,
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
    // 0~100% 범위
    if (winRate <= 0.0) {
      winRate = 0.0;
    } else if (winRate >= 100.0) {
      winRate = 100.0;
    } else if (winRate < 1.0) {
      // 1% 미만일 경우 소수점 표시
      winRate = winRate * 100; // 0.x => x.x%
      return winRate.toInt().toString();
    }
    return winRate.toString();
  }

  ///리스트 탭
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

  ///모아보기 탭
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
      elevation: shrinkOffset > 0 ? 1.0 : 0.0,
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

  _FriendProfileHeaderDelegate({
    required this.height,
    required this.nickname,
    required this.isScrolled,
    required this.followStatus,
    required this.onBackPressed,
    required this.onFollowPressed,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // overlapsContent가 true이면 탭바가 헤더 아래로 들어왔다는 의미
    // 이 시점에 닉네임과 팔로우 버튼을 표시하도록 변경
    final bool showHeaderContent = shrinkOffset > 0;

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

          // 상단에 붙었을 때 (showHeaderContent == true) 닉네임과 팔로우 버튼 표시
          if (showHeaderContent) ...[
            SizedBox(width: scaleWidth(20)),
            Expanded(
              child: Text(
                nickname,
                style: AppFonts.suite.head_sm_700(context).copyWith(color: Colors.black), // Suite체, head_sm_700 굵기, black 색상
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 팔로우/팔로잉 버튼
            Container(
              width: scaleWidth(88),
              height: scaleHeight(32),
              child: ElevatedButton(
                onPressed: onFollowPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonBackgroundColor(followStatus ?? "NOTFOLLOWING"),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize: Size(scaleWidth(88), scaleHeight(32)),
                ),
                child: Center(
                  child: Text(
                    _getButtonText(followStatus!),
                    style: AppFonts.pretendard.caption_md_500(context).copyWith(
                      color: _getButtonTextColor(followStatus!),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // 평상시에는 dots_horizontal
            Spacer(),
            GestureDetector(
              onTap: () {
                print("더보기 메뉴");
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


  Color _getButtonBackgroundColor(String status) {
    switch (status) {
      case 'FOLLOWING':
        return AppColors.gray50;
      case 'REQUESTED':
        return AppColors.gray50;
      default:
        return AppColors.gray600;
    }
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'FOLLOWING':
        return '팔로잉';
      case 'REQUESTED':
        return '요청됨';
      default:
        return '팔로우';
    }
  }

  Color _getButtonTextColor(String status) {
    switch (status) {
      case 'FOLLOWING':
        return AppColors.gray600;
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
        followStatus != oldDelegate.followStatus;
  }
}