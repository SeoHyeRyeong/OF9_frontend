import 'package:flutter/material.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/onboarding_login/favorite_team_screen.dart';
import 'package:frontend/features/report/report_screen.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:url_launcher/url_launcher.dart';

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
      'subtitle': '직관 횟수, 감정 분포 등 통계로 확인하고\n특별한 팬 뱃지를 모아 보세요'
    },
    {
      'image': AppImages.loginOnboarding3,
      'title': '친구와 직관 기록 공유',
      'subtitle': '설레는 직관, 그 순간의 감정을\n친구와 함께 나눠 보세요'
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
              width: scaleHeight(10),
              height: scaleHeight(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? AppColors.gray700: AppColors.gray100,
              ),
            ),
            if (index != onboardingData.length - 1)
              SizedBox(width: scaleWidth(16)),
          ],
        );
      }),
    );
  }

  Future<void> _handleKakaoLogin() async {
    setState(() => isLoading = true);

    try {
      // 1. 카카오 로그인으로 액세스 토큰 획득
      final kakaoAccessToken = await kakaoAuthService.kakaoLogin();

      if (kakaoAccessToken == null) {
        setState(() => isLoading = false);
        return;
      }

      // 2. 기존 사용자인지 확인
      final isExistingUser = await kakaoAuthService.checkExistingUser(kakaoAccessToken);

      setState(() => isLoading = false);

      if (isExistingUser) {
        // 기존 사용자: 바로 로그인 후 피드로 이동
        final loginSuccess = await kakaoAuthService.loginExistingUser(kakaoAccessToken);

        if (loginSuccess) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const ReportScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 실패')),
          );
        }
      } else {
        // 신규 사용자: 회원가입 플로우로 이동
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                FavoriteTeamScreen(kakaoAccessToken: kakaoAccessToken),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('로그인 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 처리 중 오류가 발생했습니다')),
      );
    }
  }

  // URL 열기 함수 추가
  Future<void> _launchHelpUrl() async {
    final Uri url = Uri.parse('https://www.notion.so/2c6f22b2f4cd806e8dabd3d01ed28d3d');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          child: Column(
            children: [
              SizedBox(height: scaleHeight(25)),

              // 1. 이미지 영역
              AspectRatio(
                aspectRatio: 320 / 364,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final data = onboardingData[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(scaleHeight(8)),
                      child: Image.asset(
                        data['image']!,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: scaleHeight(25)),

              // 2. 페이지 인디케이터
              _buildPageIndicator(),
              SizedBox(height: scaleHeight(28)),

              // 3. Title
              FixedText(
                onboardingData[_currentIndex]['title']!,
                style: AppFonts.pretendard.title_md_600(context).copyWith(
                  color: AppColors.gray800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: scaleHeight(16)),

              // 4. Subtitle
              FixedText(
                onboardingData[_currentIndex]['subtitle']!,
                style: AppFonts.pretendard.body_md_400(context).copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: scaleHeight(28)),

              // 5. 카카오 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: scaleHeight(60),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleKakaoLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kakao01,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleHeight(16)),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: AppColors.kakao02)
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppImages.kakaobrown,
                        width: scaleHeight(28),
                        height: scaleHeight(28),
                        color: AppColors.kakao02,
                      ),
                      SizedBox(width: scaleWidth(8)),
                      FixedText(
                        '카카오로 로그인',
                        style: AppFonts.pretendard.head_sm_600(context).copyWith(
                          color: AppColors.kakao02,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: scaleHeight(16)),

              // 6. 로그인 문제 텍스트
              GestureDetector(
                onTap: _launchHelpUrl,
                child: FixedText(
                  '로그인에 문제가 있나요?',
                  style: AppFonts.pretendard.body_sm_400(context).copyWith(
                    color: AppColors.gray300,
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}