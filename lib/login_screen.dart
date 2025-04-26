import 'package:flutter/material.dart';
import 'kakao_auth_service.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/utils/size_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController(); // 페이지 뷰 컨트롤러
  int _currentIndex = 0; // 현재 페이지 인덱스
  bool isLoggedIn = false; //로그인 로딩 상태
  bool isLoading = false; //로그인 여부 상태
  final kakaoAuthService = KakaoAuthService(); // 카카오 로그인 서비스 인스턴스
  final String favTeam = "삼성 라이온즈"; // 테스트용 임시 팀 → 나중에 팀 고르는 dart 파일 만들면 그걸 kakao_auth_service.dart랑 연결하기

  /// 로그인 화면에 들어갈 그래픽 및 설명
  final onboardingData = [
    {
      'image': 'assets/imgs/login_onboarding1.png',
      'title': '직관 기록 업로드',
      'subtitle': '기능설명! 기능설명! 기능설명! 기능설명!\n기능설명! 기능설명! 기능설명! 기능설명!'
    },
    {
      'image': 'assets/imgs/login_onboarding2.png',
      'title': '기록으로 쌓이는 팬 히스토리',
      'subtitle': '직관 횟수, 감정 분포 등 통계를 확인하고\n특별한 팬 뱃지를 모아보세요'
    },
    {
      'image': 'assets/imgs/login_onboarding3.png',
      'title': '친구와 직관 기록 공유',
      'subtitle': '이제부터 직찍!\n친구와 직관 순간을 나눠 보세요'
    },
  ];

  /// 페이지 인디케이터(동그라미)
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          onboardingData.length, (index) { //onboardingData 길이만큼 개수 생성
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), //색상 전환 애니메이션 속도
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle, //원형 동그라미
                color: _currentIndex == index ? AppColors.gray600 : AppColors
                    .gray100,
              ),
            ),
            if (index != onboardingData.length - 1) // 마지막 인덱스가 아니라면 gap 삽입
              SizedBox(width: 16.w),
          ],
        );
      }),
    );
  }

  /// 카카오 로그인 + 백엔드 전송 + 토큰 저장 전체 처리
  Future<void> _handleKakaoLogin() async {
    setState(() => isLoading = true);
    print('▶️ 좋아하는 팀: $favTeam 으로 로그인 시작');
    final result = await kakaoAuthService.loginAndStoreTokens(favTeam);
    print('◀️ 로그인 결과: $result');
    setState(() {
      isLoggedIn = result;
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result ? '로그인 성공!' : '로그인 실패')),
    );
  }

  /// 뷰 디자인
  @override
  Widget build(BuildContext context) {
    final heights = calculateHeights(
      imageBaseHeight: 450, // 이 화면의 상단 기준 높이
      contentBaseHeight: 350, // 이 화면의 하단 기준 높이
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( // 노치, 상태바 등 피해서 배치
        child: Stack(
          children: [

            /// 상단 그래픽 이미지 (450 영역)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heights['imageHeight'],
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index); // 페이지 전환 시 인디케이터 갱신
                },
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return Image.asset(
                    data['image']!,
                    width: double.infinity, // 가로 꽉 채우기
                    fit: BoxFit.cover, // 이미지 비율 유지하며 빈 공간 없이 채우기
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error), // 이미지 로딩 실패 시
                  );
                },
              ),
            ),

            /// 인디케이터 (480 위치)
            Positioned(
              top: scaleHeight(480),
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),

            /// 메인 텍스트 (530 위치)
            Positioned(
              top: scaleHeight(530),
              left: 0,
              right: 0,
              child: Text(
                onboardingData[_currentIndex]['title']!,
                style: AppFonts.h3_eb.copyWith(
                  color: AppColors.gray800,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            /// 서브 텍스트 (574 위치)
            Positioned(
              top: scaleHeight(574),
              left: 0,
              right: 0,
              child: Text(
                onboardingData[_currentIndex]['subtitle']!,
                style: AppFonts.b2_m_long.copyWith(
                  color: AppColors.gray300,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            /// 카카오 버튼 (674 위치)
            Positioned(
              top: scaleHeight(674),
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 320.w,
                  height: 54.h,
                  child: isLoading
                      ? const CircularProgressIndicator() // 로딩 중이면 로딩 표시
                      : ElevatedButton(
                    onPressed: _handleKakaoLogin, // 버튼 클릭 시 로그인 함수 실행
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(10.w), // 피그마에는 18인데... 그러면 글자가 안 들어가져서 줄임
                      backgroundColor: AppColors.kakao01,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r), // 모서리 둥근 정도
                      ),
                      elevation: 0, // 그림자 제거
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 버튼 내용 크기만큼만 차지
                      mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                      children: [
                        Image.asset(
                          AppImages.kakaobrown,
                          width: 28.w,
                          height: 28.h,
                          filterQuality: FilterQuality.high,
                        ),
                        SizedBox(width: 4.w), // 아이콘과 텍스트 사이 간격 추가
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