import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/onboarding_login/signup_complete_screen.dart';
import 'package:frontend/utils/fixed_text.dart';

class FavoriteTeamScreen extends StatefulWidget {
  final String? kakaoAccessToken;

  const FavoriteTeamScreen({Key? key, this.kakaoAccessToken}) : super(key: key);

  @override
  State<FavoriteTeamScreen> createState() => _FavoriteTeamScreenState();
}

class _FavoriteTeamScreenState extends State<FavoriteTeamScreen> {
  String? _selectedTeam;

  final List<Map<String, String>> _teams = [
    {'name': '두산 베어스', 'image': AppImages.bears},
    {'name': '롯데 자이언츠', 'image': AppImages.giants},
    {'name': '삼성 라이온즈', 'image': AppImages.lions},
    {'name': '키움 히어로즈', 'image': AppImages.kiwoom},
    {'name': '한화 이글스', 'image': AppImages.eagles},
    {'name': 'KIA 타이거즈', 'image': AppImages.tigers},
    {'name': 'KT WIZ', 'image': AppImages.ktwiz},
    {'name': 'LG 트윈스', 'image': AppImages.twins},
    {'name': 'NC 다이노스', 'image': AppImages.dinos},
    {'name': 'SSG 랜더스', 'image': AppImages.landers},
  ];

  final kakaoAuthService = KakaoAuthService();

  Future<void> _handleComplete() async {
    if (widget.kakaoAccessToken != null && _selectedTeam != null) {
      final tokens = await kakaoAuthService.sendKakaoTokenToBackend(
          widget.kakaoAccessToken!,
          _selectedTeam!
      );

      if (tokens != null) {
        await kakaoAuthService.saveTokens(
          accessToken: tokens['accessToken']!,
          refreshToken: tokens['refreshToken']!,
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                SignupCompleteScreen(selectedTeam: _selectedTeam),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 1. PopScope: 시스템 뒤로 가기 동작을 정의합니다.
    return PopScope(
      canPop: false, // 시스템 pop 동작을 막습니다.
      onPopInvoked: (didPop) {
        if (!didPop) {
          // canPop이 false이므로, pop 시도 시 이 코드가 실행됩니다.
          // LoginScreen으로 돌아가도록 설정 (pushReplacement)
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const LoginScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 1. 뒤로가기 영역 - 60px 높이
              Container(
                width: double.infinity,
                height: scaleHeight(60),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: scaleWidth(20)),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const LoginScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    AppImages.backBlack,
                    width: scaleWidth(24),
                    height: scaleHeight(24),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: scaleHeight(16)),

              // 2. 제목 영역
              Padding(
                padding: EdgeInsets.only(left: scaleWidth(20)),
                child: Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FixedText(
                        '최애 구단 선택',
                        style: AppFonts.pretendard.title_lg_600(context).copyWith(color: AppColors.gray800),
                      ),
                      SizedBox(height: scaleHeight(4)),
                      FixedText(
                        '나중에 마이페이지에서 변경 가능해요',
                        style: AppFonts.pretendard.body_md_400(context).copyWith(color: AppColors.gray300),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: scaleHeight(8)),

              // 3. 그리드 영역
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                  child: GridView.builder(
                    padding: EdgeInsets.only(
                      top: scaleHeight(20),
                      bottom: scaleHeight(5),
                    ),
                    itemCount: _teams.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: scaleWidth(8),
                      mainAxisSpacing: scaleHeight(8),
                      childAspectRatio: 1.2,
                    ),
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      final isSelected = _selectedTeam == team['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedTeam == team['name']) {
                              _selectedTeam = null;
                            } else {
                              _selectedTeam = team['name'];
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            border: isSelected
                                ? Border.all(color: AppColors.gray700, width: scaleWidth(3))
                                : Border.all(color: AppColors.gray50, width: scaleWidth(1)),
                            borderRadius: BorderRadius.circular(scaleHeight(20)),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      team['image']!,
                                      width: scaleHeight(76),
                                      height: scaleHeight(76),
                                    ),
                                    SizedBox(height: scaleHeight(2)),
                                    FixedText(
                                      team['name']!,
                                      style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray900),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: scaleHeight(14),
                                      left: scaleHeight(14),
                                    ),
                                    child: Container(
                                      width: scaleWidth(24),
                                      height: scaleWidth(24),
                                      decoration: BoxDecoration(
                                        color: AppColors.gray700,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          AppImages.check,
                                          width: scaleWidth(13),
                                          height: scaleHeight(11),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (!isSelected && _selectedTeam != null)
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.gray50.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(scaleHeight(20)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. 확인 버튼 영역
              Container(
                width: double.infinity,
                height: scaleHeight(88),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gray20,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: scaleHeight(24),
                  right: scaleWidth(20),
                  bottom: scaleHeight(10),
                  left: scaleWidth(20),
                ),
                child: ElevatedButton(
                  onPressed: _selectedTeam != null ? _handleComplete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTeam != null
                        ? AppColors.gray700
                        : AppColors.gray200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleHeight(16)),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: Center(
                    child: FixedText(
                      '확인',
                      style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}