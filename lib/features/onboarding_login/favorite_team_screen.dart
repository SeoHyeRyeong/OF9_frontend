import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:frontend/features/onboarding_login/signup_complete_screen.dart';

class FavoriteTeamScreen extends StatefulWidget {
  const FavoriteTeamScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteTeamScreen> createState() => _FavoriteTeamScreenState();
}

class _FavoriteTeamScreenState extends State<FavoriteTeamScreen> {
  String? _selectedTeam;

  final List<Map<String, String>> _teams = [
    {'name': 'KIA 타이거즈', 'image': AppImages.tigers},
    {'name': '두산 베어스', 'image': AppImages.bears},
    {'name': '롯데 자이언츠', 'image': AppImages.giants},
    {'name': '삼성 라이온즈', 'image': AppImages.lions},
    {'name': '키움 히어로즈', 'image': AppImages.kiwoom},
    {'name': '한화 이글스', 'image': AppImages.engles},
    {'name': 'KT WIZ', 'image': AppImages.ktwiz},
    {'name': 'LG 트윈스', 'image': AppImages.twins},
    {'name': 'NC 다이노스', 'image': AppImages.dinos},
    {'name': 'SSG 랜더스', 'image': AppImages.landers},
  ];

  final kakaoAuthService = KakaoAuthService();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; // 전체 화면 높이 가져오기
    final statusBarHeight = MediaQuery.of(context).padding.top; // 상태바 높이 가져오기
    final baseScreenHeight = 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 뒤로가기 버튼
            Positioned(
              top: (screenHeight * (46 / baseScreenHeight)) - statusBarHeight,
              left: 0,
              right: 0,
              child: SizedBox(
                width: 360.w,
                height: screenHeight * (60 / baseScreenHeight),
                child: Stack(
                  children: [
                    Positioned(
                      top: screenHeight * (18 / baseScreenHeight),
                      left: 20.w,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        child: SvgPicture.asset(
                          AppImages.backBlack,
                          width: 24.h,
                          height: 24.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // "최애 구단 선택" 텍스트
            Positioned(
              top: (screenHeight * (130 / baseScreenHeight)) - statusBarHeight,
              left: 20.w,
              child: Text(
                '최애 구단 선택',
                style: AppFonts.h1_b(context).copyWith(color: Colors.black),
              ),
            ),

            // "나중에 마이페이지에서 변경 가능해요" 텍스트
            Positioned(
              top: (screenHeight * (174 / baseScreenHeight)) - statusBarHeight,
              left: 20.w,
              child: Text(
                '나중에 마이페이지에서 변경 가능해요',
                style: AppFonts.b2_m(context).copyWith(color: AppColors.gray300),
              ),
            ),

            // 구단 선택 그리드
            Positioned(
              top: (screenHeight * (190 / baseScreenHeight)) - statusBarHeight,
              left: 0,
              right: 0,
              bottom: (screenHeight * (88 / baseScreenHeight)) + (screenHeight * (24 / baseScreenHeight)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: GridView.builder(
                  padding: EdgeInsets.only(top: screenHeight * (32 / baseScreenHeight)),
                  itemCount: _teams.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: screenHeight * (8 / baseScreenHeight),
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
                              ? Border.all(color: AppColors.pri300, width: 3.w)
                              : Border.all(color: AppColors.gray50, width: 1.w),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    team['image']!,
                                    width: 60.h,
                                    height: 60.h,
                                  ),
                                  SizedBox(height: screenHeight * (8 / baseScreenHeight)),
                                  Text(
                                    team['name']!,
                                    style: AppFonts.b2_b(context).copyWith(
                                        color: AppColors.gray900),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 16.h,
                                left: 16.h,
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppColors.pri300,
                                  size: 24.w,
                                ),
                              ),
                            if (!isSelected && _selectedTeam != null)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.gray50.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12.r),
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

            // 완료 버튼
            Positioned(
              top: (screenHeight * (688 / baseScreenHeight)) - statusBarHeight,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                width: 360.w,
                height: screenHeight * (88 / baseScreenHeight),
                padding: EdgeInsets.only(
                  top: screenHeight * (24 / baseScreenHeight),
                  left: 20.w,
                  right: 20.w,
                  bottom: screenHeight * (10 / baseScreenHeight),
                ),
                child: Center(
                  child: SizedBox(
                    width: 320.w,
                    height: screenHeight * (54 / baseScreenHeight),
                    child: ElevatedButton(
                      onPressed: _selectedTeam != null
                          ? () async {
                        final success = await kakaoAuthService
                            .loginAndStoreTokens(_selectedTeam!);
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (
                                context) => const SignupCompleteScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그인 실패')),
                          );
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTeam != null ? AppColors
                            .gray700 : AppColors.gray200,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                      ),
                      child: Text(
                        '완료',
                        style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}