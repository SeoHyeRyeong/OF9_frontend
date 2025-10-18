import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';

/// 사용 예시
///
/// import 'package:frontend/components/custom_action_sheet.dart';
///
/// void _showImageOptions() {
///   showCustomActionSheet(
///     context: context,
///     options: [
///       ActionSheetOption(
///         text: '앨범에서 사진 선택',
///         textColor: AppColors.gray950,
///         onTap: () {
///           Navigator.pop(context);
///           _pickImageFromGallery();
///         },
///       ),
///       ActionSheetOption(
///         text: '현재 사진 삭제',
///         textColor: AppColors.error,
///         onTap: () {
///           Navigator.pop(context);
///           _deleteProfileImage();
///         },
///       ),
///     ],
///   );
/// }

class ActionSheetOption {
  final String text;
  final Color textColor;
  final VoidCallback onTap;

  const ActionSheetOption({
    required this.text,
    required this.textColor,
    required this.onTap,
  });
}

void showCustomActionSheet({
  required BuildContext context,
  required List<ActionSheetOption> options,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.trans300,
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: scaleWidth(20),
            right: scaleWidth(20),
            top: scaleHeight(8),
            bottom: scaleHeight(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 옵션 리스트
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(scaleHeight(12)),
                ),
                child: Column(
                  children: List.generate(
                    options.length * 2 - 1,
                        (index) {
                      // 홀수 인덱스는 구분선
                      if (index.isOdd) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                          child: const Divider(
                            color: AppColors.trans100,
                            height: 1,
                            thickness: 1,
                          ),
                        );
                      }

                      // 짝수 인덱스는 옵션 버튼
                      final optionIndex = index ~/ 2;
                      final option = options[optionIndex];

                      return ListTile(
                        title: Center(
                          child: FixedText(
                            option.text,
                            style: AppFonts.suite.b2_m(context).copyWith(
                              color: option.textColor,
                            ),
                          ),
                        ),
                        onTap: option.onTap,
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: scaleHeight(8)),

              // 취소 버튼
              SizedBox(
                width: double.infinity,
                height: scaleHeight(54),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray20,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleHeight(16)),
                    ),
                  ),
                  child: FixedText(
                    '취소',
                    style: AppFonts.suite.b2_m(context).copyWith(
                      color: AppColors.gray300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}