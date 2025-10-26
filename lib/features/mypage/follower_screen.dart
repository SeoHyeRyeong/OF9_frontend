import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';
import 'package:frontend/features/mypage/friend_profile_screen.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/api/user_api.dart';

class FollowerScreen extends StatefulWidget {
  final int? targetUserId;
  const FollowerScreen({
    Key? key,
    this.targetUserId,
  }) : super(key: key);

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

class _FollowerScreenState extends State<FollowerScreen> {
  // 팔로워 목록
  List<Map<String, dynamic>> followers = [];
  bool isLoading = true;
  int? myUserId;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때마다 데이터 새로고침
    _loadFollowers();
  }

  // 팔로워 목록 불러오기
  Future<void> _loadFollowers() async {
    try {
      final myProfile = await UserApi.getMyProfile();
      myUserId = myProfile['data']['id'];

      int targetUserId;
      if (widget.targetUserId != null) {
        targetUserId = widget.targetUserId!;
      } else {
        targetUserId = myUserId!;
      }

      final response = await UserApi.getFollowers(targetUserId);
      final followersData = response['data'] as List<dynamic>? ?? [];


      setState(() {
        followers = followersData.map((follower) {
          // followStatus를 기반으로 상태 결정
          String followStatus = follower['followStatus'] ?? 'NOT_FOLLOWING';

          return {
            'userId': follower['id'] ?? follower['userId'],
            'nickname': follower['nickname'] ?? '알 수 없음',
            'favTeam': follower['favTeam'] ?? '응원팀 없음',
            'profileImageUrl': follower['profileImageUrl'],
            'followStatus': followStatus,
            'isFollowing': followStatus == 'FOLLOWING',
            'isRequested': followStatus == 'REQUESTED',
            'isMe': (follower['id'] ?? follower['userId']) == myUserId,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('❌ 팔로워 목록 불러오기 실패: $e');
      setState(() {
        followers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로워 목록을 불러오는데 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 팔로우/언팔로우 처리
  Future<void> _handleFollow(int index) async {
    try {
      final follower = followers[index];
      final userId = follower['userId'];
      final currentStatus = follower['followStatus'];

      if (currentStatus == 'FOLLOWING') {
        // 언팔로우
        await UserApi.unfollowUser(userId);
        setState(() {
          followers[index]['followStatus'] = 'NOT_FOLLOWING';
          followers[index]['isFollowing'] = false;
          followers[index]['isRequested'] = false;
        });
      } else if (currentStatus == 'NOT_FOLLOWING') {
        // 팔로우 요청
        final response = await UserApi.followUser(userId);
        final responseData = response['data'];

        setState(() {
          if (responseData['pending'] == true) {
            // 비공개 계정 - 요청 상태
            followers[index]['followStatus'] = 'REQUESTED';
            followers[index]['isFollowing'] = false;
            followers[index]['isRequested'] = true;
          } else {
            // 공개 계정 - 즉시 팔로우
            followers[index]['followStatus'] = 'FOLLOWING';
            followers[index]['isFollowing'] = true;
            followers[index]['isRequested'] = false;
          }
        });
      } else if (currentStatus == 'REQUESTED') {
        // 요청 취소 (언팔로우 API 사용)
        await UserApi.unfollowUser(userId);
        setState(() {
          followers[index]['followStatus'] = 'NOT_FOLLOWING';
          followers[index]['isFollowing'] = false;
          followers[index]['isRequested'] = false;
        });
      }
    } catch (e) {
      print('❌ 팔로우 처리 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로우 처리에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.targetUserId != null,
      onPopInvoked: (didPop) {
        if (!didPop && widget.targetUserId == null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const MyPageScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 뒤로가기 영역 + 타이틀
                  Container(
                    width: double.infinity,
                    height: scaleHeight(60),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (widget.targetUserId != null) {
                                // 친구 프로필에서 온 경우: 일반 뒤로가기
                                Navigator.pop(context);
                              } else {
                                // 내 팔로워 목록에서 온 경우: MyPage로 이동
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation1, animation2) => const MyPageScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              }
                            },
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
                          Expanded(
                            child: Center(
                              child: FixedText(
                                "팔로워",
                                style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray900),
                              ),
                            ),
                          ),
                          SizedBox(width: scaleHeight(24)),
                        ],
                      ),
                    ),
                  ),

                  // 팔로워 목록 또는 빈 상태
                  Expanded(
                    child: isLoading
                        ? Center(
                      child: CircularProgressIndicator(color: AppColors.pri900),
                    )
                        : followers.isEmpty
                        ? _buildEmptyState()
                        : _buildFollowerList(),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(currentIndex: 4),
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: FixedText(
        "아직 팔로워가 없어요",
        style: AppFonts.suite.head_sm_700(context).copyWith(color: AppColors.gray400),
      ),
    );
  }

  // 팔로워 목록 위젯
  Widget _buildFollowerList() {
    return ListView.builder(
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final follower = followers[index];
        return _buildFollowerItem(follower, index);
      },
    );
  }

  // 팔로워 아이템 위젯
  Widget _buildFollowerItem(Map<String, dynamic> follower, int index) {
    return Container(
      width: double.infinity,
      height: scaleHeight(74),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)), //전체 양쪽 여백
        child: Row(
          children: [
            // 프로필 이미지 - 클릭 시 친구 프로필로 이동
            GestureDetector(
              onTap: () {
                if (follower['isMe'] == true) {
                  // 내가 맞으면 MyPage로 이동
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                      const MyPageScreen(
                        fromNavigation: false, // 일반 뒤로가기 허용
                        showBackButton: true,  // 뒤로가기 버튼 표시
                      ),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  // 다른 사람이면 FriendProfileScreen으로 이동
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          FriendProfileScreen(userId: follower['userId']),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  ).then((_) => _loadFollowers());
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(scaleHeight(12.43)),
                child: follower['profileImageUrl'] != null
                    ? Image.network(
                  follower['profileImageUrl']!,
                  width: scaleHeight(42),
                  height: scaleHeight(42),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SvgPicture.asset(
                    AppImages.profile,
                    width: scaleHeight(42),
                    height: scaleHeight(42),
                    fit: BoxFit.cover,
                  ),
                )
                    : SvgPicture.asset(
                  AppImages.profile,
                  width: scaleHeight(42),
                  height: scaleHeight(42),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(width: scaleWidth(12)),

            // 닉네임과 최애구단 컬럼 - 클릭 시 친구 프로필로 이동
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (follower['isMe'] == true) {
                    // 내가 맞으면 MyPage로 이동
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const MyPageScreen(
                          fromNavigation: false, // 일반 뒤로가기 허용
                          showBackButton: true,  // 뒤로가기 버튼 표시
                        ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  } else {
                    // 다른 사람이면 FriendProfileScreen으로 이동
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => FriendProfileScreen(
                          userId: follower['userId'],
                        ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    ).then((_) => _loadFollowers());
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(top: scaleHeight(19)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 닉네임
                      FixedText(
                        follower['nickname'] ?? '알 수 없음',
                        style: AppFonts.pretendard.b3_sb(context).copyWith(color: Colors.black),
                      ),
                      SizedBox(height: scaleHeight(6)),
                      // 최애 구단
                      FixedText(
                        "${follower['favTeam'] ?? '응원팀 없음'} 팬",
                        style: AppFonts.suite.caption_re_400(context).copyWith(color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 팔로우 버튼
            if (follower['isMe'] != true)
              Container(
                width: scaleWidth(88),
                height: scaleHeight(32),
                child: ElevatedButton(
                  onPressed: () => _handleFollow(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonBackgroundColor(follower),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleHeight(8)),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: Center(
                    child: FixedText(
                      _getButtonText(follower),
                      style: AppFonts.suite.c1_m(context).copyWith(
                        color: _getButtonTextColor(follower),
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: scaleWidth(88)),
          ],
        ),
      ),
    );
  }

  // 버튼 배경색 결정
  Color _getButtonBackgroundColor(Map<String, dynamic> follower) {
    final followStatus = follower['followStatus'] ?? 'NOT_FOLLOWING';

    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray50; // 팔로잉 상태
      case 'REQUESTED':
        return AppColors.gray50; // 요청됨 상태 (팔로잉과 동일)
      default:
        return AppColors.gray600; // 팔로우 안 한 상태
    }
  }

  // 버튼 텍스트 결정
  String _getButtonText(Map<String, dynamic> follower) {
    final followStatus = follower['followStatus'] ?? 'NOT_FOLLOWING';

    switch (followStatus) {
      case 'FOLLOWING':
        return '팔로잉';
      case 'REQUESTED':
        return '요청됨';
      default:
        return '팔로우';
    }
  }

  // 버튼 텍스트 색상 결정
  Color _getButtonTextColor(Map<String, dynamic> follower) {
    final followStatus = follower['followStatus'] ?? 'NOT_FOLLOWING';

    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray600; // 팔로잉 상태일 때
      case 'REQUESTED':
        return AppColors.gray600; // 요청됨 상태일 때
      default:
        return AppColors.gray20; // 팔로우 안 한 상태일 때
    }
  }
}