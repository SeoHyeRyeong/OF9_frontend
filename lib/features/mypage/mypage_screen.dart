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
import 'dart:convert';
import 'dart:typed_data';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int selectedTabIndex = 2; // 0: 캘린더, 1: 리스트, 2: 모아보기(그리드)

  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  int postCount = 0;
  int followingCount = 0;
  int followerCount = 0;
  bool isPrivate = false;

  List<Map<String, dynamic>> feedList = [];
  bool isLoading = true;
  bool isLoadingRecords = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 불러오는데 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMyRecords() async {
    setState(() => isLoadingRecords = true);
    try {
      List<Map<String, dynamic>> records;
      if (selectedTabIndex == 0) {
        records = await RecordApi.getMyRecordsCalendar();
      } else if (selectedTabIndex == 1) {
        records = await RecordApi.getMyRecordsList();
      } else {
        records = await RecordApi.getMyRecordsFeed();
      }
      if (!mounted) return;
      setState(() {
        feedList = records;
        isLoadingRecords = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('❌ 기록 불러오기 실패 (탭: $selectedTabIndex): $e');
      setState(() {
        feedList = [];
        isLoadingRecords = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('기록을 불러오는데 실패했습니다 (탭: ${_getTabName(selectedTabIndex)}).'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _onTabChanged(int index) {
    if (selectedTabIndex == index) return;
    setState(() {
      selectedTabIndex = index;
    });
    _loadMyRecords();
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
        borderRadius: BorderRadius.circular(scaleWidth(16)),
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
              Positioned(
                top: scaleHeight(16),
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(6), vertical: scaleHeight(2)),
                    decoration: BoxDecoration(
                      color: AppColors.trans700,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      gameDate,
                      textAlign: TextAlign.center,
                      style: AppFonts.suite.c3_sb(context).copyWith(
                        color: Colors.white,
                        letterSpacing: -0.16,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: scaleHeight(12),
                right: scaleWidth(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(6), vertical: scaleHeight(2)),
                  decoration: BoxDecoration(
                    color: AppColors.trans300,
                    borderRadius: BorderRadius.circular(scaleWidth(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //SvgPicture.asset(AppImages.heart_white, width: scaleWidth(14), height: scaleHeight(14)),
                      SizedBox(width: scaleWidth(2)),
                      Text(
                        likeCount.toString(),
                        style: AppFonts.suite.c2_sb(context).copyWith(
                          color: AppColors.gray50,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: SvgPicture.asset(
                AppImages.Share,
                width: scaleWidth(24),
                height: scaleHeight(24),
                color: AppColors.gray600,
              ),
              onPressed: () { print("공유 버튼 클릭"); },
            ),
            IconButton(
              icon: SvgPicture.asset(
                AppImages.Setting,
                width: scaleWidth(24),
                height: scaleHeight(24),
                color: AppColors.gray600,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            SizedBox(width: scaleWidth(10)),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.pri500,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      SizedBox(height: scaleHeight(0)),
                      _buildProfileSection(),
                      SizedBox(height: scaleHeight(20)),
                      _buildStatsSection(),
                      SizedBox(height: scaleHeight(19)),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _MyPageTabBarDelegate(
                    height: scaleHeight(46),
                    child: _buildTabBar(),
                  ),
                  pinned: true,
                ),
                _buildTabContentSliver(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () { print("프로필 이미지 선택"); },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(scaleWidth(40)),
              child: Container(
                width: scaleWidth(110),
                height: scaleHeight(110),
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
                  ),)
                    : SvgPicture.asset(AppImages.profile, fit: BoxFit.cover),
              ),
            ),
          ),
          SizedBox(height: scaleHeight(20)),
          if (!isLoading && favTeam.isNotEmpty && favTeam != "응원팀 없음")
            Container(
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(12), vertical: scaleHeight(6)),
              decoration: BoxDecoration(
                color: AppColors.gray30,
                borderRadius: BorderRadius.circular(scaleWidth(20)),
              ),
              child: Text(
                "$favTeam 팬",
                style: AppFonts.suite.caption_md_500(context).copyWith(
                  color: AppColors.pri800,
                  letterSpacing: -0.2,
                ),
              ),),
          SizedBox(height: scaleHeight(14)),
          isLoading
              ? SizedBox(height: scaleHeight(28), child: Center(child: Text("...", style: AppFonts.pretendard.head_sm_600(context))))
              : Text(
            nickname,
            textAlign: TextAlign.center,
            style: AppFonts.pretendard.head_sm_600(context).copyWith(
              letterSpacing: -0.36,
            ),),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
      child: Container(
        height: scaleHeight(84),
        decoration: BoxDecoration(
          color: AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleWidth(16)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: scaleHeight(17.5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn("게시글", postCount),
              _buildVerticalDivider(),
              _buildStatColumn("팔로잉", followingCount, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowingScreen()));
              }),
              _buildVerticalDivider(),
              _buildStatColumn("팔로워", followerCount, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowerScreen()));
              }),
            ],
          ),
        ),),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: scaleHeight(46),
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (index) {
                final images = [AppImages.calendar, AppImages.list, AppImages.gallery];
                final isSelected = selectedTabIndex == index;
                return GestureDetector(
                  onTap: () => _onTabChanged(index),
                  child: Container(
                    width: scaleWidth(51),
                    height: double.infinity,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SvgPicture.asset(
                            images[index],
                            width: scaleWidth(28),
                            height: scaleHeight(28),
                            color: isSelected ? AppColors.gray700 : AppColors.gray200,
                          ),
                        ),
                        Container(
                          height: 2.0,
                          width: scaleWidth(51),
                          color: isSelected ? AppColors.gray700 : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Divider(color: AppColors.gray100, thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, {VoidCallback? onTap}) {
    String displayCount = count.toString();
    if (label == "팔로워" && count >= 1000) {
      displayCount = "${(count / 1000).toStringAsFixed(1)}K";
    }

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppFonts.suite.body_sm_500(context).copyWith( // 폰트: body_sm_500
            color: AppColors.gray400, // 색상: gray400
          ),
        ),
        Text(
          displayCount,
          style: AppFonts.pretendard.head_sm_600(context).copyWith( // 폰트: head_sm_600
            color: Colors.black, // 색상: black
          ),
        ),
      ],
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: scaleHeight(40),
      color: AppColors.gray100,
    );
  }

  Widget _buildTabContentSliver() {
    if (isLoadingRecords) {
      return SliverFillRemaining(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: scaleHeight(50)),
          child: const Center(child: CircularProgressIndicator(color: AppColors.pri500)),
        ),
      );
    }
    if (feedList.isEmpty) {
      return SliverFillRemaining(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: scaleHeight(50)),
          child: Center(
            child: Text(
              '업로드한 기록이 아직 없어요.',
              style: AppFonts.suite.h5_b(context).copyWith(color: AppColors.gray300),
            ),
          ),
        ),
      );
    }

    switch (selectedTabIndex) {
      case 0:
        return SliverToBoxAdapter(child: Container(alignment: Alignment.center, height: 200, child: const Text("캘린더 뷰 (구현 필요)")));
      case 1:
        return SliverToBoxAdapter(child: Container(alignment: Alignment.center, height: 200, child: const Text("리스트 뷰 (구현 필요)")));
      case 2:
      default:
        return SliverPadding(
          padding: EdgeInsets.only(
            left: scaleWidth(20),
            right: scaleWidth(20),
            top: scaleHeight(24),
            bottom: scaleHeight(100),
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: scaleWidth(9),
              mainAxisSpacing: scaleHeight(9),
              childAspectRatio: 154 / 212,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final record = feedList[index];
                return _buildGridItem(record);
              },
              childCount: feedList.length,
            ),
          ),
        );
    }
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