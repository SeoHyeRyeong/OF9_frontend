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
  int _selectedTabIndex = 0; // 탭 선택 상태 관리

  List<String> _popularSearches = [];
  List<String> _recentSearches = [];
  SearchResult? _searchResult;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // 텍스트 변경 감지
    _searchController.addListener(() {
      setState(() {
        _hasText = _searchController.text.isNotEmpty;
      });
    });

    // 포커스 변경 감지
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
            // 상단 검색 영역
            Container(
              height: scaleHeight(60),
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
              child: Row(
                children: [
                  // 뒤로가기 버튼
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

                  // 검색 컨테이너
                  GestureDetector(
                    onTap: () {
                      _focusNode.requestFocus();
                    },
                    child: Container(
                      width: scaleWidth(288),
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

                          // 검색/X 버튼 컨테이너
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
                ],
              ),
            ),

            // 메인 콘텐츠
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

  // 기능 메서드들
  void _handleBackButton() {
    if (_hasSearched) {
      setState(() {
        _hasSearched = false;
        _searchController.clear();
        _focusNode.unfocus();
        _selectedTabIndex = 0; // 탭 인덱스 초기화
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSearchTap(String term) {
    _searchController.text = term;
    _performSearch(term);
  }

  // 검색/X 버튼 아이콘 결정
  String _getButtonIcon() {
    if (_hasSearched && !_isSearchFocused && _hasText) {
      return AppImages.search; // 검색 완료 상태
    } else if (_hasText) {
      return AppImages.x; // 텍스트 입력 중
    } else {
      return AppImages.search; // 기본 상태
    }
  }

  // 검색/X 버튼 색상 결정
  Color _getButtonColor() {
    if (_hasSearched && !_isSearchFocused && _hasText) {
      return AppColors.gray700; // 검색 완료 상태
    } else if (_hasText) {
      return AppColors.gray300; // 텍스트 입력 중 (x 아이콘)
    } else {
      return AppColors.gray700; // 기본 상태 (search 아이콘)
    }
  }

  // 검색/X 버튼 탭 처리
  void _handleSearchButtonTap() {
    if (_hasSearched && !_isSearchFocused && _hasText) {
      // 검색 완료 상태에서 search 버튼 클릭 - 포커스 주기
      _focusNode.requestFocus();
    } else if (_hasText) {
      // X 버튼 기능 - 텍스트만 삭제 (포커스 유지)
      _searchController.clear();
    } else {
      // 검색 버튼 기능 - 포커스 주기
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
      _selectedTabIndex = 0; // 검색 시 탭 초기화
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

// 검색 결과 위젯 - 커스텀 탭으로 수정
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

    // PageView 스크롤 감지
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
      // 탭 클릭으로 인한 변경인 경우에만 PageView 동기화
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
    // PageView 스와이프로 인한 변경
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
        // 커스텀 탭 헤더
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
                  // 게시글 탭
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

                  // 사용자 탭
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

              // 실시간 슬라이딩 인디케이터
              _buildRealtimeIndicator(),
            ],
          ),
        ),

        // 탭 콘텐츠 - PageView로 변경
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

  // 실시간 스크롤에 따른 탭 색상 계산
  Color _getTabColor(int tabIndex) {
    final progress = (_currentPageValue - tabIndex).abs();
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    if (tabIndex == 0) {
      // 게시글 탭: 0에 가까울수록 진하게
      return Color.lerp(Color(0x330E1117), AppColors.gray600, opacity) ?? AppColors.gray600;
    } else {
      // 사용자 탭: 1에 가까울수록 진하게
      return Color.lerp(Color(0x330E1117), AppColors.gray600, opacity) ?? AppColors.gray600;
    }
  }

  // 실시간 인디케이터 빌드
  Widget _buildRealtimeIndicator() {
    final tab0Width = _getTabWidth(context, '게시글', widget.searchResult!.records.totalElements);
    final tab1Width = _getTabWidth(context, '사용자', widget.searchResult!.users.totalElements);

    // 실시간 스크롤 진행도 (0.0 ~ 1.0)
    final scrollProgress = _currentPageValue.clamp(0.0, 1.0);

    // 인디케이터 위치와 너비 실시간 계산
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

  // 탭 밑줄 너비 계산 (텍스트 + 숫자 + 간격 포함)
  double _getTabWidth(BuildContext context, String text, int count) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: AppFonts.suite.b3_sb(context),
          ),
          TextSpan(text: ' '), // 4px 간격을 공백으로 근사
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

// 초기 화면 위젯
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
        // 추천 검색어 섹션
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

        // 추천 검색어 가로 스크롤 리스트
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

        // 최근 검색어 헤더 (검색 기록이 있을 때만 표시)
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

          // 최근 검색어 리스트
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: scaleHeight(20)),
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
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

        // 최근 검색어가 없을 때는 빈 공간
        if (recentSearches.isEmpty)
          Expanded(child: SizedBox()),
      ],
    );
  }
}

