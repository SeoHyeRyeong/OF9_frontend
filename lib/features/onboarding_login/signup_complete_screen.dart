import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/onboarding_login/home_screen.dart';

class SignupCompleteScreen extends StatelessWidget {
  const SignupCompleteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray20,
      bottomNavigationBar: Padding( // 버튼 고정
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
        child: SizedBox(
          width: double.infinity,
          height: 54.h,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pri500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            child: Text(
              '완료',
              style: AppFonts.b2_b.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: scaleHeight(64)),
              Text(
                '회원가입을 완료했어요!',
                style: AppFonts.h3_sb.copyWith(color: AppColors.gray900),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: scaleHeight(8)),
              Text(
                '지금부터 당신의 야구 이야기를 기록해 보세요',
                style: AppFonts.b3_m.copyWith(color: AppColors.gray400),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: scaleHeight(48)),
              Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    '축하의 의미를 담은\n그래픽 에셋',
                    style: AppFonts.b3_m.copyWith(color: AppColors.gray500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Spacer(), // 버튼은 body 아래 고정
            ],
          ),
        ),
      ),
    );
  }
}
