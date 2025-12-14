import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/api/report_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:frontend/features/upload/ticket_ocr_screen.dart';
import 'package:frontend/features/report/badge_screen.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  Map<String, dynamic>? _userData; // 사용자 정보 저장
  String? _errorMessage;
  bool _isNetworkError = false;

  // 티켓 위젯 캡처를 위한 GlobalKey
  final GlobalKey _ticketKey = GlobalKey();

  // 감정 코드와 이미지 경로 매핑 (AppImages에 정의된 경로 사용)
  final Map<int, String> _emotionImageMap = {
    1: AppImages.emotion_1,
    2: AppImages.emotion_2,
    3: AppImages.emotion_3,
    4: AppImages.emotion_4,
    5: AppImages.emotion_5,
    6: AppImages.emotion_6,
    7: AppImages.emotion_7,
    8: AppImages.emotion_8,
    9: AppImages.emotion_9,
    10: AppImages.emotion_10,
    11: AppImages.emotion_11,
    12: AppImages.emotion_12,
    13: AppImages.emotion_13,
    14: AppImages.emotion_14,
    15: AppImages.emotion_15,
    16: AppImages.emotion_16,
  };

  // 카테고리별 에셋 매핑
  String? _getBadgeAssetPath(String? category, String? name) {
    if (name == null) return null;

    // 이름으로 직접 매핑
    switch (name) {
    // 어서와, 야구 직관은 처음이지?
      case "기록의 시작":
        return 'assets/imgs/badge/1_start.png';
      case "홈의 따뜻함":
        return 'assets/imgs/badge/1_home.png';
      case "원정의 즐거움":
        return 'assets/imgs/badge/1_away.png';
      case "같이 응원해요":
        return 'assets/imgs/badge/1_cheer.png';
      case "속닥속닥":
        return 'assets/imgs/badge/1_comment.png';

    // 나는야 승리요정
      case "응원의 보답":
        return 'assets/imgs/badge/2_heart.png';
      case "네잎클로버":
        return 'assets/imgs/badge/2_clover.png';
      case "행운의 편지":
        return 'assets/imgs/badge/2_letter.png';

    // 패배해도 괜찮아
      case "토닥토닥":
        return 'assets/imgs/badge/3_halfheart.png';
      case "그래도 응원해":
        return 'assets/imgs/badge/3_force.png';
      case "이게 사랑이야":
        return 'assets/imgs/badge/3_ring.png';

    // 모든 야구장을 제패하겠어
      case "베어스 정복":
        return 'assets/imgs/badge/4_bears.png';
      case "갈매기 정복":
        return 'assets/imgs/badge/4_lotte.png';
      case "사자 정복":
        return 'assets/imgs/badge/4_lions.png';
      case "히어로 정복":
        return 'assets/imgs/badge/4_kiwoom.png';
      case "독수리 정복":
        return 'assets/imgs/badge/4_eagles.png';
      case "호랑이 정복":
        return 'assets/imgs/badge/4_kia.png';
      case "마법사 정복":
        return 'assets/imgs/badge/4_kt.png';
      case "쌍둥이 정복":
        return 'assets/imgs/badge/4_lg.png';
      case "공룡 정복":
        return 'assets/imgs/badge/4_nc.png';
      case "랜더스 정복":
        return 'assets/imgs/badge/4_ssg.png';

      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNetworkError = false;
    });
    try {
      final results = await Future.wait([
        ReportApi.getMainReport(),
        UserApi.getMyProfile(),
      ]);
      if (!mounted) return;

      setState(() {
        _reportData = results[0] as Map<String, dynamic>;
        final userApiResponse = results[1] as Map<String, dynamic>;
        _userData = userApiResponse['data'] as Map<String, dynamic>?;
        _isLoading = false;
        _isNetworkError = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('❌ 리포트 데이터 로딩 실패: $e');
      final isNetwork = e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Network');
      setState(() {
        _isLoading = false;
        _isNetworkError = isNetwork;
        _errorMessage = '리포트 정보를 불러오는 데 실패했습니다.';
      });
    }
  }

  // 티켓 이미지 저장 함수
  Future<void> _saveTicketImage() async {
    try {
      // Android 13 이상에서는 권한 불필요, iOS는 항상 권한 필요
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('갤러리 접근 권한이 필요합니다.')),
            );
          }
          return;
        }
      }

      // RepaintBoundary를 찾아서 이미지로 변환
      RenderRepaintBoundary boundary =
      _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 고해상도 이미지를 위해 pixelRatio 설정
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일 경로 생성
      final String fileName = "baseball_diary_${DateTime.now().millisecondsSinceEpoch}.png";

      // gal 패키지로 갤러리에 저장
      await Gal.putImageBytes(pngBytes, name: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지가 갤러리에 저장되었습니다.'),
          ),
        );
      }
    } catch (e) {
      print('❌ 이미지 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 저장 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  // 네트워크 오류 화면 위젯
  Widget _buildNetworkErrorScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '네트워크에 연결할 수 없습니다.',
              style: AppFonts.pretendard.body_sm_400(context).copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: scaleHeight(8)),
            Text(
              '네트워크 연결 상태를 확인하신 후 다시 시도해 주세요.',
              style: AppFonts.pretendard.body_sm_400(context).copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: scaleHeight(24)),
            GestureDetector(
              onTap: _loadReportData,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scaleWidth(24),
                  vertical: scaleHeight(12),
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '재시도',
                  style: AppFonts.pretendard.body_sm_500(context).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    final bool hasRecords = !_isLoading && _errorMessage == null && !_isNetworkError &&
        (_reportData?['winRateInfo']?['totalGameCount'] ?? 0) > 0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 홈 헤더
            SafeArea(
              bottom: false,
              child: Container(
                height: scaleHeight(64),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: scaleHeight(24),
                    left: scaleWidth(20),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '2025',
                          style: AppFonts.pretendard.title_md_600(context).copyWith(
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: scaleWidth(10)),
                        SvgPicture.asset(
                          AppImages.dropdown,
                          width: scaleWidth(16),
                          height: scaleHeight(16),
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 메인 콘텐츠 영역
            Expanded(
              child: _isLoading
                  ? Center(
                  child: CircularProgressIndicator(color: AppColors.pri500))
                  : _isNetworkError
                  ? _buildNetworkErrorScreen()
                  : Stack(
                children: [
                  // 카운트다운, 티켓 요약 카드
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.gray800,
                    child: SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                      child: _buildCountdownSection(hasRecords: hasRecords),
                    ),
                  ),

                  // 앞에서 올라오는 흰색 영역
                  DraggableScrollableSheet(
                    initialChildSize: 0.32,
                    minChildSize: 0.32,
                    maxChildSize: 0.95,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(scaleWidth(20)),
                            topRight: Radius.circular(scaleWidth(20)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            top: scaleHeight(30),
                            left: scaleWidth(20),
                            right: scaleWidth(20),
                            bottom: scaleHeight(18),
                          ),
                          child: Column(
                            children: [
                              _buildBadgeSection(hasRecords: hasRecords),
                              SizedBox(height: scaleHeight(40)),
                              _buildAnalysisSection(hasRecords: hasRecords),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 0,
          isDisabled: _isNetworkError, // 네트워크 오류 시 네비게이션 비활성화
        ),
      ),
    );
  }

  ///카운트다운,티켓 요약 카드
  Widget _buildCountdownSection({required bool hasRecords}) {
    final seasonInfo = _reportData?['seasonInfo'];
    final message = seasonInfo?['message'] ?? '시즌 정보 없음';
    final daysRemaining = seasonInfo?['daysRemaining'] ?? 0;
    final daysRemainingStr = daysRemaining.toString();

    final bool isDDay = daysRemaining >= 0 && daysRemaining <= 10;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: scaleHeight(28)),
      child: Column(
        children: [
          Text(
            message,
            style: AppFonts.suite.body_md_500(context).copyWith(
                color: AppColors.gray30),
          ),
          SizedBox(height: scaleHeight(13)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // D 박스
              Container(
                width: scaleWidth(38),
                height: scaleHeight(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(scaleWidth(5)),
                ),
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(0, scaleHeight(3)),
                  child: Text(
                    "D",
                    style: TextStyle(
                      fontFamily: 'Jalnan',
                      fontSize: 30.sp,
                      color: AppColors.gray900,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              // 하이픈
              Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleWidth(4)),
                child: Container(
                  width: scaleWidth(10),
                  height: scaleHeight(4),
                  decoration: BoxDecoration(
                    color: AppColors.gray20,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // 숫자 박스들
              if (daysRemaining == 0) ...[
                // 0일일 때 "DAY" 표시
                ...['D', 'A', 'Y'].map((char) =>
                    Padding(
                      padding: EdgeInsets.only(
                          right: char != 'Y' ? scaleWidth(4) : 0),
                      child: Container(
                        width: scaleWidth(38),
                        height: scaleHeight(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(scaleWidth(5)),
                        ),
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(0, scaleHeight(3)),
                          child: Text(
                            char,
                            style: TextStyle(
                              fontFamily: 'Jalnan',
                              fontSize: 30.sp,
                              color: AppColors.error,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    )),
              ] else
                ...[
                  // 1~10일 때 숫자 표시
                  ...List.generate(daysRemainingStr.length, (index) {
                    final bool isNumeric = int.tryParse(
                        daysRemainingStr[index]) != null;
                    final Color textColor = (isDDay && isNumeric) ? AppColors
                        .error: AppColors.gray900;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < daysRemainingStr.length - 1 ? scaleWidth(
                            4) : 0,
                      ),
                      child: Container(
                        width: scaleWidth(38),
                        height: scaleHeight(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(scaleWidth(5)),
                        ),
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(0, scaleHeight(3)),
                          child: Text(
                            daysRemainingStr[index],
                            style: TextStyle(
                              fontFamily: 'Jalnan',
                              fontSize: 30.sp,
                              color: textColor,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
            ],
          ),
          SizedBox(height: scaleHeight(33)),
          _buildSummaryCard(hasRecords: hasRecords),
          SizedBox(height: scaleHeight(22)),
          _buildImageSaveButton(),
        ],
      ),
    );
  }

  // 경기 티켓 카드 영역
  Widget _buildSummaryCard({bool hasRecords = true}) {
    final winRateInfo = _reportData?['winRateInfo'];
    final totalWinRate = winRateInfo?['totalWinRate'] ?? 0.0;
    final totalWin = winRateInfo?['totalWinCount'] ?? 0;
    final totalLose = winRateInfo?['totalLoseCount'] ?? 0;
    final totalDraw = winRateInfo?['totalDrawCount'] ?? 0;
    final totalGames = winRateInfo?['totalGameCount'] ?? 0;
    final homeWinRate = winRateInfo?['homeWinRate'] ?? 0.0;
    final homeWin = winRateInfo?['homeWinCount'] ?? 0;
    final homeLose = winRateInfo?['homeLoseCount'] ?? 0;
    final awayWinRate = winRateInfo?['awayWinRate'] ?? 0.0;
    final awayWin = winRateInfo?['awayWinCount'] ?? 0;
    final awayLose = winRateInfo?['awayLoseCount'] ?? 0;

    final nickname = _userData?['nickname'] ?? '사용자';
    final favTeam = _userData?['favTeam'] ?? '응원팀 없음';
    final profileImageUrl = _userData?['profileImageUrl'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
      child: RepaintBoundary(
        key: _ticketKey,
        child: Container(
          width: double.infinity,
          height: scaleHeight(195),
          child: Stack(
            children: [
              // 기본 티켓
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scaleWidth(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x339397A1),
                      blurRadius: scaleWidth(32),
                      offset: Offset(0, 0),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: TicketShapePainter(
                    backgroundColor: Colors.white,
                    dividerColor: Color(0xFFB1C4D3),
                    notchRadius: scaleWidth(12),
                    dividerDashWidth: scaleHeight(7),
                    dividerDashSpace: scaleHeight(7),
                    dividerXPosition: (MediaQuery
                        .of(context)
                        .size
                        .width - scaleWidth(32)) * 0.7,
                    dividerStrokeWidth: 1.47,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: scaleWidth(15.27),
                      top: scaleHeight(16.4),
                      right: scaleWidth(10.25),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 왼쪽 영역
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 프로필
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: scaleWidth(32),
                                    height: scaleHeight(32),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          scaleWidth(11.85)),
                                      border: Border.all(
                                          color: AppColors.gray100, width: 0.76),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          scaleWidth(11.85)),
                                      child: profileImageUrl != null &&
                                          profileImageUrl!.isNotEmpty
                                          ? Image.network(
                                        profileImageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error,
                                            stackTrace) =>
                                            SvgPicture.asset(
                                              AppImages.profile,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                      )
                                          : SvgPicture.asset(
                                        AppImages.profile,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: scaleWidth(9)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nickname,
                                        style: AppFonts.suite.caption_md_500(
                                            context).copyWith(
                                            color: AppColors.gray800),
                                      ),
                                      if (favTeam != '응원팀 없음')
                                        Text(
                                          "$favTeam 팬",
                                          style: AppFonts.suite.caption_re_400(
                                              context).copyWith(
                                              color: AppColors.gray300),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: scaleHeight(3)),

                              Align(
                                alignment: Alignment((0.36 * 2) - 1, 0),
                                child: Text(
                                  "${totalWinRate % 1 == 0
                                      ? totalWinRate.toInt()
                                      : totalWinRate.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontFamily: AppFonts.suiteFontFamily,
                                    fontSize: 42.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray800,
                                    height: 1.6,
                                    letterSpacing: -0.84,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              Align(
                                alignment: Alignment((0.37 * 2) - 1, 0),
                                child: Text(
                                  "총 ${totalGames}회의 경기를 관람했어요",
                                  style: AppFonts.suite.caption_re_400(context)
                                      .copyWith(
                                      color: AppColors.gray600, fontSize: 10.sp),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              SizedBox(height: scaleHeight(14)),

                              Align(
                                alignment: Alignment((0.29 * 2) - 1, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildWinLossDrawBadge(
                                        AppImages.win, totalWin),
                                    SizedBox(width: scaleWidth(10)),
                                    _buildWinLossDrawBadge(
                                        AppImages.tie, totalDraw),
                                    SizedBox(width: scaleWidth(10)),
                                    _buildWinLossDrawBadge(
                                        AppImages.lose, totalLose),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 오른쪽 홈/원정 박스
                        Column(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(child: _buildHomeAwayBox(
                                      "홈", homeWinRate, homeWin, homeLose)),
                                  SizedBox(height: scaleHeight(8)),
                                  Expanded(child: _buildHomeAwayBox(
                                      "원정", awayWinRate, awayWin, awayLose)),
                                ],
                              ),
                            ),
                            SizedBox(height: scaleHeight(14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 기록 없을 때만 블러 오버레이 표시
              if (!hasRecords)
                Container(
                  width: double.infinity,
                  height: scaleHeight(195),
                  child: ClipPath(
                    clipper: TicketShapeClipper(
                      notchRadius: scaleWidth(12),
                      dividerXPosition: (MediaQuery.of(context).size.width - scaleWidth(32)) * 0.7,
                    ),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        width: double.infinity,
                        height: scaleHeight(195), // 전체 티켓 높이
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: scaleHeight(5)),
                            Text(
                              "첫 직관 기록을 시작해 보세요!",
                              style: AppFonts.pretendard.head_sm_600(context).copyWith(color: AppColors.gray800),
                            ),
                            SizedBox(height: scaleHeight(10)),
                            Text(
                              "첫 직관을 기록하고 나의 승률 데이터를 확인해 보세요.",
                              style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray600),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: scaleHeight(23)),
                            Container(
                              width: scaleWidth(178),
                              height: scaleHeight(45),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation1, animation2) => const TicketOcrScreen(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gray700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleWidth(16)),
                                  ),
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "직관 기록하러 가기",
                                      style: AppFonts.pretendard.body_md_500(context).copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: scaleWidth(3)),
                                    SvgPicture.asset(
                                      AppImages.arrow,
                                      width: scaleWidth(20),
                                      height: scaleHeight(20),
                                      color: AppColors.gray20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

// 승/무/패 뱃지 위젯
  Widget _buildWinLossDrawBadge(String iconPath, int count) {
    if (!iconPath.endsWith('.svg')) iconPath += '.svg';
    return Container(
      height: scaleHeight(23),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleWidth(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: scaleWidth(4)),
          SvgPicture.asset(
              iconPath, width: scaleWidth(16), height: scaleHeight(16)),
          Container(
            width: scaleWidth(24),
            height: scaleHeight(18),
            alignment: Alignment.center,
            child: Text(
              count.toString(),
              style: AppFonts.suite.caption_md_500(context).copyWith(
                  color: AppColors.black),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: scaleWidth(4)),
        ],
      ),
    );
  }

  // 홈/어웨이 승률 박스 위젯
  Widget _buildHomeAwayBox(String title, double rate, int win, int lose) {
    return Container(
      width: scaleWidth(72),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleWidth(12)),
      ),
      child: Column(
        children: [
          SizedBox(height: scaleHeight(5)), // 홈 글자 5px 아래
          Text(
            title,
            style: AppFonts.suite.caption_md_500(context).copyWith(
                color: AppColors.gray600),
          ),
          Expanded(
            child: Center(
              child: Text(
                "${rate % 1 == 0 ? rate.toInt() : rate.toStringAsFixed(1)}%",
                style: AppFonts.suite.head_sm_700(context).copyWith(
                    color: AppColors.gray600),
              ),
            ),
          ),
          Text(
            "${win}승 ${lose}패",
            style: AppFonts.suite.caption_md_400(context).copyWith(
                color: AppColors.gray400),
          ),
          SizedBox(height: scaleHeight(5)), // 승패 텍스트 아래 5px 위
        ],
      ),
    );
  }

  //이미지 저장
  Widget _buildImageSaveButton() {
    final totalGames = _reportData?['winRateInfo']?['totalGameCount'] ?? 0;
    final bool hasRecords = !_isLoading && _errorMessage == null &&
        totalGames > 0;

    return GestureDetector(
      onTap: hasRecords ? _saveTicketImage : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: scaleWidth(10),
          vertical: scaleHeight(4),
        ),
        decoration: BoxDecoration(
          color: hasRecords
              ? AppColors.gray600
              : AppColors.gray600.withOpacity(0.8),
          borderRadius: BorderRadius.circular(scaleWidth(16)),
        ),
        child: Text(
          "이미지 저장",
          style: AppFonts.pretendard.caption_md_500(context).copyWith(
            color: hasRecords
                ? AppColors.gray50
                : AppColors.gray800,
          ),
        ),
      ),
    );
  }

  // 뱃지, 나의 직관 기록 분석 헤더 (제목 + 자세히 보기)
  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppFonts.pretendard.head_sm_600(context).copyWith(
            color: AppColors.gray700)),
        GestureDetector(
          onTap: onTap, // null이면 클릭 안 됨
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "자세히 보기",
                  style: AppFonts.pretendard.caption_md_500(context).copyWith(color: AppColors.gray400),
                ),
                SizedBox(width: scaleWidth(2)),
                SvgPicture.asset(
                  AppImages.arrow,
                  width: scaleWidth(15),
                  height: scaleHeight(15),
                  color: AppColors.gray400,
                ),
              ]
          ),
        ),
      ],
    );
  }

  ///나의 배지 섹션
  Widget _buildBadgeSection({required bool hasRecords}) {
    final badgeSummary = _reportData?['badgeSummary'];
    final mainPageBadges = badgeSummary?['mainPageBadges'] as List<dynamic>? ??
        [];

    print("=== 뱃지 데이터 확인 ===");
    print("badgeSummary: $badgeSummary");
    print("mainPageBadges: $mainPageBadges");

    // 디폴트로 보여줄 뱃지 이름 (아무것도 획득 안했을 때)
    final defaultBadgeNames = ['기록의 시작', '홈의 따뜻함', '응원의 보답', '토닥토닥', '베어스 정복'];

    List<Map<String, dynamic>> displayBadges = [];
    Set<String> addedBadgeNames = {};

    // 1. 획득한 뱃지 추가
    for (var badge in mainPageBadges) {
      if (displayBadges.length >= 5) break;

      final badgeMap = badge as Map<String, dynamic>;
      final name = badgeMap['badgeName'] as String?;

      if (name != null) {
        displayBadges.add({
          'name': name,
          'imageUrl': badgeMap['imageUrl'],
          'category': null,
          'isAchieved': true,
        });
        addedBadgeNames.add(name);
      }
    }

    // 2. 부족한 자리는 디폴트 뱃지로 채우기 (획득하지 않은 것만)
    for (var badgeName in defaultBadgeNames) {
      if (displayBadges.length >= 5) break;
      if (!addedBadgeNames.contains(badgeName)) {
        displayBadges.add({
          'name': badgeName,
          'imageUrl': null,
          'category': null,
          'isAchieved': false,
        });
      }
    }

    // 3. 그래도 5개가 안되면 빈 슬롯으로 채우기 (혹시 모를 경우 대비)
    while (displayBadges.length < 5) {
      displayBadges.add({
        'name': null,
        'imageUrl': null,
        'category': null,
        'isAchieved': false,
      });
    }

    return Column(
      children: [
        _buildSectionHeader("나의 배지", onTap: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1,
                  animation2) => const BadgeScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );

          // badge 화면에서 돌아왔을 때 데이터 새로고침
          if (result == true && mounted) {
            _loadReportData();
          }
        }),
        SizedBox(height: scaleHeight(14)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < displayBadges.length; i++) ...[
                _buildBadgeItem(
                  displayBadges[i]['imageUrl'],
                  displayBadges[i]['name'],
                  category: displayBadges[i]['category'],
                  isAchieved: displayBadges[i]['isAchieved'] ?? false,
                ),
                if (i < displayBadges.length - 1) SizedBox(
                    width: scaleWidth(25)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 뱃지 아이템 위젯
  Widget _buildBadgeItem(String? imageUrl, String? name,
      {String? category, bool isAchieved = false}) {
    final assetPath = isAchieved ? _getBadgeAssetPath(category, name) : null;

    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              width: scaleWidth(84),
              height: scaleWidth(84),
              child: Stack(
                children: [
                  // 1. 획득한 뱃지 asset 또는 lock 이미지
                  if (assetPath != null)
                    Transform.scale(
                      scale: 1.38,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Transform.scale(
                      scale: 1.0,
                      child: Image.asset(
                        'assets/imgs/badge/lock.png',
                        fit: BoxFit.cover,
                      ),
                    ),

                  // 2. imageUrl이 있을 때만 추가로 표시
                  if (isAchieved && imageUrl != null && imageUrl.isNotEmpty &&
                      assetPath == null)
                    Positioned.fill(
                      child: Transform.scale(
                        scale: 1.38,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => SizedBox(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: scaleHeight(10)),
          SizedBox(
            width: scaleWidth(84),
            child: Text(
              name ?? '뱃지 이름',
              style: AppFonts.pretendard.caption_md_500(context).copyWith(
                color: isAchieved ? AppColors.gray800: AppColors.gray800,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  ///나의 직관 기록 분석 섹션
  Widget _buildAnalysisSection({required bool hasRecords}) {
    // 데이터 추출
    final bestMonth = _reportData?['bestAttendanceMonth'];
    final year = bestMonth?['year'];
    final month = bestMonth?['month'];
    final monthText = (year != null && month != null) ? "$year년 $month월" : "-";

    final topStadium = _reportData?['topStadium']?['stadiumName'] ?? "-";

    final topEmotion = _reportData?['topEmotion'];
    final topEmotionName = topEmotion?['emotion'] ?? "-";
    final topEmotionCode = topEmotion?['emotionCode'] as int?;

    final bestCompanion = _reportData?['bestCompanion'];
    final companionNickname = bestCompanion?['nickname'] ?? "-";
    final companionProfileUrl = bestCompanion?['profileImageUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          "나의 직관 기록 분석",
          style: AppFonts.pretendard.body_md_500(context).copyWith(color: Colors.black),
        ),
        SizedBox(height: scaleHeight(14)),

        // 첫 번째 행: 최다 직관 월, 단골 구장
        Row(
          children: [
            Expanded(
              child: _buildAnalysisCardNew(
                iconPath: AppImages.day,
                subtitle: hasRecords ? "직관을 가장 많이 다녔던" : "???",
                value: hasRecords ? monthText : "???",
                isPlaceholder: !hasRecords,
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            Expanded(
              child: _buildAnalysisCardNew(
                iconPath: AppImages.stadium,
                subtitle: hasRecords ? "이제는 단골이 된" : "???",
                value: hasRecords ? topStadium : "???",
                isPlaceholder: !hasRecords,
              ),
            ),
          ],
        ),

        SizedBox(height: scaleHeight(8)),

        // 두 번째 행: 최다 감정, 베스트 프렌드
        Row(
          children: [
            Expanded(
              child: _buildAnalysisCardNew(
                iconPath: _emotionImageMap[topEmotionCode] ??
                    AppImages.emotion_5,
                subtitle: hasRecords ? "직관을 볼 때 내 감정은..." : "???",
                value: hasRecords ? topEmotionName : "???",
                isPlaceholder: !hasRecords,
                isEmotion: true,
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            Expanded(
              child: _buildAnalysisCardNew(
                iconPath: companionProfileUrl,
                subtitle: hasRecords ? "내 직관 베스트 프렌드" : "???",
                value: hasRecords ? companionNickname : "???",
                isPlaceholder: !hasRecords,
                isProfileImage: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 분석 카드 위젯 (2x2 그리드용)
  Widget _buildAnalysisCardNew({
    String? iconPath,
    required String subtitle,
    required String value,
    bool isPlaceholder = false,
    bool isEmotion = false,
    bool isProfileImage = false,
  }) {
    // 플레이스홀더일 때 투명도 적용
    final double opacity = isPlaceholder ? 0.2 : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 가로 크기를 기준으로 세로 크기 계산 (비율 156:132)
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = cardWidth * (132 / 156);

        final double scale = cardWidth / 156;

        final double iconSize = 40 * scale;
        final double horizontalPadding = 12 * scale;
        final double verticalPadding = 16 * scale;
        final double iconBottomMargin = 8 * scale;
        final double textBottomMargin = 6 * scale;
        final double tagVerticalPadding = 5 * scale;
        final double tagHorizontalPadding = 8 * scale;

        // 아이콘 위젯 결정
        Widget iconWidget;
        if (isProfileImage) {
          // 프로필 이미지
          final bool hasProfileUrl = iconPath != null && iconPath.isNotEmpty &&
              !isPlaceholder;
          iconWidget = ClipOval(
            child: hasProfileUrl
                ? Image.network(
              iconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return SvgPicture.asset(
                  AppImages.profile,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.cover,
                );
              },
            )
                : SvgPicture.asset(
              AppImages.profile,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
            ),
          );
        } else if (isEmotion) {
          // 감정 이미지 (SVG)
          iconWidget = SvgPicture.asset(
            iconPath ?? AppImages.emotion_5,
            width: iconSize,
            height: iconSize,
          );
        } else {
          // PNG 아이콘 (day, stadium)
          String displayIconPath = iconPath ?? '';
          iconWidget = Image.asset(
            displayIconPath,
            width: iconSize,
            height: iconSize,
          );
        }

        return Container(
          height: cardHeight,
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Opacity(
            opacity: opacity,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  // 아이콘
                  iconWidget,
                  SizedBox(height: iconBottomMargin),
                  // 설명 텍스트
                  Text(
                    subtitle,
                    style: AppFonts.pretendard.caption_md_500(context).copyWith(
                      color: AppColors.gray700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: textBottomMargin),
                  // 값 태그
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: tagVerticalPadding,
                      horizontal: tagHorizontalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pri800,
                      borderRadius: BorderRadius.circular(38 * scale),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      value,
                      style: AppFonts.pretendard.caption_md_500(context).copyWith(
                        color: AppColors.gray20,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


//  티켓 모양 배경을 그리는 CustomPainter
class TicketShapePainter extends CustomPainter {
  final Color backgroundColor;
  final Color dividerColor;
  final double notchRadius;
  final double dividerDashWidth;
  final double dividerDashSpace;
  final double dividerXPosition; // 구분선 X 좌표
  final double dividerStrokeWidth;

  TicketShapePainter({
    this.backgroundColor = Colors.white,
    required this.dividerColor,
    required this.notchRadius,
    required this.dividerDashWidth,
    required this.dividerDashSpace,
    required this.dividerXPosition,
    this.dividerStrokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    final Path path = Path();

    // --- 1. 티켓 모양(외곽선 + 노치) 그리기 ---
    // 시작 (왼쪽 상단)
    path.moveTo(scaleWidth(16), 0); // 왼쪽 상단 모서리 시작점
    // 상단 가장자리 (왼쪽)
    path.lineTo(dividerXPosition - notchRadius, 0);
    // 상단 노치 (반원)
    path.arcToPoint(
      Offset(dividerXPosition + notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false, // 아래로 파인 모양
    );
    // 상단 가장자리 (오른쪽)
    path.lineTo(size.width - scaleWidth(16), 0);
    // 오른쪽 상단 모서리 (둥글게)
    path.quadraticBezierTo(size.width, 0, size.width, scaleWidth(16));
    // 오른쪽 가장자리
    path.lineTo(size.width, size.height - scaleWidth(16));
    // 오른쪽 하단 모서리 (둥글게)
    path.quadraticBezierTo(size.width, size.height, size.width - scaleWidth(16), size.height);
    // 하단 가장자리 (오른쪽)
    path.lineTo(dividerXPosition + notchRadius, size.height);
    // 하단 노치 (반원)
    path.arcToPoint(
      Offset(dividerXPosition - notchRadius, size.height),
      radius: Radius.circular(notchRadius),
      clockwise: false, // 위로 파인 모양
    );
    // 하단 가장자리 (왼쪽)
    path.lineTo(scaleWidth(16), size.height);
    // 왼쪽 하단 모서리 (둥글게)
    path.quadraticBezierTo(0, size.height, 0, size.height - scaleWidth(16));
    // 왼쪽 가장자리
    path.lineTo(0, scaleWidth(16));
    // 왼쪽 상단 모서리 (둥글게)
    path.quadraticBezierTo(0, 0, scaleWidth(16), 0);
    path.close();


    // --- 2. 배경 채우기 ---
    canvas.drawPath(path, backgroundPaint);

    // --- 3. 점선 그리기 ---
    final Paint dashPaint = Paint()
      ..color = dividerColor
      ..strokeWidth = 1.0 // 1.5 -> 1.0 (더 얇게)
      ..style = PaintingStyle.stroke;

    final double dashStart = notchRadius + scaleHeight(8); // 상단 노치 아래에서 시작
    final double dashEnd = size.height - notchRadius - scaleHeight(8); // 하단 노치 위에서 끝
    double currentY = dashStart;

    while (currentY < dashEnd) {
      canvas.drawLine(
        Offset(dividerXPosition, currentY),
        Offset(dividerXPosition, currentY + dividerDashWidth),
        dashPaint,
      );
      currentY += (dividerDashWidth + dividerDashSpace);
    }
  }

  @override
  bool shouldRepaint(covariant TicketShapePainter oldDelegate) {
    // 필요한 속성들이 변경될 때만 다시 그리도록 최적화
    return backgroundColor != oldDelegate.backgroundColor ||
        dividerColor != oldDelegate.dividerColor ||
        notchRadius != oldDelegate.notchRadius ||
        dividerDashWidth != oldDelegate.dividerDashWidth ||
        dividerDashSpace != oldDelegate.dividerDashSpace ||
        dividerXPosition != oldDelegate.dividerXPosition;
  }
}

// 티켓 모양으로 자르는 CustomClipper
class TicketShapeClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double dividerXPosition;

  TicketShapeClipper({
    required this.notchRadius,
    required this.dividerXPosition,
  });

  @override
  Path getClip(Size size) {
    Path path = Path();

    // 기본 직사각형에서 시작 (rounded corners)
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(12),
    ));

    // 위쪽 반원 구멍
    path = Path.combine(
      PathOperation.difference,
      path,
      Path()..addOval(Rect.fromCircle(
        center: Offset(dividerXPosition, 0),
        radius: notchRadius,
      )),
    );

    // 아래쪽 반원 구멍
    path = Path.combine(
      PathOperation.difference,
      path,
      Path()..addOval(Rect.fromCircle(
        center: Offset(dividerXPosition, size.height),
        radius: notchRadius,
      )),
    );

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 육각형 모양 CustomClipper
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // 육각형 좌표 계산
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}