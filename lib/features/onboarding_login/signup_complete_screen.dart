import 'package:flutter/material.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/features/feed/feed_screen.dart';

class SignupCompleteScreen extends StatefulWidget {
  final String? selectedTeam;

  const SignupCompleteScreen({Key? key, this.selectedTeam}) : super(key: key);

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen> {
  final Map<String, String> _teamImages = {
    '두산 베어스': AppImages.bears,
    '롯데 자이언츠': AppImages.giants,
    '삼성 라이온즈': AppImages.lions,
    '키움 히어로즈': AppImages.kiwoom,
    '한화 이글스': AppImages.eagles,
    'KIA 타이거즈': AppImages.tigers,
    'KT WIZ': AppImages.ktwiz,
    'LG 트윈스': AppImages.twins,
    'NC 다이노스': AppImages.dinos,
    'SSG 랜더스': AppImages.landers,
  };

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: scaleHeight(76)),

            // Welcome 이미지
            Image.asset(
              AppImages.welcome,
              width: scaleWidth(296),
              height: scaleHeight(262),
            ),

            SizedBox(height: scaleHeight(40)),

            // 메인 타이틀
            Column(
              children: [
                FixedText(
                  '두다다에 오신 것을',
                  style: AppFonts.suite.h1_b(context).copyWith(color: Colors.black),
                ),
                SizedBox(height: scaleHeight(12)),
                FixedText(
                  '환영합니다!',
                  style: AppFonts.suite.h1_b(context).copyWith(color: Colors.black),
                ),
              ],
            ),

            SizedBox(height: scaleHeight(20)),

            // 서브 타이틀
            FixedText(
              '지금부터 나만의 직관 이야기를 기록해 보세요!',
              style: AppFonts.suite.b2_m_long(context).copyWith(color: AppColors.gray300),
            ),

            SizedBox(height: scaleHeight(26)),

            // 티켓 이미지와 팀 정보
            Container(
              width: scaleWidth(320),
              height: scaleHeight(76),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImages.img_ticket),
                  fit: BoxFit.contain,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: scaleWidth(35)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // "최애 구단" 텍스트
                    FixedText(
                      '최애 구단',
                      style: AppFonts.suite.b2_m_long(context).copyWith(color: AppColors.gray800),
                    ),

                    SizedBox(width: scaleWidth(40)),

                    // 팀 정보
                    if (widget.selectedTeam != null) ...[
                      // 팀 이미지
                      Image.asset(
                        _teamImages[widget.selectedTeam!]!,
                        width: scaleWidth(40),
                        height: scaleHeight(40),
                      ),

                      SizedBox(width: scaleWidth(10)),

                      // 팀 이름
                      FixedText(
                        widget.selectedTeam!,
                        style: AppFonts.suite.b2_m_long(context).copyWith(color: AppColors.gray800),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: scaleHeight(50)),

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
          ],
        ),
      ),
    );
  }
}