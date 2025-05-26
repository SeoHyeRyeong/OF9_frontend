import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/features/upload/ticket_info_screen.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:image_picker/image_picker.dart';


late List<CameraDescription> _cameras;
late CameraController _cameraController;

class TicketOcrScreen extends StatefulWidget {
  const TicketOcrScreen({Key? key}) : super(key: key);

  @override
  State<TicketOcrScreen> createState() => _TicketOcrScreenState();
}

class _TicketOcrScreenState extends State<TicketOcrScreen> with WidgetsBindingObserver {
  bool _isCameraInitialized = false;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _initializeCameraIfNeeded();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnly(); // request() 하지 않음
    }
  }

  Future<void> _checkPermissionOnly() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      if (!_isCameraInitialized) {
        _initializeCameraIfNeeded();
      }
    }

    // 이 상태에서는 시스템이 팝업 띄우고 있을 수 있음 → 아무것도 하지 않음
  }


  Future<void> _initializeCameraIfNeeded() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return;

    _cameras = await availableCameras();
    final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );
    _cameraController = CameraController(
      _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 초기화 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  Future<void> _onGalleryButtonPressed() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketInfoScreen(imagePath: pickedFile.path),
      ),
    );
  }

  Future<bool> _requestCameraPermission() async {
    final result = await Permission.camera.request();

    if (result.isGranted) return true;

    // 시스템 팝업이 사라질 시간 확보 (겹침 방지)
    await Future.delayed(const Duration(milliseconds: 300));

    final status = await Permission.camera.status;

    if (status.isPermanentlyDenied) {
      // '다시 묻지 않음' 눌렀을 때만 커스텀 다이얼로그 표시
      _showCustomPermissionDialog();
    }

    // denied 또는 restricted일 경우 false 리턴 (다음 시도 가능)
    return false;
  }

  void _showCustomPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: _buildCameraPermissionDialog(
          context: context,
          screenHeight: MediaQuery.of(context).size.height,
          screenWidth: MediaQuery.of(context).size.width,
        ),
      ),
    );
  }

  Future<void> _onCameraButtonPressed() async {
    final status = await Permission.camera.status;

    if (!status.isGranted) {
      final granted = await _requestCameraPermission();
      if (!granted) return;
    }

    // 카메라 초기화 및 촬영 실행
    if (!_isCameraInitialized) return;

    setState(() => _isLoading = true);

    try {
      final XFile file = await _cameraController.takePicture();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketInfoScreen(imagePath: file.path),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('촬영 오류: $e')),
        );
      }
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
    final extraCameraHeight = 20.h;

    final whitePanelTop = statusBarHeight + imageHeight;
    final whitePanelHeight = screenHeight - whitePanelTop;
    final navBarHeight = screenHeight * 86 / baseScreenHeight;
    final navBarTopInWhite = whitePanelHeight - navBarHeight - bottomPadding;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.gray400),
          if (_isCameraInitialized && _cameraController.value.isInitialized && _cameraController.value.previewSize != null)
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
                      child: FixedText('티켓을 스캔해 주세요', style: AppFonts.h4_b(context).copyWith(color: Colors.black)),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 72 / baseScreenHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FixedText(
                        '팀명, 일시가 잘 보이게 직관 티켓을 찍어주세요',
                        style: AppFonts.b3_r(context).copyWith(color: AppColors.gray300),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 132 / baseScreenHeight,
                    left: 48,
                    child: GestureDetector(
                      onTap: _onGalleryButtonPressed,
                      child: SvgPicture.asset(
                        AppImages.solar_gallery,
                        width: 36.w,
                        height: 36.w,
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

  /*Widget _buildCameraPermissionDialog({
    required double screenHeight,
    required double screenWidth,
    required BuildContext context,
  }) {

    const double designDialogHeight = 294.0;

    return Center(
      child: Container(
        width: screenWidth * 320 / 360,
        height: screenHeight * 294 / 800,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 20 / 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppImages.icAlert, width: screenHeight * 82 / 800, height: screenHeight * 82 / 800),

            // 이미지 ↔ 텍스트 간격: 10px
            SizedBox(height: screenHeight * 10 / 800),

            FixedText(
              '현재 카메라 사용에 대한\n접근 권한이 없어요',
              style: AppFonts.h5_b(context).copyWith(
                color: AppColors.gray950,
                  height: designDialogHeight * 30 / 294 / AppFonts.h5_b(context).fontSize!
              ),
              textAlign: TextAlign.center,
            ),

            // 텍스트 ↔ 텍스트 간격: 18px
            SizedBox(height: screenHeight * 18 / 800),

            FixedText(
              '설정의 (Lookit) 탭에서 접근 활성화가 필요해요',
              style: AppFonts.b3_r(context).copyWith(color: AppColors.gray300),
              textAlign: TextAlign.center,
            ),

            // 텍스트 ↔ 버튼 간격: 26px
            SizedBox(height: screenHeight * 26 / 800),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 136,
                  height: screenHeight * 46 / 800,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TicketInfoScreen(imagePath: ''),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.gray50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: FixedText(
                      '직접 입력',
                      style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 136,
                  height: screenHeight * 46 / 800,
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await openAppSettings();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.pri700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: FixedText(
                      '설정으로 이동',
                      style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }*/

  Widget _buildCameraPermissionDialog({
    required double screenHeight,
    required double screenWidth,
    required BuildContext context,
  }) {
    const double baseScreenHeight = 800;
    const double baseScreenWidth = 360;
    const double dialogWidth = 320;
    const double dialogHeight = 294;

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
            // 이미지
            SvgPicture.asset(
              AppImages.icAlert,
              width: screenHeight * 82 / baseScreenHeight,
              height: screenHeight * 82 / baseScreenHeight,
            ),

            // 이미지 ↔ 타이틀 간격 10px
            SizedBox(height: screenHeight * 10 / baseScreenHeight),

            // 타이틀
            FixedText(
              '현재 카메라 사용에 대한\n접근 권한이 없어요',
              style: AppFonts.h5_b(context).copyWith(
                color: AppColors.gray950,
                height: (dialogHeight * 30 / 294) / AppFonts.h5_b(context).fontSize!,
              ),
              textAlign: TextAlign.center,
            ),

            // 타이틀 ↔ 서브텍스트 간격 18px
            SizedBox(height: screenHeight * 18 / baseScreenHeight),

            // 서브텍스트
            FixedText(
              '설정의 (Lookit) 탭에서 접근 활성화가 필요해요',
              style: AppFonts.b3_r(context).copyWith(color: AppColors.gray300),
              textAlign: TextAlign.center,
            ),

            // 서브텍스트 ↔ 버튼 간격 26px
            SizedBox(height: screenHeight * 26 / baseScreenHeight),

            // 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 직접 입력 버튼
                Expanded(
                  child: SizedBox(
                    height: screenHeight * 46 / baseScreenHeight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TicketInfoScreen(imagePath: ''),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.gray50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: FixedText(
                        '직접 입력',
                        style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray600),
                      ),
                    ),
                  ),
                ),

                // 버튼 사이 간격 8px
                SizedBox(width: screenWidth * 8 / 360),

                // 설정으로 이동 버튼
                Expanded(
                  child: SizedBox(
                    height: screenHeight * 46 / baseScreenHeight,
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openAppSettings();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.pri700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: FixedText(
                        '설정으로 이동',
                        style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        FixedText(
          label,
          style: AppFonts.c1_b(context).copyWith(
            color: isActive ? Colors.black : AppColors.gray200,
          ),
        ),
      ],
    );
  }
}