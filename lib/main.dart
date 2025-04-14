import 'package:flutter/material.dart';
import 'login_screen.dart'; // 온보딩 이후 로그인으로 넘어가기 위해
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // .env에서 KAKAO_NATIVE_APP_KEY 읽기
    String kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? 'No Key Found';

    return Scaffold(
      appBar: AppBar(
        title: Text('환경 변수 테스트'),
      ),
      body: Center(
        child: Text('카카오 네이티브 앱 키: $kakaoKey'),
      ),
    );
  }}
