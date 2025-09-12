import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';
import 'package:frontend/features/mypage/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 사용자 정보 상태
  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  bool isLoading = true;

  // 푸시 알림 토글 상태
  bool isPushNotificationOn = false;

  // 계정 공개 토글 상태
  bool isAccountPublic = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
        isAccountPublic = !(userInfo['isPrivate'] ?? false);  //계정 공개/비공개 설정
        isLoading = false;
      });
    } catch (e) {
      print('❌ 사용자 정보 불러오기 실패: $e');
      setState(() {
        nickname = "정보 불러오기 실패";
        favTeam = "정보 불러오기 실패";
        isLoading = false;
      });
    }
  }

  /// 계정 공개/비공개 설정 변경
  Future<void> _updateAccountPrivacy(bool isPublic) async {
    try {
      print('🔄 계정 공개/비공개 설정 변경 중: ${isPublic ? '공개' : '비공개'}');

      await UserApi.updateMyProfile(
        nickname: nickname,
        favTeam: favTeam.replaceAll(' 팬', ''), // ' 팬' 제거하여 원본 팀명만 전송
        profileImageUrl: profileImageUrl,
        isPrivate: !isPublic, // isPublic의 반대값을 isPrivate로 전송
      );

      setState(() {
        isAccountPublic = isPublic;
      });

      print('✅ 계정 공개/비공개 설정 변경 성공: ${isPublic ? '공개' : '비공개'}');
    } catch (e) {
      print('❌ 계정 공개/비공개 설정 변경 실패: $e');
      // 실패 시 원래 상태로 되돌리기
      setState(() {
        isAccountPublic = !isPublic;
      });
    }
  }

  /// 커스텀 토글 스위치 위젯
  Widget _buildCustomToggle(bool isOn, VoidCallback onToggle) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: scaleWidth(42),
        height: scaleHeight(24),
        decoration: BoxDecoration(
          color: isOn ? AppColors.pri400 : AppColors.gray200,
          borderRadius: BorderRadius.circular(scaleHeight(92.31)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isOn ? 0 : scaleWidth(3),
                  right: isOn ? scaleWidth(2) : 0,
                ),
                child: Container(
                  width: scaleWidth(20),
                  height: scaleHeight(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        isOn ? scaleHeight(92.31) : scaleHeight(100)
                    ),
                    boxShadow: isOn ? [
                      BoxShadow(
                        color: const Color(0x26000000),
                        blurRadius: scaleHeight(7.38),
                        offset: Offset(0, scaleHeight(2.77)),
                      ),
                      BoxShadow(
                        color: const Color(0x0A000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: scaleHeight(0.92),
                      ),
                    ] : [
                      BoxShadow(
                        color: const Color(0x26000000),
                        blurRadius: scaleHeight(8),
                        offset: Offset(0, scaleHeight(3)),
                      ),
                      BoxShadow(
                        color: const Color(0x0A000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: scaleHeight(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // 뒤로가기 영역
                  SizedBox(
                    height: screenHeight * 0.075,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.0325),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MyPageScreen()),
                                );
                              },
                              child: SvgPicture.asset(
                                AppImages.backBlack,
                                width: scaleHeight(24),
                                height: scaleHeight(24),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 프로필 영역
                  Transform(
                    transform: Matrix4.translationValues(0, -scaleHeight(10), 0),
                    child: Column(
                      children: [
                        // 프로필 이미지
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
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

                        SizedBox(height: scaleHeight(16)),

                        // 닉네임
                        isLoading
                            ? CircularProgressIndicator()
                            : FixedText(
                          nickname,
                          style: AppFonts.pretendard.h5_sb(context).copyWith(color: AppColors.black),
                        ),

                        SizedBox(height: scaleHeight(12)),

                        // 최애구단
                        isLoading
                            ? Container()
                            : FixedText(
                          "$favTeam 팬",
                          style: AppFonts.pretendard.b3_r(context).copyWith(color: AppColors.gray300),
                        ),

                        SizedBox(height: scaleHeight(12)),

                        // 내 정보 수정 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation1, animation2) => const EditProfileScreen(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          child: Container(
                            width: scaleWidth(76),
                            height: scaleHeight(28),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.only(
                              top: scaleHeight(8),
                              right: scaleWidth(10),
                              bottom: scaleHeight(8),
                              left: scaleWidth(10),
                            ),
                            child: Center(
                              child: FixedText(
                                "내 정보 수정",
                                style: AppFonts.pretendard.c1_sb(context).copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: scaleHeight(16)),

                        // 테마 변경 메뉴
                        GestureDetector(
                          onTap: () {
                            // 테마 변경 페이지로 이동하는 로직 추가
                            print('테마 변경 버튼 클릭');
                          },
                          child: Container(
                            width: scaleWidth(320),
                            height: scaleHeight(48),
                            decoration: BoxDecoration(
                              color: AppColors.gray30,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.all(scaleWidth(16)),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FixedText(
                                "테마 변경",
                                style: AppFonts.suite.b3_sb(context).copyWith(
                                  color: AppColors.gray900,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: scaleHeight(16)),

                        // 푸시 알림 메뉴
                        Container(
                          width: scaleWidth(320),
                          height: scaleHeight(56),
                          decoration: BoxDecoration(
                            color: AppColors.gray30,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                            child: Row(
                              children: [
                                FixedText(
                                  "푸시 알림",
                                  style: AppFonts.suite.b3_sb(context).copyWith(
                                    color: AppColors.gray900,
                                  ),
                                ),
                                const Spacer(),
                                _buildCustomToggle(isPushNotificationOn, () {
                                  setState(() {
                                    isPushNotificationOn = !isPushNotificationOn;
                                  });
                                  print('푸시 알림 토글: ${isPushNotificationOn ? 'ON' : 'OFF'}');
                                }),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: scaleHeight(16)),

                        // 계정 공개 / 차단된 계정 메뉴
                        Container(
                          width: scaleWidth(320),
                          height: scaleHeight(104),
                          decoration: BoxDecoration(
                            color: AppColors.gray30,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // 계정 공개
                              Container(
                                width: scaleWidth(320),
                                height: scaleHeight(56),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                  child: Row(
                                    children: [
                                      FixedText(
                                        "계정 공개",
                                        style: AppFonts.suite.b3_sb(context).copyWith(
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                      const Spacer(),
                                      _buildCustomToggle(isAccountPublic, () {
                                        _updateAccountPrivacy(!isAccountPublic);
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              // 차단된 계정
                              GestureDetector(
                                onTap: () {
                                  print('차단된 계정 버튼 클릭');
                                },
                                child: Container(
                                  width: scaleWidth(320),
                                  height: scaleHeight(48),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: scaleWidth(16)),
                                      child: FixedText(
                                        "차단된 계정",
                                        style: AppFonts.suite.b3_sb(context).copyWith(
                                          color: AppColors.gray900,
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

                  SizedBox(height: scaleHeight(16)),

                  // 기타 설정 메뉴들
                  Container(
                    width: scaleWidth(320),
                    height: scaleHeight(270),
                    decoration: BoxDecoration(
                      color: AppColors.gray30,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // 버전 정보
                        GestureDetector(
                          onTap: () {
                            print('버전 정보 버튼 클릭');
                          },
                          child: Container(
                            width: scaleWidth(320),
                            height: scaleHeight(54),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: scaleWidth(16)),
                                child: FixedText(
                                  "버전 정보",
                                  style: AppFonts.suite.b3_sb(context).copyWith(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 이용 약관
                        GestureDetector(
                          onTap: () {
                            print('이용 약관 버튼 클릭');
                          },
                          child: Container(
                            width: scaleWidth(320),
                            height: scaleHeight(54),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: scaleWidth(16)),
                                child: FixedText(
                                  "이용 약관",
                                  style: AppFonts.suite.b3_sb(context).copyWith(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 개인정보 처리방침
                        GestureDetector(
                          onTap: () {
                            print('개인정보 처리방침 버튼 클릭');
                          },
                          child: Container(
                            width: scaleWidth(320),
                            height: scaleHeight(54),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: scaleWidth(16)),
                                child: FixedText(
                                  "개인정보 처리방침",
                                  style: AppFonts.suite.b3_sb(context).copyWith(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 로그아웃
                        GestureDetector(
                          onTap: () {
                            print('로그아웃 버튼 클릭');
                          },
                          child: Container(
                            width: scaleWidth(320),
                            height: scaleHeight(54),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: scaleWidth(16)),
                                child: FixedText(
                                  "로그아웃",
                                  style: AppFonts.suite.b3_sb(context).copyWith(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 회원 탈퇴
                        GestureDetector(
                          onTap: () {
                            print('회원 탈퇴 버튼 클릭');
                          },
                          child: Container(
                            width: scaleWidth(320),
                            height: scaleHeight(54),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: scaleWidth(16)),
                                child: FixedText(
                                  "회원 탈퇴",
                                  style: AppFonts.suite.b3_sb(context).copyWith(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: scaleHeight(24)),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 4),
    );
  }
}