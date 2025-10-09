import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/api/search_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isSearchFocused = false;
  bool _hasText = false;
  int _selectedTabIndex = 0;

  List<String> _popularSearches = [];
  List<String> _recentSearches = [];
  SearchResult? _searchResult;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _searchController.addListener(() {
      setState(() {
        _hasText = _searchController.text.isNotEmpty;
      });
    });

    _focusNode.addListener(() {
      setState(() {
        _isSearchFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: scaleHeight(60),
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleBackButton,
                    child: Container(
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        AppImages.backBlack,
                        width: scaleHeight(24),
                        height: scaleHeight(24),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(width: scaleWidth(8)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _focusNode.requestFocus();
                      },
                      child: Container(
                        height: scaleHeight(48),
                        decoration: BoxDecoration(
                          color: AppColors.gray30,
                          borderRadius: BorderRadius.circular(scaleHeight(12)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: scaleWidth(20)),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _focusNode,
                                  autofocus: false,
                                  style: AppFonts.pretendard.b3_sb(context).copyWith(color: AppColors.gray700),
                                  decoration: InputDecoration(
                                    hintText: '글, 제목, 내용, 해시태그, 유저',
                                    hintStyle: AppFonts.pretendard.b3_sb(context).copyWith(color: AppColors.gray300),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: _performSearch,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: scaleWidth(8)),
                              width: scaleWidth(36),
                              height: scaleHeight(36),
                              decoration: BoxDecoration(
                                color: _getButtonColor(),
                                borderRadius: BorderRadius.circular(scaleHeight(12)),
                              ),
                              child: GestureDetector(
                                onTap: _handleSearchButtonTap,
                                child: Center(
                                  child: SvgPicture.asset(
                                    _getButtonIcon(),
                                    width: scaleHeight(24),
                                    height: scaleHeight(24),
                                    color: AppColors.gray30,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _hasSearched
                  ? SearchResultsWidget(
                searchResult: _searchResult,
                selectedTabIndex: _selectedTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              )
                  : InitialSearchWidget(
                popularSearches: _popularSearches,
                recentSearches: _recentSearches,
                onSearchTap: _onSearchTap,
                onClearAllRecent: _clearAllRecentSearches,
                onDeleteRecent: _deleteRecentSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackButton() {
    if (_hasSearched) {
      setState(() {
        _hasSearched = false;
        _searchController.clear();
        _focusNode.unfocus();
        _selectedTabIndex = 0;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSearchTap(String term) {
    _searchController.text = term;
    _performSearch(term);
  }

  String _getButtonIcon() {
    if (_hasSearched && !_isSearchFocused && _hasText) {
      return AppImages.search;
    } else if (_hasText) {
      return AppImages.x;
    } else {
      return AppImages.search;
    }
  }

  Color _getButtonColor() {
    if (_hasSearched && !_isSearchFocused && _hasText) {
      return AppColors.gray700;
    } else if (_hasText) {
      return AppColors.gray300;
    } else {
      return AppColors.gray700;
    }
  }

  void _handleSearchButtonTap() {
    if (_hasSearched && !_isSearchFocused && _hasText) {
      _focusNode.requestFocus();
    } else if (_hasText) {
      _searchController.clear();
    } else {
      _focusNode.requestFocus();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final popular = await SearchApi.getPopularSearches();
      final recent = await SearchApi.getRecentSearches();
      setState(() {
        _popularSearches = popular.map((p) => p.query).toList();
        _recentSearches = recent;
      });
    } catch (e) {
      print("초기 데이터 로드 실패: $e");
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _selectedTabIndex = 0;
    });

    try {
      final result = await SearchApi.search(query);
      setState(() {
        _searchResult = result;
      });
      _loadInitialData();
    } catch (e) {
      print("검색 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllRecentSearches() async {
    await SearchApi.deleteAllRecentSearches();
    _loadInitialData();
  }

  Future<void> _deleteRecentSearch(String term) async {
    await SearchApi.deleteRecentSearch(term);
    _loadInitialData();
  }
}

/// 탭 설정
class SearchResultsWidget extends StatefulWidget {
  final SearchResult? searchResult;
  final int selectedTabIndex;
  final Function(int) onTabChanged;

  const SearchResultsWidget({
    Key? key,
    required this.searchResult,
    required this.selectedTabIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _indicatorAnimation;
  late PageController _pageController;

  double _currentPageValue = 0.0;
  bool _isPageViewScrolling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );

    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pageController = PageController(initialPage: widget.selectedTabIndex);
    _currentPageValue = widget.selectedTabIndex.toDouble();

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPageValue = _pageController.page ?? 0.0;
          _isPageViewScrolling = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTabIndex != widget.selectedTabIndex && !_isPageViewScrolling) {
      _pageController.animateToPage(
        widget.selectedTabIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      if (widget.selectedTabIndex == 1) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _isPageViewScrolling = false;
    });

    widget.onTabChanged(index);

    if (index == 1) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchResult == null) {
      return Center(child: FixedText('검색 결과가 없습니다.'));
    }

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(
            top: scaleHeight(16),
            left: scaleWidth(20),
            right: scaleWidth(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPageViewScrolling = false;
                      });
                      widget.onTabChanged(0);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FixedText(
                          '게시글',
                          style: AppFonts.suite.b3_sb(context).copyWith(
                            color: _getTabColor(0),
                          ),
                        ),
                        SizedBox(width: scaleWidth(4)),
                        FixedText(
                          '${widget.searchResult!.records.totalElements}',
                          style: AppFonts.suite.c1_m(context).copyWith(
                            color: _getTabColor(0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: scaleWidth(20)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPageViewScrolling = false;
                      });
                      widget.onTabChanged(1);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FixedText(
                          '사용자',
                          style: AppFonts.suite.b3_sb(context).copyWith(
                            color: _getTabColor(1),
                          ),
                        ),
                        SizedBox(width: scaleWidth(4)),
                        FixedText(
                          '${widget.searchResult!.users.totalElements}',
                          style: AppFonts.suite.c1_m(context).copyWith(
                            color: _getTabColor(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: scaleHeight(12)),
              _buildRealtimeIndicator(),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              RecordsListWidget(records: widget.searchResult!.records.records),
              UsersListWidget(users: widget.searchResult!.users.users),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTabColor(int tabIndex) {
    final progress = (_currentPageValue - tabIndex).abs();
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    if (tabIndex == 0) {
      return Color.lerp(Color(0x330E1117), AppColors.gray600, opacity) ?? AppColors.gray600;
    } else {
      return Color.lerp(Color(0x330E1117), AppColors.gray600, opacity) ?? AppColors.gray600;
    }
  }

  Widget _buildRealtimeIndicator() {
    final tab0Width = _getTabWidth(context, '게시글', widget.searchResult!.records.totalElements);
    final tab1Width = _getTabWidth(context, '사용자', widget.searchResult!.users.totalElements);

    final scrollProgress = _currentPageValue.clamp(0.0, 1.0);
    final indicatorOffset = scrollProgress * (tab0Width + scaleWidth(20));
    final indicatorWidth = tab0Width + (tab1Width - tab0Width) * scrollProgress;

    return Container(
      width: double.infinity,
      height: scaleHeight(2),
      child: Stack(
        children: [
          Positioned(
            left: indicatorOffset,
            child: Container(
              width: indicatorWidth,
              height: scaleHeight(2),
              decoration: BoxDecoration(
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getTabWidth(BuildContext context, String text, int count) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: AppFonts.suite.b3_sb(context),
          ),
          TextSpan(text: ' '),
          TextSpan(
            text: '$count',
            style: AppFonts.suite.c1_m(context),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
}

/// 추천 검색어, 최근 검색어 영역
class InitialSearchWidget extends StatelessWidget {
  final List<String> popularSearches;
  final List<String> recentSearches;
  final Function(String) onSearchTap;
  final VoidCallback onClearAllRecent;
  final Function(String) onDeleteRecent;

  const InitialSearchWidget({
    Key? key,
    required this.popularSearches,
    required this.recentSearches,
    required this.onSearchTap,
    required this.onClearAllRecent,
    required this.onDeleteRecent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: scaleHeight(20),
            left: scaleWidth(20),
          ),
          child: FixedText(
            '추천 검색어',
            style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray700),
          ),
        ),
        Container(
          height: scaleHeight(36),
          margin: EdgeInsets.only(top: scaleHeight(16)),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
            itemCount: popularSearches.length,
            separatorBuilder: (context, index) => SizedBox(width: scaleWidth(8)),
            itemBuilder: (context, index) {
              return SearchChipWidget(
                term: popularSearches[index],
                onTap: () => onSearchTap(popularSearches[index]),
              );
            },
          ),
        ),
        if (recentSearches.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.only(
              top: scaleHeight(36),
              left: scaleWidth(20),
              right: scaleWidth(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FixedText(
                  '최근 검색어',
                  style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray700),
                ),
                GestureDetector(
                  onTap: onClearAllRecent,
                  child: FixedText(
                    '전체삭제',
                    style: AppFonts.suite.c2_b(context).copyWith(
                      color: AppColors.gray400,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.gray400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: scaleHeight(20)),
              padding: EdgeInsets.only(left: scaleWidth(20)),
              child: SingleChildScrollView(
                child: Column(
                  children: recentSearches
                      .map((term) => RecentSearchItemWidget(
                    term: term,
                    onTap: () => onSearchTap(term),
                    onDelete: () => onDeleteRecent(term),
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
        if (recentSearches.isEmpty)
          Expanded(child: SizedBox()),
      ],
    );
  }
}

class SearchChipWidget extends StatelessWidget {
  final String term;
  final VoidCallback onTap;

  const SearchChipWidget({
    Key? key,
    required this.term,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: scaleHeight(36),
        padding: EdgeInsets.fromLTRB(
          scaleWidth(13),
          scaleHeight(11),
          scaleWidth(13),
          scaleHeight(11),
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(scaleHeight(68)),
          border: Border.all(
            color: AppColors.gray100,
            width: 1,
          ),
        ),
        child: Center(
          child: FixedText(
            term,
            style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray500),
          ),
        ),
      ),
    );
  }
}

class RecentSearchItemWidget extends StatelessWidget {
  final String term;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecentSearchItemWidget({
    Key? key,
    required this.term,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: scaleHeight(28),
      margin: EdgeInsets.only(bottom: scaleHeight(20)),
      padding: EdgeInsets.only(right: scaleWidth(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    width: scaleWidth(28),
                    height: scaleHeight(28),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(scaleHeight(14)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        AppImages.update,
                        width: scaleWidth(16),
                        height: scaleHeight(16),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(width: scaleWidth(12)),
                  Expanded(
                    child: FixedText(
                      term,
                      style: AppFonts.pretendard.b3_m(context).copyWith(color: AppColors.gray600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: scaleWidth(12)),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: scaleWidth(20),
              height: scaleHeight(20),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                AppImages.x,
                width: scaleWidth(20),
                height: scaleHeight(20),
                color: AppColors.gray200,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 게시글 검색 결과
class RecordsListWidget extends StatelessWidget {
  final List<Record> records;

  const RecordsListWidget({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray30,
      child: records.isEmpty
          ? Center(
        child: FixedText(
          "게시글 검색 결과가 없습니다.",
          style: AppFonts.pretendard.b2_m(context).copyWith(color: AppColors.gray400),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.all(scaleWidth(20)),
        itemCount: records.length,
        separatorBuilder: (context, index) => SizedBox(height: scaleHeight(16)),
        itemBuilder: (context, index) {
          final record = records[index];
          return RecordCardWidget(record: record);
        },
      ),
    );
  }
}

class RecordCardWidget extends StatelessWidget {
  final Record record;

  const RecordCardWidget({Key? key, required this.record}) : super(key: key);

  String _getTeamLogo(String teamName) {
    switch (teamName) {
      case 'KIA 타이거즈': return AppImages.tigers;
      case '두산 베어스': return AppImages.bears;
      case '롯데 자이언츠': return AppImages.giants;
      case '삼성 라이온즈': return AppImages.lions;
      case '키움 히어로즈': return AppImages.kiwoom;
      case '한화 이글스': return AppImages.eagles;
      case 'KT WIZ': return AppImages.ktwiz;
      case 'LG 트윈스': return AppImages.twins;
      case 'NC 다이노스': return AppImages.dinos;
      case 'SSG 랜더스': return AppImages.landers;
      default: return AppImages.tigers;
    }
  }

  Map<String, String> _getEmotionData(int emotionCode) {
    switch (emotionCode) {
      case 1: return {'image': AppImages.emotion_1, 'label': '짜릿해요'};
      case 2: return {'image': AppImages.emotion_2, 'label': '만족해요'};
      case 3: return {'image': AppImages.emotion_3, 'label': '감동이에요'};
      case 4: return {'image': AppImages.emotion_4, 'label': '놀랐어요'};
      case 5: return {'image': AppImages.emotion_5, 'label': '행복해요'};
      case 6: return {'image': AppImages.emotion_6, 'label': '답답해요'};
      case 7: return {'image': AppImages.emotion_7, 'label': '아쉬워요'};
      case 8: return {'image': AppImages.emotion_8, 'label': '화났어요'};
      case 9: return {'image': AppImages.emotion_9, 'label': '지쳤어요'};
      default: return {'image': AppImages.emotion_1, 'label': '짜릿해요'};
    }
  }

  String _getTimeAgo(String createdAt) {
    try {
      // 먼저 로컬 시간으로 파싱 시도
      DateTime recordTime;
      try {
        // "2025-05-26 17:42:26" 형태를 "2025-05-26T17:42:26"로 변환 후 로컬 시간으로 파싱
        recordTime = DateTime.parse(createdAt.replaceAll(' ', 'T'));
      } catch (e) {
        // 로컬 파싱이 실패하면 UTC로 파싱 후 로컬 변환
        recordTime = DateTime.parse(createdAt.replaceAll(' ', 'T') + 'Z').toLocal();
      }

      final DateTime now = DateTime.now();
      final Duration difference = now.difference(recordTime);

      // 음수가 나오면 "방금 전"으로 처리 (미래 시간인 경우)
      if (difference.inSeconds < 0) {
        return '방금 전';
      }

      // 1년 이상인 경우
      final int yearDiff = now.year - recordTime.year;
      if (yearDiff >= 1) {
        // 해당 월/일이 이미 지났는지 확인
        final bool hasDatePassed = now.month > recordTime.month ||
            (now.month == recordTime.month && now.day >= recordTime.day);

        final int actualYearDiff = hasDatePassed ? yearDiff : yearDiff - 1;

        if (actualYearDiff >= 1) {
          return '${actualYearDiff}년 전';
        }
      }

      // 1개월 이상인 경우 (월 단위 계산)
      int monthDiff = (now.year - recordTime.year) * 12 + (now.month - recordTime.month);

      // 일자까지 고려해서 정확한 월 차이 계산
      if (now.day < recordTime.day) {
        monthDiff -= 1;
      }

      if (monthDiff >= 1) {
        return '${monthDiff}개월 전';
      }

      // 1개월 미만인 경우
      if (difference.inDays >= 1) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전'; // 0초나 음수인 경우도 "방금 전"으로 처리
      }
    } catch (e) {
      print('❌ 시간 파싱 실패: $e, createdAt: $createdAt');
      return '알 수 없음';
    }
  }

  Widget _buildLongContentWidget(String longContent, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final TextStyle textStyle = AppFonts.pretendard.c1_m_narrow(context).copyWith(
          color: AppColors.gray600,
        );

        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: longContent, style: textStyle),
          maxLines: 4,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return FixedText(
            longContent,
            style: textStyle,
            maxLines: 4,
          );
        } else {
          const String moreText = '...더보기';
          final TextPainter moreTextPainter = TextPainter(
            text: TextSpan(text: moreText, style: textStyle),
            textDirection: TextDirection.ltr,
          );
          moreTextPainter.layout();

          final TextPainter truncatedPainter = TextPainter(
            text: TextSpan(text: longContent, style: textStyle),
            maxLines: 4,
            textDirection: TextDirection.ltr,
          );

          truncatedPainter.layout(maxWidth: constraints.maxWidth);

          final int endIndex = truncatedPainter.getPositionForOffset(
            Offset(constraints.maxWidth - moreTextPainter.width,
                truncatedPainter.height - textStyle.fontSize!),
          ).offset;

          final String truncatedText = longContent.substring(0, endIndex).trimRight();

          return RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: truncatedText,
                  style: textStyle,
                ),
                TextSpan(
                  text: moreText,
                  style: textStyle.copyWith(color: AppColors.gray400),
                ),
              ],
            ),
            maxLines: 4,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleHeight(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: scaleHeight(60),
            decoration: BoxDecoration(
              color: AppColors.gray700,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(scaleHeight(16)),
                topRight: Radius.circular(scaleHeight(16)),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: scaleWidth(25),
                right: scaleWidth(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.location,
                            width: scaleWidth(10),
                            height: scaleHeight(11.7),
                            color: AppColors.gray50,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: scaleWidth(9)),
                          FixedText(
                            record.gameDate.replaceAll("요일", ""),
                            style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray50),
                          ),
                        ],
                      ),
                      SizedBox(height: scaleHeight(8)),
                      Padding(
                        padding: EdgeInsets.only(left: scaleWidth(19)),
                        child: FixedText(
                          record.stadium,
                          style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: scaleWidth(24),
                        height: scaleHeight(24),
                        child: Image.asset(
                          _getTeamLogo(record.homeTeam),
                          width: scaleWidth(24),
                          height: scaleHeight(24),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: scaleWidth(24),
                              height: scaleHeight(24),
                              decoration: BoxDecoration(
                                color: AppColors.gray200,
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: scaleWidth(12)),
                      FixedText(
                        '${record.homeScore}',
                        style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                      ),
                      SizedBox(width: scaleWidth(10)),
                      FixedText(
                        ':',
                        style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                      ),
                      SizedBox(width: scaleWidth(10)),
                      FixedText(
                        '${record.awayScore}',
                        style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                      ),
                      SizedBox(width: scaleWidth(12)),
                      Container(
                        width: scaleWidth(24),
                        height: scaleHeight(24),
                        child: Image.asset(
                          _getTeamLogo(record.awayTeam),
                          width: scaleWidth(24),
                          height: scaleHeight(24),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: scaleWidth(24),
                              height: scaleHeight(24),
                              decoration: BoxDecoration(
                                color: AppColors.gray200,
                                shape: BoxShape.circle,
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
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: scaleHeight(16)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: scaleWidth(28),
                      height: scaleHeight(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gray50, width: 0.8),
                      ),
                      child: ClipOval(
                        child: record.authorProfileImage != null && record.authorProfileImage!.isNotEmpty
                            ? Image.network(
                          record.authorProfileImage!,
                          width: scaleWidth(28),
                          height: scaleHeight(28),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return SvgPicture.asset(
                              AppImages.profile,
                              width: scaleWidth(28),
                              height: scaleHeight(28),
                              fit: BoxFit.cover,
                            );
                          },
                        )
                            : SvgPicture.asset(
                          AppImages.profile,
                          width: scaleWidth(28),
                          height: scaleHeight(28),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: scaleWidth(8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: scaleHeight(4)),
                          Row(
                            children: [
                              FixedText(
                                record.authorNickname,
                                style: AppFonts.pretendard.b3_m(context).copyWith(color: Colors.black),
                              ),
                              SizedBox(width: scaleWidth(6)),
                              FixedText(
                                '${record.authorFavTeam} 팬',
                                style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
                              ),
                              SizedBox(width: scaleWidth(6)),
                              FixedText(
                                _getTimeAgo(record.createdAt),
                                style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
                              ),
                            ],
                          ),
                          SizedBox(height: scaleHeight(8)),
                          if (record.longContent != null && record.longContent!.trim().isNotEmpty)
                            _buildLongContentWidget(record.longContent!, context),
                        ],
                      ),
                    ),
                  ],
                ),
                if (record.longContent != null && record.longContent!.trim().isNotEmpty) ...[
                  if (record.mediaUrls != null && record.mediaUrls!.isNotEmpty) ...[
                    SizedBox(height: scaleHeight(12)),
                    Padding(
                      padding: EdgeInsets.only(left: scaleWidth(36)),
                      child: Container(
                        height: scaleHeight(96),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: record.mediaUrls!.length,
                          separatorBuilder: (context, index) => SizedBox(width: scaleWidth(4)),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                print('사진 클릭: ${record.mediaUrls![index]}');
                              },
                              child: Container(
                                width: scaleWidth(96),
                                height: scaleHeight(96),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  border: Border.all(color: AppColors.gray100, width: 0.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(scaleHeight(8)),
                                  child: Image.network(
                                    record.mediaUrls![index],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppColors.gray50,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.gray400,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.gray100,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: scaleWidth(24),
                                            color: AppColors.gray400,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
                if (record.longContent == null || record.longContent!.trim().isEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(left: scaleWidth(36)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          _getEmotionData(record.emotionCode)['image']!,
                          width: scaleWidth(45),
                          height: scaleHeight(45),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: scaleWidth(8)),
                        FixedText(
                          _getEmotionData(record.emotionCode)['label']!,
                          style: AppFonts.suite.b3_m(context).copyWith(color: AppColors.gray700),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: scaleHeight(12)),
                Padding(
                  padding: EdgeInsets.only(left: scaleWidth(36)),
                  child: Row(
                    children: [
                      Container(
                        height: scaleHeight(24),
                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(8)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(scaleHeight(40)),
                          border: Border.all(color: AppColors.gray50, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppImages.good,
                              width: scaleWidth(14),
                              height: scaleHeight(14),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: scaleWidth(4)),
                            FixedText(
                              '응원해요',
                              style: AppFonts.pretendard.c2_m(context).copyWith(color: AppColors.gray300),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: scaleWidth(8)),
                      Container(
                        height: scaleHeight(24),
                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(8)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(scaleHeight(40)),
                          border: Border.all(color: AppColors.gray50, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppImages.smile,
                              width: scaleWidth(14),
                              height: scaleHeight(14),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: scaleWidth(4)),
                            FixedText(
                              '힘내요',
                              style: AppFonts.pretendard.c2_m(context).copyWith(color: AppColors.gray300),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: scaleWidth(8)),
                      Container(
                        height: scaleHeight(24),
                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(8)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(scaleHeight(40)),
                          border: Border.all(color: AppColors.gray50, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppImages.congratulate,
                              width: scaleWidth(14),
                              height: scaleHeight(14),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: scaleWidth(4)),
                            FixedText(
                              '축하해요',
                              style: AppFonts.pretendard.c2_m(context).copyWith(color: AppColors.gray300),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: scaleHeight(16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 사용자 검색 결과
class UsersListWidget extends StatelessWidget {
  final List<UserSearchResult> users;

  const UsersListWidget({Key? key, required this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray30,
      child: users.isEmpty
          ? Center(
        child: FixedText(
          "사용자 검색 결과가 없습니다.",
          style: AppFonts.pretendard.b2_m(context).copyWith(color: AppColors.gray400),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.all(scaleWidth(20)),
        itemCount: users.length,
        separatorBuilder: (context, index) => SizedBox(height: scaleHeight(8)),
        itemBuilder: (context, index) {
          final user = users[index];
          return UserSearchTileWidget(user: user);
        },
      ),
    );
  }
}

class UserSearchTileWidget extends StatefulWidget {
  final UserSearchResult user;

  const UserSearchTileWidget({Key? key, required this.user}) : super(key: key);

  @override
  State<UserSearchTileWidget> createState() => _UserSearchTileWidgetState();
}

class _UserSearchTileWidgetState extends State<UserSearchTileWidget> {
  late String _currentFollowStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentFollowStatus = widget.user.followStatus;
  }

  String _getButtonText() {
    switch (_currentFollowStatus) {
      case 'FOLLOWING':
        return '팔로잉';
      case 'PENDING':
      case 'REQUESTED':
        return '요청됨';
      case 'NOT_FOLLOWING':
      default:
        return '팔로우';
    }
  }

  Color _getButtonBackgroundColor() {
    switch (_currentFollowStatus) {
      case 'FOLLOWING':
        return AppColors.gray50;
      case 'PENDING':
      case 'REQUESTED':
        return AppColors.gray50;
      case 'NOT_FOLLOWING':
      default:
        return AppColors.gray700;
    }
  }

  Color _getButtonTextColor() {
    switch (_currentFollowStatus) {
      case 'FOLLOWING':
        return AppColors.gray600;
      case 'PENDING':
      case 'REQUESTED':
        return AppColors.gray600;
      case 'NOT_FOLLOWING':
      default:
        return Colors.white;
    }
  }

  Future<void> _handleFollowButton() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = widget.user.userId;

      if (_currentFollowStatus == 'FOLLOWING') {
        await UserApi.unfollowUser(userId);
        setState(() {
          _currentFollowStatus = 'NOT_FOLLOWING';
        });
      } else if (_currentFollowStatus == 'NOT_FOLLOWING') {
        final response = await UserApi.followUser(userId);
        final responseData = response['data'];

        setState(() {
          if (responseData['pending'] == true) {
            _currentFollowStatus = 'REQUESTED';
          } else {
            _currentFollowStatus = 'FOLLOWING';
          }
        });
      } else if (_currentFollowStatus == 'REQUESTED' || _currentFollowStatus == 'PENDING') {
        await UserApi.unfollowUser(userId);
        setState(() {
          _currentFollowStatus = 'NOT_FOLLOWING';
        });
      }
    } catch (e) {
      print("팔로우 상태 변경 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: scaleHeight(80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleHeight(16)),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: scaleWidth(20)),
            child: Container(
              width: scaleWidth(40),
              height: scaleHeight(40),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray50, width: 1),
                borderRadius: BorderRadius.circular(scaleWidth(20)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(scaleWidth(20)),
                child: widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
                    ? Image.network(
                  widget.user.profileImageUrl!,
                  width: scaleWidth(40),
                  height: scaleHeight(40),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: scaleWidth(40),
                      height: scaleHeight(40),
                      color: AppColors.gray100,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SvgPicture.asset(
                      AppImages.profile,
                      width: scaleWidth(40),
                      height: scaleHeight(40),
                      fit: BoxFit.cover,
                    );
                  },
                )
                    : SvgPicture.asset(
                  AppImages.profile,
                  width: scaleWidth(40),
                  height: scaleHeight(40),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: scaleWidth(12)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FixedText(
                  widget.user.nickname,
                  style: AppFonts.pretendard.b2_m(context).copyWith(color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: scaleHeight(8)),
                FixedText(
                  widget.user.favTeam,
                  style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray400),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: scaleWidth(20)),
            child: GestureDetector(
              onTap: _handleFollowButton,
              child: Container(
                width: scaleWidth(70),
                height: scaleHeight(36),
                decoration: BoxDecoration(
                  color: _getButtonBackgroundColor(),
                  borderRadius: BorderRadius.circular(scaleHeight(8)),
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                    width: scaleWidth(16),
                    height: scaleHeight(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_getButtonTextColor()),
                    ),
                  )
                      : FixedText(
                    _getButtonText(),
                    style: AppFonts.suite.c1_b(context).copyWith(color: _getButtonTextColor()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}