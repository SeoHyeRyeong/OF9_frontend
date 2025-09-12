import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/components/custom_popup_dialog.dart';
import 'package:frontend/api/record_api.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:frontend/features/feed/search_screen.dart';


class FeedScreen extends StatefulWidget {
  final bool showCompletionPopup;

  const FeedScreen({Key? key, this.showCompletionPopup = false})
      : super(key: key);

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
    'SSG 랜더스',
  ];

  @override
  void initState() {
    super.initState();

    // 상태바 항상 표시
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

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
      builder:
          (context) => CustomPopupDialog(
        imageAsset: AppImages.ticket,
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

  /// 경기 날짜 포맷팅 함수 ("2025년 03월 23일 (일)요일" → "2025년 03월 23일 (일)")
  String _formatGameDate(String gameDate) {
    if (gameDate.isEmpty) return '';

    // "요일" 부분을 제거
    final String formatted = gameDate.replaceAll('요일', '');
    return formatted;
  }

  /// createdAt 시간을 기준으로 경과 시간을 계산하는 함수
  String _getTimeAgo(String createdAt) {
    try {
      // "2025-05-26 17:42:26" 형태의 문자열을 DateTime으로 변환
      final DateTime recordTime = DateTime.parse(
        createdAt.replaceAll(' ', 'T'),
      );
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(recordTime);

      if (difference.inDays >= 1) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes}분 전';
      } else {
        return '${difference.inSeconds}초 전';
      }
    } catch (e) {
      return '알 수 없음';
    }
  }

  /// 감정 코드에 따른 이모지 이미지 경로를 반환하는 함수
  String _getEmotionImage(int emotionCode) {
    switch (emotionCode) {
      case 1:
        return AppImages.emotion_1;
      case 2:
        return AppImages.emotion_2;
      case 3:
        return AppImages.emotion_3;
      case 4:
        return AppImages.emotion_4;
      case 5:
        return AppImages.emotion_5;
      case 6:
        return AppImages.emotion_6;
      case 7:
        return AppImages.emotion_7;
      case 8:
        return AppImages.emotion_8;
      case 9:
        return AppImages.emotion_9;
      default:
        return AppImages.emotion_1;
    }
  }

  /// 팀명에 따른 로고 이미지 경로를 반환하는 함수
  String _getTeamLogo(String teamName) {
    switch (teamName) {
      case 'KIA 타이거즈':
        return AppImages.tigers;
      case '두산 베어스':
        return AppImages.bears;
      case '롯데 자이언츠':
        return AppImages.giants;
      case '삼성 라이온즈':
        return AppImages.lions;
      case '키움 히어로즈':
        return AppImages.kiwoom;
      case '한화 이글스':
        return AppImages.eagles;
      case 'KT WIZ':
        return AppImages.ktwiz;
      case 'LG 트윈스':
        return AppImages.twins;
      case 'NC 다이노스':
        return AppImages.dinos;
      case 'SSG 랜더스':
        return AppImages.landers;
      default:
        return AppImages.tigers; // 기본 로고
    }
  }

  // 스크롤 리스너 - 보이는 월을 계산
  void _onScroll() {
    final double offset = _scrollController.offset;
    final double itemWidth = 45.w; // 각 날짜 아이템의 너비 (40.w + 5.w spacing)
    final int visibleItemIndex = (offset / itemWidth).round();

    final DateTime today = DateTime.now();
    final DateTime visibleDate = today.subtract(
      Duration(days: visibleItemIndex),
    );

    if (_visibleMonth.month != visibleDate.month ||
        _visibleMonth.year != visibleDate.year) {
      setState(() {
        _visibleMonth = DateTime(visibleDate.year, visibleDate.month);
      });
    }
  }

  // 특정 월에 맞는 달력 아이콘을 반환하는 메서드
  String _getMonthIcon(int month) {
    switch (month) {
      case 1:
        return AppImages.month1;
      case 2:
        return AppImages.month2;
      case 3:
        return AppImages.month3;
      case 4:
        return AppImages.month4;
      case 5:
        return AppImages.month5;
      case 6:
        return AppImages.month6;
      case 7:
        return AppImages.month7;
      case 8:
        return AppImages.month8;
      case 9:
        return AppImages.month9;
      case 10:
        return AppImages.month10;
      case 11:
        return AppImages.month11;
      case 12:
        return AppImages.month12;
      default:
        return AppImages.month1;
    }
  }

  // 2025년 1월 1일부터 오늘까지의 모든 날짜를 생성
  List<DateTime> _generateAllDates() {
    final DateTime today = DateTime.now();
    final DateTime startDate = DateTime(2025, 1, 1);
    final List<DateTime> dates = [];

    DateTime currentDate = today;
    while (currentDate.isAfter(startDate) ||
        currentDate.isAtSameMomentAs(startDate)) {
      dates.add(currentDate);
      currentDate = currentDate.subtract(Duration(days: 1));
    }

    return dates;
  }

  /// 선택된 날짜에 맞는 기록들을 필터링하는 함수
  List<Map<String, dynamic>> _filterRecordsBySelectedDate(
      List<Map<String, dynamic>> records,
      ) {
    final List<DateTime> allDates = _generateAllDates();
    if (selectedDateIndex >= allDates.length) return [];

    final DateTime selectedDate = allDates[selectedDateIndex];

    return records.where((record) {
      try {
        final String gameDate = record['gameDate'] ?? '';
        if (gameDate.isEmpty) return false;

        // "2025년 03월 23일 (일)요일" 형태의 문자열을 DateTime으로 변환
        final RegExp dateRegex = RegExp(r'(\d{4})년\s*(\d{2})월\s*(\d{2})일');
        final Match? match = dateRegex.firstMatch(gameDate);

        if (match != null) {
          final int year = int.parse(match.group(1)!);
          final int month = int.parse(match.group(2)!);
          final int day = int.parse(match.group(3)!);

          final DateTime recordGameDate = DateTime(year, month, day);

          // 날짜만 비교
          return recordGameDate.year == selectedDate.year &&
              recordGameDate.month == selectedDate.month &&
              recordGameDate.day == selectedDate.day;
        }
        return false;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// 선택된 필터(홈팀)에 맞는 기록들을 필터링하는 함수
  List<Map<String, dynamic>> _filterRecordsByTeam(
      List<Map<String, dynamic>> records,
      ) {
    if (selectedFilterIndex == 0) return records; // 'ALL' 선택시 전체 반환

    final String selectedTeam = _filters[selectedFilterIndex];

    return records.where((record) {
      final String homeTeam = record['homeTeam'] ?? '';
      // 홈팀만 확인
      return homeTeam == selectedTeam;
    }).toList();
  }

  /// 날짜와 홈팀 필터를 모두 적용하는 함수
  List<Map<String, dynamic>> _applyAllFilters(
      List<Map<String, dynamic>> records,
      ) {
    // 1. 먼저 날짜 필터링
    List<Map<String, dynamic>> dateFiltered = _filterRecordsBySelectedDate(
      records,
    );

    // 2. 그 다음 홈팀 필터링
    List<Map<String, dynamic>> teamFiltered = _filterRecordsByTeam(
      dateFiltered,
    );

    return teamFiltered;
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
              style: AppFonts.pretendard.c1_r(
                context,
              ).copyWith(color: isSelected ? Colors.white : AppColors.gray400),
            ),
            SizedBox(height: 6.h),
            // 날짜
            FixedText(
              '${date.day}',
              style: AppFonts.pretendard.b3_b(
                context,
              ).copyWith(color: isSelected ? Colors.white : AppColors.gray400),
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
            style:
            isSelected
                ? AppFonts.pretendard.c1_b(context).copyWith(color: AppColors.gray20)
                : AppFonts.pretendard.c1_sb(context,).copyWith(color: AppColors.gray300),
          ),
        ),
      ),
    );
  }

  /// 이미지 위젯을 생성하는 헬퍼 메서드
  Widget _buildMediaImage(dynamic mediaData, double width, double height) {
    try {
      // mediaData가 String인지 확인
      if (mediaData is String) {
        // base64 데이터로 처리 (마이페이지와 동일한 방식)
        try {
          final Uint8List imageBytes = base64Decode(mediaData);
          return Image.memory(
            imageBytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Image.memory 에러: $error');
              return _buildImageErrorWidget(width, height);
            },
          );
        } catch (e) {
          print('❌ Base64 디코딩 실패: $e');
          print('📊 mediaData 내용: ${mediaData.substring(0, mediaData.length > 100 ? 100 : mediaData.length)}...');

          // Base64 디코딩이 실패하면 URL로 시도
          if (mediaData.startsWith('http://') || mediaData.startsWith('https://')) {
            return Image.network(
              mediaData,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Image.network 에러: $error');
                return _buildImageErrorWidget(width, height);
              },
            );
          }
          return _buildImageErrorWidget(width, height);
        }
      }
      // mediaData가 다른 형태인 경우
      else {
        print('❌ 알 수 없는 미디어 데이터 형태: ${mediaData.runtimeType}');
        print('📊 mediaData 값: $mediaData');
        return _buildImageErrorWidget(width, height);
      }
    } catch (e) {
      print('❌ 이미지 처리 실패: $e');
      return _buildImageErrorWidget(width, height);
    }
  }

  /// 에러 위젯을 생성하는 헬퍼 메서드
  Widget _buildImageErrorWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.gray200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 40.w,
            color: AppColors.gray400,
          ),
          SizedBox(height: 8.h),
          FixedText(
            '이미지 로드 실패',
            style: AppFonts.pretendard.c2_m(context).copyWith(
              color: AppColors.gray400,
            ),
          ),
        ],
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
                            style: AppFonts.pretendard.h5_b(
                              context,
                            ).copyWith(color: Colors.black),
                          ),
                          SizedBox(width: 16.w),
                          FixedText(
                            '팔로잉',
                            style: AppFonts.pretendard.h5_b(
                              context,
                            ).copyWith(color: AppColors.gray300),
                          ),
                        ],
                      ),
                      /*SvgPicture.asset(
                        AppImages.search,
                        width: 24.w,
                        height: 24.w,
                      ),*/
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => const SearchScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                        child: SvgPicture.asset(
                          AppImages.search,
                          width: 24.w,
                          height: 24.w,
                        ),
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
                              reverse: true,
                              // 오늘부터 시작하여 과거로 스크롤
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
                  Container(width: 360.w, height: 1.h, color: AppColors.gray50),

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
                          margin: EdgeInsets.only(
                            right: index == _filters.length - 1 ? 0 : 8.w,
                          ),
                          child: _buildFilterWidget(_filters[index], index),
                        );
                      },
                    ),
                  ),

                  // 24px 간격
                  SizedBox(height: 24.h),

                  // 피드 컨텐츠
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: RecordApi.getMyRecordsList(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.pri400,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: FixedText(
                              '기록을 불러오는데 실패했습니다',
                              style: AppFonts.pretendard.h5_sb(
                                context,
                              ).copyWith(color: AppColors.gray300),
                            ),
                          );
                        }

                        final List<Map<String, dynamic>> records =
                            snapshot.data ?? [];
                        // 최신 기록이 위로 오도록 정렬 (createdAt 기준 내림차순)
                        records.sort((a, b) {
                          try {
                            final DateTime timeA = DateTime.parse(
                              (a['createdAt'] ?? '').replaceAll(' ', 'T'),
                            );
                            final DateTime timeB = DateTime.parse(
                              (b['createdAt'] ?? '').replaceAll(' ', 'T'),
                            );
                            return timeB.compareTo(timeA); // 내림차순 (최신이 위로)
                          } catch (e) {
                            return 0;
                          }
                        });

                        final List<Map<String, dynamic>> filteredRecords =
                        _applyAllFilters(records);

                        if (filteredRecords.isEmpty) {
                          return Center(
                            child: FixedText(
                              '직관 기록이 없어요',
                              style: AppFonts.pretendard.h5_sb(
                                context,
                              ).copyWith(color: AppColors.gray300),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.only(top: 0),
                          itemCount: filteredRecords.length * 2 - 1, // 구분선 포함
                          itemBuilder: (context, index) {
                            // 구분선 아이템
                            if (index.isOdd) {
                              return Column(
                                children: [
                                  SizedBox(height: 25.h),
                                  Container(
                                    width: 320.w,
                                    height: 1.h,
                                    color: AppColors.gray50,
                                  ),
                                  SizedBox(height: 20.h),
                                ],
                              );
                            }

                            // 기록 아이템
                            final recordIndex = index ~/ 2;
                            final record = filteredRecords[recordIndex];
                            final String nickname = record['nickname'] ?? '';
                            final String favTeam = record['favTeam'] ?? '';
                            final String profileImageUrl =
                                record['profileImageUrl'] ?? '';
                            final String createdAt = record['createdAt'] ?? '';
                            final String longContent =
                                record['longContent'] ?? '';
                            final String gameDate = record['gameDate'] ?? '';
                            final String stadium = record['stadium'] ?? '';
                            final String homeTeam = record['homeTeam'] ?? '';
                            final String awayTeam = record['awayTeam'] ?? '';
                            final int homeScore = record['homeScore'] ?? 0;
                            final int awayScore = record['awayScore'] ?? 0;
                            final int emotionCode = record['emotionCode'] ?? 1;
                            final String emotionLabel =
                                record['emotionLabel'] ?? '';

                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 20.w),
                              decoration: BoxDecoration(color: Colors.white),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 사용자 정보 헤더 (1~4번)
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        // 1. 프로필 이미지 (36*36, 원형)
                                        Container(
                                          width: 36.w,
                                          height: 36.h,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                            profileImageUrl.isNotEmpty
                                                ? null
                                                : AppColors.gray50,
                                            image:
                                            profileImageUrl.isNotEmpty
                                                ? DecorationImage(
                                              image: NetworkImage(
                                                profileImageUrl,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                                : null,
                                          ),
                                          child:
                                          profileImageUrl.isEmpty
                                              ? ClipOval(
                                            child: SvgPicture.asset(
                                              AppImages.profile,
                                              width: 36.w,
                                              height: 36.h,
                                            ),
                                          )
                                              : null,
                                        ),

                                        SizedBox(width: 8.w),

                                        // 텍스트 영역을 Expanded로 감싸기
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              // 2, 3, 4번을 한 줄에 배치
                                              Row(
                                                children: [
                                                  // 2. 닉네임 (b3_b 폰트, gray950 색상)
                                                  FixedText(
                                                    nickname,
                                                    style: AppFonts.pretendard.b3_b(
                                                      context,
                                                    ).copyWith(
                                                      color: AppColors.gray950,
                                                    ),
                                                  ),

                                                  SizedBox(width: 8.w),

                                                  // 3. 팬 정보 (c1_r 폰트, gray400 색상)
                                                  FixedText(
                                                    '$favTeam 팬',
                                                    style: AppFonts.pretendard.c1_r(
                                                      context,
                                                    ).copyWith(
                                                      color: AppColors.gray400,
                                                    ),
                                                  ),

                                                  Spacer(),

                                                  // 4. 경과 시간 (c2_m 폰트, gray400 색상)
                                                  FixedText(
                                                    _getTimeAgo(createdAt),
                                                    style: AppFonts.suite.c2_m(
                                                      context,
                                                    ).copyWith(
                                                      color: AppColors.gray400,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(height: 8.h),

                                              // 5. 긴 내용
                                              FixedText(
                                                longContent,
                                                style: AppFonts.pretendard.b3_sb_long(
                                                  context,
                                                ).copyWith(
                                                  color: AppColors.gray400,
                                                ),
                                                maxLines:
                                                null, // 여러 줄 허용 (다음줄로 넘어가는 형태)
                                              ),

                                              SizedBox(height: 10.h),

                                              // 경기 정보 카드
                                              Container(
                                                width: 276.w,
                                                height: 88.h,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    12.r,
                                                  ),
                                                  border: Border.all(
                                                    color: AppColors.gray30,
                                                    width: 1,
                                                  ),
                                                ),
                                                padding: EdgeInsets.only(
                                                  top: 16.h,
                                                  left: 20.w,
                                                  right: 20.w,
                                                  bottom: 0.h,
                                                ),
                                                child: Row(
                                                  children: [
                                                    // 왼쪽: 경기 정보
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          // 경기 날짜 및 구장
                                                          FixedText(
                                                            '${_formatGameDate(gameDate)}, ${stadium}에서',
                                                            style: AppFonts.suite.c2_m(
                                                              context,
                                                            ).copyWith(
                                                              color:
                                                              AppColors
                                                                  .gray400,
                                                            ),
                                                          ),

                                                          SizedBox(
                                                            height: 10.h,
                                                          ),

                                                          // 점수 및 팀 로고
                                                          Row(
                                                            children: [
                                                              // 홈팀 로고
                                                              Container(
                                                                width: 31.w,
                                                                child: Image.asset(
                                                                  _getTeamLogo(
                                                                    homeTeam,
                                                                  ),
                                                                  width: 30.w,
                                                                  fit:
                                                                  BoxFit
                                                                      .contain,
                                                                  errorBuilder: (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                      ) {
                                                                    return Container(
                                                                      width:
                                                                      30.w,
                                                                      height:
                                                                      30.w,
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                        AppColors.gray200,
                                                                        shape:
                                                                        BoxShape.circle,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),

                                                              SizedBox(
                                                                width: 17.w,
                                                              ),

                                                              // 점수
                                                              FixedText(
                                                                '$homeScore',
                                                                style: AppFonts.pretendard.h3_sb(
                                                                  context,
                                                                ).copyWith(
                                                                  color:
                                                                  AppColors
                                                                      .gray500,
                                                                ),
                                                              ),

                                                              SizedBox(
                                                                width: 12.w,
                                                              ),

                                                              FixedText(
                                                                ':',
                                                                style: AppFonts.pretendard.h3_sb(
                                                                  context,
                                                                ).copyWith(
                                                                  color:
                                                                  AppColors
                                                                      .gray500,
                                                                ),
                                                              ),

                                                              SizedBox(
                                                                width: 12.w,
                                                              ),

                                                              FixedText(
                                                                '$awayScore',
                                                                style: AppFonts.pretendard.h3_sb(
                                                                  context,
                                                                ).copyWith(
                                                                  color:
                                                                  AppColors
                                                                      .gray500,
                                                                ),
                                                              ),

                                                              SizedBox(
                                                                width: 17.w,
                                                              ),

                                                              // 원정팀 로고
                                                              Container(
                                                                width: 30.w,
                                                                child: Image.asset(
                                                                  _getTeamLogo(
                                                                    awayTeam,
                                                                  ),
                                                                  width: 30.w,
                                                                  fit:
                                                                  BoxFit
                                                                      .contain,
                                                                  errorBuilder: (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                      ) {
                                                                    return Container(
                                                                      width:
                                                                      30.w,
                                                                      height:
                                                                      30.w,
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                        AppColors.gray200,
                                                                        shape:
                                                                        BoxShape.circle,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // 오른쪽: 감정 표현
                                                    Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      children: [
                                                        // 감정 이모지 (위로 올리기)
                                                        Transform.translate(
                                                          offset: Offset(
                                                            0, -7.h,
                                                          ),
                                                          child: Container(
                                                            width: 54.w,
                                                            height: 54.h,
                                                            child: SvgPicture.asset(
                                                              _getEmotionImage(
                                                                emotionCode,
                                                              ),
                                                              width: 54.w,
                                                              height: 54.h,
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                        ),

                                                        // 감정 라벨 (위로 더 올리기)
                                                        Transform.translate(
                                                          offset: Offset(0, -8.h,),
                                                          // 8px 위로 이동
                                                          child: FixedText(
                                                            emotionLabel,
                                                            style: AppFonts.suite.c2_m(
                                                              context,
                                                            ).copyWith(
                                                              color:
                                                              AppColors
                                                                  .gray200,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              SizedBox(height: 12.h),

                                              // 미디어 이미지들 (가로 스크롤) - 수정된 부분
                                              if ((record['mediaUrls']
                                              as List<dynamic>?)
                                                  ?.isNotEmpty ??
                                                  false) ...[
                                                Container(
                                                  height: 188.h,
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                    Axis.horizontal,
                                                    itemCount:
                                                    (record['mediaUrls']
                                                    as List<
                                                        dynamic
                                                    >)
                                                        .length,
                                                    itemBuilder: (
                                                        context,
                                                        mediaIndex,
                                                        ) {
                                                      final mediaData =
                                                      (record['mediaUrls']
                                                      as List<
                                                          dynamic
                                                      >)[mediaIndex];

                                                      return Container(
                                                        width: 210.w,
                                                        height: 188.h,
                                                        margin: EdgeInsets.only(
                                                          right:
                                                          mediaIndex ==
                                                              (record['mediaUrls']
                                                              as List<dynamic>)
                                                                  .length -
                                                                  1
                                                              ? 0
                                                              : 12.w,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                            12.r,
                                                          ),
                                                          color:
                                                          AppColors.gray100,
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                            12.r,
                                                          ),
                                                          child: _buildMediaImage(mediaData, 210.w, 188.h),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
    );
  }
}