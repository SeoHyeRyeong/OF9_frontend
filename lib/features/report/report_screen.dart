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
                  // 카운트다운 섹션
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

  /// 카운트다운, 요약 카드
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
              // D 박스 (기존과 동일)
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
              // 하이픈 (기존과 동일)
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
              // 숫자 박스들 (기존과 동일)
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
          ),
          SizedBox(height: scaleHeight(33)),
          _buildSummaryCard(hasRecords: hasRecords),
          SizedBox(height: scaleHeight(22)),
          _buildImageSaveButton(),
        ],
      ),
    );
  }

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
                  dividerXPosition: (MediaQuery.of(context).size.width - scaleWidth(32)) * 0.685,
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
                                SizedBox(width: scaleWidth(8)),
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
                            SizedBox(height: scaleHeight(5)),

                            Padding(
                              padding: EdgeInsets.only(left: scaleWidth(33)),
                              child: Text(
                                "${totalWinRate.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontFamily: AppFonts.suiteFontFamily,
                                  fontSize: 42.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray800,
                                  height: 1.6,
                                  letterSpacing: -0.84,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(left: scaleWidth(43)),
                              child: Text(
                                "총 ${totalGames}회의 경기를 관람했어요",
                                style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray600, fontSize: 10.sp),
                                textAlign: TextAlign.start,
                              ),
                            ),

                            SizedBox(height: scaleHeight(14)),

                            Padding(
                              padding: EdgeInsets.only(left: scaleWidth(16)),
                              child: Row(
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
                    dividerXPosition: (MediaQuery.of(context).size.width - scaleWidth(32)) * 0.685,
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TicketOcrScreen(),
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
                "${rate.toStringAsFixed(1)}%",
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

  // 나의 뱃지 섹션
  Widget _buildBadgeSection({required bool hasRecords}) { // hasRecords 파라미터 추가
    final badgeSummary = _reportData?['badgeSummary'];
    final recentBadges = badgeSummary?['recentBadges'] as List<dynamic>? ?? [];
    // 기록이 없을 때 보여줄 플레이스홀더 뱃지 정보 (3개)
    final placeholderBadges = [
      {'imageUrl': null, 'name': '직관 1회'},
      {'imageUrl': null, 'name': '창원 정복'},
      {'imageUrl': null, 'name': '승리요정 입문'},
    ];
    // 표시할 뱃지 리스트 결정
    final badgesToShow = hasRecords ? recentBadges : placeholderBadges;

    return Column(
      children: [
        _buildSectionHeader("나의 뱃지", onTap: hasRecords ? () { // 기록이 있을 때만 자세히 보기 활성화
          // TODO: 뱃지 전체보기 화면으로 이동 (BadgeReportScreen?)
          print("뱃지 자세히 보기 클릭");
        } : null), // 기록 없으면 onTap 비활성화
        SizedBox(height: scaleHeight(16)),
        Container( // 높이 고정 (플레이스홀더도 동일 높이 차지)
          height: scaleHeight(110),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // itemCount를 badgesToShow 길이로 설정
            itemCount: badgesToShow.length > 3 ? 3: badgesToShow.length, // 최대 3개까지만 보여주도록 제한 (또는 스크롤 유지)
            separatorBuilder: (context, index) => SizedBox(width: scaleWidth(16)),
            itemBuilder: (context, index) {
              final badge = badgesToShow[index] as Map<String, dynamic>;
              // 기록 없을 때는 플레이스홀더 스타일 적용
              return _buildBadgeItem(badge['imageUrl'], badge['name'], isPlaceholder: !hasRecords);
            },
          ),
        ),
      ],
    );
  }

  // 섹션 헤더 (제목 + 자세히 보기)
  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray800)),
        // onTap이 null이면 비활성화된 것처럼 보이게 처리 (색상 변경 등)
        GestureDetector(
          onTap: onTap, // null이면 클릭 안 됨
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "자세히 보기",
                  // onTap이 null이면 회색으로 비활성화 표시
                  style: AppFonts.suite.caption_md_500(context).copyWith(color: onTap != null ? AppColors.gray400 : AppColors.gray200),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: scaleWidth(10),
                  // onTap이 null이면 회색으로 비활성화 표시
                  color: onTap != null ? AppColors.gray400 : AppColors.gray200,
                ),
              ]
          ),
        ),
      ],
    );
  }

  // 뱃지 아이템 위젯
  Widget _buildBadgeItem(String? imageUrl, String? name, {bool isPlaceholder = false}) { // isPlaceholder 파라미터 추가
    return SizedBox(
      width: scaleWidth(80),
      child: Column(
        children: [
          Container(
            width: scaleWidth(80),
            height: scaleHeight(80),
            decoration: BoxDecoration(
              // 플레이스홀더일 경우 회색 배경, 아니면 gray50
              color: isPlaceholder ? AppColors.gray100 : AppColors.gray50,
              // TODO: 플레이스홀더는 육각형 모양 필요 - ClipPath 또는 외부 패키지 사용
              shape: isPlaceholder ? BoxShape.circle : BoxShape.rectangle, // 임시로 원형 처리
              borderRadius: isPlaceholder ? null : BorderRadius.circular(scaleWidth(12)),
            ),
            child: isPlaceholder
                ? null // 플레이스홀더는 내부 비움
                : imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                borderRadius: BorderRadius.circular(scaleWidth(12)),
                child: Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_,__,___) => _defaultBadgeIcon())
            )
                : _defaultBadgeIcon(),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            name ?? '뱃지 이름',
            // 플레이스홀더일 경우 회색 글씨
            style: AppFonts.suite.body_sm_400(context).copyWith(color: isPlaceholder ? AppColors.gray400 : AppColors.gray900),
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

  // 나의 직관 기록 분석 섹션
  Widget _buildAnalysisSection({required bool hasRecords}) { // hasRecords 파라미터 추가
    final bestMonth = _reportData?['bestAttendanceMonth']?['month'];
    final topStadium = _reportData?['topStadium']?['stadiumName'];
    final topEmotionCode = _reportData?['topEmotion']?['emotionCode'];
    final topEmotionName = _reportData?['topEmotion']?['emotion'];

    return Column(
      children: [
        _buildSectionHeader("나의 직관 기록 분석", onTap: hasRecords ? () { // 기록 있을 때만 활성화
          // TODO: 분석 상세보기 화면 이동 구현
          print("분석 자세히 보기 클릭");
        } : null), // 기록 없으면 비활성화
        SizedBox(height: scaleHeight(16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // hasRecords 값에 따라 카드 내용 다르게 표시
            _buildAnalysisCard(
              iconPath: AppImages.telescope,
              title: "최다 직관의 달",
              value: hasRecords ? (bestMonth != null ? "${bestMonth}월" : "-") : "????", // 기록 없으면 ????
              isPlaceholder: !hasRecords, // 플레이스홀더 여부 전달
            ),
            _buildAnalysisCard(
              iconPath: AppImages.location_marker,
              title: "최다 방문 지역",
              value: hasRecords ? (topStadium ?? "-") : "????", // 기록 없으면 ????
              isPlaceholder: !hasRecords,
            ),
            _buildAnalysisCard(
              iconPath: _emotionImageMap[topEmotionCode] ?? AppImages.etc, // 아이콘은 그대로 두거나 기본 아이콘 표시
              title: "최다 기록 감정",
              value: hasRecords ? (topEmotionName ?? "-") : "????", // 기록 없으면 ????
              isPlaceholder: !hasRecords,
              emotionCodeForPlaceholder: hasRecords ? null : topEmotionCode, // 플레이스홀더 감정 아이콘 위해 전달
            ),
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
    bool isPlaceholder = false, // 플레이스홀더 여부 파라미터
    int? emotionCodeForPlaceholder, // 플레이스홀더 감정 아이콘 위한 코드
  }) {
    // 플레이스홀더일 경우 아이콘 경로 처리
    String displayIconPath = iconPath;
    if (isPlaceholder && title == "최다 기록 감정") {
      // TODO: 플레이스홀더 감정 아이콘 디자인 정의 필요 (임시로 ? 아이콘)
      displayIconPath = AppImages.etc; // 감정 플레이스홀더 아이콘 경로로 변경
    }
    // SVG 확장자 확인 및 추가
    if (!displayIconPath.endsWith('.svg') && !displayIconPath.contains('/ic_emotion/')) {
      displayIconPath += '.svg';
    }

    // 플레이스홀더일 때 투명도 적용
    final double opacity = isPlaceholder ? 0.2 : 1.0;

    return Container(
      width: scaleWidth(101),
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
            Text(title, style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray800)),
            SizedBox(height: scaleHeight(8)),
            // 값 (태그)
            Container(
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(14), vertical: scaleHeight(3)),
              decoration: BoxDecoration(
                color: const Color(0xFF354E66), // 태그 배경색은 동일
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
