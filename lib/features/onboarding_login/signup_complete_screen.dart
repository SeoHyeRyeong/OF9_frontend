import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/home_screen.dart';

class SignupCompleteScreen extends StatelessWidget {
  const SignupCompleteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; // 전체 화면 높이 가져오기
    final statusBarHeight = MediaQuery.of(context).padding.top; // 상태바 높이 가져오기
    final baseScreenHeight = 800; // 디자인 기준 높이

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 회원가입 완료 텍스트
            Positioned(
              top: (screenHeight * (182 / baseScreenHeight)) - statusBarHeight,
              left: 0,
              right: 0,
              child: Text(
                '회원가입을 완료했어요!',
                style: AppFonts.h1_b(context).copyWith(color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),

            // 서브 텍스트
            Positioned(
              top: (screenHeight * (226 / baseScreenHeight)) - statusBarHeight,
              left: 0,
              right: 0,
              child: Text(
                '지금부터 당신의 야구 이야기를 기록해 보세요',
                style: AppFonts.b2_m_long(context).copyWith(color: AppColors.gray300),
                textAlign: TextAlign.center,
              ),
            ),

            // 축하 에셋
            Positioned(
              top: (screenHeight * (319 / baseScreenHeight)) - statusBarHeight,
              left: (ScreenUtil().screenWidth - 240.h) / 2, // 가운데 정렬
              child: Container(
                width: 240.h,
                height: 240.h,
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                ),
              ),
            ),

            // 완료 버튼 영역
            Positioned(
              top: (screenHeight * (688 / baseScreenHeight)) - statusBarHeight, // 10px bottom padding
              left: 20.w,
              right: 20.w,
              child: SizedBox(
                width: 320.w,
                height: 88.h,
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: 320.w,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gray700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          elevation: 0,
                        ),
                        child: Text(
                          '완료',
                          style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20,),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
