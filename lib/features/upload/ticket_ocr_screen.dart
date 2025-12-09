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
        imageFormatGroup: ImageFormatGroup.yuv420,
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
    print('  _cameraController.value.isInitialized: ${_cameraController.value.isInitialized}');
    print('  _cameraController.value.isStreamingImages: ${_cameraController.value.isStreamingImages}');
    print('  _isMovingToNextScreen: $_isMovingToNextScreen');

    if (!_isCameraInitialized || !_cameraController.value.isInitialized || _cameraController.value.isStreamingImages) {
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

        if (_lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds < 1000) {
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
      final bytes = allBytes.done().buffer.asUint8List();
      print('  이미지 바이트 변환 완료: ${bytes.length} bytes');

      final InputImageRotation rotation = _rotationIntToInputImageRotation(
          _cameraController.value.deviceOrientation ?? DeviceOrientation.portraitUp
      );

      final InputImageFormat format = _imageFormatToInputImageFormat(image.format.group);

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

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      print('  TextRecognizer 생성 완료');

      final recognizedText = await textRecognizer.processImage(inputImage);
      print('  OCR 처리 완료');

      final cleanedText = recognizedText.text.replaceAll(RegExp(r'\s+'), ' ').trim();

      print('====================================');
      print('🔍 OCR 인식 텍스트 (총 ${recognizedText.text.length}자):');
      print(recognizedText.text.isEmpty ? '(인식된 텍스트 없음)' : recognizedText.text);
      print('====================================');

      if (cleanedText.isNotEmpty) {
        await _attemptMatchAndMove(cleanedText);
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

  InputImageRotation _rotationIntToInputImageRotation(DeviceOrientation orientation) {
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

  InputImageFormat _imageFormatToInputImageFormat(ImageFormatGroup group) {
    switch (group) {
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      case ImageFormatGroup.jpeg:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }

  Future<void> _attemptMatchAndMove(String cleanedText) async {
    if (_isMovingToNextScreen || !mounted) return;

    final extracted = _extractTicketInfoFromText(cleanedText);

    print('🔍 매칭 시도:');
    print('  extracted.awayTeam: ${extracted.awayTeam}');
    print('  extracted.date: ${extracted.date}');
    print('  조건 통과: ${extracted.awayTeam?.isNotEmpty == true && extracted.date?.isNotEmpty == true}');

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

  Future<void> _handleScanSuccess(dynamic game, ExtractedTicketInfo extracted) async {
    _stopAutoScan();

    try {
      final XFile file = await _cameraController.takePicture();
      _capturedImagePath = file.path;

      if (_capturedImagePath == null) {
        throw Exception("Captured image path is null.");
      }

      final recordState = Provider.of<RecordState>(context, listen: false);
      recordState.reset();

      // ✨ DB 형식을 풀네임으로 변환
      final fullHomeTeam = _mapCorpToFullName(game.homeTeam) ?? game.homeTeam;
      final fullAwayTeam = _mapCorpToFullName(game.awayTeam) ?? game.awayTeam;
      final fullStadium = _mapStadiumName(game.stadium) ?? game.stadium;

      // 날짜와 시간을 합쳐서 DateTime 형식으로 만들기
      String formattedDateTime = '';
      if (extracted.date != null && game.time != null) {
        formattedDateTime = '${extracted.date} ${game.time}';
      }

      print('💾 RecordState 저장 시작:');
      print('  ticketImagePath: $_capturedImagePath');
      print('  selectedHome: $fullHomeTeam (원본: ${game.homeTeam})');
      print('  selectedAway: $fullAwayTeam (원본: ${game.awayTeam})');
      print('  selectedDateTime: $formattedDateTime');
      print('  selectedStadium: $fullStadium (원본: ${game.stadium})');
      print('  gameId: ${game.gameId}');

      recordState.setTicketInfo(
        ticketImagePath: _capturedImagePath!,
        selectedHome: fullHomeTeam,           // ✨ 풀네임
        selectedAway: fullAwayTeam,           // ✨ 풀네임
        selectedDateTime: formattedDateTime,
        selectedStadium: fullStadium,         // ✨ 풀네임
        gameId: game.gameId,
        // extracted* 필드도 함께 저장
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
            pageBuilder: (context, animation1, animation2) => TicketInfoScreen(
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
      builder: (context) => CustomPopupDialog(
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
      builder: (context) => CustomPopupDialog(
        imageAsset: AppImages.icAlert,
        title: '티켓 속 정보를\n인식하지 못했어요',
        subtitle: '다시 시도하거나 정보를 직접 입력해 주세요',
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
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        _startAutoScan();
        return;
      }

      final recordState = Provider.of<RecordState>(context, listen: false);
      recordState.reset();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TicketInfoScreen(imagePath: pickedFile.path),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      _startAutoScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('갤러리 접근 실패: $e')));
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
        pageBuilder: (_, __, ___) => const TicketInfoScreen(
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
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(14), vertical: scaleHeight(8)),
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
              pageBuilder: (context, animation1, animation2) => const ReportScreen(),
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
                if (_isCameraInitialized && _cameraController.value.isInitialized)
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
                    height: scaleHeight(70) + MediaQuery.of(context).padding.bottom,
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
                  top: scaleHeight(50) + MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FixedText(
                        '티켓을 스캔해 주세요',
                        style: AppFonts.pretendard.head_md_600(context).copyWith(
                          color: Colors.white,
                          fontSize: scaleFont(20),
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: scaleHeight(8)),
                      FixedText(
                        '팀명, 일시가 잘 보이게 직관 티켓을 스캔해 주세요',
                        style: AppFonts.pretendard.body_sm_400(context).copyWith(
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
                    padding: EdgeInsets.symmetric(
                      horizontal: scaleWidth(31),
                      vertical: scaleHeight(200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SvgPicture.asset(AppImages.icCornerTopLeft, width: scaleWidth(24), height: scaleHeight(24), color: Colors.white),
                            SvgPicture.asset(AppImages.icCornerTopRight, width: scaleWidth(24), height: scaleHeight(24), color: Colors.white),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SvgPicture.asset(AppImages.icCornerBottomLeft, width: scaleWidth(24), height: scaleHeight(24), color: Colors.white),
                            SvgPicture.asset(AppImages.icCornerBottomRight, width: scaleWidth(24), height: scaleHeight(24), color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isCameraInitialized && _cameraController.value.isInitialized && _isProcessing)
                  Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.pri500),
                    ),
                  ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + scaleHeight(88) + scaleHeight(24),
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
}
