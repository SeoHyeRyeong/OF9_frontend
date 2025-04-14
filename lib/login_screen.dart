import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_signup.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> kakaoLogin() async {
    try {
      OAuthToken token;

      // 카카오톡 설치 여부 확인
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 성공: ${token.accessToken}');
        } catch (error) {
          print('카카오톡으로 로그인 실패: $error');
          token = await UserApi.instance.loginWithKakaoAccount();
          print('카카오 계정으로 로그인 성공: ${token.accessToken}');
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오 계정으로 로그인 성공: ${token.accessToken}');
      }

      // 사용자 정보 조회
      User user = await UserApi.instance.me();
      print('사용자 정보: ${user.kakaoAccount?.email}, ${user.kakaoAccount?.profile?.nickname}');

      final backendUrl = dotenv.env['BACKEND_URL'] ?? '';

      // ✅ 백엔드로 access token 전송
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'accessToken': token.accessToken}),
      );

      if (response.statusCode == 200 && mounted) {
        print('백엔드 로그인 성공: ${response.body}');

        // ✅ 화면 전환 (Flutter 프레임 이후 안전하게)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginSignupScreen(
                nickname: user.kakaoAccount?.profile?.nickname,
                email: user.kakaoAccount?.email,
              ),
            ),
          );
        });
      } else {
        print('백엔드 로그인 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (error) {
      print('로그인 실패: $error');
    }
  }

  Future<void> kakaoLogout() async {
    try {
      await UserApi.instance.logout();
      print('로그아웃 성공');
    } catch (error) {
      print('로그아웃 실패: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('카카오 로그인'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: kakaoLogin,
              child: Text('카카오 로그인'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: kakaoLogout,
              child: Text('카카오 로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
