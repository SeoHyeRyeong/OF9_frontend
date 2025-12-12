import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/api/report_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/features/report/report_screen.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';

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

  // 동적으로 뱃지 목록 생성
  Map<String, List<Map<String, String>>> _getAllBadges() {
    return {
      "어서와, 야구 직관은 처음이지?": [
        {"name": "기록의 시작", "assetPath": "assets/imgs/badge/1_start.png"},
        {"name": "홈의 따뜻함", "assetPath": "assets/imgs/badge/1_home.png"},
        {"name": "원정의 즐거움", "assetPath": "assets/imgs/badge/1_away.png"},
        {"name": "같이 응원해요", "assetPath": "assets/imgs/badge/1_cheer.png"},
        {"name": "속닥속닥", "assetPath": "assets/imgs/badge/1_comment.png"},
      ],
      "나는야 승리요정": [
        {"name": "응원의 보답", "assetPath": "assets/imgs/badge/2_heart.png"},
        {"name": "네잎클로버", "assetPath": "assets/imgs/badge/2_clover.png"},
        {"name": "행운의 편지", "assetPath": "assets/imgs/badge/2_letter.png"},
      ],
      "패배해도 괜찮아": [
        {"name": "토닥토닥", "assetPath": "assets/imgs/badge/3_halfheart.png"},
        {"name": "그래도 응원해", "assetPath": "assets/imgs/badge/3_force.png"},
        {"name": "이게 사랑이야", "assetPath": "assets/imgs/badge/3_ring.png"},
      ],
      "모든 야구장을 제패하겠어": [
        {"name": "베어스 정복", "assetPath": "assets/imgs/badge/4_bears.png"},
        {"name": "갈매기 정복", "assetPath": "assets/imgs/badge/4_lotte.png"},
        {"name": "사자 정복", "assetPath": "assets/imgs/badge/4_lions.png"},
        {"name": "히어로 정복", "assetPath": "assets/imgs/badge/4_kiwoom.png"},
        {"name": "독수리 정복", "assetPath": "assets/imgs/badge/4_eagles.png"},
        {"name": "호랑이 정복", "assetPath": "assets/imgs/badge/4_kia.png"},
        {"name": "마법사 정복", "assetPath": "assets/imgs/badge/4_kt.png"},
        {"name": "쌍둥이 정복", "assetPath": "assets/imgs/badge/4_lg.png"},
        {"name": "공룡 정복", "assetPath": "assets/imgs/badge/4_nc.png"},
        {"name": "랜더스 정복", "assetPath": "assets/imgs/badge/4_ssg.png"},
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
                        Navigator.pop(context, true);
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
                          "나의 배지",
                          style: AppFonts.pretendard.body_md_500(context).copyWith(
                              color: AppColors.gray900),
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
                    SizedBox(height: scaleHeight(10)),

                    // 직관 기록 독려
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Container(
                        width: double.infinity,
                        height: scaleHeight(88),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(scaleWidth(16)),
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
                                      style: AppFonts.pretendard.body_sm_500(
                                          context).copyWith(
                                          color: AppColors.gray700),
                                    ),
                                    SizedBox(height: scaleHeight(4)),
                                    Text(
                                      "더 많은 배지를 모아 보세요!",
                                      style: AppFonts.pretendard.body_sm_500(
                                          context).copyWith(
                                          color: AppColors.gray900),
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

                    SizedBox(height: scaleHeight(28)),

                    // 보유한 배지 제목
                    Padding(
                      padding: EdgeInsets.only(left: scaleWidth(20)),
                      child: Row(
                        children: [
                          Text(
                            "보유한 배지",
                            style: AppFonts.pretendard.head_sm_600(context).copyWith(
                                color: AppColors.gray900),
                          ),
                          SizedBox(width: scaleWidth(6)),
                          Text(
                            "${_badgeData?['myBadgeCount'] ?? 0}",
                            style: AppFonts.pretendard.head_sm_600(context).copyWith(
                                color: AppColors.pri700),
                          ),
                        ],
                      ),
                    ),

                    // 배지 목록
                    _buildAllBadgeCategories(),
                    SizedBox(height: scaleHeight(46)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }


  // 모든 뱃지 카테고리별 배치
  Widget _buildAllBadgeCategories() {
    final allBadges = _getAllBadges();
    final categoryNames = allBadges.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int categoryIndex = 0; categoryIndex <
            categoryNames.length; categoryIndex++)
          _buildCategorySection(
              categoryNames[categoryIndex],
              allBadges[categoryNames[categoryIndex]]!,
              categoryIndex == categoryNames.length - 1
          ),
      ],
    );
  }

  // 각 카테고리 섹션 빌드
  Widget _buildCategorySection(String categoryName,
      List<Map<String, String>> badges, bool isLastCategory) {
    // 첫 번째 카테고리인지 확인 (인덱스 전달 필요하므로 간접적으로 판단)
    final allBadges = _getAllBadges();
    final isFirstCategory = categoryName == allBadges.keys.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 제목
        SizedBox(height: scaleHeight(isFirstCategory ? 24 : 48)),
        Padding(
          padding: EdgeInsets.only(left: scaleWidth(20)),
          child: Text(
            categoryName,
            style: AppFonts.pretendard.body_md_500(context).copyWith(
                color: AppColors.gray800),
          ),
        ),

        // 뱃지 그리드 (3개씩 배치)
        SizedBox(height: scaleHeight(16)),
        _buildBadgeGrid(categoryName, badges),
      ],
    );
  }

  // 뱃지 그리드 (3개씩 배치)
  Widget _buildBadgeGrid(String categoryName,
      List<Map<String, String>> badges) {
    List<Widget> rows = [];

    for (int i = 0; i < badges.length; i += 3) {
      List<Widget> rowItems = [];

      for (int j = 0; j < 3 && i + j < badges.length; j++) {
        final badge = badges[i + j];
        rowItems.add(_buildBadgeItem(categoryName, badge));
      }

      // 부족한 자리는 빈 공간으로 채우기
      while (rowItems.length < 3) {
        rowItems.add(SizedBox(width: scaleWidth(84)));
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

    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              width: scaleWidth(84),
              height: scaleWidth(84),
              child: isAchieved
                  ? Transform.scale(
                scale: 1.38,
                child: Image.asset(assetPath, fit: BoxFit.cover),
              )
                  : Image.asset(
                  'assets/imgs/badge/lock.png', fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: scaleHeight(10)),
          SizedBox(
            width: scaleWidth(84),
            child: Text(
              name,
              style: AppFonts.pretendard.body_sm_400(context).copyWith(
                color: isAchieved ? Colors.black : Colors.black,
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
}