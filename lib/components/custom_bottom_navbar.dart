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
import 'package:frontend/features/notification/notification_screen.dart';
import 'package:frontend/features/report/report_screen.dart';

// 사용법
// import 'package:frontend/components/custom_bottom_navbar.dart';
// bottomNavigationBar: CustomBottomNavBar(
//   currentIndex: 0,
//   isDisabled: false, // 네트워크 오류 시 true로 설정
// ),

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDisabled; // 네트워크 오류 등으로 네비게이션 비활성화

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    this.isDisabled = false,
  }) : super(key: key);

  static const _navItems = [
    {'icon': AppImages.home, 'label': '홈'},
    {'icon': AppImages.report, 'label': '피드'},
    {'icon': AppImages.upload, 'label': '업로드'},
    {'icon': AppImages.bell, 'label': '알림'},
    {'icon': AppImages.person, 'label': 'MY'},
  ];

  void _handleTap(BuildContext context, int index) {
    // 비활성화 상태면 아무 동작도 하지 않음
    if (isDisabled) {
      return;
    }

    Widget? target;

    switch (index) {
      case 0:
        target = const ReportScreen();
        break;

      case 1:
        target = const FeedScreen();
        break;

      case 2:
        target = const TicketOcrScreen();
        break;

      case 3:
        target = const NotificationScreen();
        break;

      case 4:
        target = const MyPageScreen();
        break;

      default:
        return;
    }

    if (target != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => target!,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
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
              behavior: HitTestBehavior.opaque,
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
                      style: AppFonts.suite.c2_m(context).copyWith(
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