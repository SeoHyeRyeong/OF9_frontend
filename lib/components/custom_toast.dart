import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';

class CustomToast {
  // 현재 표시 중인 토스트 추적
  static OverlayEntry? _currentOverlayEntry;

  /// 상단 토스트 버전
  static void showSimpleTop({
    required BuildContext context,
    required String iconAsset,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 이미 토스트가 표시 중이면 제거
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedToast(
        iconAsset: iconAsset,
        message: message,
        duration: duration,
        onComplete: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
          _currentOverlayEntry = null;
        },
      ),
    );

    _currentOverlayEntry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  /// 프로필 이미지 버전
  static void showWithProfile({
    required BuildContext context,
    required String? profileImageUrl,
    required String defaultIconAsset,
    required String nickname,
    required String message,
    VoidCallback? onCancel,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 이미 토스트가 표시 중이면 제거
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: scaleHeight(70 + 8),
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

                    // 프로필 이미지
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
                      child: Padding(
                        padding: EdgeInsets.only(right: scaleWidth(13)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: nickname,
                                  style: AppFonts.pretendard.b3_sb(context)
                                      .copyWith(color: AppColors.gray20),
                                ),
                                TextSpan(
                                  text: '님 ',
                                  style: AppFonts.pretendard.body_sm_400(context)
                                      .copyWith(color: AppColors.gray100),
                                ),
                                TextSpan(
                                  text: message,
                                  style: AppFonts.pretendard.body_sm_400(context)
                                      .copyWith(color: AppColors.gray100),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 취소 버튼 or 여백
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
                              style: AppFonts.pretendard.caption_md_500(context)
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

    _currentOverlayEntry = overlayEntry;
    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        _currentOverlayEntry = null;
      }
    });
  }


  /// 글자만 있는 버전
  static void showWithAction({
    required BuildContext context,
    required String message,
    required String actionText,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 이미 토스트가 표시 중이면 제거
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: scaleHeight(70 + 8),
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
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FixedText(
                          message,
                          style: AppFonts.pretendard.body_sm_400(context).copyWith(color: AppColors.gray30),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        overlayEntry.remove();
                        _currentOverlayEntry = null;
                        onAction();
                      },
                      child: Padding(
                        padding: EdgeInsets.only(right: scaleWidth(20)),
                        child: Center(
                          child: FixedText(
                            actionText,
                            style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray100),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentOverlayEntry = overlayEntry;
    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        _currentOverlayEntry = null;
      }
    });
  }
}


// 애니메이션 토스트 위젯 -> 상단 토스트에 사용
class _AnimatedToast extends StatefulWidget {
  final String iconAsset;
  final String message;
  final Duration duration;
  final VoidCallback onComplete;

  const _AnimatedToast({
    required this.iconAsset,
    required this.message,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1), // 위에서 시작
      end: Offset.zero, // 원래 위치로
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // duration 후 위로 올라가면서 사라지기
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse(); // 역방향 애니메이션 (위로 올라감)
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: EdgeInsets.only(top: scaleHeight(34)),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scaleWidth(20),
                  vertical: scaleHeight(12),
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(scaleHeight(24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      widget.iconAsset,
                      width: scaleWidth(24),
                      height: scaleHeight(24),
                    ),
                    SizedBox(width: scaleWidth(8)),
                    FixedText(
                      widget.message,
                      style: AppFonts.pretendard.body_sm_400(context).copyWith(color: AppColors.gray30),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}