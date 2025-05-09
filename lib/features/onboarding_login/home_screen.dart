import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';

late List<CameraDescription> _cameras;
late CameraController _cameraController;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCameraInitialized = false;
  bool _isLoading = false;

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  // 카메라 권한 요청 메서드
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      // 설정 화면으로 이동 유도 다이얼로그
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('카메라 권한이 필요합니다'),
          content: const Text(
            '앱에서 카메라를 사용하려면 권한이 필요합니다. 설정 화면으로 이동할까요?',
          ),
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

  // 카메라 버튼 동작: 초기화 또는 촬영
  Future<void> _onCameraButtonPressed() async {
    if (!_isCameraInitialized) {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) return;

      // 가용 카메라 리스트 가져와서 후면 카메라 선택
      _cameras = await availableCameras();
      _cameraController = CameraController(
        _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } else {
      setState(() => _isLoading = true);
      try {
        final XFile file = await _cameraController.takePicture();
        if (!mounted) return;
        // 촬영 후 파일 경로를 스낵바로 안내
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 저장 경로: \${file.path}')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('촬영 오류: \$e')));
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
    final extraCameraHeight = 20.h; // 모서리 카메라 여분 높이 추가

    final whitePanelTop = statusBarHeight + imageHeight;
    final whitePanelHeight = screenHeight - whitePanelTop;

    final navBarHeight = screenHeight * 86 / baseScreenHeight; //네비게이션 바 높이 및 위치
    final navBarTopInWhite = whitePanelHeight - navBarHeight - bottomPadding; //흰 패널 중 네비바 띄울 위치

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.gray400),
          // 카메라 뷰
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
            child: SvgPicture.asset(
              AppImages.icCornerTopLeft,
              width: 24.h,
              height: 24.h,
            ),
          ),
          Positioned(
            top: screenHeight * 55 / baseScreenHeight,
            right: 24.w,
            child: SvgPicture.asset(
              AppImages.icCornerTopRight,
              width: 24.h,
              height: 24.h,
            ),
          ),
          Positioned(
            top: statusBarHeight + screenHeight * 430 / baseScreenHeight,
            left: 24.w,
            child: SvgPicture.asset(
              AppImages.icCornerBottomLeft,
              width: 24.h,
              height: 24.h,
            ),
          ),
          Positioned(
            top: statusBarHeight + screenHeight * 430 / baseScreenHeight,
            right: 24.w,
            child: SvgPicture.asset(
              AppImages.icCornerBottomRight,
              width: 24.h,
              height: 24.h,
            ),
          ),


          // 텍스트 및 바텀네비게이션
          Positioned(
            top: statusBarHeight + imageHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [

                  Positioned(
                    top: screenHeight * 33 / baseScreenHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '티켓을 스캔해 주세요',
                        style: AppFonts.h4_b(context)
                            .copyWith(color: Colors.black),
                      ),
                    ),
                  ),

                  Positioned(
                    top: screenHeight * 72 / baseScreenHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '직관 티켓을 사각 프레임 안에 맞춰 찍어주세요',
                        style: AppFonts.b3_r(context)
                            .copyWith(color: AppColors.gray300),
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
                        border: Border(top: BorderSide(color: AppColors.gray20, width: 0.5.w,),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBottomNavItem(
                              context, AppImages.home, '피드',
                              isActive: false,
                              screenHeight: screenHeight),
                          _buildBottomNavItem(
                              context, AppImages.report, '리포트',
                              isActive: false,
                              screenHeight: screenHeight),
                          _buildBottomNavItem(
                              context, AppImages.upload, '업로드',
                              isActive: true,
                              screenHeight: screenHeight),
                          _buildBottomNavItem(
                              context, AppImages.bell, '알림',
                              isActive: false,
                              screenHeight: screenHeight),
                          _buildBottomNavItem(
                              context, AppImages.person, 'MY',
                              isActive: false,
                              screenHeight: screenHeight),
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
        style: AppFonts.c1_b(context)
            .copyWith(color: isActive ? Colors.black : AppColors.gray200),
      ),
    ],
  );
}