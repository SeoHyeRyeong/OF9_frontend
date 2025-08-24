import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/features/onboarding_login/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/upload/providers/record_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['NATIVE_APP_KEY']);

  // 시스템 기본 상태바 사용 (항상 표시)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 상태바 배경 투명 (디자인에 맞게 조절 가능)
      statusBarIconBrightness: Brightness.dark, // 밝은 배경이면 dark
      statusBarBrightness: Brightness.light,
    ),
  );
  // 화면 회전 고정 (세로 방향만)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

// 간단한 로그인 상태 확인 - 토큰만 있으면 OK
  final authService = KakaoAuthService();
  final isLoggedIn = await authService.hasStoredTokens();

  print('🚀 앱 시작 - 로그인 상태: $isLoggedIn');

  runApp(
    ScreenUtilInit(
      designSize: Size(360, 800), // 디자인 기준 잡은 해상도
      minTextAdapt: true,         // 폰트 사이즈 줄어들게 설정
      splitScreenMode: true,      // 분할화면 대응
      builder: (context, child) => MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecordState(),
      child: MaterialApp(
        title: 'Flutter Kakao Login',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false, //디버그 리본 숨기기

        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(
              textScaler: TextScaler.linear(1.0), // 시스템 폰트 크기 무시
            ),
            child: child!,
          );
        },

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'), // 한국어
        ],
        locale: const Locale('ko', 'KR'),

        // 로그인 여부에 따라 시작 화면 분기 -> 스플래시 코드에서 처리
        home: SplashScreen(isLoggedIn: isLoggedIn),
        //home: const LoginScreen(),//MyPageScreen(),
      ),
    );
  }
}