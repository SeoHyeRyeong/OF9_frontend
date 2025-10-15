import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/models/game_response.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/utils/size_utils.dart';
import '../../theme/app_imgs.dart';

/// OCR텍스트에서 날짜 파싱
DateTime? tryParseDateFromOcr(String rawText) {
  final regex = RegExp(r'(20\d{2})[년\-. ]+(\d{1,2})[월\-. ]+(\d{1,2})');
  final match = regex.firstMatch(rawText);
  if (match != null) {
    try {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);

      if (year != 2025) {
        print('⚠️ OCR 추출된 연도가 범위를 벗어남: $year (2025년만 허용)');
        return null;
      }

      if (month < 1 || month > 12 || day < 1 || day > 31) {
        print('⚠️ OCR 추출된 월/일이 유효하지 않음: $month월 $day일');
        return null;
      }

      return DateTime(year, month, day);
    } catch (_) {}
  }
  return null;
}

///최근 맞대결 날짜 찾기
DateTime? findRecentMatchDate({
  required List<GameResponse> games,
  required String home,
  required String away,
}) {
  final matched = games
      .where(
        (g) =>
    (g.homeTeam == home && g.awayTeam == away) ||
        (g.homeTeam == away && g.awayTeam == home),
  )
      .toList();
  if (matched.isEmpty) return null;
  matched.sort((a, b) => a.date.compareTo(b.date));
  return matched.last.date;
}

///가장 가까운 경기 날짜 찾기
DateTime? findClosestGameDate(DateTime target, Iterable<DateTime> gameDates) {
  if (gameDates.isEmpty) return null;
  return gameDates.reduce(
        (a, b) => (a.difference(target).abs() < b.difference(target).abs()) ? a : b,
  );
}

///시간을 한국어 형식으로 변환 (14:00 -> 14시 00분)
String _formatTimeToKorean(String time) {
  final parts = time.split(':');
  if (parts.length >= 2) {
    final hour = parts[0];
    final minute = parts[1];
    return '${hour}시 ${minute}분';
  }
  return time;
}

