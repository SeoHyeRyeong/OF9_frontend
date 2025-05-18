import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/onboarding_login/favorite_team_screen.dart'; // 추가
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
      'subtitle': '기능설명! 기능설명! 기능설명! 기능설명!\n기능설명! 기능설명! 기능설명! 기능설명!'
    },
    {
      'image': AppImages.loginOnboarding2,
      'title': '기록으로 쌓이는 팬 히스토리',
      'subtitle': '직관 횟수, 감정 분포 등 통계를 확인하고\n특별한 팬 뱃지를 모아보세요'
    },
    {
      'image': AppImages.loginOnboarding3,
      'title': '친구와 직관 기록 공유',
      'subtitle': '이제부터 직찍!\n친구와 직관 순간을 나눠 보세요'
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
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? AppColors.gray600 : AppColors
                    .gray100,
              ),
            ),
            if (index != onboardingData.length - 1)
              SizedBox(width: 16.w),
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
        MaterialPageRoute(builder: (context) => const FavoriteTeamScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; //전체 화면 높이 가져오기
    final statusBarHeight = MediaQuery.of(context).padding.top; // 상태바 높이 가져오기
    final baseScreenHeight = 800;

    final imageBaseHeight = 450 - statusBarHeight;
    final imageHeightWithoutStatusBar = screenHeight *
        (imageBaseHeight / baseScreenHeight);
    final imageHeightWithStatusBar = imageHeightWithoutStatusBar +
        statusBarHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // PageView: 온보딩 이미지 슬라이더
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imageHeightWithStatusBar,
              child: PageView.builder(
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
            ),

            // 로고:
            Positioned(
              top: (screenHeight * 0.0575),
              left: 20.w,
              child: SvgPicture.asset(
                AppImages.logo_small,
                width: 82.w,
                height: 16.h,
                fit: BoxFit.contain,
              ),
            ),

            // 인디케이터
            Positioned(
              top: screenHeight * 0.6,
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),

            // 타이틀
            Positioned(
              top: screenHeight * 0.6625,
              left: 0,
              right: 0,
              child: FixedText(
                onboardingData[_currentIndex]['title']!,
                style: AppFonts.h3_eb(context).copyWith(
                    color: AppColors.gray800),
                textAlign: TextAlign.center,
              ),
            ),

            // 서브타이틀
            Positioned(
              top: screenHeight * 0.7175,
              left: 0,
              right: 0,
              child: FixedText(
                onboardingData[_currentIndex]['subtitle']!,
                style: AppFonts.b2_m_long(context).copyWith(
                    color: AppColors.gray300),
                textAlign: TextAlign.center,
              ),
            ),

            // 카카오 로그인 버튼
            Positioned(
              top: screenHeight * 0.8425,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 320.w,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: _handleKakaoLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kakao01,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          AppImages.kakaobrown,
                          width: 28.w,
                          height: 28.h,
                          color: AppColors.kakao02,
                        ),
                        SizedBox(width: 4.w),
                        FixedText(
                          '카카오로 계속하기',
                          style: AppFonts.b2_b(context).copyWith(
                            color: AppColors.kakao02,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}