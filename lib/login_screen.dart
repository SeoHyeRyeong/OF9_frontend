import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/kakao_auth_service.dart';
import 'favorite_team_screen.dart'; // 추가

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
                color: _currentIndex == index ? AppColors.gray600 : AppColors.gray100,
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
    final heights = calculateHeights(
      imageBaseHeight: 450,
      contentBaseHeight: 350,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heights['imageHeight'],
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
            Positioned(
              top: scaleHeight(480),
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),
            Positioned(
              top: scaleHeight(530),
              left: 0,
              right: 0,
              child: Text(
                onboardingData[_currentIndex]['title']!,
                style: AppFonts.h3_eb.copyWith(color: AppColors.gray800),
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: scaleHeight(574),
              left: 0,
              right: 0,
              child: Text(
                onboardingData[_currentIndex]['subtitle']!,
                style: AppFonts.b2_m_long.copyWith(color: AppColors.gray300),
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: scaleHeight(674),
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 320.w,
                  height: 54.h,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
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
                        Image.asset(
                          AppImages.kakaobrown,
                          width: 28.w,
                          height: 28.h,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '카카오로 계속하기',
                          style: AppFonts.b2_b.copyWith(
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
