import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/features/feed/feed_screen.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';
import 'package:frontend/utils/size_utils.dart';

// 사용법
// import 'package:frontend/components/custom_bottom_navbar.dart';
// bottomNavigationBar: CustomBottomNavBar(
//   currentIndex: 0,
// ),
// 위에 currentIndex만 바꾸면 됨

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  static const _navItems = [
    {'icon': AppImages.home, 'label': '피드'},
    {'icon': AppImages.report, 'label': '리포트'},
    {'icon': AppImages.upload, 'label': '업로드'},
    {'icon': AppImages.bell, 'label': '알림'},
    {'icon': AppImages.person, 'label': 'MY'},
  ];

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return; // 현재 탭이면 무시

    Widget target;
    switch (index) {
      case 0:
        target = const FeedScreen();
        break;

    //리포트 1은 아직 미구현

      case 2:
        target = const TicketOcrScreen();
        break;

    //알림 3은 아직 미구현

      case 4:
        target = const MyPageScreen();
        break;

      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => target,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: scaleHeight(70),
        padding: EdgeInsets.fromLTRB(scaleWidth(32), scaleHeight(8), scaleWidth(32), scaleHeight(15)),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.gray100, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = currentIndex == index;
            return GestureDetector(
              onTap: () => _handleTap(context, index),
              behavior: HitTestBehavior.opaque, // 터치 안 되는 문제 방지
              child: SizedBox(
                width: scaleWidth(32),
                height: scaleHeight(44),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      item['icon']!,
                      width: scaleHeight(28),
                      height: scaleHeight(28),
                      color: isActive ? null : AppColors.gray200,
                    ),
                    SizedBox(height: scaleHeight(4)),
                    FixedText(
                      item['label']!,
                      style: AppFonts.c1_b(context).copyWith(
                        color: isActive ? Colors.black : AppColors.gray200,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}