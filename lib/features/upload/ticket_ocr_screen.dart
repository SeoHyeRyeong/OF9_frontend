import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/components/custom_popup_dialog.dart';
import 'package:frontend/features/report/report_screen.dart';
import 'package:frontend/features/upload/providers/record_state.dart';
import 'package:frontend/features/upload/ticket_info_screen.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/ticket_info_extractor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;  // 새로 추가


late List<CameraDescription> _cameras;
late CameraController _cameraController;

class ExtractedTicketInfo {
  final String? awayTeam;
  final String? date;

  ExtractedTicketInfo({this.awayTeam, this.date});
}

class TicketOcrScreen extends StatefulWidget {
  const TicketOcrScreen({Key? key}) : super(key: key);

  @override
  State<TicketOcrScreen> createState() => _TicketOcrScreenState();
}

class _TicketOcrScreenState extends State<TicketOcrScreen>
    with WidgetsBindingObserver {
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isDialogShowing = false;
  final ImagePicker _picker = ImagePicker();
  DateTime? _lastScanTime;
  CameraImage? _successfulScanFrame;

  bool _isMovingToNextScreen = false;

  String? _capturedImagePath;

  final Map<String, String> teamToCorpMap = {
    'KIA 타이거즈': 'KIA', 'KIA': 'KIA', '두산 베어스': '두산', '두산': '두산',
    '롯데 자이언츠': '롯데', '롯데': '롯데', '삼성 라이온즈': '삼성', '삼성': '삼성',
    '키움 히어로즈': '키움', '키움': '키움', '한화 이글스': '한화', '한화': '한화',
    'KT WIZ': 'KT', 'KT': 'KT', 'LG 트윈스': 'LG', 'LG': 'LG',
    'NC 다이노스': 'NC', 'NC': 'NC', 'SSG 랜더스': 'SSG', 'SSG': 'SSG',
    '자이언츠': '롯데', '타이거즈': 'KIA', '라이온즈': '삼성', '히어로즈': '키움',
    '이글스': '한화', 'WIZ': 'KT', '트윈스': 'LG', '다이노스': 'NC',
    '랜더스': 'SSG', '베어스': '두산', 'Eagles': '한화',
  };

  final List<String> teamKeywordsList = [
    'KIA 타이거즈', '두산 베어스', '롯데 자이언츠', '삼성 라이온즈', '키움 히어로즈', '한화 이글스',
    'KT WIZ', 'LG 트윈스', 'NC 다이노스', 'SSG 랜더스', '자이언츠', '타이거즈', '라이온즈',
    '히어로즈', '이글스', '트윈스', '다이노스', '랜더스', '베어스', 'Eagles', 'KIA', '두산',
    '롯데', '삼성', '키움', '한화', 'KT', 'LG', 'NC', 'SSG', 'WIZ',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCameraIfNeeded();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnly();
    } else if (state == AppLifecycleState.paused) {
      _stopAutoScan();
    }
  }

  Future<void> _checkPermissionOnly() async {
    if (!_isCameraInitialized && !_isDialogShowing) {
      await _initializeCameraIfNeeded();
    } else if (_isCameraInitialized) {
      _startAutoScan();
    }
  }

  Future<void> _initializeCameraIfNeeded() async {
    if (_isCameraInitialized) return;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('사용 가능한 카메라가 없습니다');

      final backCamera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        // ✨ 안드로이드/iOS 포맷 분기 처리
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.yuv420,
      );

      await _cameraController.initialize();

      if (_cameraController.value.isInitialized) {
        if (_cameraController.value.focusPointSupported) {
          await _cameraController.setFocusMode(FocusMode.auto);
        }
        if (_cameraController.value.exposurePointSupported) {
          await _cameraController.setExposureMode(ExposureMode.auto);
        }
      }

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        print('✅ 카메라 초기화 완료, 자동 스캔 시작 호출');
        _startAutoScan();
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
      if (mounted && !_isDialogShowing) {
        _showCustomPermissionDialog();
      }
    }
  }


  void _startAutoScan() {
    print('📸 _startAutoScan 호출됨');
    print('  _isCameraInitialized: $_isCameraInitialized');
    print('  _cameraController.value.isInitialized: ${_cameraController.value
        .isInitialized}');
    print(
        '  _cameraController.value.isStreamingImages: ${_cameraController.value
            .isStreamingImages}');
    print('  _isMovingToNextScreen: $_isMovingToNextScreen');

    if (!_isCameraInitialized || !_cameraController.value.isInitialized ||
        _cameraController.value.isStreamingImages) {
      print('❌ 자동 스캔 시작 실패: 조건 미충족');
      return;
    }
    if (_isMovingToNextScreen) {
      print('❌ 자동 스캔 시작 실패: 이미 다음 화면으로 이동 중');
      return;
    }

    try {
      _cameraController.startImageStream((image) async {
        if (!mounted || _isProcessing || _isMovingToNextScreen) return;

        final now = DateTime.now();

        print('🎞️ 프레임 수신: ${now.millisecondsSinceEpoch}');

        if (_lastScanTime != null && now
            .difference(_lastScanTime!)
            .inMilliseconds < 500) {
          return;
        }

        _lastScanTime = now;
        setState(() => _isProcessing = true);

        try {
          await _processCameraImage(image);
        } catch (e) {
          print('❌ OCR 스트림 처리 오류: $e');
          print('❌ 스택 트레이스: ${StackTrace.current}');
        } finally {
          if (mounted && !_isMovingToNextScreen) {
            setState(() => _isProcessing = false);
          }
        }
      });
      print('✅ 자동 스캔 스트림 시작 성공');
    } catch (e) {
      print('❌ startImageStream 오류: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
    }
  }

  void _stopAutoScan() {
    if (_isCameraInitialized && _cameraController.value.isStreamingImages) {
      _cameraController.stopImageStream();
      print('⏸️ 자동 스캔 스트림 중지');
    }
  }

  @override
  void dispose() {
    _successfulScanFrame = null;
    _stopAutoScan();
    WidgetsBinding.instance.removeObserver(this);
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    print('🔄 _processCameraImage 시작');

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes
          .done()
          .buffer
          .asUint8List();
      print('  이미지 바이트 변환 완료: ${bytes.length} bytes');

      final InputImageRotation rotation = _rotationIntToInputImageRotation(
          _cameraController.value.deviceOrientation ??
              DeviceOrientation.portraitUp
      );

      // ✨ 안드로이드/iOS 포맷 분기 처리
      InputImageFormat format;
      if (Platform.isAndroid) {
        // 안드로이드: nv21 또는 yuv420
        if (image.format.group == ImageFormatGroup.nv21) {
          format = InputImageFormat.nv21;
        } else if (image.format.group == ImageFormatGroup.yuv420) {
          format = InputImageFormat.yuv420;
        } else {
          print('❌ 지원하지 않는 안드로이드 이미지 포맷: ${image.format.group}');
          return;
        }
      } else {
        // iOS: bgra8888 또는 yuv420
        if (image.format.group == ImageFormatGroup.bgra8888) {
          format = InputImageFormat.bgra8888;
        } else {
          format = InputImageFormat.yuv420;
        }
      }

      print('  포맷: $format, rotation: $rotation');

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      print('  InputImage 생성 완료');

      final textRecognizer = TextRecognizer(
          script: TextRecognitionScript.korean);
      print('  TextRecognizer 생성 완료');

      final recognizedText = await textRecognizer.processImage(inputImage);
      print('  OCR 처리 완료');

      final cleanedText = recognizedText.text
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      print('====================================');
      print('🔍 OCR 인식 텍스트 (총 ${recognizedText.text.length}자):');
      print(recognizedText.text.isEmpty ? '(인식된 텍스트 없음)' : recognizedText.text);
      print('====================================');

      if (cleanedText.isNotEmpty) {
        await _attemptMatchAndMove(cleanedText, image);
      } else {
        print('⚠️ OCR 결과가 비어있음');
      }

      await textRecognizer.close();
      print('  TextRecognizer 종료 완료');
    } catch (e) {
      print('❌ _processCameraImage 오류: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
    }
  }


  InputImageRotation _rotationIntToInputImageRotation(
      DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return InputImageRotation.rotation0deg;
      case DeviceOrientation.landscapeLeft:
        return InputImageRotation.rotation270deg;
      case DeviceOrientation.portraitDown:
        return InputImageRotation.rotation180deg;
      case DeviceOrientation.landscapeRight:
        return InputImageRotation.rotation90deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _attemptMatchAndMove(String cleanedText,
      CameraImage image) async {
    if (_isMovingToNextScreen || !mounted) return;

    final extracted = _extractTicketInfoFromText(cleanedText);

    print('🔍 매칭 시도:');
    print('  extracted.awayTeam: ${extracted.awayTeam}');
    print('  extracted.date: ${extracted.date}');
    print('  조건 통과: ${extracted.awayTeam?.isNotEmpty == true &&
        extracted.date?.isNotEmpty == true}');

    if (extracted.awayTeam?.isNotEmpty == true &&
        extracted.date?.isNotEmpty == true) {
      final String awayTeam = extracted.awayTeam!;
      final String dateStr = extracted.date!;

      print('🌐 DB 조회 시작: awayTeam=$awayTeam, date=$dateStr');

      try {
        final allDayGames = await GameApi.listByDateRange(
          from: dateStr,
          to: dateStr,
        );

        print('📦 DB 응답: ${allDayGames.length}개 경기');

        final matchedGames = allDayGames.where((game) {
          print('  - 경기: ${game.homeTeam} vs ${game.awayTeam}');
          return game.awayTeam == awayTeam;
        }).toList();

        print('✅ 매칭된 경기: ${matchedGames.length}개');

        if (matchedGames.isNotEmpty) {
          final game = matchedGames.first;

          _successfulScanFrame = image;

          HapticFeedback.mediumImpact();

          setState(() {
            _isMovingToNextScreen = true;
          });

          print('✅ DB 매칭 성공:');
          print('  홈팀: ${game.homeTeam}');
          print('  원정팀: ${game.awayTeam}');
          print('  날짜: $dateStr');
          print('  시간: ${game.time}');
          print('  구장: ${game.stadium}');
          print('  게임ID: ${game.gameId}');

          await _handleScanSuccess(game, extracted);
        } else {
          print('❌ DB 매칭 실패: $awayTeam, $dateStr 와 일치하는 경기가 없습니다.');
        }
      } catch (e) {
        print('❌ DB 통신 오류: $e');
      }
    } else {
      print('⚠️ 매칭 조건 미충족 (원정팀 또는 날짜 누락)');
    }
  }

  Future<void> _handleScanSuccess(dynamic game,
      ExtractedTicketInfo extracted) async {
    _stopAutoScan();

    try {
      // ✅ 무음 Raw 캡처 (3줄 변환!)
      if (_successfulScanFrame == null) {
        throw Exception("No successful frame captured.");
      }
      final imageBytes = await _cameraImageToJpegBytes(_successfulScanFrame!);
      _capturedImagePath = await _saveBytesToTempFile(imageBytes);

      final recordState = Provider.of<RecordState>(context, listen: false);
      recordState.reset();

      // ✨ DB 형식을 풀네임으로 변환 (기존 그대로)
      final fullHomeTeam = _mapCorpToFullName(game.homeTeam) ?? game.homeTeam;
      final fullAwayTeam = _mapCorpToFullName(game.awayTeam) ?? game.awayTeam;
      final fullStadium = _mapStadiumName(game.stadium) ?? game.stadium;

      String formattedDateTime = '';
      if (extracted.date != null && game.time != null) {
        formattedDateTime = '${extracted.date} ${game.time}';
      }

      print('💾 RecordState 저장 시작:');
      print('  ticketImagePath: $_capturedImagePath');
      print('  selectedHome: $fullHomeTeam');
      print('  selectedAway: $fullAwayTeam');
      print('  selectedDateTime: $formattedDateTime');
      print('  selectedStadium: $fullStadium');
      print('  gameId: ${game.gameId}');

      recordState.setTicketInfo(
        ticketImagePath: _capturedImagePath!,
        selectedHome: fullHomeTeam,
        selectedAway: fullAwayTeam,
        selectedDateTime: formattedDateTime,
        selectedStadium: fullStadium,
        gameId: game.gameId,
        extractedHomeTeam: fullHomeTeam,
        extractedAwayTeam: fullAwayTeam,
        extractedDate: extracted.date,
        extractedTime: game.time,
        extractedStadium: fullStadium,
      );

      print('✅ RecordState 저장 완료');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                TicketInfoScreen(
                  imagePath: _capturedImagePath!,
                  skipOcrFailPopup: true,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      print('❌ 캡처 후 이동 실패: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isMovingToNextScreen = false;
        });
        _showMissingInfoDialog('');
      }
    }
  }


  // ✨ 헬퍼 함수: 짧은 팀명 → 풀네임
  String? _mapCorpToFullName(String? shortName) {
    if (shortName == null || shortName.isEmpty) return null;

    final Map<String, String> corpToFullName = {
      'KIA': 'KIA 타이거즈',
      '두산': '두산 베어스',
      '롯데': '롯데 자이언츠',
      '삼성': '삼성 라이온즈',
      '키움': '키움 히어로즈',
      '한화': '한화 이글스',
      'KT': 'KT WIZ',
      'LG': 'LG 트윈스',
      'NC': 'NC 다이노스',
      'SSG': 'SSG 랜더스',
    };

    return corpToFullName[shortName.trim()] ?? shortName;
  }

  // ✨ 헬퍼 함수: 짧은 구장명 → 풀네임
  String? _mapStadiumName(String? shortName) {
    if (shortName == null || shortName.isEmpty) return null;

    final Map<String, String> stadiumFullName = {
      '잠실': '잠실 야구장',
      '사직': '사직 야구장',
      '대구': '대구삼성라이온즈파크',
      '문학': '인천 SSG 랜더스필드',
      '수원': '수원 케이티 위즈 파크',
      '광주': '기아 챔피언스 필드',
      '창원': '창원 NC 파크',
      '고척': '고척 SKYDOME',
      '대전': '한화생명 볼파크',
      '대전(신)': '한화생명 볼파크',
    };

    return stadiumFullName[shortName.trim()] ?? shortName;
  }

  ExtractedTicketInfo _extractTicketInfoFromText(String cleanedText) {
    final awayTeam = extractAwayTeam(
      cleanedText,
      teamToCorpMap,
      teamKeywordsList,
    );
    final date = extractDate(cleanedText);

    print('📋 추출 결과:');
    print('  원정팀: $awayTeam');
    print('  날짜: $date');

    return ExtractedTicketInfo(awayTeam: awayTeam, date: date);
  }

  void _showCustomPermissionDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          CustomPopupDialog(
            imageAsset: AppImages.icAlert,
            title: '현재 카메라 사용에 대한\n접근 권한이 없어요',
            subtitle: '설정에서 카메라 권한을 허용해주세요',
            firstButtonText: '직접 입력',
            firstButtonAction: () {
              _isDialogShowing = false;
              Navigator.pop(context);
              _onDirectWriteButtonPressed();
            },
            secondButtonText: '확인',
            secondButtonAction: () {
              _isDialogShowing = false;
              Navigator.pop(context);
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
            subtitle: '다시 시도하거나 정보를 직접 입력해 주세요',
            firstButtonText: '직접 입력',
            firstButtonAction: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      TicketInfoScreen(
                        imagePath: imagePath,
                        skipOcrFailPopup: true,
                      ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            secondButtonText: '다시 시도하기',
            secondButtonAction: () {
              Navigator.pop(context);
              setState(() {
                _isMovingToNextScreen = false;
              });
              _startAutoScan();
            },
          ),
    );
  }

  Future<void> _onGalleryButtonPressed() async {
    _stopAutoScan();
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery);
      if (pickedFile == null) {
        _startAutoScan();
        return;
      }

      final recordState = Provider.of<RecordState>(context, listen: false);
      recordState.reset();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              TicketInfoScreen(imagePath: pickedFile.path),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      _startAutoScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('갤러리 접근 실패: $e')));
      }
    }
  }

  void _onDirectWriteButtonPressed() {
    _stopAutoScan();
    final recordState = Provider.of<RecordState>(context, listen: false);
    recordState.reset();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
        const TicketInfoScreen(
          imagePath: '',
          skipOcrFailPopup: true,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildFloatingButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
    bool isPencil = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scaleWidth(115),
        height: scaleHeight(44),
        padding: EdgeInsets.symmetric(
            horizontal: scaleWidth(14), vertical: scaleHeight(8)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scaleWidth(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: scaleWidth(28),
              height: scaleHeight(28),
              child: Center(
                child: isPencil
                    ? SvgPicture.asset(
                  AppImages.write,
                  width: scaleWidth(18),
                  height: scaleHeight(18),
                  color: AppColors.gray600,
                )
                    : SvgPicture.asset(
                  icon,
                  width: scaleWidth(28),
                  height: scaleHeight(28),
                  color: AppColors.gray600,
                ),
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            FixedText(
              text,
              style: AppFonts.pretendard.body_sm_500(context).copyWith(
                color: AppColors.gray600,
                fontSize: scaleFont(14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1,
                  animation2) => const ReportScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.gray400,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                if (_isCameraInitialized &&
                    _cameraController.value.isInitialized)
                  SizedBox(
                    height: screenHeight,
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
                  )
                else
                  Container(
                    color: AppColors.gray400,
                    height: screenHeight,
                    width: double.infinity,
                  ),

                // ✨ 내비게이션 바 아래 하얀색 배경 추가
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: scaleHeight(70) + MediaQuery
                        .of(context)
                        .padding
                        .bottom,
                    color: Colors.white,
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: scaleHeight(212),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: scaleHeight(50) + MediaQuery
                      .of(context)
                      .padding
                      .top,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FixedText(
                        '티켓을 스캔해 주세요',
                        style: AppFonts.pretendard
                            .head_md_600(context)
                            .copyWith(
                          color: Colors.white,
                          fontSize: scaleFont(20),
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: scaleHeight(8)),
                      FixedText(
                        '팀명, 일시가 잘 보이게 직관 티켓을 스캔해 주세요',
                        style: AppFonts.pretendard
                            .body_sm_400(context)
                            .copyWith(
                          color: AppColors.gray30,
                          fontSize: scaleFont(14),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: scaleWidth(31),
                      right: scaleWidth(31),
                      // ✨ 위: 안내 텍스트 끝 + 44 여백
                      top: scaleHeight(50) + MediaQuery
                          .of(context)
                          .padding
                          .top + scaleHeight(20 + 8 + 14 + 44),
                      // 안내 텍스트 위치(50) + 타이틀 높이(20) + 간격(8) + 서브타이틀 높이(14) + 여백(44)
                      // ✨ 아래: 버튼 위 + 44 여백
                      bottom: MediaQuery
                          .of(context)
                          .padding
                          .bottom + scaleHeight(70) + scaleHeight(24) +
                          scaleHeight(44) + scaleHeight(44),
                      // 내비바(70) + 간격(24) + 버튼 높이(44) + 여백(44)
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SvgPicture.asset(AppImages.icCornerTopLeft,
                                width: scaleWidth(24),
                                height: scaleHeight(24),
                                color: Colors.white),
                            SvgPicture.asset(AppImages.icCornerTopRight,
                                width: scaleWidth(24),
                                height: scaleHeight(24),
                                color: Colors.white),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SvgPicture.asset(AppImages.icCornerBottomLeft,
                                width: scaleWidth(24),
                                height: scaleHeight(24),
                                color: Colors.white),
                            SvgPicture.asset(AppImages.icCornerBottomRight,
                                width: scaleWidth(24),
                                height: scaleHeight(24),
                                color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery
                      .of(context)
                      .padding
                      .bottom + scaleHeight(88) + scaleHeight(24),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildFloatingButton(
                          icon: AppImages.solar_gallery,
                          text: '내 갤러리',
                          onTap: _onGalleryButtonPressed,
                        ),
                        SizedBox(width: scaleWidth(12)),
                        _buildFloatingButton(
                          icon: AppImages.dropdown,
                          text: '직접 작성',
                          onTap: _onDirectWriteButtonPressed,
                          isPencil: true,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomBottomNavBar(currentIndex: 2),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ticket_ocr_screen.dart: _TicketOcrScreenState 클래스 내부
// ... (생략)

  Future<Uint8List> _cameraImageToJpegBytes(CameraImage image) async {
    Uint8List? rgbBytes;

    // 1. Raw 카메라 이미지 데이터를 RGB 바이트로 변환
    if (image.format.group == ImageFormatGroup.yuv420 ||
        image.format.group == ImageFormatGroup.nv21) {
      // YUV 계열 포맷 (Android 및 일부 iOS)
      rgbBytes = _yuv420toRgb(image);
      print('✅ Raw YUV420 → RGB 변환 완료');
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      // BGRA8888 포맷 (iOS)
      rgbBytes = _bgra8888toRgb(image);
      print('✅ Raw BGRA8888 → RGB 변환 완료');
    } else {
      print('❌ 지원하지 않는 이미지 포맷: ${image.format.group}');
      throw Exception("Unsupported image format for JPEG encoding.");
    }

    if (rgbBytes == null) {
      throw Exception("Failed to convert raw image to RGB bytes.");
    }

    // 2. RGB 바이트를 image 패키지의 Image 객체로 변환
    // 💡 img.Image.fromBytes는 buffer를 사용하고, numChannels: 4 (RGBA/ARGB)를 명시해야 합니다.
    final img.Image? decodedImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rgbBytes.buffer,
      numChannels: 4, // ARGB (Alpha, Red, Green, Blue) 4채널
    );

    if (decodedImage == null) {
      throw Exception("Failed to decode RGB bytes into img.Image.");
    }

    // 3. Image 객체를 JPEG로 인코딩하여 유효한 파일 데이터 생성
    // (선택 사항: Android/iOS에서 디바이스 방향에 따라 회전이 필요할 수 있습니다.)
    // final img.Image rotatedImage = img.copyRotate(decodedImage, angle: 90);

    final Uint8List jpgBytes = img.encodeJpg(decodedImage, quality: 90);
    print('✅ RGB → JPEG 인코딩 성공 (${jpgBytes.length} bytes)');

    return jpgBytes;
  }

  Future<String> _saveBytesToTempFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    final file = File('${tempDir.path}/ticket_$timestamp.jpg');
    await file.writeAsBytes(bytes);
    print('💾 컬러 티켓 저장: ${file.path} (${bytes.length} bytes)');
    return file.path;
  }


  // YUV420 포맷에서 RGB로 변환하는 로직 (Android/iOS YUV 포맷 처리)
  Uint8List _yuv420toRgb(CameraImage image) {
    if (image.planes.length < 2) {
      throw Exception("YUV420 conversion failed: insufficient planes (${image.planes.length}).");
    }

    final int width = image.width;
    final int height = image.height;

    // --- Y Plane (Luminance) ---
    final int yRowStride = image.planes[0].bytesPerRow;
    final Uint8List y = image.planes[0].bytes;

    // --- UV Planes (Chrominance) ---
    final Uint8List uv = image.planes[1].bytes;
    final Uint8List? vPlane = image.planes.length > 2 ? image.planes[2].bytes : null;

    // UV 데이터 접근 정보
    final int uvRowStride = image.planes[1].bytesPerRow;
    int? uvPixelStride = image.planes[1].bytesPerPixel;

    // UV Pixel Stride 유효성 검사 및 대체
    if (uvPixelStride == null || uvPixelStride <= 0) {
      print('⚠️ uvPixelStride가 유효하지 않아 기본값 2를 사용합니다. (iOS/Android)');
      uvPixelStride = 2; // NV12/NV21의 기본값 2로 설정
    }

    final Uint8List rgb = Uint8List(width * height * 4); // RGBA 버퍼 (패딩 없음)

    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        // 1. YUV 데이터 읽기 인덱스 (패딩/Stride 포함)
        final int yDataIndex = h * yRowStride + w;

        // 2. RGB 버퍼 쓰기 인덱스 (패딩 미포함, 논리적 픽셀 위치)
        // RGB 버퍼는 width 기준 (yRowStride보다 작음)
        final int pixelIndex = h * width + w;

        // UV 인덱스 계산: UV Row Stride 사용 (정렬된 데이터 처리)
        final int uvRow = h ~/ 2;
        final int uvCol = w ~/ 2;

        final int uvIndex = uvRow * uvRowStride + uvCol * uvPixelStride;

        final int Y = y[yDataIndex];
        int U, V;

        if (vPlane != null) {
          // 3 Planes (YUV420p)
          U = uv[uvIndex];

          final int vIndex = uvRow * image.planes[2].bytesPerRow + uvCol * image.planes[2].bytesPerPixel!;
          V = vPlane[vIndex];
        } else {
          // 2 Planes (NV21/NV12): UV가 인터리브드 됨
          if (Platform.isIOS) {
            // 💡 iOS는 NV12(UV 순서)가 표준이므로, 순서를 되돌립니다.
            // 이전의 '빨간색 오류'는 Y/Stride 문제였고, 이제 U/V 순서를 맞춥니다.
            U = uv[uvIndex]; // U 먼저 (청색 성분)
            V = uv[uvIndex + 1]; // V 다음 (적색 성분)
          } else {
            // Android (NV21) 가정: VU 순서
            V = uv[uvIndex];
            U = uv[uvIndex + 1];
          }
        }

        // YUV to RGB conversion formula
        int R = (Y + 1.402 * (V - 128)).round();
        int G = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128)).round();
        int B = (Y + 1.772 * (U - 128)).round();

        // Clamp R, G, B to [0, 255]
        R = R.clamp(0, 255);
        G = G.clamp(0, 255);
        B = B.clamp(0, 255);

        // RGBA 순서로 버퍼에 쓰기 (논리적 픽셀 인덱스 사용)
        final int offset = pixelIndex * 4;
        rgb[offset] = R;
        rgb[offset + 1] = G;
        rgb[offset + 2] = B;
        rgb[offset + 3] = 255;   // Alpha
      }
    }

    return rgb;
  }

// BGRA8888 포맷에서 RGB로 변환하는 로직 (iOS에서 사용될 수 있음)
  Uint8List _bgra8888toRgb(CameraImage image) {
    // BGRA8888은 한 Plane에 모든 데이터가 있습니다.
    final bytes = image.planes[0].bytes;
    final int width = image.width;
    final int height = image.height;
    final Uint8List rgb = Uint8List(width * height * 4); // ARGB

    for (int i = 0, j = 0; i < bytes.length; i += 4, j += 4) {
      final int B = bytes[i];
      final int G = bytes[i + 1];
      final int R = bytes[i + 2];
      // bytes[i + 3]은 A (Alpha) 값입니다.

      rgb[j] = 255; // Alpha
      rgb[j + 1] = R;
      rgb[j + 2] = G;
      rgb[j + 3] = B;
    }
    return rgb;
  }
}