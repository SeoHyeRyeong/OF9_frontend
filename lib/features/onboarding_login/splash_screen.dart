import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:frontend/features/report/report_screen.dart';
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

    _lottieController = AnimationController(vsync: this);
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
    _fadeController.forward();

    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _performAppInitialization(),
    ]);

    if (mounted) {
      await _fadeController.reverse();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          widget.isLoggedIn ? const ReportScreen() : const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  Future<void> _performAppInitialization() async {
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
    // 중복 제거된 SystemUiOverlayStyle 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // 한 번만 지정
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;

              return Stack(
                children: [
                  // 배경 레이어
                  Container(
                    width: screenWidth,
                    height: screenHeight,
                    child: Column(
                      children: [
                        Container(
                          height: screenHeight * 0.7,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF78BDEC),
                                Color(0xFFFFFFFF),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lottie 애니메이션
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.29),
                        Center(
                          child: Lottie.asset(
                            'assets/animations/splash.json',
                            controller: _lottieController,
                            width: scaleWidth(225),
                            height: scaleHeight(136),
                            fit: BoxFit.contain,
                            repeat: true,
                            onLoaded: (composition) {
                              _lottieController
                                ..duration = composition.duration
                                ..repeat();
                            },
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),

                  // dodada 이미지
                  Positioned(
                    bottom: scaleHeight(242 + 1),
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

                  // splash 이미지
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        height: scaleHeight(242),
                        width: screenWidth,
                        child: SvgPicture.asset(
                          AppImages.splash,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
