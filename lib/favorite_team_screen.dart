import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/kakao_auth_service.dart';
import 'signup_complete_screen.dart'; // 회원가입 완료 화면 import

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

  final kakaoAuthService = KakaoAuthService(); // Kakao 서비스 인스턴스

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray20,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: scaleHeight(32)),
              Text(
                '최애 구단 선택',
                style: AppFonts.h3_eb.copyWith(color: AppColors.gray900),
              ),
              SizedBox(height: 8.h),
              Text(
                '나중에 마이페이지에서 변경 가능해요',
                style: AppFonts.b3_m.copyWith(color: AppColors.gray400),
              ),
              SizedBox(height: scaleHeight(24)),

              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _teams.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    final isSelected = _selectedTeam == team['name'];

                    // 박스 색상 결정
                    Color boxColor;
                    if (_selectedTeam == null) {
                      boxColor = AppColors.gray50; // 아무것도 선택 안했을 때는 모두 연회색
                    } else {
                      boxColor = isSelected ? AppColors.gray50 : const Color(0xFF83878A); // 선택된 것만 연회색, 나머지 회색
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTeam == team['name']) {
                            _selectedTeam = null; // 같은 걸 누르면 선택 해제
                          } else {
                            _selectedTeam = team['name']; // 새로 선택
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: boxColor,
                          border: Border.all(
                            color: isSelected ? AppColors.pri500 : AppColors.gray100,
                            width: isSelected ? 2.w : 1.w,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  team['image']!,
                                  width: 48.w,
                                  height: 48.w,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  team['name']!,
                                  style: AppFonts.b3_sb.copyWith(color: AppColors.gray800),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8.w,
                                right: 8.w,
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppColors.pri500,
                                  size: 20.w,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 16.h),

              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _selectedTeam != null
                      ? () async {
                    final success = await kakaoAuthService.loginAndStoreTokens(_selectedTeam!);
                    if (success) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupCompleteScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인 실패')),
                      );
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTeam != null ? AppColors.pri500 : AppColors.gray100,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '완료',
                    style: AppFonts.b2_b.copyWith(
                      color: _selectedTeam != null ? Colors.white : AppColors.gray400,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
