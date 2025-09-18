import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/api/record_api.dart';
import 'dart:convert';
import 'package:frontend/features/mypage/settings_screen.dart';
import 'package:frontend/features/mypage/follower_screen.dart';
import 'package:frontend/features/mypage/following_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int selectedTabIndex = 2; // 0: 캘린더, 1: 리스트, 2: 모아보기

  // 사용자 정보 상태
  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  int postCount = 0;
  int followingCount = 0;
  int followerCount = 0;
  bool isPrivate = false;

  // 피드 데이터 상태
  List<Map<String, dynamic>> feedList = [];
  bool isLoading = true;
  bool isLoadingRecords = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadMyRecords();
  }

  /// 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final response = await UserApi.getMyProfile();
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
      print('❌ 사용자 정보 불러오기 실패: $e');
      setState(() {
        nickname = "정보 불러오기 실패";
        favTeam = "정보 불러오기 실패";
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사용자 정보를 불러오는데 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 내 기록 불러오기
  Future<void> _loadMyRecords() async {
    try {
      // 모든 엔드포인트 테스트
      await RecordApi.getMyRecordsList();
      await RecordApi.getMyRecordsCalendar();

      // 기존 피드 조회
      final records = await RecordApi.getMyRecordsFeed();
      setState(() {
        feedList = records;
        isLoadingRecords = false;
      });
    } catch (e) {
      print('❌ 기록 불러오기 실패: $e');
      setState(() {
        isLoadingRecords = false;
      });
    }
  }

  /// 새로고침
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      isLoadingRecords = true;
    });
    await Future.wait([_loadUserInfo(), _loadMyRecords()]);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: Stack(
              children: [
                // 상단 고정 영역 (프로필~드롭박스)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // 우측상단 톱니바퀴
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: scaleHeight(10),
                                right: scaleWidth(20)
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => const SettingsScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              },
                              child: SvgPicture.asset(
                                AppImages.Setting,
                                width: scaleWidth(24),
                                height: scaleHeight(24),
                              ),
                            ),
                          ),
                        ),
                        // 프로필 이미지
                        SizedBox(height: scaleHeight(8)),
                        Center(
                          child: GestureDetector(
                            onTap: () => print("프로필 이미지 선택"),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(scaleHeight(14)),
                              child: profileImageUrl != null
                                  ? Image.network(
                                profileImageUrl!,
                                width: scaleWidth(100),
                                height: scaleHeight(100),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => SvgPicture.asset(
                                  AppImages.profile,
                                  width: scaleWidth(100),
                                  height: scaleHeight(100),
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : SvgPicture.asset(
                                AppImages.profile,
                                width: scaleWidth(100),
                                height: scaleHeight(100),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // 닉네임
                        SizedBox(height: scaleHeight(14)),
                        isLoading
                            ? CircularProgressIndicator()
                            : FixedText(
                          nickname,
                          style: AppFonts.pretendard.b1_b(context).copyWith(color: AppColors.black),
                        ),
                        // 구단명
                        SizedBox(height: scaleHeight(12)),
                        isLoading
                            ? Container()
                            : FixedText(
                          "$favTeam 팬",
                          style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.gray300),
                        ),
                        // 게시글/팔로잉/팔로워
                        SizedBox(height: scaleHeight(16)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 게시글
                            Column(
                              children: [
                                FixedText(postCount.toString(), style: AppFonts.pretendard.b2_b(context)),
                                SizedBox(height: scaleHeight(4)),
                                FixedText("게시글", style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400)),
                              ],
                            ),
                            SizedBox(width: scaleWidth(44.5)),
                            // 팔로잉
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => const FollowingScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  FixedText(followingCount.toString(), style: AppFonts.pretendard.b2_b(context)),
                                  SizedBox(height: scaleHeight(4)),
                                  FixedText("팔로잉", style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400)),
                                ],
                              ),
                            ),
                            SizedBox(width: scaleWidth(44.5)),
                            // 팔로워
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => const FollowerScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  FixedText(
                                    followerCount >= 1000
                                        ? "${(followerCount / 1000).toStringAsFixed(1)}K"
                                        : followerCount.toString(),
                                    style: AppFonts.pretendard.b2_b(context),
                                  ),
                                  SizedBox(height: scaleHeight(4)),
                                  FixedText("팔로워", style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // 버튼
                        SizedBox(height: scaleHeight(24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                          child: SizedBox(
                            width: scaleWidth(320),
                            height: scaleHeight(52),
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gray600,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleHeight(8))
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                      AppImages.Share,
                                      width: scaleWidth(16),
                                      height: scaleHeight(16)
                                  ),
                                  SizedBox(width: scaleWidth(11)),
                                  FixedText(
                                      "프로필 공유하기",
                                      style: AppFonts.pretendard.b3_sb(context).copyWith(color: AppColors.white)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: scaleHeight(24)),
                        // 탭 선택
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(43.5)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(3, (index) {
                              final images = [AppImages.calendar, AppImages.list, AppImages.gallery];
                              return GestureDetector(
                                onTap: () => setState(() => selectedTabIndex = index),
                                child: Container(
                                  width: scaleWidth(51),
                                  height: scaleHeight(36),
                                  alignment: Alignment.center,
                                  color: Colors.transparent,
                                  child: SvgPicture.asset(
                                    images[index],
                                    width: scaleWidth(24),
                                    height: scaleHeight(24),
                                    color: selectedTabIndex == index ? AppColors.gray600 : AppColors.trans200,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // 가로 구분선
                        SizedBox(height: scaleHeight(0)),
                        Divider(color: AppColors.gray100, thickness: 1),
                        // 드롭박스
                        SizedBox(height: scaleHeight(16)),
                        Padding(
                          padding: EdgeInsets.only(left: scaleWidth(20)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // 경기 구단 드롭박스
                              _buildDropdownBox(scaleWidth(83), "경기 구단"),
                              SizedBox(width: scaleWidth(6)),
                              _buildDropdownBox(scaleWidth(61), "구장"),
                              SizedBox(width: scaleWidth(6)),
                              _buildDropdownBox(scaleWidth(83), "승패 여부"),
                            ],
                          ),
                        ),
                        SizedBox(height: scaleHeight(16)),
                      ],
                    ),
                  ),
                ),
                // 스크롤 가능한 본문 (상단 고정 영역 제외)
                Positioned(
                  top: scaleHeight(474),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 피드 그리드 (모아보기 탭 기준)
                        if (isLoadingRecords)
                          Padding(
                            padding: EdgeInsets.all(scaleWidth(50)),
                            child: CircularProgressIndicator(),
                          )
                        else if (feedList.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(scaleWidth(50)),
                            child: Text(
                              '작성한 기록이 없습니다.',
                              style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400),
                            ),
                          )
                        else
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(5)),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: feedList.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: scaleWidth(5),
                                mainAxisSpacing: scaleHeight(5),
                                childAspectRatio: 0.7,
                              ),
                              itemBuilder: (context, index) {
                                final record = feedList[index];
                                return GestureDetector(
                                  onTap: () => print('기록 상세보기: ${record['recordId']}'),
                                  child: Container(
                                    width: scaleWidth(112),
                                    height: scaleHeight(152),
                                    child: Stack(
                                      children: [
                                        // base64 이미지 표시
                                        record['mediaUrls'] != null && record['mediaUrls'].isNotEmpty
                                            ? Image.memory(
                                          base64Decode(record['mediaUrls'][0]),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (_, __, ___) => _buildPlaceholder(record),
                                        )
                                            : _buildPlaceholder(record),
                                        // 날짜 오버레이
                                        Positioned(
                                          top: 8,
                                          left: 10,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(scaleHeight(6)),
                                            ),
                                            child: Text(
                                              record['gameDate'] ?? '',
                                              style: AppFonts.pretendard.c3_sb(context).copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        SizedBox(height: scaleHeight(100)), // 하단 내비게이션 바 공간 확보
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(currentIndex: 4),
      ),
    );
  }

  Widget _buildDropdownBox(double width, String text) {
    return Container(
      width: width,
      height: scaleHeight(28),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFCFD3DE), width: 1),
        borderRadius: BorderRadius.circular(scaleHeight(14)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FixedText(
              text,
              style: AppFonts.pretendard.c1_m(context).copyWith(color: Color(0xFF96A0B1)),
            ),
            SvgPicture.asset(
                AppImages.dropdownBlack,
                width: scaleWidth(16),
                height: scaleHeight(16)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Map<String, dynamic> record) {
    return Container(
      color: AppColors.gray50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: scaleHeight(4)),
            Text(
              record['gameDate'] ?? '',
              style: AppFonts.pretendard.c2_b(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
