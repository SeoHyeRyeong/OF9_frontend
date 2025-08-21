import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/features/feed/feed_screen.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';
import 'package:frontend/utils/fixed_text.dart';

class SignupCompleteScreen extends StatelessWidget {
  const SignupCompleteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      return Column(
                        children: [
                          const Spacer(flex: 238),

                          FixedText(
                            '회원가입을 완료했어요!',
                            style: AppFonts.suite.h1_b(context).copyWith(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),

                          const Spacer(flex: 30),

                          // 서브 텍스트
                          FixedText(
                            '지금부터 당신의 야구 이야기를 기록해 보세요',
                            style: AppFonts.suite.b2_m_long(context).copyWith(color: AppColors.gray300),
                            textAlign: TextAlign.center,
                          ),

                          const Spacer(flex: 85),

                          // 축하 에셋
                          Image.asset(
                            AppImages.complete,
                            width: scaleHeight(260),
                            height: scaleHeight(260),
                            fit: BoxFit.contain,
                          ),

                          const Spacer(flex: 244),

                          // 완료 버튼
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: SizedBox(
                              width: scaleWidth(320),
                              height: scaleHeight(54),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation1, animation2) => const FeedScreen(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gray700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleHeight(16)),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(18)),
                                  elevation: 0,
                                ),
                                child: FixedText(
                                  '완료',
                                  style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 51),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
