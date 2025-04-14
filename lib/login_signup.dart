import 'package:flutter/material.dart';

class LoginSignupScreen extends StatelessWidget {
  final String? nickname;
  final String? email;

  const LoginSignupScreen({Key? key, this.nickname, this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('로그인 완료')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$nickname 님, 환영합니다!', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('이메일: $email', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => Placeholder()), // 나중에 HomeScreen으로 변경 가능
                );
              },
              child: Text('계속하기'),
            ),
          ],
        ),
      ),
    );
  }
}
