import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/utils/fixed_text.dart';

/// 사용 예시
/// 버튼 2개인 경우
// import 'package:frontend/components/custom_popup_dialog.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:frontend/theme/app_imgs.dart';
//
// void _showCustomPermissionDialog() {
//     showDialog(
//       context: context,
//       // barrierDismissible: false, 여백 터치로 팝업 닫는 것을 방지할 경우 추가
//       builder: (context) => CustomPopupDialog(
//         imageAsset: AppImages.icAlert,
//         title: '현재 카메라 사용에 대한\n접근 권한이 없어요',
//         subtitle: '설정의 (Lookit) 탭에서 접근 활성화가 필요해요',
//         firstButtonText: '직접 입력',
//         firstButtonAction: () {
//           Navigator.pop(context);
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const TicketInfoScreen(imagePath: '')),
//           );
//         },
//         secondButtonText: '설정으로 이동',
//         secondButtonAction: () async {
//           Navigator.pop(context);
//           await openAppSettings();
//         },
//       ),
//     );
//   }
//
/// 버튼 1개인 경우
// import 'package:frontend/components/custom_popup_dialog.dart';
// import 'package:frontend/theme/app_imgs.dart';
//
// void _showSimpleAlertDialog(BuildContext context) {
//   showDialog(
//   context: context,
//   // barrierDismissible: false, 여백 터치로 팝업 닫는 것을 방지할 경우 추가
//   builder: (context) => CustomPopupDialog(
//     imageAsset: AppImages.icAlert,
//     title: '카메라 권한이 필요해요',
//     subtitle: '설정에서 권한을 허용해주세요',
//     firstButtonText: '확인',
//     firstButtonAction: () => Navigator.pop(context),
//     secondButtonText: '', // 버튼 1개일 경우
//     secondButtonAction: () {},
//   ),
// );
// }
//
/// 타이틀 텍스트만 있는 경우 (서브텍스트 X)
// import 'package:frontend/components/custom_popup_dialog.dart';
// import 'package:frontend/theme/app_imgs.dart';
//
// void _showSimpleAlertDialog(BuildContext context) {
//   showDialog(
//   context: context,
//   // barrierDismissible: false, 여백 터치로 팝업 닫는 것을 방지할 경우 추가
//   builder: (context) => CustomPopupDialog(
//     imageAsset: AppImages.icAlert,
//     title: '카메라 권한이 필요해요',
//     subtitle: null,
//     firstButtonText: '확인',
//     firstButtonAction: () => Navigator.pop(context),
//     secondButtonText: '', // 버튼 1개일 경우
//     secondButtonAction: () {},
//   ),
// );
// }
class CustomPopupDialog extends StatelessWidget {
  final String imageAsset; // 상단 아이콘
  final String title; // 타이틀 텍스트
  final String? subtitle; // 서브 텍스트 (null 가능)
  final String firstButtonText; // 첫 번째 버튼 텍스트
  final VoidCallback firstButtonAction; // 첫 번째 버튼 동작
  final String secondButtonText; // 두 번째 버튼 텍스트 (null 시 버튼 1개)
  final VoidCallback secondButtonAction; // 두 번째 버튼 동작

  const CustomPopupDialog({
    Key? key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.firstButtonText,
    required this.firstButtonAction,
    required this.secondButtonText,
    required this.secondButtonAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    const double baseScreenHeight = 800;
    const double baseScreenWidth = 360;
    const double dialogWidth = 320;
    const double dialogHeight = 294;

    final bool hasSecondButton = secondButtonText.isNotEmpty;

    return Center(
      child: Container(
        width: screenWidth * dialogWidth / baseScreenWidth,
        height: screenHeight * dialogHeight / baseScreenHeight,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 20 / baseScreenWidth),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘 이미지
            SvgPicture.asset(
              imageAsset,
              width: screenHeight * 82 / baseScreenHeight,
              height: screenHeight * 82 / baseScreenHeight,
            ),

            // 이미지 ↔ 타이틀 간격: 10px
            SizedBox(height: screenHeight * 10 / baseScreenHeight),

            // 타이틀
            FixedText(
              title,
              style: AppFonts.h5_b(context).copyWith(
                color: AppColors.gray950,
                  decoration: TextDecoration.none,
                height: (dialogHeight * 30 / 294) / AppFonts.h5_b(context).fontSize!,
              ),
              textAlign: TextAlign.center,
            ),

            // 서브텍스트
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              // 타이틀 ↔ 서브텍스트 간격: 18px
              SizedBox(height: screenHeight * 18 / baseScreenHeight),
              FixedText(
                subtitle!,
                style: AppFonts.b3_r(context).copyWith(
                  color: AppColors.gray300,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              // 서브텍스트 있을 경우: 서브텍스트 ↔ 버튼 간격: 26px
              SizedBox(height: screenHeight * 26 / baseScreenHeight),
            ] else ...[
              // 서브텍스트 없을 경우: 타이틀텍스트 ↔ 버튼 간격: 28px
              SizedBox(height: screenHeight * 28 / baseScreenHeight),
            ],

            // 버튼들
            hasSecondButton
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: screenHeight * 46 / 800,
                    child: TextButton(
                      onPressed: firstButtonAction,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.gray50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: FixedText(firstButtonText, style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray600)),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 8 / 360),
                Expanded(
                  child: SizedBox(
                    height: screenHeight * 46 / 800,
                    child: TextButton(
                      onPressed: secondButtonAction,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.pri700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: FixedText(secondButtonText, style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray20)),
                    ),
                  ),
                ),
              ],
            )
                : SizedBox(
              width: double.infinity,
              height: screenHeight * 46 / 800,
              child: TextButton(
                onPressed: firstButtonAction,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.pri700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: FixedText(
                  firstButtonText,
                  style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray20),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}