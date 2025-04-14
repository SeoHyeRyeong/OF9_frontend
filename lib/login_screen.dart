import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class LoginScreen extends StatelessWidget {
  Future<void> kakaoLogin() async {
    try {
      // 카카오톡 설치 여부 확인
      if (await isKakaoTalkInstalled()) {
        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 성공: ${token.accessToken}');
        } catch (error) {
          print('카카오톡으로 로그인 실패: $error');
          // 카카오톡 로그인 실패 시, 계정으로 로그인 시도
          OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
          print('카카오 계정으로 로그인 성공: ${token.accessToken}');
        }
      } else {
        // 카카오톡이 설치되어 있지 않은 경우, 계정으로 로그인
        OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오 계정으로 로그인 성공: ${token.accessToken}');
      }

      // 사용자 정보 조회
      User user = await UserApi.instance.me();
      print('사용자 정보: ${user.kakaoAccount?.email}, ${user.kakaoAccount?.profile?.nickname}');
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
              onPressed: () async {
                await kakaoLogin(); // 카카오 로그인 함수 호출
              },
              child: Text('카카오 로그인'),
            ),
            SizedBox(height: 20), // 버튼 간격 조정
            ElevatedButton(
              onPressed: () async {
                await kakaoLogout(); // 카카오 로그아웃 함수 호출
              },
              child: Text('카카오 로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
