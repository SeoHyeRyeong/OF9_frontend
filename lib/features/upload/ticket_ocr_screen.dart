import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/upload/ticket_info_screen.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/components/custom_popup_dialog.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:frontend/utils/ticket_info_extractor.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';

class ExtractedTicketInfo {
  final String? awayTeam;
  final String? date;
  final String? time;

  ExtractedTicketInfo({this.awayTeam, this.date, this.time});
}

late List<CameraDescription> _cameras;
late CameraController _cameraController;

class TicketOcrScreen extends StatefulWidget {
  const TicketOcrScreen({Key? key}) : super(key: key);

  @override
  State<TicketOcrScreen> createState() => _TicketOcrScreenState();
}

class _TicketOcrScreenState extends State<TicketOcrScreen>
    with WidgetsBindingObserver {
  bool _isCameraInitialized = false;
  bool _isLoading = false;

  final Map<String, String> teamToCorpMap = {
    'KIA 타이거즈': 'KIA',
    'KIA': 'KIA',
    '두산 베어스': '두산',
    '두산': '두산',
    '롯데 자이언츠': '롯데',
    '롯데': '롯데',
    '삼성 라이온즈': '삼성',
    '삼성': '삼성',
    '키움 히어로즈': '키움',
    '키움': '키움',
    '한화 이글스': '한화',
    '한화': '한화',
    'KT WIZ': 'KT',
    'KT': 'KT',
    'LG 트윈스': 'LG',
    'LG': 'LG',
    'NC 다이노스': 'NC',
    'NC': 'NC',
    'SSG 랜더스': 'SSG',
    'SSG': 'SSG',
    '자이언츠': '롯데',
    '타이거즈': 'KIA',
    '라이온즈': '삼성',
    '히어로즈': '키움',
    '이글스': '한화',
    'WIZ': 'KT',
    '트윈스': 'LG',
    '다이노스': 'NC',
    '랜더스': 'SSG',
    '베어스': '두산',
    'Eagles': '한화',
  };

  final List<String> teamKeywordsList = [
    'KIA 타이거즈',
    '두산 베어스',
    '롯데 자이언츠',
    '삼성 라이온즈',
    '키움 히어로즈',
    '한화 이글스',
    'KT WIZ',
    'LG 트윈스',
    'NC 다이노스',
    'SSG 랜더스',
    '자이언츠',
    '타이거즈',
    '라이온즈',
    '히어로즈',
    '이글스',
    '트윈스',
    '다이노스',
    '랜더스',
    '베어스',
    'Eagles',
    'KIA',
    '두산',
    '롯데',
    '삼성',
    '키움',
    '한화',
    'KT',
    'LG',
    'NC',
    'SSG',
    'WIZ',
  ];

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
      _checkPermissionOnly();
    }
  }

  Future<void> _checkPermissionOnly() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      if (!_isCameraInitialized) {
        _initializeCameraIfNeeded();
      }
    }
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
      backCamera,
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
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TicketInfoScreen(
          imagePath: pickedFile.path,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
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
      _showCustomPermissionDialog(); // '허용 안함' 눌렀을 때만 커스텀 다이얼로그 표시
    }

    return false; // denied 또는 restricted일 경우 false 리턴 (다음 시도 가능)
  }

  void _showCustomPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          CustomPopupDialog(
            imageAsset: AppImages.icAlert,
            title: '현재 카메라 사용에 대한\n접근 권한이 없어요',
            subtitle: '설정의 (Lookit) 탭에서 접근 활성화가 필요해요',
            firstButtonText: '직접 입력',
            firstButtonAction: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const TicketInfoScreen(imagePath: ''),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            secondButtonText: '설정으로 이동',
            secondButtonAction: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
          ),
    );
  }

  void _showMissingInfoDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          CustomPopupDialog(
            imageAsset: AppImages.icAlert,
            title: '티켓 속 정보를\n인식하지 못했어요',
            subtitle: '다시 촬영하거나 정보를 직접 입력해 주세요',
            firstButtonText: '직접 입력',
            firstButtonAction: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => TicketInfoScreen(
                    imagePath: imagePath,
                    skipOcrFailPopup: true,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            secondButtonText: '다시 촬영하기',
            secondButtonAction: () {
              Navigator.pop(context);
            },
          ),
    );
  }

  Future<ExtractedTicketInfo> extractTicketInfoFromImage(
      String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final recognizedText = await textRecognizer.processImage(inputImage);
    final cleanedText = recognizedText.text.replaceAll(RegExp(r'\\s+'), ' ')
        .trim();

    final awayTeam = extractAwayTeam(
      cleanedText,
      teamToCorpMap,
      teamKeywordsList,
    );
    final date = extractDate(cleanedText);
    final time = extractTime(cleanedText);

    return ExtractedTicketInfo(awayTeam: awayTeam, date: date, time: time);
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

      final extracted = await extractTicketInfoFromImage(file.path);

      if (extracted.awayTeam?.isEmpty != false ||
          extracted.date?.isEmpty != false ||
          extracted.time?.isEmpty != false) {
        _showMissingInfoDialog(file.path);
      } else {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                TicketInfoScreen(
                  imagePath: file.path,
                  preExtractedAwayTeam: extracted.awayTeam,
                  preExtractedDate: extracted.date,
                  preExtractedTime: extracted.time,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
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
    return Scaffold(
      backgroundColor: AppColors.gray400,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // 카메라 배경 - 하단 흰색 영역까지 확장
              if (_isCameraInitialized &&
                  _cameraController.value.isInitialized &&
                  _cameraController.value.previewSize != null)
                Container(
                  height: (screenHeight * 0.696) + scaleHeight(20),
                  width: double.infinity,
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

              // Column 기반 UI 레이아웃
              Column(
                children: [
                  // 카메라 영역 - 스캔 가이드
                  Container(
                    height: screenHeight * 0.696,
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: scaleWidth(20),
                          vertical: scaleHeight(15),
                        ),
                        child: Column(
                          children: [
                            // 상단 코너들
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SvgPicture.asset(
                                  AppImages.icCornerTopLeft,
                                  width: scaleWidth(24),
                                  height: scaleHeight(24),
                                ),
                                SvgPicture.asset(
                                  AppImages.icCornerTopRight,
                                  width: scaleWidth(24),
                                  height: scaleHeight(24),
                                ),
                              ],
                            ),

                            const Expanded(child: SizedBox()),

                            // 하단 코너들
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SvgPicture.asset(
                                  AppImages.icCornerBottomLeft,
                                  width: scaleWidth(24),
                                  height: scaleHeight(24),
                                ),
                                SvgPicture.asset(
                                  AppImages.icCornerBottomRight,
                                  width: scaleWidth(24),
                                  height: scaleHeight(24),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 하단 컨트롤 영역
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: LayoutBuilder(
                          builder: (context, contentConstraints) {
                            return Column(
                              children: [
                                const Spacer(flex: 50),

                                // 메인 타이틀
                                FixedText(
                                  '티켓을 스캔해 주세요',
                                  style: AppFonts.pretendard.h4_b(context).copyWith(
                                    color: Colors.black,
                                  ),
                                ),

                                const Spacer(flex: 25),

                                // 서브타이틀
                                FixedText(
                                  '팀명, 일시가 잘 보이게 직관 티켓을 찍어주세요',
                                  style: AppFonts.pretendard.b3_r(context).copyWith(
                                    color: AppColors.gray300,
                                  ),
                                ),

                                const Spacer(flex: 40),

                                // 버튼 영역
                                SizedBox(
                                  height: scaleHeight(80),
                                  child: Row(
                                    children: [
                                      // 갤러리 버튼
                                      Expanded(
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: _onGalleryButtonPressed,
                                            child: SvgPicture.asset(
                                              AppImages.solar_gallery,
                                              width: scaleWidth(36),
                                              height: scaleWidth(36),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 카메라 촬영 버튼
                                      GestureDetector(
                                        onTap: _isLoading
                                            ? null
                                            : _onCameraButtonPressed,
                                        child: Container(
                                          width: scaleHeight(80),
                                          height: scaleHeight(80),
                                          decoration: BoxDecoration(
                                            color: _isLoading
                                                ? AppColors.gray300
                                                : AppColors.gray700,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: _isLoading
                                                ? SizedBox(
                                              width: scaleWidth(24),
                                              height: scaleWidth(24),
                                              child: const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                                : SvgPicture.asset(
                                              AppImages.camera,
                                              width: scaleHeight(48),
                                              height: scaleHeight(48),
                                              color: AppColors.gray20,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 오른쪽 여백
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ),

                                const Spacer(flex: 35),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}