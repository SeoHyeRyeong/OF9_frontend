import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/onboarding_login/signup_complete_screen.dart';
import 'package:frontend/utils/fixed_text.dart';

class FavoriteTeamScreen extends StatefulWidget {
  final String? kakaoAccessToken; // 추가

  const FavoriteTeamScreen({Key? key, this.kakaoAccessToken}) : super(key: key);

  @override
  State<FavoriteTeamScreen> createState() => _FavoriteTeamScreenState();
}

class _FavoriteTeamScreenState extends State<FavoriteTeamScreen> {
  String? _selectedTeam;

  final List<Map<String, String>> _teams = [
    {'name': '두산 베어스', 'image': AppImages.bears},
    {'name': '롯데 자이언츠', 'image': AppImages.giants},
    {'name': '삼성 라이온즈', 'image': AppImages.lions},
    {'name': '키움 히어로즈', 'image': AppImages.kiwoom},
    {'name': '한화 이글스', 'image': AppImages.eagles},
    {'name': 'KIA 타이거즈', 'image': AppImages.tigers},
    {'name': 'KT WIZ', 'image': AppImages.ktwiz},
    {'name': 'LG 트윈스', 'image': AppImages.twins},
    {'name': 'NC 다이노스', 'image': AppImages.dinos},
    {'name': 'SSG 랜더스', 'image': AppImages.landers},
  ];

  final kakaoAuthService = KakaoAuthService();

  Future<void> _handleComplete() async {
    if (widget.kakaoAccessToken != null && _selectedTeam != null) {
      // 신규 회원가입: sendTokenToBackend 사용
      final tokens = await kakaoAuthService.sendKakaoTokenToBackend(
          widget.kakaoAccessToken!,
          _selectedTeam!
      );

      if (tokens != null) {
        await kakaoAuthService.saveTokens(
          accessToken: tokens['accessToken']!,
          refreshToken: tokens['refreshToken']!,
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                SignupCompleteScreen(selectedTeam: _selectedTeam),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 실패')),
        );
      }
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

            return Column(
              children: [
                // 뒤로가기 영역 - 전체 높이의 7.5% (60/800)
                SizedBox(
                  height: screenHeight * 0.075,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.0225), // 18/800
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation1, animation2) => const LoginScreen(),
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
                      ],
                    ),
                  ),
                ),

                // 콘텐츠 영역 - 나머지 92.5%
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(flex: 33),

                          // 제목
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: FixedText(
                              '최애 구단 선택',
                              style: AppFonts.suite.h1_b(context).copyWith(color: Colors.black),
                            ),
                          ),

                          const Spacer(flex: 18),

                          // 서브타이틀
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: FixedText(
                              '나중에 마이페이지에서 변경 가능해요',
                              style: AppFonts.suite.b2_m(context).copyWith(color: AppColors.gray300),
                            ),
                          ),

                          const Spacer(flex: 16),

                          // 그리드 영역
                          Expanded(
                            flex: 520,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                              child: GridView.builder(
                                padding: EdgeInsets.only(
                                  top: screenHeight * 0.02,
                                  bottom: screenHeight * 0.02,
                                ),
                                itemCount: _teams.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: scaleWidth(8),
                                  mainAxisSpacing: screenHeight * 0.01,
                                  childAspectRatio: 1.2,
                                ),
                                itemBuilder: (context, index) {
                                  final team = _teams[index];
                                  final isSelected = _selectedTeam == team['name'];

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedTeam == team['name']) {
                                          _selectedTeam = null;
                                        } else {
                                          _selectedTeam = team['name'];
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.gray50,
                                        border: isSelected
                                            ? Border.all(color: AppColors.pri300, width: scaleWidth(3))
                                            : Border.all(color: AppColors.gray50, width: scaleWidth(1)),
                                        borderRadius: BorderRadius.circular(scaleHeight(20)),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  team['image']!,
                                                  width: scaleHeight(60),
                                                  height: scaleHeight(60),
                                                ),
                                                SizedBox(height: scaleHeight(8)),
                                                FixedText(
                                                  team['name']!,
                                                  style: AppFonts.suite.b2_b(context).copyWith(
                                                      color: AppColors.gray900),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Align(
                                              alignment: Alignment.topLeft,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: scaleHeight(15),
                                                  left: scaleHeight(15),
                                                ),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.pri300,
                                                  size: scaleWidth(24),
                                                ),
                                              ),
                                            ),
                                          if (!isSelected && _selectedTeam != null)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.gray50.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(scaleHeight(12)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const Spacer(flex: 24),

                          // 확인 버튼
                          Center(
                            child: SizedBox(
                              width: scaleWidth(320),
                              height: scaleHeight(54),
                              child: ElevatedButton(
                                onPressed: _selectedTeam != null ? _handleComplete : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedTeam != null
                                      ? AppColors.gray700
                                      : AppColors.gray200,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleHeight(16)),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(18)),
                                ),
                                child: FixedText(
                                  '확인',
                                  style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 33),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}