///날짜/시간 선택용 BottomSheet표시
Future<Map<String, dynamic>?> showDateTimePicker({
  required BuildContext context,
  String? ocrDateText,
  required String? homeTeam,
  required String? opponentTeam,
}) async {
  DateTime focused = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;
  List<GameResponse> matchedGames = [];
  int selectedGameIndex = 0;
  final events = <DateTime, List<GameResponse>>{};

  ///해당 달 이벤트 로드
  Future<void> loadEvents(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    final games = await GameApi.listByDateRange(
      from: DateFormat('yyyy-MM-dd').format(from),
      to: DateFormat('yyyy-MM-dd').format(to),
    );
    events.clear();
    for (var g in games) {
      final day = DateTime(g.date.year, g.date.month, g.date.day);
      events.putIfAbsent(day, () => []).add(g);
    }
  }

  ///선택된 날짜의 경기 시간 가져오기
  Future<void> loadMatchedGames(DateTime selectedDate) async {
    if (homeTeam == null || opponentTeam == null) {
      matchedGames = [];
      return;
    }

    String convertToShortName(String fullName) {
      final teamToShort = {
        'KIA 타이거즈': 'KIA',
        '두산 베어스': '두산',
        '롯데 자이언츠': '롯데',
        '삼성 라이온즈': '삼성',
        '키움 히어로즈': '키움',
        '한화 이글스': '한화',
        'KT WIZ': 'KT',
        'LG 트윈스': 'LG',
        'NC 다이노스': 'NC',
        'SSG 랜더스': 'SSG',
      };
      return teamToShort[fullName] ?? fullName;
    }

    bool isTeamMatch(String apiTeam, String searchTeam) {
      return apiTeam == searchTeam;
    }

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final homeShort = convertToShortName(homeTeam!);
      final awayShort = convertToShortName(opponentTeam!);

      print('🔍 경기 검색 - 날짜: $dateStr');
      print('   홈팀: $homeTeam -> $homeShort');
      print('   원정팀: $opponentTeam -> $awayShort');

      final games = await GameApi.listByDateRange(
        from: dateStr,
        to: dateStr,
      );

      print('📋 가져온 경기 목록: ${games.length}개');
      for (var game in games) {
        print('   경기: ${game.homeTeam} vs ${game.awayTeam}');
      }

      matchedGames = games.where((game) {
        final homeMatch = isTeamMatch(game.homeTeam, homeShort);
        final awayMatch = isTeamMatch(game.awayTeam, awayShort);
        return homeMatch && awayMatch;
      }).toList();

      print('✅ 매칭된 경기: ${matchedGames.length}개');
      if (matchedGames.isNotEmpty) {
        print('   시간: ${matchedGames.first.time}');
        print('   매칭된 경기: ${matchedGames.first.homeTeam} vs ${matchedGames.first.awayTeam}');
      }

    } catch (e) {
      print('❌ 경기 정보 로드 실패: $e');
      matchedGames = [];
    }
  }

  await loadEvents(focused);
  final firstDay = DateTime(2025, 1, 1);
  final lastDay = DateTime(2025, 12, 31);

  // OCR 또는 팀 매칭으로 focus 다시 결정
  DateTime? resolvedFocus;
  if (ocrDateText != null) {
    resolvedFocus = tryParseDateFromOcr(ocrDateText);
    if (resolvedFocus != null) {
      if (resolvedFocus.isBefore(firstDay) || resolvedFocus.isAfter(lastDay)) {
        print('⚠️ OCR 날짜가 달력 범위를 벗어남: $resolvedFocus (범위: $firstDay ~ $lastDay)');
        resolvedFocus = null;
      }
    }
  }
  if (resolvedFocus == null && homeTeam != null && opponentTeam != null) {
    resolvedFocus = findRecentMatchDate(
      games: events.values.expand((e) => e).toList(),
      home: homeTeam,
      away: opponentTeam,
    );
  }
  resolvedFocus ??= findClosestGameDate(DateTime.now(), events.keys);
  focused = resolvedFocus ?? DateTime.now();

  // OCR 날짜가 있으면 자동으로 해당 날짜 선택
  DateTime? initialSelectedDay;
  if (ocrDateText != null && resolvedFocus != null) {
    initialSelectedDay = resolvedFocus;
  }

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        width: double.infinity,
        height: scaleHeight(600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(scaleHeight(20)),
          ),
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            // 초기 상태 설정
            if (initialSelectedDay != null && selectedDay == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                selectedDay = initialSelectedDay;
                await loadMatchedGames(selectedDay!);
                setState(() {
                  selectedGameIndex = 0;
                });
              });
            }

            // 달 이동 함수
            void changeMonth(int diff) async {
              final newFocus = DateTime(focused.year, focused.month + diff, 1);
              if (newFocus.isBefore(firstDay) || newFocus.isAfter(lastDay)) return;
              focused = newFocus;
              await loadEvents(focused);
              setState(() {
                selectedDay = null;
                selectedTime = null;
                matchedGames = [];
                selectedGameIndex = 0;
              });
            }

            // 현재 달의 주 수 계산
            final firstOfMonth = DateTime(focused.year, focused.month, 1);
            final lastOfMonth = DateTime(focused.year, focused.month + 1, 0);
            final startOfCalendar = firstOfMonth.subtract(
                Duration(days: firstOfMonth.weekday % 7));
            final endOfCalendar = lastOfMonth.add(
                Duration(days: (6 - lastOfMonth.weekday % 7) % 7));
            final totalWeeks = (endOfCalendar.difference(startOfCalendar).inDays + 1) ~/ 7;

            // 달력 영역 동적 계산
            final screenWidth = MediaQuery.of(ctx).size.width;
            final calendarPadding = scaleWidth(20);
            final calendarInnerWidth = screenWidth - (calendarPadding * 2);
            final dateAreaPadding = scaleWidth(9);

            // 전체 달력 영역 높이 (300px 기준)
            final calendarTotalHeight = scaleHeight(300);

            // 요일 헤더 높이
            final weekdayHeaderHeight = scaleHeight(20);

            // 네비게이션과 요일 헤더 사이 간격
            final navToWeekdayGap = scaleHeight(6);

            // 그리드 영역 높이
            final gridHeight = calendarTotalHeight - weekdayHeaderHeight - navToWeekdayGap;

            // 날짜 영역 너비
            final dateAreaWidth = calendarInnerWidth - (dateAreaPadding * 2);
            final dateSpacing = scaleWidth(6);

            // 날짜 하나당 width 계산
            final cellWidth = (dateAreaWidth - (dateSpacing * 6)) / 7;

            // rowHeight 계산: gridHeight를 주 수로 나눔
            final rowHeight = gridHeight / totalWeeks;

            // 세로 간격 = rowHeight - cellWidth
            final verticalSpacing = rowHeight - cellWidth;

            return SafeArea(
              top: false,
              child: Column(
                children: [
                  // 헤더 영역
                  Container(
                    height: scaleHeight(60),
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: Stack(
                      children: [
                        // 뒤로가기 버튼
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SvgPicture.asset(
                              AppImages.backBlack,
                              width: scaleWidth(24),
                              height: scaleHeight(24),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // 타이틀
                        Center(
                          child: FixedText(
                            '일시',
                            style: AppFonts.suite.head_sm_700(context).copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: scaleHeight(8)),

                  // 년/월 네비게이션
                  SizedBox(
                    height: scaleHeight(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => changeMonth(-1),
                          child: SvgPicture.asset(
                            AppImages.back_black,
                            width: scaleWidth(16),
                            height: scaleHeight(16),
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(width: scaleWidth(12)),
                        FixedText(
                          '${focused.year}년 ${focused.month}월',
                          style: AppFonts.suite.head_sm_700(context).copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(width: scaleWidth(12)),
                        GestureDetector(
                          onTap: () => changeMonth(1),
                          child: SvgPicture.asset(
                            AppImages.right_black,
                            width: scaleWidth(16),
                            height: scaleHeight(16),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: scaleHeight(8)),

                  // 달력 영역
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: calendarPadding),
                    child: SizedBox(
                      width: calendarInnerWidth,
                      height: calendarTotalHeight,
                      child: Column(
                        children: [
                          SizedBox(height: navToWeekdayGap),

                          // 요일 헤더
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: dateAreaPadding),
                            child: SizedBox(
                              height: weekdayHeaderHeight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int i = 0; i < 7; i++)
                                    SizedBox(
                                      width: cellWidth,
                                      child: Center(
                                        child: FixedText(
                                          const ['일', '월', '화', '수', '목', '금', '토'][i],
                                          style: AppFonts.suite.caption_md_500(context).copyWith(
                                            color: AppColors.gray300,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // 달력 그리드
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: dateAreaPadding),
                            child: SizedBox(
                              width: dateAreaWidth,
                              height: gridHeight,
                              child: TableCalendar<GameResponse>(
                                firstDay: firstDay,
                                lastDay: lastDay,
                                focusedDay: focused,
                                headerVisible: false,
                                daysOfWeekVisible: false,
                                calendarFormat: CalendarFormat.month,
                                sixWeekMonthsEnforced: false,
                                startingDayOfWeek: StartingDayOfWeek.sunday,
                                rowHeight: rowHeight,
                                eventLoader: (d) => events[d] ?? [],
                                calendarStyle: CalendarStyle(
                                  outsideDaysVisible: false,
                                  canMarkersOverflow: false,
                                  cellMargin: EdgeInsets.symmetric(
                                    horizontal: dateSpacing / 2,
                                    vertical: verticalSpacing / 2,
                                  ),
                                ),
                                selectedDayPredicate: (d) =>
                                selectedDay != null && isSameDay(d, selectedDay),
                                enabledDayPredicate: (date) => true,
                                onPageChanged: (fd) => setState(() => focused = fd),
                                onDaySelected: (day, _) async {
                                  if (day.month != focused.month || day.year != focused.year) {
                                    focused = DateTime(day.year, day.month, 1);
                                    await loadEvents(focused);
                                    setState(() {
                                      if (day.isBefore(DateTime.now()) ||
                                          isSameDay(day, DateTime.now())) {
                                        selectedDay = day;
                                        if ((events[day]?.isNotEmpty ?? false)) {
                                          final p = events[day]![0].time.split(':');
                                          selectedTime = TimeOfDay(
                                            hour: int.parse(p[0]),
                                            minute: int.parse(p[1]),
                                          );
                                        }
                                      }
                                    });
                                    if (selectedDay != null) {
                                      await loadMatchedGames(selectedDay!);
                                      setState(() {
                                        selectedGameIndex = 0;
                                      });
                                    }
                                  } else {
                                    if (day.isBefore(DateTime.now()) ||
                                        isSameDay(day, DateTime.now())) {
                                      if (selectedDay != null &&
                                          isSameDay(selectedDay!, day)) {
                                        setState(() {
                                          selectedDay = null;
                                          selectedTime = null;
                                          matchedGames = [];
                                          selectedGameIndex = 0;
                                        });
                                      } else {
                                        setState(() {
                                          selectedDay = day;
                                          if ((events[day]?.isNotEmpty ?? false)) {
                                            final p = events[day]![0].time.split(':');
                                            selectedTime = TimeOfDay(
                                              hour: int.parse(p[0]),
                                              minute: int.parse(p[1]),
                                            );
                                          }
                                        });
                                        loadMatchedGames(day).then((_) {
                                          setState(() {
                                            selectedGameIndex = 0;
                                          });
                                        });
                                      }
                                    }
                                  }
                                },
                                calendarBuilders: CalendarBuilders(
                                  // 기본 날짜 빌더
                                  defaultBuilder: (ctx, date, _) {
                                    final isBeforeToday = date.isBefore(DateTime.now()) ||
                                        isSameDay(date, DateTime.now());
                                    return Container(
                                      width: cellWidth,
                                      height: cellWidth,
                                      child: Center(
                                        child: FixedText(
                                          '${date.day}',
                                          style: AppFonts.suite.b2_m_long(ctx).copyWith(
                                            color: isBeforeToday
                                                ? AppColors.gray900
                                                : AppColors.gray200,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  // 선택된 날짜 빌더
                                  selectedBuilder: (ctx, date, _) {
                                    return Container(
                                      width: cellWidth,
                                      height: cellWidth,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // 원형 배경 (4px 패딩)
                                          Padding(
                                            padding: EdgeInsets.all(scaleWidth(4)),
                                            child: Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              decoration: BoxDecoration(
                                                color: AppColors.pri100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: FixedText(
                                                  '${date.day}',
                                                  style: AppFonts.suite.b2_m_long(ctx).copyWith(
                                                    color: AppColors.pri700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // 하단 점 표시 (셀 바로 아래)
                                          Positioned(
                                            bottom: -scaleHeight(4),
                                            left: cellWidth / 2 - scaleWidth(2),
                                            child: Container(
                                              width: scaleWidth(4),
                                              height: scaleHeight(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.pri700,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  // 오늘 날짜 빌더
                                  todayBuilder: (ctx, date, _) {
                                    final isSel = selectedDay != null &&
                                        isSameDay(date, selectedDay);
                                    return Container(
                                      width: cellWidth,
                                      height: cellWidth,
                                      child: isSel
                                          ? Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // 원형 배경 (4px 패딩)
                                          Padding(
                                            padding: EdgeInsets.all(scaleWidth(4)),
                                            child: Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              decoration: BoxDecoration(
                                                color: AppColors.pri100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: FixedText(
                                                  '${date.day}',
                                                  style: AppFonts.suite.b2_m_long(ctx).copyWith(
                                                    color: AppColors.pri700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // 하단 점 표시 (셀 바로 아래)
                                          Positioned(
                                            bottom: -scaleHeight(4),
                                            left: cellWidth / 2 - scaleWidth(2),
                                            child: Container(
                                              width: scaleWidth(4),
                                              height: scaleHeight(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.pri700,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                          : Center(
                                        child: FixedText(
                                          '${date.day}',
                                          style: AppFonts.suite.b2_m_long(ctx).copyWith(
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: scaleHeight(12)),

                  // 경기 시간 표시 영역 (항상 고정 공간 차지)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: scaleHeight(40),
                      padding: EdgeInsets.only(left: calendarPadding),
                      child: selectedDay != null && matchedGames.isNotEmpty
                          ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < matchedGames.length; i++) ...[
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedGameIndex = i;
                                  });
                                },
                                child: Container(
                                  height: scaleHeight(40),
                                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(10)),
                                  decoration: BoxDecoration(
                                    color: selectedGameIndex == i
                                        ? AppColors.pri700
                                        : AppColors.pri100,
                                    borderRadius: BorderRadius.circular(scaleHeight(20)),
                                  ),
                                  child: Center(
                                    child: FixedText(
                                      _formatTimeToKorean(matchedGames[i].time),
                                      style: AppFonts.suite.body_sm_500(context).copyWith(
                                        color: selectedGameIndex == i
                                            ? AppColors.gray20
                                            : AppColors.gray300,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (i < matchedGames.length - 1)
                                SizedBox(width: scaleWidth(8)),
                            ],
                          ],
                        ),
                      )
                          : SizedBox(), // 빈 공간이지만 높이는 유지
                    ),
                  ),

                  SizedBox(height: scaleHeight(14)),

                  // 구분선 (항상 표시)
                  Container(
                    width: calendarInnerWidth,
                    height: scaleHeight(1),
                    color: AppColors.gray50,
                    margin: EdgeInsets.symmetric(horizontal: calendarPadding),
                  ),

                  SizedBox(height: scaleHeight(10)),

                  // 선택 결과 텍스트 (항상 표시)
                  Container(
                    height: scaleHeight(20),
                    padding: EdgeInsets.symmetric(horizontal: calendarPadding),
                    child: Center(
                      child: FixedText(
                        selectedDay != null && matchedGames.isNotEmpty
                            ? () {
                          final year = selectedDay!.year;
                          final month = selectedDay!.month;
                          final day = selectedDay!.day;

                          final timeOnly = matchedGames[selectedGameIndex].time.substring(0, 5);
                          final timeParts = timeOnly.split(':');
                          final timeKorean = '${timeParts[0]}시 ${timeParts[1]}분';

                          return '현재 ${year}년 ${month}월 ${day}일 $timeKorean이 선택되어 있어요';
                        }()
                            : '일치하는 경기가 없습니다',
                        style: AppFonts.suite.caption_re_500(context).copyWith(
                          color: AppColors.gray200,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 완료 버튼 영역
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: scaleHeight(14),
                      right: calendarPadding,
                      bottom: scaleHeight(20),
                      left: calendarPadding,
                    ),
                    child: SizedBox(
                      height: scaleHeight(54),
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedDay != null && matchedGames.isNotEmpty) {
                            const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

                            final year = selectedDay!.year;
                            final month = selectedDay!.month.toString().padLeft(2, '0');
                            final day = selectedDay!.day.toString().padLeft(2, '0');
                            final weekday = weekdays[selectedDay!.weekday % 7];

                            final timeOnly = matchedGames[selectedGameIndex].time.substring(0, 5);
                            final timeParts = timeOnly.split(':');
                            final timeKorean = '${timeParts[0]}시 ${timeParts[1]}분';

                            final formattedResult = '$year - $month - $day ($weekday) $timeKorean';
                            Navigator.pop(context, {
                              'dateTime': formattedResult,
                              'gameId': matchedGames[selectedGameIndex].gameId,
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (selectedDay != null && matchedGames.isNotEmpty)
                              ? AppColors.gray700
                              : AppColors.gray200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(scaleHeight(16)),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Center(
                          child: FixedText(
                            '완료',
                            style: AppFonts.suite.head_sm_700(context).copyWith(
                              color: AppColors.gray20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}