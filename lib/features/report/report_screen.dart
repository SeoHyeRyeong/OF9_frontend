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

  // 감정 코드와 이미지 경로 매핑 (AppImages에 정의된 경로 사용)
  final Map<int, String> _emotionImageMap = {
    1: AppImages.emotion_1_transparent,
    2: AppImages.emotion_2_transparent,
    3: AppImages.emotion_3_transparent,
    4: AppImages.emotion_4_transparent,
    5: AppImages.emotion_5_transparent,
    6: AppImages.emotion_6_transparent,
    7: AppImages.emotion_7_transparent,
    8: AppImages.emotion_8_transparent,
    9: AppImages.emotion_9_transparent,
  };

  // 카테고리별 에셋 매핑
  String? _getBadgeAssetPath(String? category, String? name) {
    if (category == null || name == null) return null;

    // 구단 도장깨기
    if (category == "구단 도장깨기") {
      if (name == "잠실 정복") return 'assets/imgs/badge/1_Jamsil.png';
      // if (name == "고척 정복") return 'assets/imgs/badge/1_Gocheok.png';
      // if (name == "부산 정복") return 'assets/imgs/badge/1_Busan.png';
      // if (name == "대구 정복") return 'assets/imgs/badge/1_Daegu.png';
      // if (name == "광주 정복") return 'assets/imgs/badge/1_Gwangju.png';
      // if (name == "대전 정복") return 'assets/imgs/badge/1_Daejeon.png';
      // if (name == "창원 정복") return 'assets/imgs/badge/1_Changwon.png';
      // if (name == "인천 정복") return 'assets/imgs/badge/1_Incheon.png';
      // if (name == "수원 정복") return 'assets/imgs/badge/1_Suwon.png';
    }

    // 직관 기록 수
    // if (category == "직관 기록수") {
    //   if (name == "직관 5회") return 'assets/imgs/badge/2_5.png';
    //   if (name == "직관 10회") return 'assets/imgs/badge/2_10.png';
    //   if (name == "직관 25회") return 'assets/imgs/badge/2_25.png';
    //   if (name == "직관 50회") return 'assets/imgs/badge/2_50.png';
    //   if (name == "직관 75회") return 'assets/imgs/badge/2_75.png';
    //   if (name == "직관 100회") return 'assets/imgs/badge/2_100.png';
    // }

    // 좋아하는 구단 직관 기록 수 (동적 처리 필요)
    // final favTeam = _userData?['favTeam'] as String? ?? 'NC 다이노스';
    // final shortTeam = _convertFavTeam(favTeam);
    // if (category == "$shortTeam 직관 기록수") {
    //   if (name == "$shortTeam 직관 5회") return 'assets/imgs/badge/3_${shortTeam}_5.png';
    //   if (name == "$shortTeam 직관 10회") return 'assets/imgs/badge/3_${shortTeam}_10.png';
    //   if (name == "$shortTeam 직관 25회") return 'assets/imgs/badge/3_${shortTeam}_25.png';
    //   if (name == "$shortTeam 직관 50회") return 'assets/imgs/badge/3_${shortTeam}_50.png';
    //   if (name == "$shortTeam 직관 75회") return 'assets/imgs/badge/3_${shortTeam}_75.png';
    //   if (name == "$shortTeam 직관 100회") return 'assets/imgs/badge/3_${shortTeam}_100.png';
    // }

    // 승리요정
    if (category == "승리요정") {
      if (name == "승리요정 입문") return 'assets/imgs/badge/4_Win_1.png';
      //   if (name == "승리요정 초급") return 'assets/imgs/badge/4_Win_5.png';
      //   if (name == "승리요정 중급") return 'assets/imgs/badge/4_Win_15.png';
      //   if (name == "승리요정 고급") return 'assets/imgs/badge/4_Win_30.png';
      //   if (name == "승리는 나의 것") return 'assets/imgs/badge/4_Win_50.png';
      //   if (name == "KBO는 내 손에") return 'assets/imgs/badge/4_Win_100.png';
    }

    // 패배요정
    // if (category == "패배요정") {
    //   if (name == "패배요정 입문") return 'assets/imgs/badge/5_Lose_1.png';
    //   if (name == "패배요정 초급") return 'assets/imgs/badge/5_Lose_5.png';
    //   if (name == "패배요정 중급") return 'assets/imgs/badge/5_Lose_15.png';
    //   if (name == "패배요정 고급") return 'assets/imgs/badge/5_Lose_30.png';
    //   if (name == "지면 또 와요...") return 'assets/imgs/badge/5_Lose_50.png';
    //   if (name == "패배의 저주") return 'assets/imgs/badge/5_Lose_100.png';
    // }

    // 감정 수집
    // if (category == "감정 수집") {
    //   if (name == "짜릿함 중독") return 'assets/imgs/badge/6_Emotion_1.png';
    //   if (name == "만족의 미학") return 'assets/imgs/badge/6_Emotion_2.png';
    //   if (name == "감동주의보") return 'assets/imgs/badge/6_Emotion_3.png';
    //   if (name == "예측불가!") return 'assets/imgs/badge/6_Emotion_4.png';
    //   if (name == "행복전도사") return 'assets/imgs/badge/6_Emotion_5.png';
    //   if (name == "고구마 먹방") return 'assets/imgs/badge/6_Emotion_6.png';
    //   if (name == "조금만 더...") return 'assets/imgs/badge/6_Emotion_7.png';
    //   if (name == "분노의질주") return 'assets/imgs/badge/6_Emotion_8.png';
    //   if (name == "피로회복제") return 'assets/imgs/badge/6_Emotion_9.png';
    //   if (name == "감정수집가") return 'assets/imgs/badge/6_Emotion_All.png';
    // }

    return null;
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
    });
    try {
      final results = await Future.wait([
        ReportApi.getMainReport(),
        UserApi.getMyProfile(),
      ]);
      if (!mounted) return;

      setState(() {
        _reportData = results[0] as Map<String, dynamic>;

        print("=== 전체 reportData ===");
        print(_reportData);

        final userApiResponse = results[1] as Map<String, dynamic>;
        _userData = userApiResponse['data'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('❌ 리포트 데이터 로딩 실패: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '리포트 정보를 불러오는 데 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRecords = !_isLoading && _errorMessage == null &&
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
            // 홈 헤더 (고정)
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
                    child: Text(
                      '홈',
                      style: AppFonts.suite.h3_b(context).copyWith(
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 메인 콘텐츠 영역
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.pri500))
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
                    maxChildSize: 0.77,
                    builder: (BuildContext context, ScrollController scrollController) {
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
                            bottom: scaleHeight(40),
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
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      ),
    );
  }

  /// 카운트다운, 티켓 요약 카드
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
            style: AppFonts.suite.body_md_500(context).copyWith(color: AppColors.gray30),
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
                ...['D', 'A', 'Y'].map((char) => Padding(
                  padding: EdgeInsets.only(right: char != 'Y' ? scaleWidth(4) : 0),
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
              ] else ...[
                // 1~10일 때 숫자 표시
                ...List.generate(daysRemainingStr.length, (index) {
                  final bool isNumeric = int.tryParse(daysRemainingStr[index]) != null;
                  final Color textColor = (isDDay && isNumeric) ? AppColors.error : AppColors.gray900;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < daysRemainingStr.length - 1 ? scaleWidth(4) : 0,
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
                  dividerXPosition: (MediaQuery.of(context).size.width - scaleWidth(32)) * 0.7,
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
                                    borderRadius: BorderRadius.circular(scaleWidth(11.85)),
                                    border: Border.all(color: AppColors.gray100, width: 0.76),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(scaleWidth(11.85)),
                                    child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                                        ? Image.network(
                                      profileImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
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
                                      style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray800),
                                    ),
                                    if (favTeam != '응원팀 없음')
                                      Text(
                                        "$favTeam 팬",
                                        style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray300),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: scaleHeight(3)),

                            Align(
                              alignment: Alignment((0.36 * 2) - 1, 0),
                              child: Text(
                                "${totalWinRate % 1 == 0 ? totalWinRate.toInt() : totalWinRate.toStringAsFixed(1)}%",
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
                                style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray600, fontSize: 10.sp),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            SizedBox(height: scaleHeight(14)),

                            Align(
                              alignment: Alignment((0.29 * 2) - 1, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildWinLossDrawBadge(AppImages.win, totalWin),
                                  SizedBox(width: scaleWidth(10)),
                                  _buildWinLossDrawBadge(AppImages.tie, totalDraw),
                                  SizedBox(width: scaleWidth(10)),
                                  _buildWinLossDrawBadge(AppImages.lose, totalLose),
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
                                Expanded(child: _buildHomeAwayBox("홈", homeWinRate, homeWin, homeLose)),
                                SizedBox(height: scaleHeight(8)),
                                Expanded(child: _buildHomeAwayBox("원정", awayWinRate, awayWin, awayLose)),
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
                            style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray800),
                          ),
                          SizedBox(height: scaleHeight(10)),
                          Text(
                            "첫 직관을 기록하고 나의 승률 데이터를 확인해 보세요.",
                            style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600),
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
                                    style: AppFonts.suite.b2_b(context).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    AppImages.right_black,
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
          SvgPicture.asset(iconPath, width: scaleWidth(16), height: scaleHeight(16)),
          Container(
            width: scaleWidth(24),
            height: scaleHeight(18),
            alignment: Alignment.center,
            child: Text(
              count.toString(),
              style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.black),
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
            style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600),
          ),
          Expanded(
            child: Center(
              child: Text(
                "${rate % 1 == 0 ? rate.toInt() : rate.toStringAsFixed(1)}%",
                style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray600),
              ),
            ),
          ),
          Text(
            "${win}승 ${lose}패",
            style: AppFonts.suite.caption_md_400(context).copyWith(color: AppColors.gray400),
          ),
          SizedBox(height: scaleHeight(5)), // 승패 텍스트 아래 5px 위
        ],
      ),
    );
  }

  //이미지 저장
  Widget _buildImageSaveButton() {
    final totalGames = _reportData?['winRateInfo']?['totalGameCount'] ?? 0;
    final bool hasRecords = !_isLoading && _errorMessage == null && totalGames > 0;

    return GestureDetector(
      onTap: () {
        print("이미지 저장 버튼 클릭");
      },
      child: Container(
        width: scaleWidth(73),
        height: scaleHeight(26),
        decoration: BoxDecoration(
          color: hasRecords
              ? AppColors.pri100 // 기록이 있을 때: 기본 색상
              : AppColors.pri100.withOpacity(0.2), // 기록이 없을 때: 20% 투명도
          borderRadius: BorderRadius.circular(scaleWidth(16)),
        ),
        child: Center(
          child: Text(
            "이미지 저장",
            style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray800),
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
        Text(title, style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray700)),
        GestureDetector(
          onTap: onTap, // null이면 클릭 안 됨
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "자세히 보기",
                  style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray400),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: scaleWidth(10),
                  color: AppColors.gray400,
                ),
              ]
          ),
        ),
      ],
    );
  }

  /// 나의 뱃지 섹션
  Widget _buildBadgeSection({required bool hasRecords}) {
    final badgeSummary = _reportData?['badgeSummary'];
    final recentBadges = badgeSummary?['recentBadges'] as List<dynamic>? ?? [];

    // 사용자 최애구단 기반 초기 뱃지 이름 생성
    final favTeam = _userData?['favTeam'] as String? ?? 'NC 다이노스';
    final initialBadgeNames = _getInitialBadgeNames(favTeam);

    // 최대 5개 뱃지 리스트 구성
    List<Map<String, dynamic>> displayBadges = [];
    Set<String> addedBadgeNames = {};

    // 1. recentBadges를 정순으로 돌면서 최신 것부터 추가 (recentBadges가 최신순으로 정렬되어 있다고 가정)
    for (var badge in recentBadges) {
      final badgeMap = badge as Map<String, dynamic>;
      final name = badgeMap['name'] as String;
      if (!addedBadgeNames.contains(name) && displayBadges.length < 5) {
        displayBadges.add({
          'name': name,
          'imageUrl': badgeMap['imageUrl'],
          'category': badgeMap['category'],
          'isAchieved': true,
        });
        addedBadgeNames.add(name);
      }
    }

    // 2. 빈 자리가 있으면 디폴트 뱃지로 채우기 (5개까지)
    for (var badgeName in initialBadgeNames) {
      if (!addedBadgeNames.contains(badgeName) && displayBadges.length < 5) {
        // 뱃지 이름으로 카테고리 판단
        String? category;
        if (badgeName.contains('승리요정')) {
          category = '승리요정';
        }

        displayBadges.add({
          'name': badgeName,
          'imageUrl': null,
          'category': category,
          'isAchieved': false,
        });
        addedBadgeNames.add(badgeName);
      }
    }

    return Column(
      children: [
        _buildSectionHeader("나의 뱃지", onTap: hasRecords ? () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const BadgeScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } : null),
        SizedBox(height: scaleHeight(14)),
        Container(
          height: scaleHeight(110),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayBadges.length,
            separatorBuilder: (context, index) => SizedBox(width: scaleWidth(27)),
            itemBuilder: (context, index) {
              final badge = displayBadges[index];
              return _buildBadgeItem(
                  badge['imageUrl'],
                  badge['name'],
                  category: badge['category'],
                  isAchieved: badge['isAchieved'] ?? false
              );
            },
          ),
        ),
      ],
    );
  }

  // 최애구단 기반 초기 뱃지 이름 생성
  List<String> _getInitialBadgeNames(String favTeam) {
    final shortTeam = _convertFavTeam(favTeam);
    final homeStadium = _getHomeStadiumByTeam(shortTeam);

    return [
      '직관 5회',
      '$homeStadium 정복',
      '승리요정 입문',
      '$shortTeam 직관 5회',
      '패배요정 입문',
    ];
  }

  // 팀 이름을 짧은 코드로 변환
  String _convertFavTeam(String favTeam) {
    switch (favTeam) {
      case 'KIA 타이거즈': return 'KIA';
      case '두산 베어스': return '두산';
      case '롯데 자이언츠': return '롯데';
      case '삼성 라이온즈': return '삼성';
      case '키움 히어로즈': return '키움';
      case '한화 이글스': return '한화';
      case 'KT WIZ': return 'KT';
      case 'LG 트윈스': return 'LG';
      case 'NC 다이노스': return 'NC';
      case 'SSG 랜더스': return 'SSG';
      default: return favTeam;
    }
  }

  // 팀 코드 기반 홈구장 반환
  String _getHomeStadiumByTeam(String teamCode) {
    switch (teamCode) {
      case '두산':
      case 'LG':
        return '잠실';
      case '롯데': return '부산';
      case '삼성': return '대구';
      case '키움': return '고척';
      case '한화': return '대전';
      case 'KIA': return '광주';
      case 'KT': return '수원';
      case 'NC': return '창원';
      case 'SSG': return '인천';
      default: return '잠실';
    }
  }

  // 뱃지 아이템 위젯
  Widget _buildBadgeItem(String? imageUrl, String? name, {String? category, bool isAchieved = false}) {
    // 획득한 경우에만 카테고리별 에셋 경로 가져오기
    final assetPath = isAchieved ? _getBadgeAssetPath(category, name) : null;

    return SizedBox(
      width: scaleWidth(80),
      height: scaleHeight(108),
      child: Column(
        children: [
          SizedBox(
            width: scaleWidth(80),
            height: scaleHeight(80),
            child: Stack(
              children: [
                // 에셋이 있으면 에셋 표시, 없으면 polygon.svg 또는 circle.svg (승리요정 카테고리인 경우)
                if (assetPath != null)
                  Image.asset(
                    assetPath,
                    width: scaleWidth(79),
                    height: scaleHeight(79),
                    fit: BoxFit.contain,
                  )
                else
                  SvgPicture.asset(
                    category == "승리요정" ? 'assets/imgs/badge/circle.svg' : 'assets/imgs/badge/polygon.svg',
                    width: scaleWidth(79),
                    height: scaleHeight(79),
                    fit: BoxFit.contain,
                  ),
                // 획득한 뱃지 이미지 (imageUrl이 있는 경우, 에셋이 없을 때만)
                if (isAchieved && imageUrl != null && imageUrl.isNotEmpty && assetPath == null)
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_,__,___) => SizedBox(),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            name ?? '뱃지 이름',
            style: AppFonts.suite.body_sm_400(context).copyWith(
              color: isAchieved ? AppColors.gray900 : AppColors.gray300,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 기본 뱃지 아이콘 (기록 있을 때 이미지 로드 실패 시)
  Widget _defaultBadgeIcon() {
    return Center(child: Icon(Icons.shield_outlined, color: AppColors.gray300, size: scaleWidth(40)));
  }

  /// 나의 직관 기록 분석 섹션
  Widget _buildAnalysisSection({required bool hasRecords}) {
    final bestMonth = _reportData?['bestAttendanceMonth']?['month'];
    final topStadium = _reportData?['topStadium']?['stadiumName'];
    final topEmotionCode = _reportData?['topEmotion']?['emotionCode'];
    final topEmotionName = _reportData?['topEmotion']?['emotion'];

    return Column(
      children: [
        //잠시 자세히 보기 주석처리하고 수지 처리
        //_buildSectionHeader("나의 직관 기록 분석", onTap: hasRecords ? () { // 기록 있을 때만 활성화
        //} : null), // 기록 없으면 비활성화
        Align(
          alignment: Alignment.centerLeft,
          child: Text("나의 직관 기록 분석",
              style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray700)),
        ),
        // 나중에 위에 align 코드 삭제하고 _buildSectionHeader 주석 해제하기

        SizedBox(height: scaleHeight(16)),
        Row(
          children: [
            Expanded(child: _buildAnalysisCard(
              iconPath: AppImages.telescope,
              title: "최다 직관의 달",
              value: hasRecords ? (bestMonth != null ? "${bestMonth}월" : "-") : "????",
              isPlaceholder: !hasRecords,
            ),),
            SizedBox(width: scaleWidth(9)),
            Expanded(child: _buildAnalysisCard(
              iconPath: AppImages.location_marker,
              title: "최다 방문 지역",
              value: hasRecords ? (topStadium ?? "-") : "????",
              isPlaceholder: !hasRecords,
            ),),
            SizedBox(width: scaleWidth(9)),
            Expanded(child: _buildAnalysisCard(
              iconPath: _emotionImageMap[topEmotionCode] ?? AppImages.emotion_5_transparent,
              title: "최다 기록 감정",
              value: hasRecords ? (topEmotionName ?? "-") : "????",
              isPlaceholder: !hasRecords,
              emotionCodeForPlaceholder: hasRecords ? null : topEmotionCode, // 플레이스홀더 감정 아이콘 위해 전달
            ),),
          ],
        ),
      ],
    );
  }

  // 분석 카드 위젯
  Widget _buildAnalysisCard({
    required String iconPath,
    required String title,
    required String value,
    bool isPlaceholder = false,
    int? emotionCodeForPlaceholder,
  }) {
    // 플레이스홀더일 경우 아이콘 경로 처리
    String displayIconPath = iconPath;
    if (isPlaceholder && title == "최다 기록 감정") {
      displayIconPath = AppImages.emotion_5_transparent; // 감정 플레이스홀더 아이콘 경로로 변경
    }
    // SVG 확장자 확인 및 추가
    if (!displayIconPath.endsWith('.svg') && !displayIconPath.contains('/ic_emotion/')) {
      displayIconPath += '.svg';
    }

    // 플레이스홀더일 때 투명도 적용
    final double opacity = isPlaceholder ? 0.2 : 1.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(14)),
      decoration: BoxDecoration(
        color: AppColors.gray50, // 배경색은 동일
        borderRadius: BorderRadius.circular(scaleWidth(12)),
      ),
      child: Opacity( // 전체 내용 투명도 조절
        opacity: opacity,
        child: Column(
          children: [
            // 아이콘
            SvgPicture.asset(displayIconPath, width: scaleWidth(40), height: scaleHeight(40)),
            SizedBox(height: scaleHeight(8)),
            // 제목
            Text(title, style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray700)),
            SizedBox(height: scaleHeight(8)),
            // 값 (태그)
            Container(
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(14), vertical: scaleHeight(3)),
              decoration: BoxDecoration(
                color: AppColors.pri800,
                borderRadius: BorderRadius.circular(scaleWidth(6)),
              ),
              child: Text(
                value, // "????", "5월", "잠실" 등
                style: AppFonts.suite.caption_md_500(context).copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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