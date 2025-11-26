import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';

class CustomToast {
  /// 에셋 아이콘 버전
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
                                  style: AppFonts.pretendard.b3_sb(context)
                                      .copyWith(color: AppColors.gray20),
                                ),
                                TextSpan(
                                  text: '님',
                                  style: AppFonts.suite.body_sm_400(context)
                                      .copyWith(color: AppColors.gray20),
                                ),
                              ],
                            ),
                          ),
                          FixedText(
                            regularText,
                            style: AppFonts.suite.body_sm_400(context)
                                .copyWith(color: AppColors.gray30),
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
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// 프로필 이미지 버전
  static void showWithProfile({
    required BuildContext context,
    required String? profileImageUrl,
    required String defaultIconAsset,
    required String nickname,
    required String message,
    VoidCallback? onCancel,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: scaleHeight(70+8),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(scaleHeight(10.06)),
                      child: profileImageUrl != null
                          ? Image.network(
                        profileImageUrl,
                        width: scaleHeight(34),
                        height: scaleHeight(34),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => SvgPicture.asset(
                          defaultIconAsset,
                          width: scaleHeight(34),
                          height: scaleHeight(34),
                          fit: BoxFit.cover,
                        ),
                      )
                          : SvgPicture.asset(
                        defaultIconAsset,
                        width: scaleHeight(34),
                        height: scaleHeight(34),
                        fit: BoxFit.cover,
                      ),
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
                                  text: nickname,
                                  style: AppFonts.pretendard.b3_sb(context)
                                      .copyWith(color: AppColors.gray20),
                                ),
                                TextSpan(
                                  text: '님',
                                  style: AppFonts.suite.body_sm_400(context)
                                      .copyWith(color: AppColors.gray100),
                                ),
                              ],
                            ),
                          ),
                          FixedText(
                            message,
                            style: AppFonts.suite.body_sm_400(context)
                                .copyWith(color: AppColors.gray100),
                          ),
                        ],
                      ),
                    ),
                    if (onCancel != null) ...[
                      GestureDetector(
                        onTap: () {
                          overlayEntry.remove();
                          onCancel();
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: scaleWidth(20)),
                          child: Center(
                            child: FixedText(
                              '취소',
                              style: AppFonts.suite.caption_md_500(context)
                                  .copyWith(color: AppColors.gray20),
                            ),
                          ),
                        ),
                      ),
                    ] else
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
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
