import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';

Future<String?> showSeatInputDialog(
    BuildContext context, {
      String? initial,
    }) async {
  final parsed = parseSeatString(initial);

  String? selectedZone = parsed?['zone'];
  String? selectedBlock = parsed?['block'];
  final rowController = TextEditingController(text: parsed?['row'] ?? '');
  final numController = TextEditingController(text: parsed?['num'] ?? '');

  final List<String> zones = ['1루', '3루', '중앙', '외야'];
  final List<String> blocks = ['A', 'B', 'C', 'D'];

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final viewInset = MediaQuery.of(context).viewInsets.bottom;
      final adjustedInset = viewInset * 0.5;
      return Padding(
        padding: EdgeInsets.only(bottom: adjustedInset),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              final screenHeight = MediaQuery.of(context).size.height;
              const baseH = 800;

              final isComplete = selectedZone != null && selectedBlock != null && numController.text.isNotEmpty;

              return Container(
                width: 360.w,
                height: 537.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: Stack(
                  children: [
                    // 상단 바
                    Positioned(
                      top: 0,
                      left: 0,
                      width: 360.w,
                      height: 60.h,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 18.h,
                            left: 20.w,
                            child: SvgPicture.asset(
                              AppImages.backBlack,
                              width: 24.w,
                              height: screenHeight * (24 / baseH),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 22.h,
                            left: 166.w,
                            child: FixedText('좌석', style: AppFonts.b2_b(context)),
                          ),
                        ],
                      ),
                    ),

                    // 구역 드롭다운
                    Positioned(
                      top: 86.h,
                      left: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FixedText('구역', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                              SizedBox(width: 2.w),
                              FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 320.w,
                            height: 48.h,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                hint: FixedText('구역을 선택해 주세요', style: AppFonts.b3_sb_long(context).copyWith(color: AppColors.gray300)),
                                value: selectedZone,
                                isExpanded: true,
                                onChanged: (value) => setState(() => selectedZone = value),
                                items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 블럭 드롭다운
                    Positioned(
                      top: 182.h,
                      left: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FixedText('블럭', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                              SizedBox(width: 2.w),
                              FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 320.w,
                            height: 48.h,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                hint: FixedText('블럭을 선택해 주세요', style: AppFonts.b3_sb_long(context).copyWith(color: AppColors.gray300)),
                                value: selectedBlock,
                                isExpanded: true,
                                onChanged: (value) => setState(() => selectedBlock = value),
                                items: blocks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 열 입력
                    Positioned(
                      top: 278.h,
                      left: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FixedText('열', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                          SizedBox(height: 8.h),
                          Container(
                            width: 154.w,
                            height: 52.h,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: TextField(
                              controller: rowController,
                              decoration: InputDecoration.collapsed(hintText: '열'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 번호 입력
                    Positioned(
                      top: 278.h,
                      left: 186.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FixedText('번호', style: AppFonts.c1_b(context).copyWith(color: AppColors.gray400)),
                              SizedBox(width: 2.w),
                              FixedText('*', style: AppFonts.c1_b(context).copyWith(color: AppColors.pri200)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 154.w,
                            height: 52.h,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: TextField(
                              controller: numController,
                              decoration: InputDecoration.collapsed(hintText: '번호'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 완료 버튼
                    Positioned(
                      top: screenHeight * (425 / baseH),
                      left: 0,
                      right: 0,
                      height: 88.h,
                      child: Container(
                        width: 360.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: AppColors.gray20, width: 1)),
                        ),
                        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 10.h),
                        child: SizedBox(
                          width: 320.w,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: isComplete
                                ? () {
                              final seatText = '$selectedZone ${selectedBlock}블럭 ${rowController.text}열 ${numController.text}번';
                              Navigator.pop(ctx, seatText);
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isComplete ? AppColors.gray700 : AppColors.gray200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.all(10.w),
                              elevation: 0,
                            ),
                            child: FixedText(
                              '완료',
                              style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Map<String, String>? parseSeatString(String? text) {
  if (text == null || text.isEmpty) return null;

  final reg = RegExp(r'(.+?)\s+(.+?)블럭\s+(.+?)열\s+(.+?)번');
  final match = reg.firstMatch(text);
  if (match == null) return null;

  return {
    'zone': match.group(1)!,
    'block': match.group(2)!,
    'row': match.group(3)!,
    'num': match.group(4)!,
  };
}