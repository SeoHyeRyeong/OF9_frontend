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
import 'package:app_links/app_links.dart';
import 'dart:async';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM 초기화
  await FCMService().initialize();

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

  runApp(const MyApp());

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
  late AppLinks _appLinks;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initUniLinks() async {
    _appLinks = AppLinks();

    try {
      // 초기 링크 가져오기
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // 링크 스트림 구독
      _sub = _appLinks.uriLinkStream.listen((Uri uri) {
        _handleDeepLink(uri);
      });
    } catch (e) {
      print('❌ Deep Link 초기화 실패: $e');
    }
  }

  // _handleDeepLink는 그대로 사용 (변경 없음)
  void _handleDeepLink(Uri uri) {
    if (uri.host == 'dodada.site' && uri.pathSegments.length > 1) {
      if (uri.pathSegments[0] == 'profile') {
        final userId = uri.pathSegments[1];
        Future.delayed(const Duration(milliseconds: 500), () {
          // TODO: OtherUserProfileScreen import 후 사용
          print('✅ 프로필 페이지로 이동: userId=$userId');
        });
      }
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
