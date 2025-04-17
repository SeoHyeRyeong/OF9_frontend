import 'package:flutter/material.dart';
import 'kakao_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final KakaoAuthService _authService = KakaoAuthService();
  String favTeam = '삼성 라이온즈'; // 기본값
  bool isLoggedIn = false;
  bool isLoading = false;

  final List<String> teams = [
    '삼성 라이온즈', 'LG 트윈스', '두산 베어스', '롯데 자이언츠', 'KT 위즈',
    'NC 다이노스', '키움 히어로즈', 'SSG 랜더스', 'KIA 타이거즈', '한화 이글스'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kakao Login Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '좋아하는 팀을 선택하세요',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              DropdownButton<String>(
                value: favTeam,
                isExpanded: true,
                items: teams
                    .map((team) => DropdownMenuItem(
                  value: team,
                  child: Text(team),
                ))
                    .toList(),
                onChanged: (v) => setState(() => favTeam = v!),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () async {
                  setState(() => isLoading = true);
                  print('▶️ 좋아하는 팀: $favTeam 으로 로그인 시작');
                  final result = await _authService.loginAndStoreTokens(favTeam);
                  print('◀️ 로그인 결과: $result');
                  setState(() {
                    isLoggedIn = result;
                    isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result ? '로그인 성공!' : '로그인 실패'),
                    ),
                  );
                },
                child: const Text('카카오 로그인'),
              ),
              const SizedBox(height: 30),
              Text(
                '로그인 상태: ${isLoggedIn ? "로그인됨" : "로그아웃됨"}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
