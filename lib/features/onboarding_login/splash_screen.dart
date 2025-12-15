import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/report/report_screen.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final kakaoAuthService = KakaoAuthService();

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
    // 페이드 인 즉시 시작
    _fadeController.forward();

    // 토큰 확인과 최소 시간 병렬 처리
    final results = await Future.wait([
      _checkAuthAndValidateToken(),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    final isLoggedIn = results[0] as bool;
    if (mounted) {
      await _fadeController.reverse();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          isLoggedIn ? const ReportScreen() : const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  /// 토큰 검증 및 자동 갱신 + 실제 API 호출로 재확인
  Future<bool> _checkAuthAndValidateToken() async {
    try {
      // 1단계: JWT 디코딩으로 토큰 존재 여부 및 기본 만료 확인
      final isValid = await kakaoAuthService.validateAndRefreshTokenOnStartup();
      print('🚀 JWT 검증 결과: $isValid');

      if (!isValid) {
        return false;
      }

      // 2단계: 실제 API 호출로 토큰이 서버에서도 유효한지 확인
      print('🔍 실제 API 호출로 토큰 유효성 재확인');
      try {
        final backendUrl = dotenv.env['BACKEND_URL'];
        if (backendUrl == null) {
          print('❌ BACKEND_URL 설정 안 됨');
          return false;
        }
        final accessToken = await kakaoAuthService.getAccessToken();
        if (accessToken == null) {
          print('❌ Access Token이 null');
          return false;
        }

        final response = await http.get(
          Uri.parse('$backendUrl/users/me'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));


        // 200이면 토큰이 유효함
        if (response.statusCode == 200) {
          print('✅ 토큰이 서버에서도 유효함');
          return true;
        }

        // 401/403이면 토큰 갱신 시도
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('⏰ 서버에서 토큰 거부됨, 갱신 시도');
          final refreshResult = await kakaoAuthService.refreshTokens();
          if (refreshResult != null) {
            print('✅ 토큰 갱신 성공');
            return true;
          } else {
            print('❌ 토큰 갱신 실패 - 재로그인 필요');
            await kakaoAuthService.clearTokens();
            return false;
          }
        }

        // 그 외 에러는 토큰 무효로 간주
        print('❌ 예상치 못한 응답: ${response.statusCode}');
        await kakaoAuthService.clearTokens();
        return false;

      } catch (e) {
        print('❌ API 호출 오류: $e');

        // 네트워크 오류인 경우에도 JWT 만료 시간 체크
        if (e.toString().contains('TimeoutException') ||
            e.toString().contains('SocketException')) {

          print('⚠️ 네트워크 오류 발생 - JWT 만료 시간 확인 중...');

          // JWT 만료 시간 직접 확인
          final accessToken = await kakaoAuthService.getAccessToken();
          if (accessToken != null) {
            final parts = accessToken.split('.');
            if (parts.length == 3) {
              try {
                final payload = parts[1];
                final normalized = base64Url.normalize(payload);
                final decoded = utf8.decode(base64Url.decode(normalized));
                final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
                final exp = payloadMap['exp'] as int;
                final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

                // JWT가 아직 유효한 경우에만 통과
                if (exp > now) {
                  final timeLeft = exp - now;
                  print('✅ 네트워크 오류지만 JWT는 유효 (${timeLeft}초 = ${(timeLeft / 60).toStringAsFixed(1)}분 남음) - 통과');
                  return true;
                } else {
                  print('❌ 네트워크 오류 + JWT 만료됨 - 재로그인 필요');
                  await kakaoAuthService.clearTokens();
                  return false;
                }
              } catch (parseError) {
                print('❌ JWT 파싱 실패: $parseError');
                await kakaoAuthService.clearTokens();
                return false;
              }
            }
          }

          print('❌ 네트워크 오류 + 토큰 확인 실패 - 재로그인 필요');
          await kakaoAuthService.clearTokens();
          return false;
        }
        // 기타 오류는 재로그인 필요
        await kakaoAuthService.clearTokens();
        return false;
      }
    } catch (e) {
      print('❌ 토큰 검증 오류: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ MaterialApp의 AnnotatedRegion이 전역으로 처리하므로 여기서는 제거
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
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;

              return Stack(
                children: [
                  // 배경 레이어
                  SizedBox(
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
                            fit: BoxFit.contain,
                            width: scaleWidth(230),
                            height: scaleHeight(140),
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