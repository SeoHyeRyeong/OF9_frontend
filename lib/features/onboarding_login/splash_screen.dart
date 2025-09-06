import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:frontend/features/feed/feed_screen.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_imgs.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SplashScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Lottie 애니메이션 컨트롤러
    _lottieController = AnimationController(vsync: this);

    // 페이드 인 애니메이션 컨트롤러
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // 페이드 인 시작
    _fadeController.forward();

    // 최소 3초 대기 (또는 앱 초기화 완료까지)
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _performAppInitialization(),
    ]);

    if (mounted) {
      // 페이드 아웃
      await _fadeController.reverse();

      // 다음 화면으로 이동 (로그인 분기 처리)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          widget.isLoggedIn ? const FeedScreen() : const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  // 앱 초기화 작업 수행
  Future<void> _performAppInitialization() async {
    // ex. API 설정, 캐시 로드, 권한 확인 등
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          return Stack(
            children: [
              // 배경 레이어
              Column(
                children: [
                  // 상단 그라데이션 영역
                  Container(
                    height: screenHeight * 0.7,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF78BDEC), // #78BDEC
                          Color(0xFFFFFFFF), // #FFFFFF
                        ],
                      ),
                    ),
                  ),
                  // 나머지 하단 흰색 영역
                  Expanded(
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Lottie 애니메이션 오버레이
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.29),

                    // Lottie 애니메이션
                    Center(
                      child: Lottie.asset(
                        'assets/animations/splash.json',
                        controller: _lottieController,
                        width: scaleWidth(225),
                        height: scaleHeight(136),
                        fit: BoxFit.contain,
                        repeat: true, //반복 재생
                        onLoaded: (composition) {
                          // Lottie 파일 로드 완료 후 애니메이션 시작
                          _lottieController
                            ..duration = composition.duration //반복 재생 시간 적용
                            ..repeat(); //반복 시작
                        },
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),

              // dodada 이미지 (splash 이미지 바로 위에)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + scaleHeight(242 + 1),
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SvgPicture.asset(
                      AppImages.dodada,
                      width: scaleWidth(84),
                      height: scaleHeight(22),
                    ),
                  ),
                ),
              ),

              // splash 이미지 (네비게이션 바 바로 위에 고정)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    height: scaleHeight(242),
                    child: SvgPicture.asset(
                      AppImages.splash,
                      fit: BoxFit.cover,
                    ),
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