import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/api/record_api.dart';
import 'dart:convert';
import 'dart:typed_data';


class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int selectedTabIndex = 2; // 0: 캘린더, 1: 리스트, 2: 모아보기
  final double baseW = 360;
  final double baseH = 800;

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
      final userInfo = await UserApi.getMyInfo();
      setState(() {
        nickname = userInfo['nickname'] ?? '알 수 없음';
        favTeam = userInfo['favTeam'] ?? '응원팀 없음';
        profileImageUrl = userInfo['profileImageUrl'];
        postCount = userInfo['postCount'] ?? 0;
        followingCount = userInfo['followingCount'] ?? 0;
        followerCount = userInfo['followerCount'] ?? 0;
        isPrivate = userInfo['private'] ?? false;
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
  /*Future<void> _loadMyRecords() async {
    try {
      final records = await RecordApi.getMyRecords();
      setState(() {
        feedList = records;
        isLoadingRecords = false;
      });
    } catch (e) {
      print('❌ 기록 불러오기 실패: $e');
      setState(() {
        isLoadingRecords = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('기록을 불러오는데 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }*/

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
    await Future.wait([
      _loadUserInfo(),
      _loadMyRecords(),
    ]);
  }

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
    final double navBarTopInWhite =
        screenH - navBarHeight - MediaQuery.of(context).padding.bottom;

    // 탭 활성화 선 위치 계산
    double tabIndicatorX(int tabIndex) {
      switch (tabIndex) {
        case 0:
          return wp(43.5);
        case 1:
          return wp(154.5);
        case 2:
          return wp(265.5);
        default:
          return 0;
      }
    }

    return Scaffold(
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
                            child: profileImageUrl != null
                                ? Image.network(
                              profileImageUrl!,
                              width: wp(100),
                              height: wp(100),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SvgPicture.asset(
                                AppImages.profile,
                                width: wp(100),
                                height: wp(100),
                                fit: BoxFit.cover,
                              ),
                            )
                                : SvgPicture.asset(
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
                      isLoading
                          ? CircularProgressIndicator()
                          : FixedText(
                        nickname,
                        style: AppFonts.pretendard.b1_b(context).copyWith(color: AppColors.black),
                      ),
                      // 구단명
                      SizedBox(height: hp(224 - 196 - 16)),
                      isLoading
                          ? Container()
                          : FixedText(
                        "$favTeam 팬",
                        style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.gray300),
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
                                style: AppFonts.pretendard.b2_b(context),
                              ),
                              SizedBox(height: hp(4)),
                              FixedText(
                                "게시글",
                                style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400),
                              ),
                            ],
                          ),
                          SizedBox(width: wp(44.5)),
                          // 팔로잉
                          Column(
                            children: [
                              FixedText(
                                followingCount.toString(),
                                style: AppFonts.pretendard.b2_b(context),
                              ),
                              SizedBox(height: hp(4)),
                              FixedText(
                                "팔로잉",
                                style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400),
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
                                style: AppFonts.pretendard.b2_b(context),
                              ),
                              SizedBox(height: hp(4)),
                              FixedText(
                                "팔로워",
                                style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
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
                                  style: AppFonts.pretendard.b3_sb(context).copyWith(color: AppColors.white),
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
                            final images = [
                              AppImages.calendar,
                              AppImages.list,
                              AppImages.gallery,
                            ];
                            return GestureDetector(
                              onTap: () => setState(() => selectedTabIndex = index),
                              child: Container(
                                width: wp(51),
                                height: hp(36),
                                alignment: Alignment.center,
                                color: Colors.transparent,
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
                      // 가로 구분선
                      SizedBox(height: hp(430 - 394 - 36)),
                      Divider(color: AppColors.gray100, thickness: 1),
                      // 드롭박스
                      SizedBox(height: hp(16)),
                      Padding(
                        padding: EdgeInsets.only(left: wp(20)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // 경기 구단 드롭박스
                            Container(
                              width: wp(83),
                              height: hp(28),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFFCFD3DE),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: wp(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    FixedText(
                                      "경기 구단",
                                      style: AppFonts.pretendard.c1_m(context).copyWith(color: Color(0xFF96A0B1)),
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
                                border: Border.all(
                                  color: Color(0xFFCFD3DE),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: wp(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    FixedText(
                                      "구장",
                                      style: AppFonts.pretendard.c1_m(context).copyWith(color: Color(0xFF96A0B1)),
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
                                border: Border.all(
                                  color: Color(0xFFCFD3DE),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: wp(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    FixedText(
                                      "승패 여부",
                                      style: AppFonts.pretendard.c1_m(context).copyWith(color: Color(0xFF96A0B1)),
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
                top: hp(430 + 28 + 16),
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 피드 그리드 (모아보기 탭 기준)
                      if (isLoadingRecords)
                        Padding(
                          padding: EdgeInsets.all(wp(50)),
                          child: CircularProgressIndicator(),
                        )
                      else if (feedList.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(wp(50)),
                          child: Text(
                            '작성한 기록이 없습니다.',
                            style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray400),
                          ),
                        )
                      else
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
                              final record = feedList[index];
                              return GestureDetector(
                                onTap: () {
                                  print('기록 상세보기: ${record['recordId']}');
                                },
                                child: Container(
                                  width: wp(112),
                                  height: wp(152),
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

                                      /*? Image.network(
                                    record['mediaUrls'][0], // 첫 번째 이미지 사용
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholder(record),
                                  )
                                      : _buildPlaceholder(record),*//*? Image.network(
                                    record['mediaUrls'][0], // 첫 번째 이미지 사용
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholder(record),
                                  )
                                      : _buildPlaceholder(record),*/

                                      // 날짜 오버레이
                                      Positioned(
                                        top: 8,
                                        left: 10,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(6),
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
                      SizedBox(height: hp(100)), // 하단 내비게이션 바 공간 확보
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildPlaceholder(Map<String, dynamic> record) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final double baseW = 360;
    final double baseH = 800;
    double wp(double px) => screenW * (px / baseW);
    double hp(double px) => screenH * (px / baseH);

    return Container(
      color: AppColors.gray50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: hp(4)),
            Text(
              record['gameDate'] ?? '',
              style: AppFonts.pretendard.c2_b(context),
              textAlign: TextAlign.center,
            ),
            /*Text(
              '${record['homeTeam']} vs ${record['awayTeam']}',
              style: AppFonts.c2_b(context),
              textAlign: TextAlign.center,
            ),*/
          ],
        ),
      ),
    );
  }
}