// 추천 검색어 칩 위젯
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

// 최근 검색어 아이템 위젯
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
      width: scaleWidth(320),
      height: scaleHeight(28),
      margin: EdgeInsets.only(bottom: scaleHeight(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 영역 (아이콘 + 텍스트)
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  // 원형 아이콘 컨테이너
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

                  // 검색어 텍스트
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

          // X 버튼
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

// 게시글 리스트 위젯 - 완전히 새로운 디자인
class RecordsListWidget extends StatelessWidget {
  final List<Record> records;

  const RecordsListWidget({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray30, // 배경색을 gray30으로 변경
      child: records.isEmpty
          ? Center(
        child: FixedText(
          "게시글 검색 결과가 없습니다.",
          style: AppFonts.pretendard.b2_m(context).copyWith(color: AppColors.gray400),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.all(scaleWidth(20)), // 모든 방향 20px 패딩
        itemCount: records.length,
        separatorBuilder: (context, index) => SizedBox(height: scaleHeight(16)), // 16px 간격
        itemBuilder: (context, index) {
          final record = records[index];
          return RecordCardWidget(record: record);
        },
      ),
    );
  }
}

// 새로운 게시글 카드 위젯
class RecordCardWidget extends StatelessWidget {
  final Record record;

  const RecordCardWidget({Key? key, required this.record}) : super(key: key);

  // 팀명에 따른 로고 이미지 경로를 반환하는 함수
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
      default: return AppImages.tigers; // 기본 로고
    }
  }

  // createdAt 시간을 기준으로 경과 시간을 계산하는 함수
  String _getTimeAgo(String createdAt) {
    try {
      final DateTime recordTimeUTC = DateTime.parse(
        createdAt.replaceAll(' ', 'T') + 'Z',
      );
      final DateTime recordTime = recordTimeUTC.toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(recordTime);

      if (difference.inDays >= 365) {
        return '${(difference.inDays / 365).floor()}년 전';
      } else if (difference.inDays >= 30) {
        return '${(difference.inDays / 30).floor()}개월 전';
      } else if (difference.inDays >= 1) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return '알 수 없음';
    }
  }

  // 긴 텍스트를 4줄로 제한하고 더보기 기능을 구현하는 위젯
  Widget _buildLongContentWidget(String longContent) {
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
          // 4줄을 넘지 않으면 전체 텍스트 표시
          return FixedText(
            longContent,
            style: textStyle,
            maxLines: 4,
          );
        } else {
          // 4줄을 넘으면 더보기 처리
          const String moreText = '...더보기';

          // 더보기 텍스트의 너비 계산
          final TextPainter moreTextPainter = TextPainter(
            text: TextSpan(text: moreText, style: textStyle),
            textDirection: TextDirection.ltr,
          );
          moreTextPainter.layout();

          // 4줄에서 더보기 텍스트 너비만큼 뺀 공간에 들어갈 텍스트 계산
          final TextPainter truncatedPainter = TextPainter(
            text: TextSpan(text: longContent, style: textStyle),
            maxLines: 4,
            textDirection: TextDirection.ltr,
          );

          truncatedPainter.layout(maxWidth: constraints.maxWidth);

          // 4번째 줄 끝에서 더보기 텍스트 공간만큼 자르기
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
      width: scaleWidth(320),
      height: scaleHeight(330),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleHeight(16)), // radius 16px
      ),
      child: Column(
        children: [
          // 상단 gray700 영역 (60px)
          Container(
            width: scaleWidth(320),
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
                crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
                children: [
                  // 왼쪽: 날짜와 구장 정보
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                    children: [
                      // location 아이콘과 날짜
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.location, // location svg 파일
                            width: scaleWidth(10),
                            height: scaleHeight(11.7),
                            color: AppColors.gray50, // 아이콘 색상을 gray50으로 설정
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: scaleWidth(9)), // 이미지 9px 옆
                          FixedText(
                            record.gameDate.replaceAll("요일", ""), // "요일" 제거
                            style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray50),
                          ),
                        ],
                      ),

                      SizedBox(height: scaleHeight(8)), // 날짜 아래 8px

                      // 구장 정보
                      Padding(
                        padding: EdgeInsets.only(left: scaleWidth(19)), // location 아이콘 + 9px 간격만큼 들여쓰기
                        child: FixedText(
                          record.stadium, // 구장 정보
                          style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
                        ),
                      ),
                    ],
                  ),

                  // 오른쪽: 팀 스코어 및 이미지 (홈팀부터 원정팀 순서)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
                    children: [
                      // 홈팀 이미지 (24*24)
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

                      SizedBox(width: scaleWidth(12)), // 12px 간격

                      // 홈팀 스코어
                      FixedText(
                        '${record.homeScore}',
                        style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                      ),

                      SizedBox(width: scaleWidth(10)), // 10px 간격

                      // 콜론
                      FixedText(
                        ':',
                        style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                      ),

                      SizedBox(width: scaleWidth(10)), // 10px 간격

                      // 원정팀 스코어
                      FixedText(
                        '${record.awayScore}',
                        style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray20),
                      ),

                      SizedBox(width: scaleWidth(12)), // 12px 간격

                      // 원정팀 이미지 (24*24) - 마지막이므로 오른쪽 끝에서 20px 떨어진 위치
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

          // 나머지 270px 영역 - 사용자 정보 및 긴 텍스트
          Expanded(
            child: Container(
              width: scaleWidth(320),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(scaleHeight(16)),
                  bottomRight: Radius.circular(scaleHeight(16)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: scaleHeight(16)), // 상단 16px 패딩

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 프로필 이미지 (28*28, 원형, border 0.8px gray50)
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

                        SizedBox(width: scaleWidth(8)), // 8px 간격

                        // 1-1. 텍스트 정보 영역
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: scaleHeight(4)), // 20px - 16px = 4px 추가 여백으로 정렬

                              // 사용자 이름, 최애구단, 시간을 한 줄에 배치
                              Row(
                                children: [
                                  // 사용자 이름
                                  FixedText(
                                    record.authorNickname,
                                    style: AppFonts.pretendard.b3_m(context).copyWith(color: Colors.black),
                                  ),

                                  SizedBox(width: scaleWidth(6)), // 6px 간격

                                  // 최애 구단
                                  FixedText(
                                    '${record.authorFavTeam} 팬',
                                    style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
                                  ),

                                  SizedBox(width: scaleWidth(6)), // 6px 간격

                                  // 작성 시간
                                  FixedText(
                                    _getTimeAgo(record.createdAt),
                                    style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
                                  ),
                                ],
                              ),

                              SizedBox(height: scaleHeight(8)), // 이름 아래 8px

                              // 1-2. 긴 텍스트 (4줄 제한, 더보기 포함)
                              if (record.longContent != null && record.longContent!.trim().isNotEmpty)
                                _buildLongContentWidget(record.longContent!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 사용자 리스트 위젯 - 완전히 새로운 디자인
class UsersListWidget extends StatelessWidget {
  final List<UserSearchResult> users;

  const UsersListWidget({Key? key, required this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray30, // 배경색을 gray30으로 변경
      child: users.isEmpty
          ? Center(
        child: FixedText(
          "사용자 검색 결과가 없습니다.",
          style: AppFonts.pretendard.b2_m(context).copyWith(color: AppColors.gray400),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.all(scaleWidth(20)), // 모든 방향 20px 패딩
        itemCount: users.length,
        separatorBuilder: (context, index) => SizedBox(height: scaleHeight(8)), // 8px 간격
        itemBuilder: (context, index) {
          final user = users[index];
          return UserSearchTileWidget(user: user);
        },
      ),
    );
  }
}

// 새로운 사용자 타일 위젯
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

  // 팔로우 상태에 따른 버튼 텍스트 반환
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

  // 팔로우 상태에 따른 버튼 배경색 반환
  Color _getButtonBackgroundColor() {
    switch (_currentFollowStatus) {
      case 'FOLLOWING':
        return AppColors.gray50; // follower/following과 동일
      case 'PENDING':
      case 'REQUESTED':
        return AppColors.gray50; // follower/following과 동일
      case 'NOT_FOLLOWING':
      default:
        return AppColors.gray700;
    }
  }

  // 팔로우 상태에 따른 버튼 텍스트 색상 반환
  Color _getButtonTextColor() {
    switch (_currentFollowStatus) {
      case 'FOLLOWING':
        return AppColors.gray600; // follower/following과 동일
      case 'PENDING':
      case 'REQUESTED':
        return AppColors.gray600; // follower/following과 동일
      case 'NOT_FOLLOWING':
      default:
        return Colors.white;
    }
  }

  // 팔로우 버튼 클릭 처리 (follower/following 화면과 동일한 로직)
  Future<void> _handleFollowButton() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // UserSearchResult에서 userId 속성 사용 (id 대신)
      final userId = widget.user.userId; // 또는 widget.user.id가 있다면 그것을 사용

      if (_currentFollowStatus == 'FOLLOWING') {
        // 언팔로우
        await UserApi.unfollowUser(userId);
        setState(() {
          _currentFollowStatus = 'NOT_FOLLOWING';
        });
      } else if (_currentFollowStatus == 'NOT_FOLLOWING') {
        // 팔로우 요청
        final response = await UserApi.followUser(userId);
        final responseData = response['data'];

        setState(() {
          if (responseData['pending'] == true) {
            // 비공개 계정 - 요청 상태
            _currentFollowStatus = 'REQUESTED';
          } else {
            // 공개 계정 - 즉시 팔로우
            _currentFollowStatus = 'FOLLOWING';
          }
        });
      } else if (_currentFollowStatus == 'REQUESTED' || _currentFollowStatus == 'PENDING') {
        // 요청 취소 (언팔로우 API 사용)
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
      width: scaleWidth(320),
      height: scaleHeight(80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleHeight(16)), // radius 16px
      ),
      child: Row(
        children: [
          // 프로필 이미지 (가로 20px, 세로 중앙)
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
                borderRadius: BorderRadius.circular(scaleWidth(20)), // 40/2 = 20으로 완전한 원형
                child: Builder(
                  builder: (context) {
                    // 디버깅을 위한 로그
                    print('프로필 이미지 URL: ${widget.user.profileImageUrl}');

                    if (widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty) {
                      return Image.network(
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
                          print('이미지 로드 에러: $error');
                          // Following/Follower 화면과 동일한 기본 이미지 사용
                          return SvgPicture.asset(
                            AppImages.profile,
                            width: scaleWidth(40),
                            height: scaleHeight(40),
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    } else {
                      // Following/Follower 화면과 동일한 기본 이미지 사용
                      return SvgPicture.asset(
                        AppImages.profile,
                        width: scaleWidth(40),
                        height: scaleHeight(40),
                        fit: BoxFit.cover,
                      );
                    }
                  },
                ),
              ),
            ),
          ),

          SizedBox(width: scaleWidth(12)), // 12px 간격

          // 사용자 정보 (이름 + 최애 구단)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 이름 - pretendard b2_m black
                FixedText(
                  widget.user.nickname,
                  style: AppFonts.pretendard.b2_m(context).copyWith(color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: scaleHeight(8)), // 8px 간격

                // 최애 구단 - suite c1_m gray400
                FixedText(
                  widget.user.favTeam,
                  style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray400),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 팔로우 버튼 (오른쪽 20px)
          Padding(
            padding: EdgeInsets.only(right: scaleWidth(20)),
            child: GestureDetector(
              onTap: _handleFollowButton,
              child: Container(
                width: scaleWidth(70),
                height: scaleHeight(36),
                decoration: BoxDecoration(
                  color: _getButtonBackgroundColor(),
                  borderRadius: BorderRadius.circular(scaleHeight(8)), // radius 8px
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