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
import 'dart:ui'; // BackdropFilter 사용을 위해 import

// TODO: 뱃지 전체보기, 분석 상세보기 페이지 import 필요
// import 'badge_report_screen.dart';
// import 'analysis_detail_screen.dart';


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
    if (!mounted) return; // 위젯 unmount 시 중단
    // 이미 로딩 중이면 중복 호출 방지 (선택 사항)
    // if (_isLoading) return;

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
    // totalGames 값 확인 (로딩 완료 후, 에러 없을 때)
    final bool hasRecords = !_isLoading && _errorMessage == null && (_reportData?['winRateInfo']?['totalGameCount'] ?? 0) > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.pri500))
          : _errorMessage != null
          ? _buildErrorWidget(_errorMessage!)
          : RefreshIndicator(
        onRefresh: _loadReportData,
        color: AppColors.pri500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildCountdownSection(hasRecords: hasRecords), // hasRecords 전달
              _buildReportContent(hasRecords: hasRecords),   // hasRecords 전달
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  // 에러 발생 시 표시할 위젯
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48.sp),
          SizedBox(height: 16.h),
          Text(message, style: AppFonts.suite.body_sm_400(context)),
          SizedBox(height: 16.h),
          ElevatedButton(
              onPressed: _loadReportData,
              child: Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pri500,
                foregroundColor: Colors.white,
              )
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text('홈', style: AppFonts.suite.title_lg_700(context).copyWith(color: Colors.black)),
      centerTitle: false,
      actions: [
        GestureDetector(
          onTap: () {
            // TODO: 전체보기 화면 이동 구현 (필터?)
            print("전체보기 클릭");
          },
          child: Padding(
            padding: EdgeInsets.only(right: scaleWidth(20)),
            child: Row(
              children: [
                Text(
                  " ",//"전체",
                  style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray400),
                ),
                SizedBox(width: scaleWidth(4)),
                Icon(Icons.arrow_forward_ios, size: scaleWidth(12), color: AppColors.gray400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 상단 어두운 배경 섹션 (카운트다운, 요약 카드)
  Widget _buildCountdownSection({required bool hasRecords}) { // hasRecords 파라미터 추가
    final seasonInfo = _reportData?['seasonInfo'];
    final message = seasonInfo?['message'] ?? '시즌 정보 없음';
    final daysRemaining = seasonInfo?['daysRemaining'] ?? 0;
    String dDayStr = daysRemaining.toString().padLeft(2, '0');
    String dDay1 = dDayStr[0];
    String dDay2 = dDayStr[1];

    return Container(
      width: double.infinity,
      color: AppColors.gray900,
      padding: EdgeInsets.symmetric(vertical: scaleHeight(24)),
      child: Column(
        children: [
          Text(
            message,
            style: AppFonts.suite.body_md_500(context).copyWith(color: AppColors.gray30),
          ),
          SizedBox(height: scaleHeight(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDDayBox("D"),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleWidth(4)),
                child: Container(
                  width: scaleWidth(10),
                  height: scaleHeight(4),
                  decoration: BoxDecoration(
                    color: AppColors.gray30,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              _buildDDayBox(dDay1),
              SizedBox(width: scaleWidth(4)),
              _buildDDayBox(dDay2),
            ],
          ),
          SizedBox(height: scaleHeight(32)),
          // ▼▼▼ hasRecords 값에 따라 다른 카드 표시
          hasRecords ? _buildSummaryCard() : _buildNoRecordCard(),
          // ▲▲▲
          SizedBox(height: scaleHeight(16)),
          // 이미지 저장 버튼은 기록 유무와 상관없이 표시 (디자인 참고)
          _buildImageSaveButton(),
        ],
      ),
    );
  }

  // D-Day 숫자 표시 박스
  Widget _buildDDayBox(String text) {
    // TODO: Jalnan 폰트 추가 및 AppFonts에 정의
    TextStyle dDayStyle = TextStyle(
      fontFamily: 'Jalnan',
      fontSize: 30.sp,
      color: AppColors.gray900,
      height: 1.2,
      letterSpacing: -1,
    );

    return Container(
      width: scaleWidth(38),
      height: scaleHeight(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleWidth(5)),
      ),
      alignment: Alignment.center,
      child: Text(text, style: dDayStyle),
    );
  }

  // 사용자 승률 요약 카드 (기록 있을 때)
  Widget _buildSummaryCard() {
    // ... (기존 _buildSummaryCard 코드 내용과 동일) ...
    // (이전 답변 코드 복사)
    final winRateInfo = _reportData?['winRateInfo'];
    final totalWinRate = winRateInfo?['totalWinRate'] ?? 0.0;
    final totalWin = winRateInfo?['totalWinCount'] ?? 0;
    final totalLose = winRateInfo?['totalLoseCount'] ?? 0;
    final totalDraw = winRateInfo?['totalDrawCount'] ?? 0;
    final totalGames = winRateInfo?['totalGameCount'] ?? 0;
    final homeWinRate = winRateInfo?['homeWinRate'] ?? 0.0;
    final homeWin = winRateInfo?['homeWinCount'] ?? 0;
    final homeLose = winRateInfo?['homeLoseCount'] ?? 0;
    final homeDraw = 0; // API에 homeDrawCount 없으므로 0으로 가정
    final awayWinRate = winRateInfo?['awayWinRate'] ?? 0.0;
    final awayWin = winRateInfo?['awayWinCount'] ?? 0;
    final awayLose = winRateInfo?['awayLoseCount'] ?? 0;
    final awayDraw = 0; // API에 awayDrawCount 없으므로 0으로 가정

    final nickname = _userData?['nickname'] ?? '사용자';
    final favTeam = _userData?['favTeam'] ?? '응원팀 없음';
    final profileImageUrl = _userData?['profileImageUrl'];


    return Container(
      width: scaleWidth(320), // 가로 크기 지정 (360 - 좌우 패딩 20*2)
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20), vertical: scaleHeight(24)), // 내부 패딩
      decoration: BoxDecoration(
        color: Colors.white, // 배경 흰색
        borderRadius: BorderRadius.circular(scaleWidth(16)), // 둥근 모서리
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬
        children: [
          // 왼쪽: 프로필, 승률, 경기수, 승무패
          Expanded( // 남은 공간 모두 차지
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
              children: [
                Row(
                  children: [
                    // 프로필 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(scaleWidth(16)), // SwiftUI 코드엔 11.85, 디자인은 더 둥글어 보임. 16 정도로 조정
                      child: Container(
                        width: scaleWidth(32),
                        height: scaleHeight(32),
                        color: AppColors.gray100, // 이미지 로딩 전 배경
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? Image.network(profileImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultProfileIcon())
                            : _defaultProfileIcon(), // 기본 이미지
                      ),
                    ),
                    SizedBox(width: scaleWidth(8)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname, style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray900)), // 변경된 스타일 (12pt Medium)
                        if (favTeam != '응원팀 없음')
                          Text("$favTeam 팬", style: AppFonts.suite.caption_md_400(context).copyWith(color: AppColors.gray500)), // 변경된 스타일 (10pt Regular)
                      ],
                    ),
                  ],
                ),
                SizedBox(height: scaleHeight(16)), // 프로필과 승률 사이 간격
                Text(
                  "${totalWinRate.toStringAsFixed(1)}%", // 소수점 첫째 자리
                  style: TextStyle( // SwiftUI 코드는 SUITE 42 Bold, 해당 스타일 없으므로 직접 정의
                      fontFamily: AppFonts.suiteFontFamily,
                      fontSize: 42.sp, // 42pt
                      fontWeight: FontWeight.w700, // Bold
                      color: AppColors.gray800, // SwiftUI 코드엔 38414C (gray700과 유사하나 gray800 사용)
                      height: 1.2, // 라인 높이 조절
                      letterSpacing: -1.26 // 자간 조절 (42 * -0.03)
                  ),
                ),
                SizedBox(height: scaleHeight(4)), // 승률과 경기수 사이 간격
                Text(
                  "총 ${totalGames}회의 경기를 관람했어요",
                  style: AppFonts.suite.caption_md_400(context).copyWith(color: AppColors.gray600), // 변경된 스타일 (10pt Regular)
                ),
                SizedBox(height: scaleHeight(16)), // 경기수와 뱃지 사이 간격
                Row( // 승/패/무 뱃지
                  children: [
                    _buildWinLossDrawBadge(AppImages.win, totalWin), // 승
                    SizedBox(width: scaleWidth(10)),
                    _buildWinLossDrawBadge(AppImages.lose, totalLose), // 패
                    SizedBox(width: scaleWidth(10)),
                    _buildWinLossDrawBadge(AppImages.tie, totalDraw), // 무
                  ],
                ),
              ],
            ),
          ),
          // TODO: 구분선 (세로 점선) 구현 필요
          SizedBox(width: scaleWidth(16)), // 임시 간격
          // 오른쪽: 홈/어웨이 승률
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 위 아래 간격 벌리기
            children: [
              _buildHomeAwayBox("홈", homeWinRate, homeWin, homeLose, homeDraw),
              SizedBox(height: scaleHeight(8)), // 홈/어웨이 박스 사이 간격
              _buildHomeAwayBox("원정", awayWinRate, awayWin, awayLose, awayDraw),
            ],
          ),
        ],
      ),
    );
  }

  // ▼▼▼ [새 함수 추가] 기록 없을 때 보여줄 카드
  Widget _buildNoRecordCard() {
    return Container(
      width: scaleWidth(320),
      height: scaleHeight(187), // _buildSummaryCard 높이와 비슷하게 맞춤 (디자인 측정 필요)
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // 반투명 흰색 배경 (추정)
        borderRadius: BorderRadius.circular(scaleWidth(16)),
      ),
      // 블러 효과 적용
      child: ClipRRect( // BackdropFilter는 ClipRRect 내부에 적용해야 함
        borderRadius: BorderRadius.circular(scaleWidth(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // 블러 강도 조절
          child: Container(
            // 블러 필터 적용 후 내용물 배치
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20), vertical: scaleHeight(24)),
            alignment: Alignment.center, // 내용물 중앙 정렬
            decoration: BoxDecoration(
              color: Colors.transparent, // 블러 효과를 위해 투명하게
              borderRadius: BorderRadius.circular(scaleWidth(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
              children: [
                Text(
                  "첫 직관 기록을 시작해 보세요!",
                  // style: AppFonts.suite.b1_sb(context).copyWith(color: AppColors.gray900), // SwiftUI 코드엔 SUITE 18 Semibold
                  style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray900), // 변경된 스타일 (18pt Semibold)
                ),
                SizedBox(height: scaleHeight(8)), // 텍스트 사이 간격
                Text(
                  "첫 직관을 기록하고 나의 승률 데이터를 확인해 보세요.",
                  // style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray700), // SwiftUI 코드엔 SUITE 12 Medium
                  style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray700), // 변경된 스타일 (12pt Medium)
                  textAlign: TextAlign.center, // 중앙 정렬
                ),
                SizedBox(height: scaleHeight(20)), // 텍스트와 버튼 사이 간격
                ElevatedButton(
                  onPressed: () {
                    // TODO: 직관 기록 화면으로 이동
                    print("직관 기록하러 가기 클릭");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray800, // SwiftUI 코드엔 38414C (gray700과 유사)
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleWidth(16)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(18), vertical: scaleHeight(14)), // 버튼 패딩 (디자인 참고)
                    minimumSize: Size(scaleWidth(178), scaleHeight(44)), // 버튼 최소 크기
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞춤
                    children: [
                      // Text("직관 기록하러 가기", style: AppFonts.suite.b2_b(context)), // SwiftUI 코드엔 SUITE 16 Bold
                      Text("직관 기록하러 가기", style: AppFonts.suite.body_md_500(context).copyWith(fontWeight: FontWeight.w700)), // body_md_500 + Bold
                      SizedBox(width: scaleWidth(2)),
                      Icon(Icons.arrow_forward_ios, size: scaleWidth(14)), // > 아이콘
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ▲▲▲ [새 함수 추가]

  // 기본 프로필 아이콘
  Widget _defaultProfileIcon() {
    return Padding(
      padding: EdgeInsets.all(scaleWidth(4)),
      child: SvgPicture.asset(AppImages.profile),
    );
  }

  // 승/무/패 뱃지 위젯
  Widget _buildWinLossDrawBadge(String iconPath, int count) {
    if (!iconPath.endsWith('.svg')) iconPath += '.svg';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: scaleWidth(10), vertical: scaleHeight(2)),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleWidth(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(iconPath, width: scaleWidth(16.5), height: scaleHeight(16.5)),
          SizedBox(width: scaleWidth(4)),
          Text(count.toString(), style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.black)),
        ],
      ),
    );
  }

  // 홈/어웨이 승률 박스 위젯
  Widget _buildHomeAwayBox(String title, double rate, int win, int lose, int draw) {
    return Container(
      width: scaleWidth(72),
      padding: EdgeInsets.symmetric(vertical: scaleHeight(8)),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(scaleWidth(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray600)),
          SizedBox(height: scaleHeight(4)),
          Text(
            "${rate.toStringAsFixed(1)}%",
            style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray800),
          ),
          SizedBox(height: scaleHeight(2)),
          Text(
            "${win}승 ${lose}패",
            style: AppFonts.suite.caption_md_400(context).copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  // 이미지 저장 버튼
  Widget _buildImageSaveButton() {
    return GestureDetector(
      onTap: () {
        // TODO: 이미지 저장 로직 구현 (screenshot 패키지 + gallery_saver 등 활용)
        print("이미지 저장 버튼 클릭");
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(12), vertical: scaleHeight(6)),
        decoration: BoxDecoration(
          color: AppColors.pri100,
          borderRadius: BorderRadius.circular(scaleWidth(16)),
        ),
        child: Text(
          "이미지 저장",
          style: AppFonts.suite.caption_md_500(context).copyWith(color: AppColors.gray900),
        ),
      ),
    );
  }

  // 리포트 주요 내용 섹션 (뱃지, 분석 등) - 하얀 배경 부분
  Widget _buildReportContent({required bool hasRecords}) { // hasRecords 파라미터 추가
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(scaleWidth(20)),
          topRight: Radius.circular(scaleWidth(20)),
        ),
      ),
      padding: EdgeInsets.only(
        top: scaleHeight(32),
        left: scaleWidth(20),
        right: scaleWidth(20),
      ),
      transform: Matrix4.translationValues(0.0, -scaleHeight(20.0), 0.0), // 위로 올림
      child: Column(
        children: [
          _buildBadgeSection(hasRecords: hasRecords),     // hasRecords 전달
          SizedBox(height: scaleHeight(40)),
          _buildAnalysisSection(hasRecords: hasRecords),  // hasRecords 전달
          SizedBox(height: scaleHeight(40)), // 하단 추가 여백
        ],
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

// SliverPersistentHeaderDelegate는 탭바 고정용
class _MyPageTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _MyPageTabBarDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: shrinkOffset > 0 ? 1.0 : 0.0,
      child: Container(
        color: Colors.white,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_MyPageTabBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}