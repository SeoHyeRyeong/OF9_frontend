import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/api/report_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/report/report_screen.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({Key? key}) : super(key: key);

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  Map<String, dynamic>? _badgeData;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBadgeData();
  }

  Future<void> _loadBadgeData() async {
    try {
      final badgeData = await ReportApi.getBadgeStatus();
      if (mounted) {
        setState(() {
          _badgeData = badgeData;
        });
      }
    } catch (e) {
      print('❌ 배지 데이터 로딩 실패: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userApi = await UserApi.getMyProfile();
      if (mounted) {
        setState(() {
          _userData = userApi['data'] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('❌ 사용자 데이터 로딩 실패: $e');
    }
  }

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

  // 동적으로 뱃지 목록 생성
  Map<String, List<Map<String, String>>> _getAllBadges() {
    final favTeam = _userData?['favTeam'] as String? ?? 'NC 다이노스';
    final shortTeam = _convertFavTeam(favTeam);

    return {
      "구단 도장깨기": [
        {"name": "잠실 정복", "assetPath": "assets/imgs/badge/1_Jamsil.png"},
        {"name": "고척 정복", "assetPath": "assets/imgs/badge/1_Gocheok.png"},
        {"name": "부산 정복", "assetPath": "assets/imgs/badge/1_Busan.png"},
        {"name": "대구 정복", "assetPath": "assets/imgs/badge/1_Daegu.png"},
        {"name": "광주 정복", "assetPath": "assets/imgs/badge/1_Gwangju.png"},
        {"name": "대전 정복", "assetPath": "assets/imgs/badge/1_Daejeon.png"},
        {"name": "창원 정복", "assetPath": "assets/imgs/badge/1_Changwon.png"},
        {"name": "인천 정복", "assetPath": "assets/imgs/badge/1_Incheon.png"},
        {"name": "수원 정복", "assetPath": "assets/imgs/badge/1_Suwon.png"},
      ],
      "직관 기록수": [
        {"name": "직관 5회", "assetPath": "assets/imgs/badge/2_5.png"},
        {"name": "직관 10회", "assetPath": "assets/imgs/badge/2_10.png"},
        {"name": "직관 25회", "assetPath": "assets/imgs/badge/2_25.png"},
        {"name": "직관 50회", "assetPath": "assets/imgs/badge/2_50.png"},
        {"name": "직관 75회", "assetPath": "assets/imgs/badge/2_75.png"},
        {"name": "직관 100회", "assetPath": "assets/imgs/badge/2_100.png"},
      ],
      "$shortTeam 직관 기록수": [
        {"name": "$shortTeam 직관 5회", "assetPath": "assets/imgs/badge/3_${shortTeam}_5.png"},
        {"name": "$shortTeam 직관 10회", "assetPath": "assets/imgs/badge/3_${shortTeam}_10.png"},
        {"name": "$shortTeam 직관 25회", "assetPath": "assets/imgs/badge/3_${shortTeam}_25.png"},
        {"name": "$shortTeam 직관 50회", "assetPath": "assets/imgs/badge/3_${shortTeam}_50.png"},
        {"name": "$shortTeam 직관 75회", "assetPath": "assets/imgs/badge/3_${shortTeam}_75.png"},
        {"name": "$shortTeam 직관 100회", "assetPath": "assets/imgs/badge/3_${shortTeam}_100.png"},
      ],
      "승리요정": [
        {"name": "승리요정 입문", "assetPath": "assets/imgs/badge/4_Win_1.png"},
        {"name": "승리요정 초급", "assetPath": "assets/imgs/badge/4_Win_5.png"},
        {"name": "승리요정 중급", "assetPath": "assets/imgs/badge/4_Win_15.png"},
        {"name": "승리요정 고급", "assetPath": "assets/imgs/badge/4_Win_30.png"},
        {"name": "승리는 나의 것", "assetPath": "assets/imgs/badge/4_Win_50.png"},
        {"name": "KBO는 내 손에", "assetPath": "assets/imgs/badge/4_Win_100.png"},
      ],
      "패배요정": [
        {"name": "패배요정 입문", "assetPath": "assets/imgs/badge/5_Lose_1.png"},
        {"name": "패배요정 초급", "assetPath": "assets/imgs/badge/5_Lose_5.png"},
        {"name": "패배요정 중급", "assetPath": "assets/imgs/badge/5_Lose_15.png"},
        {"name": "패배요정 고급", "assetPath": "assets/imgs/badge/5_Lose_30.png"},
        {"name": "지면 또 와요...", "assetPath": "assets/imgs/badge/5_Lose_50.png"},
        {"name": "패배의 저주", "assetPath": "assets/imgs/badge/5_Lose_100.png"},
      ],
      "감정 수집": [
        {"name": "짜릿함 중독", "assetPath": "assets/imgs/badge/6_Emotion_1.png"},
        {"name": "만족의 미학", "assetPath": "assets/imgs/badge/6_Emotion_2.png"},
        {"name": "감동주의보", "assetPath": "assets/imgs/badge/6_Emotion_3.png"},
        {"name": "예측불가!", "assetPath": "assets/imgs/badge/6_Emotion_4.png"},
        {"name": "행복전도사", "assetPath": "assets/imgs/badge/6_Emotion_5.png"},
        {"name": "고구마 먹방", "assetPath": "assets/imgs/badge/6_Emotion_6.png"},
        {"name": "조금만 더...", "assetPath": "assets/imgs/badge/6_Emotion_7.png"},
        {"name": "분노의질주", "assetPath": "assets/imgs/badge/6_Emotion_8.png"},
        {"name": "피로회복제", "assetPath": "assets/imgs/badge/6_Emotion_9.png"},
        {"name": "감정수집가", "assetPath": "assets/imgs/badge/6_Emotion_All.png"},
      ],
    };
  }


  // 특정 뱃지가 획득되었는지 확인
  bool _isBadgeAchieved(String categoryName, String badgeName) {
    if (_badgeData == null) return false;

    final badgeCategories = _badgeData!['categories'] as List? ?? [];

    for (final categoryData in badgeCategories) {
      final category = categoryData['name'] as String? ?? '';
      if (category == categoryName) {
        final badges = categoryData['badges'] as List? ?? [];
        for (final badge in badges) {
          final name = badge['name'] as String? ?? '';
          final isAchieved = badge['achieved'] as bool? ?? false;
          if (name == badgeName && isAchieved) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. 헤더 영역 (고정)
            Container(
              width: double.infinity,
              height: scaleHeight(60),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation1, animation2) => const ReportScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      child: Container(
                        width: scaleHeight(24),
                        height: scaleHeight(24),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          AppImages.backBlack,
                          width: scaleHeight(24),
                          height: scaleHeight(24),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "나의 뱃지",
                          style: AppFonts.suite.head_sm_700(context).copyWith(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: scaleHeight(24),
                      height: scaleHeight(24),
                    ),
                  ],
                ),
              ),
            ),

            // 2. 스크롤 영역 (헤더 바로 아래부터 시작)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 아래 10px 간격
                    SizedBox(height: scaleHeight(10)),

                    // 직관 기록 독려
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Container(
                        width: double.infinity,
                        height: scaleHeight(90),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(scaleWidth(12)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "직관을 기록하고",
                                      style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray700),
                                    ),
                                    SizedBox(height: scaleHeight(4)),
                                    Text(
                                      "더 많은 배지를 모아 보세요!",
                                      style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray900),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  AppImages.party,
                                  width: scaleWidth(48),
                                  height: scaleHeight(48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 독려 영역과 배지 제목 사이 간격 줄이기
                    SizedBox(height: scaleHeight(16)), // 20에서 16으로 줄임

                    // 보유한 배지 제목
                    Padding(
                      padding: EdgeInsets.only(left: scaleWidth(20)),
                      child: Row(
                        children: [
                          Text(
                            "보유한 배지",
                            style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray900),
                          ),
                          SizedBox(width: scaleWidth(6)),
                          Text(
                            "${_badgeData?['myBadgeCount'] ?? 0}",
                            style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.pri700),
                          ),
                        ],
                      ),
                    ),

                    // 배지 목록
                    _buildAllBadgeCategories(),
                    SizedBox(height: scaleHeight(40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // 모든 뱃지 카테고리별 배치
  Widget _buildAllBadgeCategories() {
    final allBadges = _getAllBadges();
    final categoryNames = allBadges.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int categoryIndex = 0; categoryIndex < categoryNames.length; categoryIndex++)
          _buildCategorySection(
              categoryNames[categoryIndex],
              allBadges[categoryNames[categoryIndex]]!,
              categoryIndex == categoryNames.length - 1
          ),
      ],
    );
  }

  // 각 카테고리 섹션 빌드
  Widget _buildCategorySection(String categoryName, List<Map<String, String>> badges, bool isLastCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 제목
        SizedBox(height: scaleHeight(16)),
        Padding(
          padding: EdgeInsets.only(left: scaleWidth(20)),
          child: Text(
            categoryName,
            style: AppFonts.suite.body_sm_500(context).copyWith(color: AppColors.gray700),
          ),
        ),

        // 뱃지 그리드 (3개씩 배치)
        SizedBox(height: scaleHeight(12)),
        _buildBadgeGrid(categoryName, badges),

        // 마지막 카테고리가 아니면 구분선 추가
        if (!isLastCategory) ...[
          SizedBox(height: scaleHeight(28)),
          Container(
            width: double.infinity,
            height: scaleHeight(8),
            color: AppColors.gray30,
          ),
          SizedBox(height: scaleHeight(14)),
        ],
      ],
    );
  }

  // 뱃지 그리드 (3개씩 배치)
  Widget _buildBadgeGrid(String categoryName, List<Map<String, String>> badges) {
    List<Widget> rows = [];

    for (int i = 0; i < badges.length; i += 3) {
      List<Widget> rowItems = [];

      for (int j = 0; j < 3 && i + j < badges.length; j++) {
        final badge = badges[i + j];
        rowItems.add(_buildBadgeItem(categoryName, badge));
      }

      // 부족한 자리는 빈 공간으로 채우기
      while (rowItems.length < 3) {
        rowItems.add(SizedBox(width: scaleWidth(80)));
      }

      rows.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rowItems,
          ),
        ),
      );

      // 행 간격
      if (i + 3 < badges.length) {
        rows.add(SizedBox(height: scaleHeight(18)));
      }
    }

    return Column(children: rows);
  }

  // 뱃지 아이템
  Widget _buildBadgeItem(String categoryName, Map<String, String> badge) {
    final name = badge['name']!;
    final assetPath = badge['assetPath']!;
    final isAchieved = _isBadgeAchieved(categoryName, name);

    return Container(
      width: scaleWidth(80),
      height: scaleHeight(110),
      child: Column(
        children: [
          SizedBox(
            width: scaleWidth(80),
            height: scaleHeight(80),
            child: isAchieved
                ? Image.asset(
              assetPath,
              width: scaleWidth(80),
              height: scaleHeight(80),
              fit: BoxFit.cover,
            )
                : SvgPicture.asset(
              'assets/imgs/badge/polygon.svg',
              width: scaleWidth(80),
              height: scaleHeight(80),
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            name,
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
}