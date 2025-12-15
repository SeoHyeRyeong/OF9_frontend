import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/features/onboarding_login/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/upload/providers/record_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/features/notification/fcm_service.dart';
import 'firebase_options.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 시스템 UI / 방향 먼저 세팅 (Android 시스템 바텀바 UI 위해)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2) Firebase / FCM 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FCMService().initialize();

  // 3) 앱 실행
  runApp(const MyApp());

  // 4) 비동기 초기화 (dotenv, Kakao 등)
  _initializeInBackground();
}

Future<void> _initializeInBackground() async {
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['NATIVE_APP_KEY']);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 네이티브 딥링크용 MethodChannel
  static const platform = MethodChannel('com.of9.dodada/deeplink');

  @override
  void initState() {
    super.initState();
    _setupNativeDeepLink();
  }

  void _setupNativeDeepLink() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'handleDeepLink') {
        final String url = call.arguments;
        print('✅ [Flutter] 네이티브에서 URL 수신: $url');
        _handleDeepLinkUrl(url);
      }
    });
  }

  void _handleDeepLinkUrl(String urlString) {
    final uri = Uri.parse(urlString);

    if (uri.host == 'dodada.site' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'profile') {
      final userId = int.parse(uri.pathSegments[1]);
      print('✅ [Flutter] 프로필 이동: userId=$userId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MyPageScreen(
                fromNavigation: false,
                showBackButton: true,
              ),
            ),
          );
          print('✅ [Flutter] 네비게이션 완료');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecordState(),
      child: FutureBuilder(
        future: _getClarityConfig(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ClarityWidget(
              clarityConfig: snapshot.data as ClarityConfig,
              app: _buildApp(),
            );
          }
          return _buildApp();
        },
      ),
    );
  }

  Future<ClarityConfig> _getClarityConfig() async {
    await dotenv.load();
    return ClarityConfig(
      projectId: dotenv.env['CLARITY_PROJECT_ID']!,
      logLevel: LogLevel.None,
    );
  }

  Widget _buildApp() {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Flutter Kakao Login',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.notoSansKrTextTheme(
            Theme.of(context).textTheme,
          ).apply(
            fontFamilyFallback: ['NotoSansKR', 'AppleSDGothicNeo', 'MalgunGothic'],
          ),
        ),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(
              textScaler: const TextScaler.linear(1.0),
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
          Locale('ko', 'KR'),
        ],
        locale: const Locale('ko', 'KR'),
        home: const SplashScreen(),
      ),
    );
  }
}
