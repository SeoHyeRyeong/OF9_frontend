import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int selectedTabIndex = 2; // 0: 캘린더, 1: 리스트, 2: 모아보기
  final double baseW = 360;
  final double baseH = 800;

  // 하드코딩 예시값
  final String nickname = "못말리는 승리요정";
  final String favTeam = "KIA 타이거즈";
  final int postCount = 100;
  final int followingCount = 5;
  final int followerCount = 2600;

  // 피드 예시 데이터
  final List<Map<String, dynamic>> feedList = [
    {"recordId": 5, "gameDate": "2025/03/23 Sun", "imageUrl": "https://example.com/photos/game1.jpg"},
    {"recordId": 6, "gameDate": "2025/03/23 Sun", "imageUrl": "https://example.com/photos/game1.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    double wp(double px) => screenW * (px / baseW);
    double hp(double px) => screenH * (px / baseH);

    // 하단 내비게이션 바 위치 및 높이 설정
    final double baseScreenHeight = 800;
    final double baseScreenWeight = 360;
    final double navBarHeight = screenH * 86 / baseScreenHeight;
    final double navBarTopInWhite = screenH - navBarHeight - MediaQuery.of(context).padding.bottom;

    // 탭 활성화 선 위치 계산
    double tabIndicatorX(int tabIndex) {
      switch (tabIndex) {
        case 0: return wp(43.5);
        case 1: return wp(154.5);
        case 2: return wp(265.5);
        default: return 0;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 상단 고정 영역 (프로필~드롭박스)
            Positioned(
              top: 0, // SafeArea로 이미 상태바 영역이 적용됨. top을 0으로 지정하면 자연스럽게 위로 붙음
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
                        padding: EdgeInsets.only(top: hp(10), right: wp(20)),
                        child: SvgPicture.asset(
                          AppImages.Setting,
                          width: wp(24),
                          height: wp(24),
                        ),
                      ),
                    ),
                    // 프로필 이미지
                    SizedBox(height: hp(82 - 54 - 24)),
                    Center(
                      child: GestureDetector(
                        onTap: () => print("프로필 이미지 선택"),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SvgPicture.asset(
                            AppImages.profile,
                            width: wp(100),
                            height: wp(100),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    // 닉네임
                    SizedBox(height: hp(196 - 82 - 100)),
                    FixedText(
                      nickname,
                      style: AppFonts.b1_b(context).copyWith(color: AppColors.black),
                    ),
                    // 구단명
                    SizedBox(height: hp(224 - 196 - 16)),
                    FixedText(
                      "$favTeam 팬",
                      style: AppFonts.c1_b(context).copyWith(color: AppColors.gray300),
                    ),
                    // 게시글/팔로잉/팔로워
                    SizedBox(height: hp(256 - 224 - 16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 게시글
                        Column(
                          children: [
                            FixedText(
                              postCount.toString(),
                              style: AppFonts.b2_b(context),
                            ),
                            SizedBox(height: hp(4)),
                            FixedText(
                              "게시글",
                              style: AppFonts.b3_m(context).copyWith(color: AppColors.gray400),
                            ),
                          ],
                        ),
                        SizedBox(width: wp(44.5)),
                        // 팔로잉
                        Column(
                          children: [
                            FixedText(
                              followingCount.toString(),
                              style: AppFonts.b2_b(context),
                            ),
                            SizedBox(height: hp(4)),
                            FixedText(
                              "팔로잉",
                              style: AppFonts.b3_m(context).copyWith(color: AppColors.gray400),
                            ),
                          ],
                        ),
                        SizedBox(width: wp(44.5)),
                        // 팔로워
                        Column(
                          children: [
                            FixedText(
                              followerCount >= 1000
                                  ? "${(followerCount / 1000).toStringAsFixed(1)}K"
                                  : followerCount.toString(),
                              style: AppFonts.b2_b(context),
                            ),
                            SizedBox(height: hp(4)),
                            FixedText(
                              "팔로워",
                              style: AppFonts.b3_m(context).copyWith(color: AppColors.gray400),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // 버튼
                    SizedBox(height: hp(316 - 256 - 36)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: wp(20)),
                      child: SizedBox(
                        width: wp(320),
                        height: hp(52),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gray600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppImages.Share,
                                width: wp(16),
                                height: wp(16),
                              ),
                              SizedBox(width: wp(11)),
                              FixedText(
                                "프로필 공유하기",
                                style: AppFonts.b3_sb(context).copyWith(color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: hp(24)),
                    // 탭 선택
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: wp(43.5)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (index) {
                          // 탭에 대응하는 이미지 리스트
                          final images = [AppImages.calendar, AppImages.list, AppImages.gallery];

                          return GestureDetector(
                            onTap: () => setState(() => selectedTabIndex = index),
                            child: Container(
                              width: wp(51),
                              height: hp(36),
                              alignment: Alignment.center,
                              color: Colors.transparent,
                              // 터치 영역: Container 전체
                              child: SvgPicture.asset(
                                images[index],
                                width: wp(24),
                                height: wp(24),
                                color: selectedTabIndex == index
                                    ? AppColors.gray600
                                    : AppColors.trans200,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    /*SizedBox(height: hp(394 - 316 - 52 - 24)),
                    Stack(
                      children: [
                        // 탭 이미지
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: wp(43.5)), // 좌우 여백 43.5
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 캘린더
                              GestureDetector(
                                onTap: () => setState(() => selectedTabIndex = 0),
                                child: Container(
                                  width: wp(51),
                                  height: hp(36),
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset(
                                    AppImages.calendar,
                                    width: wp(24),
                                    height: wp(24),
                                    color: selectedTabIndex == 0 ? AppColors.gray600 : AppColors.trans200,
                                  ),
                                ),
                              ),
                              // 리스트
                              GestureDetector(
                                onTap: () => setState(() => selectedTabIndex = 1),
                                child: Container(
                                  width: wp(51),
                                  height: hp(36),
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset(
                                    AppImages.list,
                                    width: wp(24),
                                    height: wp(24),
                                    color: selectedTabIndex == 1 ? AppColors.gray600 : AppColors.trans200,
                                  ),
                                ),
                              ),
                              // 모아보기
                              GestureDetector(
                                onTap: () => setState(() => selectedTabIndex = 2),
                                child: Container(
                                  width: wp(51),
                                  height: hp(36),
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset(
                                    AppImages.gallery,
                                    width: wp(24),
                                    height: wp(24),
                                    color: selectedTabIndex == 2 ? AppColors.gray600 : AppColors.trans200,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 탭 활성화 선
                        Positioned(
                          top: hp(36),
                          left: tabIndicatorX(selectedTabIndex),
                          child: Container(
                            width: wp(51),
                            height: hp(2),
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),*/
                    // 가로 구분선
                    SizedBox(height: hp(430 - 394 - 36)),
                    Divider(color: AppColors.gray100, thickness: 1),
                      // 드롭박스
                      SizedBox(height: hp(16)),
                    Padding(
                      padding: EdgeInsets.only(left: wp(20)), // 왼쪽 여백 20 기준 유동성 적용
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // 경기 구단 드롭박스
                          Container(
                            width: wp(83),
                            height: hp(28),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFCFD3DE), width: 1),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: wp(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  FixedText(
                                    "경기 구단",
                                    style: AppFonts.c2_sb(context).copyWith(color: Color(0xFF96A0B1)),
                                  ),
                                  SvgPicture.asset(
                                    AppImages.dropdownBlack,
                                    width: wp(16),
                                    height: wp(16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: wp(6)),
                          Container(
                            width: wp(61),
                            height: hp(28),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFCFD3DE), width: 1),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: wp(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  FixedText(
                                    "구장",
                                    style: AppFonts.c2_sb(context).copyWith(color: Color(0xFF96A0B1)),
                                  ),
                                  SvgPicture.asset(
                                    AppImages.dropdownBlack,
                                    width: wp(16),
                                    height: wp(16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: wp(6)),
                          Container(
                            width: wp(83),
                            height: hp(28),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFCFD3DE), width: 1),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: wp(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  FixedText(
                                    "승패 여부",
                                    style: AppFonts.c2_sb(context).copyWith(color: Color(0xFF96A0B1)),
                                  ),
                                  SvgPicture.asset(
                                    AppImages.dropdownBlack,
                                    width: wp(16),
                                    height: wp(16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                      SizedBox(height: hp(16)),
                    ],
                  ),
                ),
            ),

            // 스크롤 가능한 본문 (상단 고정 영역 제외)
            Positioned(
              top: hp(430 + 28 + 16), // 탭+드롭박스+여백 아래부터 시작
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 피드 그리드 (모아보기 탭 기준)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: wp(5)),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: feedList.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: wp(5),
                          mainAxisSpacing: wp(5),
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (context, index) {
                          return Container(
                            width: wp(112),
                            height: wp(152),
                            child: Image.network(
                              feedList[index]['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.gray50,
                                child: Center(child: Text(feedList[index]['gameDate'])),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: hp(100)), // 하단 내비게이션 바 공간 확보
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 하단 내비게이션 바
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenW * 32 / baseW,
          vertical: screenH * 24 / baseH,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gray20, width: 0.5.w)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBottomNavItem(context, AppImages.home, '피드', isActive: false, screenHeight: screenH),
            _buildBottomNavItem(context, AppImages.report, '리포트', isActive: false, screenHeight: screenH),
            _buildBottomNavItem(context, AppImages.upload, '업로드', isActive: false, screenHeight: screenH),
            _buildBottomNavItem(context, AppImages.bell, '알림', isActive: false, screenHeight: screenH),
            _buildBottomNavItem(context, AppImages.person, 'MY', isActive: true, screenHeight: screenH),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      BuildContext context,
      String iconPath,
      String label, {
        required bool isActive,
        required double screenHeight,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: screenHeight * 28 / 800,
          height: screenHeight * 28 / 800,
          color: isActive ? null : AppColors.gray200,
        ),
        SizedBox(height: screenHeight * 6 / 800),
        FixedText(
          label,
          style: AppFonts.c1_b(context).copyWith(
            color: isActive ? Colors.black : AppColors.gray200,
          ),
        ),
      ],
    );
  }
}
