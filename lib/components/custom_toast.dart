import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';

class CustomToast {
  static void show({
    required BuildContext context,
    required String iconAsset,
    double? iconWidth,
    double? iconHeight,
    required String boldText,
    required String regularText,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: scaleHeight(8),
              left: scaleWidth(28),
              right: scaleWidth(28),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: scaleHeight(60),
                decoration: BoxDecoration(
                  color: AppColors.trans600,
                  borderRadius: BorderRadius.circular(scaleHeight(60)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: scaleWidth(20)),
                    SvgPicture.asset(
                      iconAsset,
                      width: scaleWidth(iconWidth ?? 28),
                      height: scaleHeight(iconHeight ?? 28),
                    ),
                    SizedBox(width: scaleWidth(12)),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: boldText,
                                  style: AppFonts.pretendard.b3_sb(context).copyWith(color: AppColors.gray20),
                                ),
                                TextSpan(
                                  text: '님',
                                  style: AppFonts.suite.body_sm_400(context).copyWith(color: AppColors.gray20),
                                ),
                              ],
                            ),
                          ),
                          FixedText(
                            regularText,
                            style: AppFonts.suite.body_sm_400(context).copyWith(color: AppColors.gray30),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: scaleWidth(20)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}