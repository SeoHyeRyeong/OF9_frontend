import 'package:flutter/material.dart';
import 'kakao_auth_service.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';

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
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle, //원형 동그라미
                color: _currentIndex == index ? AppColors.gray600 : AppColors
                    .gray100,
              ),
            ),
            if (index != onboardingData.length - 1) // 마지막 인덱스가 아니라면 gap 삽입
              const SizedBox(width: 16),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( //노치, 상태바 등 피해서 배치
        child: Column(
          children: [

            /// 상단 그래픽 이미지 (450 영역)
            Expanded(
              flex: 9,
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index); //페이지 전환 시 인디케이터 갱신
                },
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return Image.asset(
                    data['image']!,
                    width: double.infinity, //가로 꽉 채우기
                    fit: BoxFit.cover, //이미지 비율 유지하며 빈 공간 없이 채우기
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error), //이미지 로딩 실패 시
                  );
                },
              ),
            ),

            /// 인디케이터 + 설명 + 버튼 (350 영역)
            Expanded(
              flex: 7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //위젯들 세로로 고르게 배치
                children: [
                  // 인디케이터
                  _buildPageIndicator(),

                  // 텍스트 설명
                  Column(
                    children: [
                      Text(
                        onboardingData[_currentIndex]['title']!,
                        style: AppFonts.h3_eb.copyWith(
                            color: AppColors.gray800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 44),
                      Text(
                        onboardingData[_currentIndex]['subtitle']!,
                        style: AppFonts.b2_m_long.copyWith(
                            color: AppColors.gray300),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),

                  // 카카오 버튼
                  isLoading
                      ? const CircularProgressIndicator() //로딩 중이면 로딩 인디케이션 표시
                      : SizedBox(
                    width: 320,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _handleKakaoLogin, //버튼 클릭 시 로그인 함수 실행
                      icon: Image.asset(AppImages.kakaobrown),
                      label: Text(
                        '카카오로 계속하기',
                        style: AppFonts.b2_b.copyWith(color: AppColors.kakao02), // 폰트 적용
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(18), // 버튼 안쪽 여백 18px
                        backgroundColor: AppColors.kakao01,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), //모서리 둥근 정도
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
    );
  }
}
