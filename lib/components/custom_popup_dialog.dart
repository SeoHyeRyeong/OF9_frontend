import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';

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
  final String? secondButtonText; // 두 번째 버튼 텍스트 (null 시 버튼 1개)
  final VoidCallback? secondButtonAction; // 두 번째 버튼 동작

  const CustomPopupDialog({
    Key? key,
    required this.imageAsset,
    required this.title,
    this.subtitle,
    required this.firstButtonText,
    required this.firstButtonAction,
    this.secondButtonText,
    this.secondButtonAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasSecondButton = secondButtonText != null &&
        secondButtonText!.isNotEmpty;

    return Center(
      child: Container(
        width: scaleWidth(320),
        height: scaleHeight(294),
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scaleHeight(20)),
        ),
        child: Column(
          children: [
            // 상단 여백
            const Spacer(flex: 20),

            // 아이콘 이미지
            SvgPicture.asset(
              imageAsset,
              width: scaleHeight(82),
              height: scaleHeight(82),
            ),

            // 이미지 ↔ 타이틀 간격
            const Spacer(flex: 5),

            // 타이틀
            FixedText(
              title,
              style: AppFonts.h5_b(context).copyWith(
                color: AppColors.gray950,
                decoration: TextDecoration.none,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // 서브텍스트
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              // 타이틀 ↔ 서브텍스트 간격
              const Spacer(flex: 12),
              FixedText(
                subtitle!,
                style: AppFonts.b3_r(context).copyWith(
                  color: AppColors.gray300,
                  decoration: TextDecoration.none,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              // 서브텍스트 있을 경우: 서브텍스트 ↔ 버튼 간격
              const Spacer(flex: 25),
            ] else ...[
              // 서브텍스트 없을 경우: 타이틀텍스트 ↔ 버튼 간격
              const Spacer(flex: 40),
            ],

            // 버튼들
            hasSecondButton
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  // 첫 번째 버튼
                  child: SizedBox(
                    width: scaleWidth(136),
                    height: scaleHeight(46),
                    child: TextButton(
                      onPressed: firstButtonAction,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.gray50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(scaleHeight(8)),
                        ),
                      ),
                      child: FixedText(
                        firstButtonText,
                        style: AppFonts.b3_sb(context).copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: scaleWidth(8)),
                Expanded(
                  // 두 번째 버튼
                  child: SizedBox(
                    width: scaleWidth(136),
                    height: scaleHeight(46),
                    child: TextButton(
                      onPressed: secondButtonAction,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.pri700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(scaleHeight(8)),
                        ),
                      ),
                      child: FixedText(
                        secondButtonText!,
                        style: AppFonts.b3_sb(context).copyWith(
                          color: AppColors.gray20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
            // 버튼 1개일 때
                : SizedBox(
              width: scaleWidth(280),
              height: scaleHeight(46),
              child: TextButton(
                onPressed: firstButtonAction,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.pri700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                  ),
                ),
                child: FixedText(
                  firstButtonText,
                  style: AppFonts.b3_sb(context).copyWith(
                    color: AppColors.gray20,
                  ),
                ),
              ),
            ),

            // 하단 여백
            const Spacer(flex: 23),
          ],
        ),
      ),
    );
  }
}
