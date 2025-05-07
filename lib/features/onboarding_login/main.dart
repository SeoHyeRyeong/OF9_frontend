import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 800), // 기준 사이즈 (예시)
      builder: (context, child) => MaterialApp(
        home: LoginScreen(), // 앱 시작하자마자 LoginScreen 띄움
      ),
    );
  }
}
