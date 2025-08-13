import 'package:flutter/material.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/onboarding_login/favorite_team_screen.dart';
import 'package:frontend/utils/fixed_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool isLoading = false;
  final kakaoAuthService = KakaoAuthService();

  final onboardingData = [
    {
      'image': AppImages.loginOnboarding1,
      'title': '직관 기록 업로드',
      'subtitle': '티켓 스캔으로 간편하게 직관 기록하고\n나만의 기록 콘텐츠를 만들어 봐요'
    },
    {
      'image': AppImages.loginOnboarding2,
      'title': '기록으로 쌓이는 팬 히스토리',
      'subtitle': '직관 횟수, 감정 분포 등 통계를 확인하고\n특별한 팬 뱃지를 모아보세요'
    },
    {
      'image': AppImages.loginOnboarding3,
      'title': '친구와 직관 기록 공유',
      'subtitle': '그 순간의 감정! 경기를 함께 본\n친구와 직관 경험을 나눠 보세요'
    },
  ];

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(onboardingData.length, (index) {
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: scaleHeight(10),   // 정사각형이므로 높이 기준으로 통일
              height: scaleHeight(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? AppColors.gray600: AppColors.gray100,
              ),
            ),
            if (index != onboardingData.length - 1)
              SizedBox(width: scaleWidth(16)), // 수평 간격은 너비 기준
          ],
        );
      }),
    );
  }

  Future<void> _handleKakaoLogin() async {
    setState(() => isLoading = true);
    final result = await kakaoAuthService.kakaoLogin();
    setState(() => isLoading = false);

    if (result != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const FavoriteTeamScreen(),
          transitionDuration: Duration.zero, // 전환 애니메이션 제거
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final statusBarHeight = MediaQuery.of(context).padding.top;

          return Column(
            children: [
              // 이미지 영역 - 전체 높이의 56.25% (450/800)
              SizedBox(
                height: screenHeight * 0.5625,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: onboardingData.length,
                      onPageChanged: (index) => setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        final data = onboardingData[index];
                        return Image.asset(
                          data['image']!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),

                    // 로고
                    Container(
                      margin: EdgeInsets.only(
                        top: statusBarHeight + (screenHeight * 0.055),
                        left: scaleWidth(20),
                      ),
                      child: SvgPicture.asset(
                        AppImages.logo_small,
                        width: scaleWidth(82),
                        height: scaleHeight(16),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              // 콘텐츠 영역 - 나머지 43.75%
              Expanded(
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      final contentHeight = contentConstraints.maxHeight;

                      return Column(
                        children: [
                          const Spacer(flex: 22),

                          _buildPageIndicator(),

                          const Spacer(flex: 33),

                          // 타이틀
                          FixedText(
                            onboardingData[_currentIndex]['title']!,
                            style: AppFonts.h3_eb(context).copyWith(
                                color: AppColors.gray800),
                            textAlign: TextAlign.center,
                          ),

                          const Spacer(flex: 20),

                          // 서브타이틀
                          FixedText(
                            onboardingData[_currentIndex]['subtitle']!,
                            style: AppFonts.b2_m_long(context).copyWith(
                                color: AppColors.gray300),
                            textAlign: TextAlign.center,
                          ),

                          const Spacer(flex: 45),

                          // 버튼
                          Center(
                            child: SizedBox(
                              width: scaleWidth(320),
                              height: scaleHeight(54),
                              child: ElevatedButton(
                                onPressed: _handleKakaoLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.kakao01,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      AppImages.kakaobrown,
                                      width: scaleHeight(28),
                                      height: scaleHeight(28),
                                      color: AppColors.kakao02,
                                    ),
                                    SizedBox(width: scaleWidth(4)),
                                    FixedText(
                                      '카카오로 계속하기',
                                      style: AppFonts.b2_b(context).copyWith(
                                        color: AppColors.kakao02,
                                      ),
                                    ),
                                  ],
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
              ),
            ],
          );
        },
      ),
    );
  }
}
