import 'package:flutter/material.dart';
import 'package:frontend/api/search_api.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;

  bool _isLoading = false;
  bool _hasSearched = false; // 검색을 실행했는지 여부

  // API 호출 결과 저장
  List<String> _popularSearches = [];
  List<String> _recentSearches = [];
  SearchResult? _searchResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();

    // 검색창 텍스트 변경 감지
    _searchController.addListener(() {
      setState(() {});
    });
  }

  // 초기 데이터 (인기/최근 검색어) 로드
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
      // 에러 처리 (예: 스낵바)
    }
  }

  // 검색 실행
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus(); // 검색 실행 시 키보드 내리기
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final result = await SearchApi.search(query);
      setState(() {
        _searchResult = result;
      });
      // 검색 성공 후 최근 검색어 목록 갱신
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

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasSearched
          ? _buildSearchResults()
          : _buildInitialView(),
    );
  }

  // 상단 앱바 (검색창)
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () {
          if (_hasSearched) {
            setState(() {
              _hasSearched = false;
              _searchController.clear();
            });
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: AppFonts.suite.b2_m(context),
        decoration: InputDecoration(
          hintText: '글, 제목, 내용, 해시태그, 유저',
          hintStyle: AppFonts.suite.b2_m(context).copyWith(color: AppColors.gray300),
          border: InputBorder.none,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.cancel, color: AppColors.gray200),
            onPressed: () => _searchController.clear(),
          )
              : null,
        ),
        onSubmitted: (value) => _performSearch(value),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black, size: 28),
          onPressed: () => _performSearch(_searchController.text),
        ),
        SizedBox(width: 12),
      ],
    );
  }

  // 초기 화면 (추천/최근 검색어)
  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('추천 검색어'),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches
                .map((term) => _buildSearchChip(term))
                .toList(),
          ),
          SizedBox(height: 24),
          _buildSectionTitle('최근 검색어', showClearAll: _recentSearches.isNotEmpty),
          SizedBox(height: 12),
          _recentSearches.isEmpty
              ? Text('최근 검색 기록이 없습니다.', style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray300))
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return _buildRecentSearchItem(term);
            },
          ),
        ],
      ),
    );
  }

  // 검색 결과 화면 (탭 + 결과 리스트)
  Widget _buildSearchResults() {
    if (_searchResult == null) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.gray300,
          labelStyle: AppFonts.suite.b2_b(context),
          unselectedLabelStyle: AppFonts.suite.b2_m(context),
          indicatorColor: Colors.black,
          tabs: [
            Tab(text: '게시글 ${_searchResult!.records.totalElements}'),
            Tab(text: '사용자 ${_searchResult!.users.totalElements}'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecordsList(_searchResult!.records.records),
              _buildUsersList(_searchResult!.users.users),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper & Component Widgets ---

  // 섹션 제목 (추천/최근 검색어)
  Widget _buildSectionTitle(String title, {bool showClearAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppFonts.suite.b3_b(context)),
        if (showClearAll)
          GestureDetector(
            onTap: () async {
              await SearchApi.deleteAllRecentSearches();
              _loadInitialData(); // 목록 갱신
            },
            child: Text('전체삭제', style: AppFonts.suite.c1_r(context).copyWith(color: AppColors.gray300)),
          ),
      ],
    );
  }

  // 추천 검색어 Chip
  Widget _buildSearchChip(String term) {
    return GestureDetector(
      onTap: () {
        _searchController.text = term;
        _performSearch(term);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(term, style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray600)),
      ),
    );
  }

  // 최근 검색어 아이템
  Widget _buildRecentSearchItem(String term) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.gray300),
          SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _searchController.text = term;
                _performSearch(term);
              },
              child: Text(term, style: AppFonts.suite.b2_m(context)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.gray300),
            onPressed: () async {
              await SearchApi.deleteRecentSearch(term);
              _loadInitialData(); // 목록 갱신
            },
          ),
        ],
      ),
    );
  }

  // 게시글 결과 리스트
  Widget _buildRecordsList(List<Record> records) {
    if (records.isEmpty) {
      return const Center(child: Text("게시글 검색 결과가 없습니다."));
    }
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        // TODO: 실제 직관 기록 카드 위젯으로 교체
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${record.homeTeam} vs ${record.awayTeam}", style: AppFonts.suite.b2_b(context)),
                SizedBox(height: 4),
                Text(record.authorNickname, style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray400)),
                SizedBox(height: 8),
                Text(record.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  // 사용자 결과 리스트
  Widget _buildUsersList(List<UserSearchResult> users) {
    if (users.isEmpty) {
      return const Center(child: Text("사용자 검색 결과가 없습니다."));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserTile(user);
      },
    );
  }

  // 사용자 타일
  Widget _buildUserTile(UserSearchResult user) {
    // TODO: 실제 팔로우 상태에 따라 버튼 UI 변경
    final isFollowing = user.followStatus == 'FOLLOWING';
    final buttonColor = isFollowing ? AppColors.gray200 : AppColors.gray700;
    final textColor = isFollowing ? AppColors.gray400 : Colors.white;
    final buttonText = isFollowing ? '팔로잉' : '팔로우';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gray100,
            // backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
            // child: user.profileImageUrl == null ? Icon(Icons.person, color: AppColors.gray300) : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nickname, style: AppFonts.suite.b2_b(context)),
                Text(user.favTeam, style: AppFonts.suite.c1_r(context).copyWith(color: AppColors.gray400)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 팔로우/언팔로우 API 호출
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: textColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
