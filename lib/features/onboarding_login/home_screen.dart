import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/features/upload/ticket_scan_screen.dart'; // ✅ 새로 만든 스캔 화면 import

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray20,
      appBar: AppBar(
        title: Text('야구 직관 기록 앱', style: AppFonts.b2_b.copyWith(color: AppColors.gray900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement( // ✅ pushReplacement로 변경!
              context,
              MaterialPageRoute(builder: (context) => TicketScanScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pri500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text('티켓 스캔 시작', style: AppFonts.b2_b.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
}
