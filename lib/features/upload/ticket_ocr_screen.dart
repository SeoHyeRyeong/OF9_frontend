import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/features/upload/ticket_info_screen.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

late List<CameraDescription> _cameras;
late CameraController _cameraController;

class TicketOcrScreen extends StatefulWidget {
  const TicketOcrScreen({Key? key}) : super(key: key);

  @override
  State<TicketOcrScreen> createState() => _TicketOcrScreenState();
}

class _TicketOcrScreenState extends State<TicketOcrScreen> {
  bool _isCameraInitialized = false;
  bool _isLoading = false;

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('카메라 권한이 필요합니다'),
          content: const Text('앱에서 카메라를 사용하려면 권한이 필요합니다. 설정 화면으로 이동할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        ),
      );
      return false;
    }
    return false;
  }

  Future<void> _onCameraButtonPressed() async {
    // 카메라가 아직 초기화되지 않았다면
    if (!_isCameraInitialized) {
      final hasPermission = await _requestCameraPermission(); //카메라 권한 요청
      if (!hasPermission) return; //권한 없으면 종료

      _cameras = await availableCameras();
      // 카메라 컨트롤러 초기화
      _cameraController = CameraController(
        _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController.initialize();

      if (mounted) {  //위젯이 아직 화면에 있다면 상태 업데이트
        setState(() => _isCameraInitialized = true);
      }
    } else {   //이미 초기화되어 있다면
      setState(() => _isLoading = true);
      try {
        final XFile file = await _cameraController.takePicture();
        if (!mounted) return;
        Navigator.push(  //촬영된 이미지를 다음 화면으로 전달
          context,
          MaterialPageRoute(
            builder: (context) => TicketInfoScreen(imagePath: file.path),
          ),
        );
        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 저장 경로: ${file.path}')),
        );*/
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('촬영 오류: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    const baseScreenHeight = 800;

    final imageHeight = screenHeight * 475 / baseScreenHeight;
    final extraCameraHeight = 20.h;

    final whitePanelTop = statusBarHeight + imageHeight;
    final whitePanelHeight = screenHeight - whitePanelTop;
    final navBarHeight = screenHeight * 86 / baseScreenHeight;
    final navBarTopInWhite = whitePanelHeight - navBarHeight - bottomPadding;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.gray400),
          if (_isCameraInitialized)
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              height: imageHeight + extraCameraHeight,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController.value.previewSize!.height,
                      height: _cameraController.value.previewSize!.width,
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: screenHeight * 55 / baseScreenHeight,
            left: 24.w,
            child: SvgPicture.asset(AppImages.icCornerTopLeft, width: 24.h, height: 24.h),
          ),
          Positioned(
            top: screenHeight * 55 / baseScreenHeight,
            right: 24.w,
            child: SvgPicture.asset(AppImages.icCornerTopRight, width: 24.h, height: 24.h),
          ),
          Positioned(
            top: statusBarHeight + screenHeight * 430 / baseScreenHeight,
            left: 24.w,
            child: SvgPicture.asset(AppImages.icCornerBottomLeft, width: 24.h, height: 24.h),
          ),
          Positioned(
            top: statusBarHeight + screenHeight * 430 / baseScreenHeight,
            right: 24.w,
            child: SvgPicture.asset(AppImages.icCornerBottomRight, width: 24.h, height: 24.h),
          ),
          Positioned(
            top: whitePanelTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: screenHeight * 33 / baseScreenHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text('티켓을 스캔해 주세요', style: AppFonts.h4_b(context).copyWith(color: Colors.black)),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 72 / baseScreenHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '직관 티켓을 사각 프레임 안에 맞춰 찍어주세요',
                        style: AppFonts.b3_r(context).copyWith(color: AppColors.gray300),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 110 / baseScreenHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _onCameraButtonPressed,
                        child: Container(
                          width: 80.h,
                          height: 80.h,
                          decoration: const BoxDecoration(
                            color: AppColors.gray700,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              AppImages.camera,
                              width: 48.h,
                              height: 48.h,
                              color: AppColors.gray20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  Positioned(
                    top: navBarTopInWhite,
                    left: 0,
                    right: 0,
                    height: navBarHeight,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHeight * 32 / baseScreenHeight,
                        vertical: screenHeight * 10 / baseScreenHeight,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: AppColors.gray20, width: 0.5.w)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBottomNavItem(context, AppImages.home, '피드', isActive: false, screenHeight: screenHeight),
                          _buildBottomNavItem(context, AppImages.report, '리포트', isActive: false, screenHeight: screenHeight),
                          _buildBottomNavItem(context, AppImages.upload, '업로드', isActive: true, screenHeight: screenHeight),
                          _buildBottomNavItem(context, AppImages.bell, '알림', isActive: false, screenHeight: screenHeight),
                          _buildBottomNavItem(context, AppImages.person, 'MY', isActive: false, screenHeight: screenHeight),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
      BuildContext context,
      String iconPath,
      String label, {
        required bool isActive,
        required double screenHeight,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: screenHeight * 28 / 800,
          height: screenHeight * 28 / 800,
          color: isActive ? null : AppColors.gray200,
        ),
        SizedBox(height: screenHeight * 6 / 800),
        Text(
          label,
          style: AppFonts.c1_b(context).copyWith(
            color: isActive ? Colors.black : AppColors.gray200,
          ),
        ),
      ],
    );
  }
}