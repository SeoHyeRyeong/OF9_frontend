import 'package:flutter/material.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 선택된 탭 인덱스 (0: ALL, 1: 친구의 직관 기록, 2: 받은 공감, 3: 소식)
  int selectedTabIndex = 0;

  // 탭 버튼 텍스트 목록
  final List<String> tabTexts = [
    "ALL",
    "친구의 직관 기록",
    "받은 공감",
    "소식"
  ];

  @override
  void initState() {
    super.initState();
    // 초기화 로직
  }

  @override
  void dispose() {
    // 리소스 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알림 제목 컨테이너
            Container(
              width: scaleWidth(360),
              height: scaleHeight(64),
              child: Padding(
                padding: EdgeInsets.only(
                  left: scaleWidth(22),
                  top: scaleHeight(25),
                ),
                child: FixedText(
                  "알림",
                  style: AppFonts.suite.h3_b(context).copyWith(color: AppColors.black),
                ),
              ),
            ),

            SizedBox(height: scaleHeight(10)),

            // 탭 버튼들
            Padding(
              padding: EdgeInsets.only(left: scaleWidth(20)),
              child: Row(
                children: List.generate(tabTexts.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < tabTexts.length - 1 ? scaleWidth(6) : 0,
                    ),
                    child: _buildTabButton(index),
                  );
                }),
              ),
            ),

            // 나머지 컨텐츠 영역
            Expanded(
              child: Center(
                child: FixedText(
                  "받은 알림이 없어요",
                  style: AppFonts.suite.b1_sb(context).copyWith(color: AppColors.gray400),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
    );
  }

  // 탭 버튼 위젯
  Widget _buildTabButton(int index) {
    final bool isSelected = selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Container(
        height: scaleHeight(36),
        padding: EdgeInsets.only(
          top: scaleHeight(12),
          right: scaleWidth(14),
          bottom: scaleHeight(12),
          left: scaleWidth(14),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray600 : AppColors.gray30,
          borderRadius: BorderRadius.circular(scaleHeight(68)),
        ),
        child: Center(
          child: FixedText(
            tabTexts[index],
            style: isSelected
                ? AppFonts.suite.c1_b(context).copyWith(color: AppColors.gray20)
                : AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray500),
          ),
        ),
      ),
    );
  }
}