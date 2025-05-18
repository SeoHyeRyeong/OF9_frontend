import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/models/game_response.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/utils/fixed_text.dart';

DateTime? tryParseDateFromOcr(String rawText) {
  final regex = RegExp(r'(20\d{2})[년\-\. ]+(\d{1,2})[월\-\. ]+(\d{1,2})');
  final match = regex.firstMatch(rawText);
  if (match != null) {
    try {
      final y = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final d = int.parse(match.group(3)!);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }
  return null;
}

DateTime? findRecentMatchDate({
  required List<GameResponse> games,
  required String home,
  required String away,
}) {
  final matched = games.where((g) =>
  (g.homeTeam == home && g.awayTeam == away) ||
      (g.homeTeam == away && g.awayTeam == home)
  ).toList();
  if (matched.isEmpty) return null;
  matched.sort((a, b) => a.date.compareTo(b.date));
  return matched.last.date;
}

DateTime? findClosestGameDate(DateTime target, Iterable<DateTime> gameDates) {
  if (gameDates.isEmpty) return null;
  return gameDates.reduce((a, b) =>
  (a.difference(target).abs().inDays < b.difference(target).abs().inDays) ? a : b);
}

Future<String?> showDateTimePicker({
  required BuildContext context,
  String? ocrDateText,
  String? homeTeam,
  String? opponentTeam,
}) async {
  DateTime focused = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;
  Map<DateTime, List<GameResponse>> events = {};

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

  await loadEvents(focused);

  final allGames = events.entries.expand((e) => e.value).toList();
  final allDates = allGames.map((g) => g.date).toList();

  final firstDay = DateTime(2024, 1, 1);
  final lastDay  = DateTime(2026, 12, 31);

  DateTime? resolvedFocus;

  if (ocrDateText != null) {
    final parsedDate = tryParseDateFromOcr(ocrDateText);
    if (parsedDate != null) resolvedFocus = parsedDate;
  }

  if (resolvedFocus == null && homeTeam != null && opponentTeam != null) {
    resolvedFocus = findRecentMatchDate(
      games: allGames,
      home: homeTeam,
      away: opponentTeam,
    );
  }

  if (resolvedFocus == null) {
    resolvedFocus = findClosestGameDate(DateTime.now(), allDates);
  }

  focused = resolvedFocus ?? DateTime.now();
  await loadEvents(focused);
  selectedDay = focused;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        height: 600.h,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (innerContext, setModalState) {
            List<TimeOfDay> timesForSelected = [];
            if (selectedDay != null && events[selectedDay] != null) {
              timesForSelected = events[selectedDay]!
                  .map((g) {
                final parts = g.time.split(':');
                return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              })
                  .toSet()
                  .toList();
            }

            void changeMonth(int diff) async {
              focused = DateTime(focused.year, focused.month + diff, 1);
              await loadEvents(focused);
              setModalState(() {
                selectedDay = null;
                selectedTime = null;
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                      const Expanded(
                        child: Center(
                          child: FixedText(
                            '일시',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => changeMonth(-1),
                      ),
                      SizedBox(width: 12.w),
                      Text('${focused.year}년 ${focused.month}월', style: AppFonts.b2_b(context)),
                      SizedBox(width: 12.w),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => changeMonth(1),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 11.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['일', '월', '화', '수', '목', '금', '토']
                        .map((d) => SizedBox(
                      width: 36.w,
                      height: 12.h,
                      child: Center(
                        child: FixedText(
                          d,
                          style: AppFonts.b2_m_long(context).copyWith(color: AppColors.gray300),
                        ),
                      ),
                    ))
                        .toList(),
                  ),
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: TableCalendar<GameResponse>(
                    firstDay: firstDay,
                    lastDay: lastDay,
                    focusedDay: focused,
                    headerVisible: false,
                    calendarFormat: CalendarFormat.month,
                    eventLoader: (d) => events[d] ?? [],
                    selectedDayPredicate: (d) => selectedDay != null && isSameDay(d, selectedDay),
                    enabledDayPredicate: (date) => date.isBefore(DateTime.now()),
                    onDaySelected: (day, _) {
                      setModalState(() {
                        selectedDay = day;
                        if ((events[day]?.isNotEmpty ?? false)) {
                          final p = events[day]![0].time.split(':');
                          selectedTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
                        }
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (ctx, date, _) {
                        final isEnabled = date.isBefore(DateTime.now());
                        final isSel = selectedDay != null && isSameDay(date, selectedDay);
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 12.w),
                          child: Container(
                            width: 30.w,
                            height: 30.w,
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.pri500 : Colors.transparent,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Center(
                              child: FixedText(
                                '${date.day}',
                                style: AppFonts.b2_m_long(ctx).copyWith(
                                  color: isEnabled ? AppColors.gray900 : AppColors.gray200,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ✅ 완료 버튼 추가
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: (selectedDay != null && selectedTime != null)
                          ? () {
                        final selectedDateTime = DateTime(
                          selectedDay!.year,
                          selectedDay!.month,
                          selectedDay!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                        final result = DateFormat('yyyy-MM-dd HH:mm:00').format(selectedDateTime);
                        Navigator.pop(context, result);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (selectedDay != null && selectedTime != null)
                            ? AppColors.gray700
                            : AppColors.gray200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: FixedText(
                        '완료',
                        style: AppFonts.b2_b(context).copyWith(color: AppColors.gray20),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
