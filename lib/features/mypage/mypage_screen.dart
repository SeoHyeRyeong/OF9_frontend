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
import 'package:frontend/features/report/report_screen.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';
import 'package:frontend/components/custom_toast.dart';
import 'package:frontend/utils/team_utils.dart';

class MyPageScreen extends StatefulWidget {
  final bool fromNavigation;
  final bool showBackButton;

  const MyPageScreen({
    Key? key,
    this.fromNavigation = true,
    this.showBackButton = false,
  }) : super(key: key);


  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> with SingleTickerProviderStateMixin {
  int selectedTabIndex = 1; // 0: 캘린더, 1: 리스트, 2: 모아보기(그리드)

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

    _tabAnimationController = AnimationController( // 탭 애니메이션 초기화
      duration: Duration(milliseconds: 250),
      vsync: this,
    );

    _tabPageController = PageController(initialPage: 1); // 초기 페이지 설정: 모아보기
    _currentTabPageValue = 1.0;

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
    setState(() {});
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

  // showLoadingIndicator 파라미터 추가
  Future<void> _loadMyRecords({bool showLoadingIndicator = true}) async {
    //  showLoadingIndicator가 true일 때만 로딩 상태 변경
    if (showLoadingIndicator) {
      setState(() => isLoadingRecords = true);
    }

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
          isLoadingRecords = false; // API 호출 완료 후 항상 false로
        });
      } else if (selectedTabIndex == 1) {
        // 리스트
        final records = await RecordApi.getMyRecordsList();
        if (!mounted) return;
        setState(() {
          feedList = records;
          isLoadingRecords = false; // API 호출 완료 후 항상 false로
        });
      } else {
        // 모아보기 (Tab 2)
        final records = await RecordApi.getMyRecordsFeed();
        if (!mounted) return;
        setState(() {
          feedList = records;
          isLoadingRecords = false; // API 호출 완료 후 항상 false로
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
            content: Text(
                '기록을 불러오는데 실패했습니다 (탭: ${_getTabName(selectedTabIndex)}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return '캘린더';
      case 1:
        return '리스트';
      case 2:
        return '모아보기';
      default:
        return '';
    }
  }

  /// 캘린더 월 변경 시 데이터 재로드
  void _onCalendarPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    if (selectedTabIndex == 0) {
      _loadMyRecords(showLoadingIndicator: false);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadUserInfo(), _loadMyRecords()]);
  }


  Widget _buildMediaImage(dynamic mediaData, double width, double height) {
    try {
      if (mediaData is String) {
        if (mediaData.startsWith('http://') ||
            mediaData.startsWith('https://')) {
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
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
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
          Icon(Icons.image_not_supported_outlined, size: scaleWidth(32),
              color: AppColors.gray300),
          SizedBox(height: scaleHeight(8)),
          Text(
            '이미지 로드 실패',
            style: AppFonts.suite.c2_m(context).copyWith(
                color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> record) {
    final dynamic rawGameDate = record['gameDate'];
    String gameDateText = '날짜 없음';

    if (rawGameDate != null) {
      try {
        final String dateStr = rawGameDate.toString();
        final DateTime date = DateTime.parse(dateStr);
        gameDateText =
        '${(date.year % 100).toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        // 파싱 안 되면 원본 그대로
        gameDateText = rawGameDate.toString();
      }
    }

    final int likeCount = record['likeCount'] ?? 0;

    return GestureDetector(
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

        if (result != null && result is Map) {
          if (result['deleted'] == true) {
            final deletedRecordId = result['recordId'];
            setState(() {
              feedList.removeWhere((r) => r['recordId'] == deletedRecordId);
            });
            _loadUserInfo();
          } else if (result['updated'] == true) {
            final updatedRecordId = result['recordId'];
            final updatedData =
            result['updatedData'] as Map<String, dynamic>;
            setState(() {
              final index =
              feedList.indexWhere((r) => r['recordId'] == updatedRecordId);
              if (index != -1) {
                final originalGameDate = feedList[index]['gameDate'];
                feedList[index] = {
                  ...feedList[index],
                  ...updatedData,
                  'gameDate': originalGameDate,
                };
              }
            });
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(scaleWidth(10)),
        child: Container(
          color: AppColors.gray50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (record['mediaUrls'] != null &&
                  record['mediaUrls'].isNotEmpty)
                _buildMediaImage(
                    record['mediaUrls'][0], double.infinity, double.infinity)
              else
                _buildImageErrorWidget(double.infinity, double.infinity),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: scaleHeight(9)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: scaleWidth(6),
                      vertical: scaleHeight(3),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.trans500,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      gameDateText,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: scaleWidth(6),
                      vertical: scaleHeight(2),
                    ),
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
      canPop: !widget.fromNavigation,
      onPopInvoked: (didPop) {
        if (!didPop && widget.fromNavigation) {
          // 바텀바에서 온 경우: ReportScreen(홈 화면)으로 이동
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1,
                  animation2) => const ReportScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
        // fromNavigation이 false면 일반 뒤로가기 허용
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context,
                bool innerBoxIsScrolled) {
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

  Widget _buildTopActionsBar() {
    return Container(
      height: scaleHeight(60),
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: scaleHeight(24),
            height: scaleHeight(24),
            child: widget.showBackButton
                ? GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: SvgPicture.asset(
                AppImages.backBlack,
                width: scaleHeight(24),
                height: scaleHeight(24),
                fit: BoxFit.contain,
              ),
            )
                : Container(),
          ),

          if (widget.showBackButton) // showBackButton이 true면 빈 공간
            SizedBox(width: scaleWidth(68))
          else // showBackButton이 false면 share + settings
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    print("Share 버튼 클릭");
                  },
                  child: SvgPicture.asset(
                    AppImages.Share,
                    width: scaleWidth(24),
                    height: scaleHeight(24),
                    color: AppColors.gray600,
                  ),
                ),
                SizedBox(width: scaleWidth(20)),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const SettingsScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                    _loadUserInfo();
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
                SizedBox(height: scaleHeight(6)),
                // 팀 정보 (조건부 표시)
                if (!isLoading && favTeam.isNotEmpty && favTeam != "응원팀 없음") ...[
                  IntrinsicWidth(
                    child: TeamUtils.buildTeamBadge(
                      context: context,
                      teamName: favTeam,
                      textStyle: AppFonts.pretendard.caption_sm_500(context),
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(7)),
                      borderRadius: scaleWidth(4),
                      height: scaleHeight(18),
                      suffix: ' 팬',
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),
                ],
                // 닉네임
                isLoading
                    ? Text(
                    "...", style: AppFonts.pretendard.head_sm_600(context))
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
                          pageBuilder: (context, animation,
                              secondaryAnimation) =>
                          const FollowingScreen(targetUserId: null),
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
                          pageBuilder: (context, animation,
                              secondaryAnimation) =>
                          const FollowerScreen(targetUserId: null),
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
          style: AppFonts.pretendard.caption_md_400(context).copyWith(
            color: AppColors.gray500,
          ),
        ),
        SizedBox(width: scaleWidth(2)),
        Text(
          count.toString(),
          style: AppFonts.pretendard.caption_md_400(context).copyWith(
            color: AppColors.gray900,
          ),
        ),
      ],
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                if (label == '팔로잉') {
                  return const FollowingScreen(targetUserId: null);
                } else {
                  return const FollowerScreen(targetUserId: null);
                }
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );

          _loadUserInfo();
        },
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
                pageBuilder: (context, animation, secondaryAnimation) =>
                const EditProfileScreen(
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
            style: AppFonts.pretendard.caption_md_500(context).copyWith(color: Colors.white),
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
                    final images = [
                      AppImages.calendar,
                      AppImages.list,
                      AppImages.gallery
                    ];
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
                              color: isSelected ? AppColors.gray600 : AppColors
                                  .trans200,
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
      indicatorOffset = centerPosition +
          (scrollProgress - 1.0) * (rightPosition - centerPosition);
    }

    return Positioned(
      bottom: 0,
      left: indicatorOffset,
      child: AnimatedContainer(
        duration: _isTabPageScrolling ? Duration.zero : Duration(
            milliseconds: 250),
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
          SizedBox(height: scaleHeight(25)),
          _buildStatsPanel(),
          SizedBox(height: scaleHeight(15)),
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
          style: AppFonts.pretendard.head_sm_600(context).copyWith(
              color: AppColors.gray300),
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

          final isLiked = _likeManager.getLikedStatus(record['recordId']) ??
              record['isLiked'] ?? false;
          final likeCount = _likeManager.getLikeCount(record['recordId']) ??
              record['likeCount'] ?? 0;
          final commentCount = _likeManager.getCommentCount(
              record['recordId']) ?? record['commentCount'] ?? 0;

          final feedData = {
            'recordId': record['recordId'],
            'userId': record['userId'],
            'profileImageUrl': record['profileImageUrl'],
            'nickname': record['nickname'],
            'favTeam': record['favTeam'],
            'followStatus': record['followStatus'] ?? 'ME',
            'mediaUrls': record['mediaUrls'] ?? [],
            'longContent': record['longContent'] ?? '',
            'emotionCode': record['emotionCode'],
            'emotionLabel': record['emotionLabel'] ?? '',
            'homeTeam': record['homeTeam'] ?? '',
            'awayTeam': record['awayTeam'] ?? '',
            'stadium': record['stadium'] ?? '',
            'gameDate': record['gameDate'] ?? '',
            'createdAt': record['createdAt'] ?? '',
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

              if (result != null && result is Map) {
                if (result['deleted'] == true) {
                  // 삭제된 경우
                  final deletedRecordId = result['recordId'];
                  setState(() {
                    feedList.removeWhere((r) =>
                    r['recordId'] == deletedRecordId);
                  });
                  _loadUserInfo();
                } else if (result['updated'] == true) {
                  // 수정된 경우 - 해당 아이템만 업데이트
                  final updatedRecordId = result['recordId'];
                  final updatedData = result['updatedData'] as Map<
                      String,
                      dynamic>;

                  setState(() {
                    final index = feedList.indexWhere(
                            (r) => r['recordId'] == updatedRecordId
                    );
                    if (index != -1) {
                      feedList[index] = {
                        ...feedList[index],
                        ...updatedData,
                      };
                    }
                  });
                  print('[MyPage] 게시글 ${updatedRecordId}번 업데이트됨 - 스크롤 유지');
                }
              }
            },
            onProfileNavigated: () async {
              final result = await Navigator.push(
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
              // 마이페이지에서 돌아온 경우 현재 상태 유지 (리프레시 안함)
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
          style: AppFonts.pretendard.head_sm_600(context).copyWith(
              color: AppColors.gray300),
        ),
      );
    }
    final recordsWithImages = feedList.where((record) {
      final mediaUrls = record['mediaUrls'];
      return mediaUrls != null && mediaUrls is List && mediaUrls.isNotEmpty;
    }).toList();

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
      itemCount: recordsWithImages.length,
      itemBuilder: (context, index) {
        return _buildGridItem(recordsWithImages[index]);
      },
    );
  }

  //달력 헤더
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

        // 오늘 날짜 또는 마커 없는 날 클릭 시 토스트 표시
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final selectedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        final events = _getEventsForDay(selectedDay);

        // 오늘이거나 과거 날짜이고, 마커가 없는 경우에만 토스트 표시
        if (selectedDate.isBefore(todayDate.add(Duration(days: 1))) && events.isEmpty) {
          CustomToast.showWithAction(
            context: context,
            message: '아직 직관 기록이 안 되어있어요!',
            actionText: '기록하기',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TicketOcrScreen()),
              );
            },
          );
        }
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
              fontSize: 8.sp
          ),
        ),
      ],
    );
  }

  // 하단 통계 패널
  Widget _buildStatsPanel() {
    final stats = calendarData['monthlyStats'];
    bool hasData = stats != null && (stats['recordCount'] ?? 0) > 0;

    return Container(
      width: double.infinity,
      height: scaleHeight(122),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleWidth(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A9397A1),
            offset: const Offset(0, 0),
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
                style: AppFonts.pretendard.body_sm_500(context).copyWith(
                  color: AppColors.gray900,),
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
                  style: AppFonts.pretendard.caption_re_400(context).copyWith(
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
                style: AppFonts.pretendard.body_md_500(context).copyWith(
                  color: AppColors.gray300,
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '직관 승률',
                        style: AppFonts.pretendard.caption_re_400(context).copyWith(
                          color: AppColors.gray500,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${_formatWinRate(stats!['winRate'] ?? 0.0)} %',
                        style: AppFonts.pretendard.title_sm_600(context)
                            .copyWith(color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기록 횟수',
                        style: AppFonts.pretendard.caption_re_400(context).copyWith(
                          color: AppColors.gray500,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${stats!['recordCount'] ?? 0} 회',
                        style: AppFonts.pretendard.title_sm_600(context)
                            .copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '공감 받은 횟수',
                        style: AppFonts.pretendard.caption_re_400(context).copyWith(
                          color: AppColors.gray500,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${stats!['totalLikes'] ?? 0} 회',
                        style: AppFonts.pretendard.title_sm_600(context)
                            .copyWith(
                          color: AppColors.gray900,
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

  // 승률 포맷팅 함수 (0과 100만 정수, 나머지는 백엔드 값 그대로)
  String _formatWinRate(double winRate) {
    // 소수점 이하가 0이면 정수로 표시
    if (winRate % 1 == 0) {
      return winRate.toInt().toString();
    }
    // 아니면 소수점 한 자리까지
    return winRate.toStringAsFixed(1);
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
    return Container(
      color: Colors.white,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_MyPageTabBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}