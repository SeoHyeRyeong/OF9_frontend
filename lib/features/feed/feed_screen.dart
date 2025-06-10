import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/components/custom_popup_dialog.dart';
import 'package:intl/intl.dart';

class FeedScreen extends StatefulWidget {
  final bool showCompletionPopup;

  const FeedScreen({
    Key? key,
    this.showCompletionPopup = false,
  }) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int selectedDateIndex = 0; // 선택된 날짜의 인덱스 (오늘이 0)
  int selectedFilterIndex = 0; // 선택된 필터의 인덱스 (ALL이 0)
  ScrollController _scrollController = ScrollController();
  DateTime _visibleMonth = DateTime.now(); // 현재 보이는 월

  // 필터 목록
  final List<String> _filters = [
    'ALL',
    'KIA 타이거즈',
    '두산 베어스',
    '롯데 자이언츠',
    '삼성 라이온즈',
    '키움 히어로즈',
    '한화 이글스',
    'KT WIZ',
    'LG 트윈스',
    'NC 다이노스',
    'SSG 랜더스'
  ];

  @override
  void initState() {
    super.initState();
    // 화면 로드 후 팝업 표시
    if (widget.showCompletionPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog();
      });
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 완료 팝업을 띄우는 함수
  void _showCompletionDialog() {
    final todayDate = getTodayFormattedDate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomPopupDialog(
        imageAsset: AppImages.icAlert,
        title: '$todayDate\n직관 기록이 완료됐어요',
        subtitle: '직관 기록은 마이 페이지에서 확인할 수 있어요',
        firstButtonText: '확인',
        firstButtonAction: () {
          Navigator.pop(context); // 팝업만 닫기
        },
        secondButtonText: '',
        secondButtonAction: () {},
      ),
    );
  }

  /// 오늘 날짜를 포맷팅하는 함수
  String getTodayFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko_KR');
    return formatter.format(now);
  }

  // 스크롤 리스너 - 보이는 월을 계산
  void _onScroll() {
    final double offset = _scrollController.offset;
    final double itemWidth = 45.w; // 각 날짜 아이템의 너비 (40.w + 5.w spacing)
    final int visibleItemIndex = (offset / itemWidth).round();

    final DateTime today = DateTime.now();
    final DateTime visibleDate = today.subtract(Duration(days: visibleItemIndex));

    if (_visibleMonth.month != visibleDate.month || _visibleMonth.year != visibleDate.year) {
      setState(() {
        _visibleMonth = DateTime(visibleDate.year, visibleDate.month);
      });
    }
  }

  // 특정 월에 맞는 달력 아이콘을 반환하는 메서드
  String _getMonthIcon(int month) {
    switch (month) {
      case 1: return AppImages.month1;
      case 2: return AppImages.month2;
      case 3: return AppImages.month3;
      case 4: return AppImages.month4;
      case 5: return AppImages.month5;
      case 6: return AppImages.month6;
      case 7: return AppImages.month7;
      case 8: return AppImages.month8;
      case 9: return AppImages.month9;
      case 10: return AppImages.month10;
      case 11: return AppImages.month11;
      case 12: return AppImages.month12;
      default: return AppImages.month1;
    }
  }

  // 2025년 1월 1일부터 오늘까지의 모든 날짜를 생성
  List<DateTime> _generateAllDates() {
    final DateTime today = DateTime.now();
    final DateTime startDate = DateTime(2025, 1, 1);
    final List<DateTime> dates = [];

    DateTime currentDate = today;
    while (currentDate.isAfter(startDate) || currentDate.isAtSameMomentAs(startDate)) {
      dates.add(currentDate);
      currentDate = currentDate.subtract(Duration(days: 1));
    }

    return dates;
  }

  // 날짜 위젯을 생성하는 메서드
  Widget _buildDateWidget(DateTime date, int index) {
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final dayOfWeek = weekdays[date.weekday % 7];
    final isSelected = selectedDateIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDateIndex = index;
        });
      },
      child: Container(
        width: 40.w,
        height: 46.h,
        margin: EdgeInsets.only(right: 5.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray950 : Colors.transparent,
          borderRadius: BorderRadius.circular(21.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 요일
            FixedText(
              dayOfWeek,
              style: AppFonts.c1_r(context).copyWith(
                color: isSelected ? Colors.white : AppColors.gray400,
              ),
            ),
            SizedBox(height: 6.h),
            // 날짜
            FixedText(
              '${date.day}',
              style: AppFonts.b3_b(context).copyWith(
                color: isSelected ? Colors.white : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 필터 위젯을 생성하는 메서드
  Widget _buildFilterWidget(String filterText, int index) {
    final isSelected = selectedFilterIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilterIndex = index;
        });
      },
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray600 : AppColors.gray20,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: FixedText(
            filterText,
            style: isSelected
                ? AppFonts.c1_b(context).copyWith(color: AppColors.gray20)
                : AppFonts.c1_sb(context).copyWith(color: AppColors.gray300),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> allDates = _generateAllDates();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 영역
            Container(
              width: double.infinity,
              height: 64.h,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          FixedText(
                            '전체',
                            style: AppFonts.h5_b(context).copyWith(color: Colors.black),
                          ),
                          SizedBox(width: 16.w),
                          FixedText(
                            '팔로잉',
                            style: AppFonts.h5_b(context).copyWith(color: AppColors.gray300),
                          ),
                        ],
                      ),
                      SvgPicture.asset(
                        AppImages.search,
                        width: 24.w,
                        height: 24.w,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 나머지 컨텐츠 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 6.h),

                  // 달력 및 날짜 영역
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 15.w),
                    child: Container(
                      height: 46.h,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 달력 레이아웃 (고정)
                          Container(
                            width: 36.w,
                            height: 46.h,
                            padding: EdgeInsets.only(
                              top: 6.h,
                              right: 10.w,
                              bottom: 6.h,
                            ),
                            child: SvgPicture.asset(
                              _getMonthIcon(_visibleMonth.month),
                              width: 25.w,
                              height: 33.h,
                            ),
                          ),

                          SizedBox(width: 10.w),

                          // 세로선
                          Container(
                            width: 1.w,
                            height: 41.h,
                            color: AppColors.gray100,
                          ),

                          SizedBox(width: 10.w),

                          // 스크롤 가능한 날짜 리스트
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              reverse: true, // 오늘부터 시작하여 과거로 스크롤
                              padding: EdgeInsets.zero,
                              itemCount: allDates.length,
                              itemBuilder: (context, index) {
                                return _buildDateWidget(allDates[index], index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 12px 간격
                  SizedBox(height: 12.h),

                  // 회색 구분선 (360*1 크기, gray50 색상)
                  Container(
                    width: 360.w,
                    height: 1.h,
                    color: AppColors.gray50,
                  ),

                  // 12px 간격
                  SizedBox(height: 12.h),

                  // 필터 영역
                  Container(
                    height: 36.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 20.w, right: 20.w),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(right: index == _filters.length - 1 ? 0 : 8.w),
                          child: _buildFilterWidget(_filters[index], index),
                        );
                      },
                    ),
                  ),

                  // 나머지 피드 컨텐츠
                  Expanded(
                    child: Center(
                      child: FixedText(
                        '직관 기록이 없어요',
                        style: AppFonts.h5_sb(context).copyWith(color: AppColors.gray300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
      ),
    );
  }
}