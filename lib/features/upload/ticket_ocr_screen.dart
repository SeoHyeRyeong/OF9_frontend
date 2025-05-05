import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'ticket_info_extractor.dart';
import 'ticket_info_form_screen.dart';

late List<CameraDescription> _cameras;
late CameraController _cameraController;

class TicketOcrScreen extends StatefulWidget {
  const TicketOcrScreen({Key? key}) : super(key: key);

  @override
  State<TicketOcrScreen> createState() => _TicketOcrScreenState();
}

class _TicketOcrScreenState extends State<TicketOcrScreen> {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
  bool _isLoading = false;
  bool _isCameraInitialized = false;

  @override
  void dispose() {
    textRecognizer.close();
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isDenied) return (await Permission.camera.request()).isGranted;
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('카메라 권한이 필요합니다'),
          content: const Text('티켓 촬영을 위해 카메라 권한이 필요합니다.\n설정 화면으로 이동할까요?'),
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
    return (await Permission.camera.request()).isGranted;
  }

  Future<void> _onCameraButtonPressed() async {
    if (!_isCameraInitialized) {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) return;

      _cameras = await availableCameras();
      _cameraController = CameraController(
        _cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back),
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } else {
      await _captureAndRecognizeText();
    }
  }

  Future<void> _captureAndRecognizeText() async {
    setState(() => _isLoading = true);
    try {
      final XFile file = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      final extracted = TicketInfoExtractor.extractTicketInfo(recognizedText.text);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketInfoFormScreen(
            homeTeam: extracted['homeTeam'],
            awayTeam: extracted['awayTeam'],
            dateTime: extracted['dateTime'],
            seatInfo: extracted['seatInfo'],
            recognizedText: recognizedText.text,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    const baseScreenHeight = 800;

    final imageHeight = screenHeight * 475 / baseScreenHeight;
    final navBarHeight = screenHeight * 86 / baseScreenHeight;
    final reservedHeight = imageHeight + navBarHeight + bottomPadding;
    final remainingHeight = screenHeight - reservedHeight;
    final textSectionHeight = remainingHeight > 0 ? remainingHeight : screenHeight * 214 / baseScreenHeight;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.gray400),

          if (_isCameraInitialized)
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              height: imageHeight,
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
            child: SvgPicture.asset(AppImages.icCornerTopLeft, width: 24.w, height: 24.h),
          ),
          Positioned(
            top: screenHeight * 55 / baseScreenHeight,
            right: 24.w,
            child: SvgPicture.asset(AppImages.icCornerTopRight, width: 24.w, height: 24.h),
          ),
          Positioned(
            top: statusBarHeight + screenHeight * 430 / baseScreenHeight,
            left: 24.w,
            child: SvgPicture.asset(AppImages.icCornerBottomLeft, width: 24.w, height: 24.h),
          ),
          Positioned(
            top: statusBarHeight + screenHeight * 430 / baseScreenHeight,
            right: 24.w,
            child: SvgPicture.asset(AppImages.icCornerBottomRight, width: 24.w, height: 24.h),
          ),

          Positioned(
            top: statusBarHeight + imageHeight,
            left: 0,
            right: 0,
            child: Container(
              height: textSectionHeight,
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
                        style: AppFonts.h4_b(context).copyWith(color: Colors.black),
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
                          width: 80.w,
                          height: 80.w,
                          decoration: const BoxDecoration(
                            color: AppColors.gray700,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(AppImages.camera, width: 48.w, height: 48.h, color: AppColors.gray20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: bottomPadding,
            left: 0,
            right: 0,
            child: Container(
              width: 360.w,
              height: navBarHeight,
              padding: EdgeInsets.symmetric(
                horizontal: screenHeight * 32 / baseScreenHeight,
                vertical: screenHeight * 12 / baseScreenHeight,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: bottomPadding, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

Widget _buildBottomNavItem(BuildContext context, String iconPath, String label, {required bool isActive, required double screenHeight}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(iconPath, width: screenHeight * 28 / 800, height: screenHeight * 28 / 800, color: isActive ? null : AppColors.gray200),
      SizedBox(height: screenHeight * 6 / 800),
      Text(label, style: AppFonts.c1_b(context).copyWith(color: isActive ? Colors.black : AppColors.gray200)),
    ],
  );
}
