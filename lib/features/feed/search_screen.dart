import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/api/search_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/api/feed_api.dart';
import 'package:frontend/features/mypage/friend_profile_screen.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/features/feed/feed_item_widget.dart';
import 'package:frontend/features/feed/detail_feed_screen.dart';
import 'package:frontend/utils/feed_count_manager.dart';
import 'package:frontend/utils/team_utils.dart';

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

  // 페이지네이션 관련 추가
  List<Record> _allRecords = [];
  int _currentRecordPage = 0;
  bool _isLoadingMoreRecords = false;
  bool _hasMoreRecords = true;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(() {
      setState(() {
        _hasText = _searchController.text.isNotEmpty;

        // 텍스트가 비워지면 검색 전 뷰로 돌아가기
        if (_searchController.text.isEmpty && _hasSearched) {
          _hasSearched = false;
          _searchResult = null;
          _allRecords.clear();
          _currentRecordPage = 0;
          _hasMoreRecords = true;
          _selectedTabIndex = 0;
        }
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
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            _handleBackButton();
          }
        },
        child: SafeArea(
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
                  onRefreshRequired: _refreshSearchResults,
                  allRecords: _allRecords,
                  hasMoreRecords: _hasMoreRecords,
                  isLoadingMoreRecords: _isLoadingMoreRecords,
                  onLoadMoreRecords: _loadMoreRecords,
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
        _searchResult = null;
        _allRecords.clear();
        _currentRecordPage = 0;
        _hasMoreRecords = true;
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
      return AppImages.search2;
    } else if (_hasText) {
      return AppImages.x;
    } else {
      return AppImages.search2;
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
      _allRecords = [];
      _currentRecordPage = 0;
      _currentQuery = query;
      _hasMoreRecords = true;
    });

    try {
      final result = await SearchApi.search(query, page: 0);
      setState(() {
        _searchResult = result;
        _allRecords = List.from(result.records.records);
        _hasMoreRecords = result.records.hasNext;
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

  Future<void> _loadMoreRecords() async {
    if (_isLoadingMoreRecords || !_hasMoreRecords) return;

    setState(() {
      _isLoadingMoreRecords = true;
    });

    try {
      final nextPage = _currentRecordPage + 1;
      final result = await SearchApi.search(_currentQuery, page: nextPage);

      setState(() {
        if (result.records.records.isEmpty) {
          _hasMoreRecords = false;
        } else {
          _allRecords.addAll(result.records.records);
          _currentRecordPage = nextPage;
          _hasMoreRecords = result.records.hasNext;
        }
      });
    } catch (e) {
      print("추가 검색 실패: $e");
    } finally {
      setState(() {
        _isLoadingMoreRecords = false;
      });
    }
  }

  Future<void> _refreshSearchResults() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SearchApi.search(query, page: 0);
      setState(() {
        _searchResult = result;
        _allRecords = List.from(result.records.records);
        _currentRecordPage = 0;
        _hasMoreRecords = result.records.hasNext;
      });
    } catch (e) {
      print("검색 새로고침 실패: $e");
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

class SearchResultsWidget extends StatefulWidget {
  final SearchResult? searchResult;
  final int selectedTabIndex;
  final Function(int) onTabChanged;
  final VoidCallback onRefreshRequired;
  final List<Record> allRecords;
  final bool hasMoreRecords;
  final bool isLoadingMoreRecords;
  final VoidCallback? onLoadMoreRecords;

  const SearchResultsWidget({
    Key? key,
    required this.searchResult,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.onRefreshRequired,
    required this.allRecords,
    required this.hasMoreRecords,
    required this.isLoadingMoreRecords,
    this.onLoadMoreRecords,
  }) : super(key: key);

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.searchResult == null) {
      return Center(child: FixedText('검색 결과가 없습니다.'));
    }

    return Column(
      children: [
        // Feed와 동일한 버튼 배치
        Padding(
          padding: EdgeInsets.only(
            top: scaleHeight(15),
            left: scaleWidth(20),
            right: scaleWidth(20),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onTabChanged(0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(14), vertical: scaleHeight(4)),
                  decoration: BoxDecoration(
                    color: widget.selectedTabIndex == 0 ? AppColors.gray30 : AppColors.gray20,
                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                  ),
                  child: FixedText(
                    '게시글',
                    style: AppFonts.pretendard.body_sm_500(context).copyWith(
                      fontWeight: widget.selectedTabIndex == 0 ? FontWeight.w500 : FontWeight.w400,
                      color: widget.selectedTabIndex == 0 ? AppColors.gray600 : AppColors.gray300,
                    ),
                  ),
                ),
              ),
              SizedBox(width: scaleWidth(8)),
              GestureDetector(
                onTap: () => widget.onTabChanged(1),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(14), vertical: scaleHeight(4)),
                  decoration: BoxDecoration(
                    color: widget.selectedTabIndex == 1 ? AppColors.gray30 : AppColors.gray20,
                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                  ),
                  child: FixedText(
                    '사용자',
                    style: AppFonts.pretendard.body_sm_500(context).copyWith(
                      fontWeight: widget.selectedTabIndex == 1 ? FontWeight.w500 : FontWeight.w400,
                      color: widget.selectedTabIndex == 1 ? AppColors.gray600 : AppColors.gray300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 게시글 탭
        if (widget.selectedTabIndex == 0)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: scaleHeight(10)),
              child: RecordsListWidget(
                records: widget.allRecords,
                onRefreshRequired: widget.onRefreshRequired,
                hasMore: widget.hasMoreRecords,
                isLoadingMore: widget.isLoadingMoreRecords,
                onLoadMore: widget.onLoadMoreRecords,
              ),
            ),
          )
        // 사용자 탭
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: scaleHeight(10)),
              child: UsersListWidget(users: widget.searchResult!.users.users),
            ),
          ),
      ],
    );
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
            style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray700),
          ),
        ),
        Container(
          height: scaleHeight(30),
          margin: EdgeInsets.only(top: scaleHeight(20)),
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
              top: scaleHeight(33),
              left: scaleWidth(20),
              right: scaleWidth(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FixedText(
                  '최근 검색어',
                  style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray700),
                ),
                GestureDetector(
                  onTap: onClearAllRecent,
                  child: FixedText(
                    '전체삭제',
                    style: AppFonts.pretendard.caption_re_400(context).copyWith(
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
        if (recentSearches.isEmpty) Expanded(child: SizedBox()),
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
        height: scaleHeight(30),
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(14)),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(scaleHeight(68)),
          border: Border.all(color: AppColors.gray100, width: 1),
        ),
        child: Center(
          child: FixedText(
            term,
            style: AppFonts.pretendard.caption_md_400(context)
                .copyWith(color: AppColors.gray500),
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

/// 게시글 검색 결과 - FeedItemWidget 사용 (피드 방식으로 페이지네이션)
class RecordsListWidget extends StatefulWidget {
  final List<Record> records;
  final VoidCallback? onRefreshRequired;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const RecordsListWidget({
    Key? key,
    required this.records,
    this.onRefreshRequired,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  }) : super(key: key);

  @override
  State<RecordsListWidget> createState() => _RecordsListWidgetState();
}

class _RecordsListWidgetState extends State<RecordsListWidget> {
  final _likeManager = FeedCountManager();

  @override
  void initState() {
    super.initState();
    // 전역 상태에 초기값 등록
    for (var record in widget.records) {
      _likeManager.setInitialState(
        record.recordId,
        record.isLiked,
        record.likeCount,
        commentCount: record.commentCount,
      );
    }

    // 전역 상태 변경 리스닝 (Feed/Detail에서 좋아요 누르면 여기도 업데이트)
    _likeManager.addListener(_onGlobalLikeStateChanged);
  }

  @override
  void dispose() {
    _likeManager.removeListener(_onGlobalLikeStateChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(RecordsListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      // 새 검색 결과 전역 상태에 등록 (기존 상태는 유지)
      for (var record in widget.records) {
        _likeManager.setInitialState(
          record.recordId,
          record.isLiked,
          record.likeCount,
          commentCount: record.commentCount,
        );
      }
      print('🔄 [Search] 검색 결과 업데이트 (기존 좋아요 상태 유지)');
    }
  }

  // 전역 상태 변경 감지 → 화면 갱신
  void _onGlobalLikeStateChanged() {
    setState(() {
      // 리스트 전체 rebuild → 각 FeedItemWidget이 최신 전역 상태 가져감
    });
    print('✅ [Search] 전역 좋아요 상태 변경 감지 → 화면 갱신');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return Center(
        child: FixedText(
          "게시글 검색 결과가 없습니다.",
          style: AppFonts.pretendard.b2_m(context).copyWith(
              color: AppColors.gray400),
        ),
      );
    }

    return Container(
      // 피드와 동일한 NotificationListener 방식
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // 스크롤이 끝에서 200픽셀 전에 도달하면 추가 로드
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            if (!widget.isLoadingMore && widget.hasMore) {
              widget.onLoadMore?.call();
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.only(top: scaleHeight(10)),
          itemCount: widget.records.length + (widget.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 로딩 인디케이터
            if (index == widget.records.length) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: scaleHeight(20)),
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );
            }

            final record = widget.records[index];
            final isLiked = _likeManager.getLikedStatus(record.recordId) ?? record.isLiked;
            final likeCount = _likeManager.getLikeCount(record.recordId) ?? record.likeCount;
            final commentCount = _likeManager.getCommentCount(record.recordId) ?? record.commentCount;

            final feedData = {
              'recordId': record.recordId,
              'userId': record.authorId,
              'authorProfileImage': record.authorProfileImage,
              'authorNickname': record.authorNickname,
              'authorFavTeam': record.authorFavTeam,
              'followStatus': record.followStatus ?? 'NOT_FOLLOWING',
              'mediaUrls': record.mediaUrls,
              'longContent': record.longContent,
              'emotionCode': record.emotionCode,
              'homeTeam': record.homeTeam,
              'awayTeam': record.awayTeam,
              'stadium': record.stadium,
              'gameDate': record.gameDate,
              'createdAt': record.createdAt,
              'isLiked': isLiked,
              'likeCount': likeCount,
              'commentCount': commentCount,
            };

            return FeedItemWidget(
              feedData: feedData,
              onProfileNavigated: widget.onRefreshRequired,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        DetailFeedScreen(recordId: record.recordId),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );

                // 삭제되었으면 리스트 업데이트
                if (result != null && result is Map &&
                    result['deleted'] == true) {
                  final deletedRecordId = result['recordId'];
                  setState(() {
                    widget.records.removeWhere((r) =>
                    r.recordId == deletedRecordId);
                  });
                  print('[Search] 게시글 ${deletedRecordId}번 삭제됨');
                } else {
                  print('[Search] Detail에서 돌아옴 (전역 상태로 동기화됨)');
                }
              },
            );
          },
        ),
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
      child: users.isEmpty
          ? Center(
        child: FixedText(
          "사용자 검색 결과가 없습니다.",
          style: AppFonts.pretendard.b2_m(context).copyWith(color: AppColors.gray400),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.only(top: scaleHeight(10), left: scaleWidth(20), right: scaleWidth(20), bottom: scaleWidth(20)),
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
  late bool isMutualFollow;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentFollowStatus = widget.user.followStatus;
    isMutualFollow = widget.user.isMutualFollow ?? false;

    // 🔍 디버그: 초기 상태 로그
    print('🔍 UserSearchTile 초기화: ${widget.user.nickname}');
    print('   followStatus: $_currentFollowStatus');
    print('   isMutualFollow from API: ${widget.user.isMutualFollow}');
    print('   isMutualFollow (사용): $isMutualFollow');

    // 📡 백엔드가 isMutualFollow를 제공하지 않는 경우 대비
    if (widget.user.isMutualFollow == null && _currentFollowStatus == 'NOT_FOLLOWING') {
      _checkMutualFollowFallback();
    } else {
      _isInitialized = true;
    }
  }

  // 📡 백엔드 응답에 isMutualFollow가 없을 때만 사용하는 fallback
  Future<void> _checkMutualFollowFallback() async {
    try {
      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];
      final myFollowers = await UserApi.getFollowers(myUserId);
      final followerIds = myFollowers['data']?.map((u) => u['id']).toSet() ?? <int>{};

      if (mounted) {
        setState(() {
          isMutualFollow = followerIds.contains(widget.user.userId);
          _isInitialized = true;
          print('📡 Fallback check - isMutualFollow: $isMutualFollow');
        });
      }
    } catch (e) {
      print('❌ Fallback mutual check error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  String _getButtonText() {
    if (_currentFollowStatus == 'FOLLOWING') {
      return '팔로잉';
    } else if (_currentFollowStatus == 'REQUESTED') {
      return '요청됨';
    } else if (isMutualFollow) {
      return '맞팔로우';
    }
    return '팔로우';
  }

  Color _getButtonBackgroundColor() {
    if (_currentFollowStatus == 'FOLLOWING') {
      return AppColors.gray50;
    } else if (_currentFollowStatus == 'REQUESTED' || _currentFollowStatus == 'PENDING') {
      return AppColors.gray50;
    } else if (isMutualFollow) {
      return AppColors.gray600;
    }
    return AppColors.gray600;
  }

  Color _getButtonTextColor() {
    if (_currentFollowStatus == 'FOLLOWING' || _currentFollowStatus == 'REQUESTED' || _currentFollowStatus == 'PENDING') {
      return AppColors.gray600;
    } else if (isMutualFollow) {
      return AppColors.gray20;
    }
    return AppColors.gray20;
  }

  Future<void> _handleFollowButton() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userId = widget.user.userId;

      if (_currentFollowStatus == 'FOLLOWING') {
        // 언팔로우
        await UserApi.unfollowUser(userId);

        // 📡 백엔드에서 최신 상태 가져오기 (isMutualFollow 확인)
        bool mutual = false;
        try {
          final myProfile = await UserApi.getMyProfile();
          final myUserId = myProfile['data']['id'];
          final myFollowers = await UserApi.getFollowers(myUserId);
          final followerIds = myFollowers['data']?.map((u) => u['id']).toSet() ?? <int>{};
          mutual = followerIds.contains(userId);
        } catch (e) {
          print('❌ 맞팔 체크 실패: $e');
        }

        if (mounted) {
          setState(() {
            _currentFollowStatus = 'NOT_FOLLOWING';
            isMutualFollow = mutual;
          });
        }
      } else if (_currentFollowStatus == 'NOT_FOLLOWING' || isMutualFollow) {
        // 팔로우 요청
        final response = await UserApi.followUser(userId);
        final responseData = response['data'];

        if (mounted) {
          setState(() {
            if (responseData['pending'] == true) {
              _currentFollowStatus = 'REQUESTED';
              // 📡 백엔드 응답에서 isFollower 값 사용
              isMutualFollow = responseData['isFollower'] ?? false;
            } else {
              _currentFollowStatus = 'FOLLOWING';
              // 📡 백엔드 응답에서 isFollower 값 사용
              isMutualFollow = responseData['isFollower'] ?? false;
            }
          });
        }
      } else if (_currentFollowStatus == 'REQUESTED') {
        // 요청 취소
        await UserApi.unfollowUser(userId);

        // 📡 백엔드에서 최신 상태 가져오기
        bool mutual = false;
        try {
          final myProfile = await UserApi.getMyProfile();
          final myUserId = myProfile['data']['id'];
          final myFollowers = await UserApi.getFollowers(myUserId);
          final followerIds = myFollowers['data']?.map((u) => u['id']).toSet() ?? <int>{};
          mutual = followerIds.contains(userId);
        } catch (e) {
          print('❌ 맞팔 체크 실패: $e');
        }

        if (mounted) {
          setState(() {
            _currentFollowStatus = 'NOT_FOLLOWING';
            isMutualFollow = mutual;
          });
        }
      }
    } catch (e) {
      print("팔로우 상태 변경 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFollowStatus() async {
    try {
      final response = await FeedApi.getUserFeed(widget.user.userId);
      if (mounted) {
        setState(() {
          _currentFollowStatus = response['followStatus'] ?? "NOT_FOLLOWING";
        });
      }
    } catch (e) {
      print('팔로우 상태 새로고침 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FriendProfileScreen(
              userId: widget.user.userId,
              initialFollowStatus: _currentFollowStatus,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );

        if (result != null && result is Map && mounted) {
          setState(() {
            _currentFollowStatus = result['followStatus'] ?? _currentFollowStatus;
            isMutualFollow = result['isMutualFollow'] ?? false;
          });

          final searchScreenState = context.findAncestorStateOfType<_SearchScreenState>();
          if (searchScreenState != null && searchScreenState._hasSearched) {
            searchScreenState._refreshSearchResults();
          } else {
            await _refreshFollowStatus();
          }
        }
      },
      child: Container(
        height: scaleHeight(56),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scaleHeight(12)),
        ),
        child: Row(
          children: [
            Container(
              width: scaleWidth(40),
              height: scaleHeight(40),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray50, width: 1),
                borderRadius: BorderRadius.circular(scaleWidth(20)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(scaleWidth(20)),
                child: widget.user.profileImageUrl != null &&
                    widget.user.profileImageUrl!.isNotEmpty
                    ? Image.network(
                  widget.user.profileImageUrl!,
                  width: scaleWidth(40),
                  height: scaleHeight(40),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.gray100,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      SvgPicture.asset(
                        AppImages.profile,
                        width: scaleWidth(40),
                        height: scaleHeight(40),
                        fit: BoxFit.cover,
                      ),
                )
                    : SvgPicture.asset(
                  AppImages.profile,
                  width: scaleWidth(40),
                  height: scaleHeight(40),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: scaleWidth(12)),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: FixedText(
                      widget.user.nickname,
                      style: AppFonts.pretendard.b2_m(context).copyWith(color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: scaleWidth(6)),
                  TeamUtils.buildTeamBadge(
                    context: context,
                    teamName: widget.user.favTeam,
                    textStyle: AppFonts.pretendard.caption_sm_500(context),
                    height: scaleHeight(18),
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(7)),
                    borderRadius: scaleWidth(4),
                    suffix: ' 팬',
                  ),
                ],
              ),
            ),
            SizedBox(width: scaleWidth(8)),
            GestureDetector(
              onTap: _handleFollowButton,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: scaleWidth(70),
                height: scaleHeight(34),
                decoration: BoxDecoration(
                  color: _getButtonBackgroundColor(),
                  borderRadius: BorderRadius.circular(scaleHeight(8)),
                ),
                child: Center(
                  child: FixedText(
                    _getButtonText(),
                    style: AppFonts.pretendard.caption_md_500(context)
                        .copyWith(color: _getButtonTextColor()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}