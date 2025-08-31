import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/features/mypage/settings_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 사용자 정보 상태
  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  bool isLoading = true;

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
                  // 뒤로가기 영역 + 타이틀
                  SizedBox(
                    height: screenHeight * 0.075,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.0225),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => const SettingsScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
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
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: screenHeight * 0.0225),
                              child: Center(
                                child: FixedText(
                                  "내 정보 수정",
                                  style: AppFonts.suite.b2_b(context).copyWith(
                                    color: AppColors.gray950,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 뒤로가기 버튼과 균형을 맞추기 위한 빈 공간
                          SizedBox(width: scaleHeight(24)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: scaleHeight(20)),

                  // 프로필 이미지 영역
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none, // Stack 영역을 넘어서도 표시되도록
                      children: [
                        // 프로필 이미지 (중앙에 자연스럽게 배치)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(scaleHeight(29.6)),
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
                        // 카메라 버튼 - 프로필 이미지 기준 위치
                        Positioned(
                          left: scaleWidth(78),
                          top: scaleHeight(80),
                          child: GestureDetector(
                            onTap: () {
                              // 프로필 사진 변경 로직 추가
                              print('프로필 사진 변경 버튼 클릭');
                            },
                            child: SvgPicture.asset(
                              AppImages.btn_camera,
                              width: scaleWidth(24),
                              height: scaleHeight(24),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            );
          },
        ),
      ),
    );
  }
}