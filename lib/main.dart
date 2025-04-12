import 'package:flutter/material.dart';
import 'login_screen.dart'; // 온보딩 이후 로그인으로 넘어가기 위해

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginScreen(),
    );
  }
}

