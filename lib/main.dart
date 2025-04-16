import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await printKeyHash();
  await dotenv.load();
  final kakaoKey = dotenv.env['NATIVE_APP_KEY'];
  KakaoSdk.init(nativeAppKey: kakaoKey);
  runApp(const MyApp());
}

Future<void> printKeyHash() async {
  try {
    final keyHash = await KakaoSdk.origin;
    print("현재 사용 중인 키 해시: $keyHash");
  } catch (e) {
    print("키 해시를 가져오는 중 오류 발생: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Kakao Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Kakao Login Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoggedIn = false;

  Future<bool> login() async {
    try {
      bool isInstalled = await isKakaoTalkInstalled();
      if (isInstalled) {
        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
          print("카카오톡으로 로그인 성공 ${token.accessToken}");
          return true;
        } catch (e) {
          print("카카오톡으로 로그인 실패 $e");
          return false;
        }
      } else {
        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
          print("카카오 계정으로 로그인 성공");
          return true;
        } catch (e) {
          print("카카오 계정으로 로그인 실패 $e");
          return false;
        }
      }
    } catch (error) {
      print("로그인 중 오류 발생: $error");
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await UserApi.instance.unlink();
      print("로그아웃 성공");
      return true;
    } catch (error) {
      print("로그아웃 실패 $error");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '로그인 상태: ${isLoggedIn ? "로그인됨" : "로그아웃됨"}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () async {
                bool result = await login();
                setState(() {
                  isLoggedIn = result;
                });
              },
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool result = await logout();
                setState(() {
                  isLoggedIn = !result;
                });
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
