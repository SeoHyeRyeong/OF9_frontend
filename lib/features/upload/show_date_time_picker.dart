import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

      // 연도 범위 검증 (2025년만 허용)
      if (year != 2025) {
        print('⚠️ OCR 추출된 연도가 범위를 벗어남: $year (2025년만 허용)');
        return null;
      }

      // 월, 일 범위 검증
      if (month < 1 || month > 12 || day < 1 || day > 31) {
        print('⚠️ OCR 추출된 월/일이 유효하지 않음: $month월 $day일');
        return null;
      }

      return DateTime(year, month, day);
    } catch (_) {}
  }
  return null;
}

///날짜를 요일 포함 형식으로 변환 (2025 - 04 - 15 (수)형식)
String formatDateWithWeekday(String dateStr, String timeStr) {
  try {
    // extractedDate가 "2025-04-15" 형식으로 온다고 가정
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);

      const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
      final weekday = weekdays[date.weekday % 7];

      // 시간 형식 변환 (14:00 -> 14시 00분)
      final timeParts = timeStr.split(':');
      final timeKorean = '${timeParts[0]}시 ${timeParts[1]}분';

      return '${parts[0]} - ${parts[1].padLeft(2, '0')} - ${parts[2].padLeft(2, '0')} ($weekday) $timeKorean';
    }
  } catch (e) {
    print('날짜 포맷 변환 오류: $e');
  }
  return '$dateStr $timeStr'; // 실패시 원본 반환
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
Future<String?> showDateTimePicker({
  required BuildContext context,
  String? ocrDateText,
  String? homeTeam,  // fullname으로 받음
  String? opponentTeam,  // fullname으로 받음
}) async {
  DateTime focused = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;
  List<GameResponse> matchedGames = []; // 선택된 날짜의 경기 목록
  int selectedGameIndex = 0; // 선택된 경기 인덱스 추가
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

    // fullname을 shortname으로 변환하는 함수
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

    // 팀명 매칭 함수
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

      // 홈팀, 원정팀 순서대로만 매칭
      matchedGames = games.where((game) {
        final homeMatch = isTeamMatch(game.homeTeam, homeShort);
        final awayMatch = isTeamMatch(game.awayTeam, awayShort);

        return homeMatch && awayMatch; // 홈팀, 원정팀 순서가 정확히 일치할 때만
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
    // OCR 날짜가 달력 범위를 벗어나는지 확인
    if (resolvedFocus != null) {
      if (resolvedFocus.isBefore(firstDay) || resolvedFocus.isAfter(lastDay)) {
        print('⚠️ OCR 날짜가 달력 범위를 벗어남: $resolvedFocus (범위: $firstDay ~ $lastDay)');
        resolvedFocus = null; // 범위를 벗어나면 null로 설정
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

  // OCR 날짜가 있으면 자동으로 해당 날짜 선택 및 매칭된 경기 로드
  DateTime? initialSelectedDay;
  if (ocrDateText != null && resolvedFocus != null) {
    initialSelectedDay = resolvedFocus;
  }

  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight; //실제 사용 가능 높이

          return Container(
            width: double.infinity,
            height: screenHeight * 0.775,
            margin: EdgeInsets.only(top: screenHeight * 0.2),
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

                // 현재 달의 주 수 계산 (5주 또는 6주)
                final firstOfMonth = DateTime(focused.year, focused.month, 1);
                final lastOfMonth = DateTime(focused.year, focused.month + 1, 0);
                final startOfCalendar = firstOfMonth.subtract(
                    Duration(days: firstOfMonth.weekday % 7));
                final endOfCalendar = lastOfMonth.add(
                    Duration(days: (6 - lastOfMonth.weekday % 7) % 7));
                final totalWeeks = (endOfCalendar.difference(startOfCalendar).inDays + 1) ~/ 7;

                // 5주/6주에 따른 동적 크기 조정
                final is6Weeks = totalWeeks == 6;
                final rowHeight = is6Weeks ? scaleHeight(42.5) : scaleHeight(51.5);
                final cellSize = is6Weeks ? scaleHeight(36) : scaleHeight(42);
                final selectedCircleSize = is6Weeks ? scaleHeight(28) : scaleHeight(32);

                return SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, sheetConstraints) {
                      return Column(
                        children: [
                          // 헤더 영역
                          Container(
                            height: sheetConstraints.maxHeight * 0.1,
                            child: Row(
                              children: [
                                // 뒤로가기 버튼
                                Padding(
                                  padding: EdgeInsets.only(left: scaleWidth(20)),
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: SvgPicture.asset(
                                      AppImages.backBlack,
                                      width: scaleHeight(24),
                                      height: scaleHeight(24),
                                    ),
                                  ),
                                ),

                                // 중앙 제목
                                Expanded(
                                  child: Center(
                                    child: FixedText(
                                      '일시',
                                      style: AppFonts.b2_b(context),
                                    ),
                                  ),
                                ),

                                SizedBox(width: scaleWidth(44)),
                              ],
                            ),
                          ),

                          const Spacer(flex: 5),

                          // 년/월 네비게이션
                          SizedBox(
                            width: scaleWidth(142),
                            height: scaleHeight(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => changeMonth(-1),
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: scaleHeight(18),
                                    color: AppColors.gray400,
                                  ),
                                ),
                                FixedText(
                                  '${focused.year}년 ${focused.month}월',
                                  style: AppFonts.b1_sb(context).copyWith(
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => changeMonth(1),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: scaleHeight(18),
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 18),

                          // 달력 영역
                          Expanded(
                            flex: 300,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                              child: Column(
                                children: [
                                  // 요일 헤더
                                  Container(
                                    width: scaleWidth(320),
                                    height: scaleHeight(20),
                                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(22)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        for (int i = 0; i < 7; i++)
                                          FixedText(
                                            const ['일', '월', '화', '수', '목', '금', '토'][i],
                                            style: AppFonts.c1_r(context).copyWith(
                                              color: AppColors.gray300,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // 달력 그리드
                                  Expanded(
                                    flex: 100,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: scaleWidth(3),
                                      ),
                                      child: ClipRect(
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
                                            canMarkersOverflow: true,
                                            cellMargin: EdgeInsets.zero,
                                          ),
                                          selectedDayPredicate: (d) =>
                                          selectedDay != null && isSameDay(d, selectedDay),
                                          enabledDayPredicate: (date) => true,
                                          onPageChanged: (fd) => setState(() => focused = fd),
                                          onDaySelected: (day, _) async {
                                            // 날짜 선택 로직 (기존과 동일)
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
                                                width: cellSize,
                                                height: cellSize,
                                                margin: EdgeInsets.zero,
                                                child: Center(
                                                  child: FixedText(
                                                    '${date.day}',
                                                    style: AppFonts.b2_m_long(ctx).copyWith(
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
                                                width: cellSize,
                                                height: cellSize,
                                                margin: EdgeInsets.zero,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Center(
                                                      child: Container(
                                                        width: selectedCircleSize,
                                                        height: selectedCircleSize,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.pri500,
                                                          borderRadius: BorderRadius.circular(
                                                            scaleHeight(16),
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: FixedText(
                                                            '${date.day}',
                                                            style: AppFonts.b2_m_long(ctx).copyWith(
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // 하단 점 표시
                                                    Align(
                                                      alignment: Alignment.bottomCenter,
                                                      child: Transform.translate(
                                                        offset: Offset(0, scaleHeight(4)),
                                                        child: Container(
                                                          width: scaleHeight(4),
                                                          height: scaleHeight(4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.gray300,
                                                            shape: BoxShape.circle,
                                                          ),
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
                                                width: cellSize,
                                                height: cellSize,
                                                margin: EdgeInsets.zero,
                                                child: isSel
                                                    ? Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Center(
                                                      child: Container(
                                                        width: selectedCircleSize,
                                                        height: selectedCircleSize,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.pri500,
                                                          borderRadius: BorderRadius.circular(
                                                            scaleHeight(16),
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: FixedText(
                                                            '${date.day}',
                                                            style: AppFonts.b2_m_long(ctx).copyWith(
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment.bottomCenter,
                                                      child: Transform.translate(
                                                        offset: Offset(0, scaleHeight(4)),
                                                        child: Container(
                                                          width: scaleHeight(4),
                                                          height: scaleHeight(4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.gray300,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                    : Center(
                                                  child: FixedText(
                                                    '${date.day}',
                                                    style: AppFonts.b2_m_long(ctx).copyWith(
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
                                  ),
                                ],
                              ),
                            ),
                          ),


                          // 경기 시간 표시 영역
                          if (selectedDay != null && matchedGames.isNotEmpty)
                            Container(
                              width: scaleWidth(320),
                              height: scaleHeight(34),
                              margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
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
                                        width: scaleWidth(75),
                                        height: scaleHeight(34),
                                        decoration: BoxDecoration(
                                          color: selectedGameIndex == i
                                              ? AppColors.pri300
                                              : AppColors.gray50.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(scaleHeight(60)),
                                        ),
                                        child: Center(
                                          child: FixedText(
                                            _formatTimeToKorean(matchedGames[i].time),
                                            style: AppFonts.b3_sb(context).copyWith(
                                              color: selectedGameIndex == i
                                                  ? AppColors.gray20
                                                  : AppColors.gray600,
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
                            ),

                          const Spacer(flex: 15),

                          // 구분선
                          Container(
                            width: scaleWidth(320),
                            height: scaleHeight(1),
                            color: AppColors.gray50,
                            margin: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                          ),

                          const Spacer(flex: 18),

                          // 선택 결과 텍스트
                          Container(
                            width: scaleWidth(300),
                            child: Center(
                              child: FixedText(
                                selectedDay != null && matchedGames.isNotEmpty
                                    ? () {
                                  const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
                                  final year = selectedDay!.year;
                                  final month = selectedDay!.month;
                                  final day = selectedDay!.day;
                                  final weekday = weekdays[selectedDay!.weekday % 7];

                                  final timeOnly = matchedGames[selectedGameIndex].time.substring(0, 5);
                                  final timeParts = timeOnly.split(':');
                                  final timeKorean = '${timeParts[0]}시 ${timeParts[1]}분';

                                  return '현재는 ${year}년 ${month}월 ${day}일 $timeKorean이 선택되어 있어요';
                                }()
                                    : '일치하는 경기가 없습니다',
                                style: AppFonts.c2_sb(context).copyWith(
                                  color: AppColors.gray400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          // 완료 버튼
                          Container(
                            padding: EdgeInsets.fromLTRB(
                              scaleWidth(20),
                              scaleHeight(24),
                              scaleWidth(20),
                              scaleHeight(10),
                            ),
                            child: SizedBox(
                              width: scaleWidth(320),
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
                                    Navigator.pop(context, formattedResult);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (selectedDay != null && matchedGames.isNotEmpty)
                                      ? AppColors.gray700
                                      : AppColors.gray200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  ),
                                  elevation: 0,
                                ),
                                child: FixedText(
                                  '완료',
                                  style: AppFonts.b3_sb(context).copyWith(
                                    color: AppColors.gray20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(flex: 21),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}
