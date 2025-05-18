import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['NATIVE_APP_KEY']);
  runApp(
    ScreenUtilInit(
      designSize: Size(360, 800),
      minTextAdapt: false,
      splitScreenMode: true,
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: MaterialApp(
        title: 'Flutter Kakao Login',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
  }
}
