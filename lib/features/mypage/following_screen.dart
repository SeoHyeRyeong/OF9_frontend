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

class FollowingScreen extends StatefulWidget {
  final int? targetUserId;

  const FollowingScreen({
    Key? key,
    this.targetUserId,
  }) : super(key: key);

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  // 팔로잉 목록
  List<Map<String, dynamic>> followings = [];
  bool isLoading = true;
  int? myUserId;

  @override
  void initState() {
    super.initState();
    _loadFollowings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때마다 데이터 새로고침
    _loadFollowings();
  }

  // 팔로잉 목록 불러오기
  Future<void> _loadFollowings() async {
    try {
      final myProfile = await UserApi.getMyProfile();
      myUserId = myProfile['data']['id'];

      int targetUserId = widget.targetUserId ?? myUserId!;

      // 1. 팔로잉 목록
      final response = await UserApi.getFollowing(targetUserId);
      final followingsData = response['data'] as List? ?? [];

      // 2. 내 팔로워 목록 (맞팔 확인용)
      final myFollowersResponse = await UserApi.getFollowers(myUserId!);
      final myFollowersData = myFollowersResponse['data'] as List? ?? [];
      final Set<int> iAmFollowedByIds = myFollowersData
          .where((user) => user['id'] != null)
          .map((user) => user['id'] as int)
          .toSet();

      setState(() {
        followings = followingsData.map((following) {
          String followStatus = following['followStatus'] ?? 'FOLLOWING';
          final userId = following['id'] ?? following['userId'];
          final isMutualFollow = iAmFollowedByIds.contains(userId);

          return {
            'userId': userId,
            'nickname': following['nickname'] ?? '알 수 없음',
            'favTeam': following['favTeam'] ?? '응원팀 없음',
            'profileImageUrl': following['profileImageUrl'],
            'followStatus': followStatus,
            'isFollowing': followStatus == 'FOLLOWING',
            'isRequested': followStatus == 'REQUESTED',
            'isMe': userId == myUserId,
            'isMutualFollow': isMutualFollow,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('❌ 팔로잉 목록 불러오기 실패: $e');
      setState(() {
        followings = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('팔로잉 목록을 불러오는데 실패했습니다.'), backgroundColor: Colors.red),
      );
    }
  }

  // 팔로우/언팔로우 처리
  Future<void> _handleFollow(int index) async {
    try {
      final following = followings[index];
      final userId = following['userId'];
      final currentStatus = following['followStatus'];

      if (currentStatus == 'FOLLOWING') {
        // 언팔로우
        await UserApi.unfollowUser(userId);

        // 📡 백엔드에서 최신 상태 가져오기
        try {
          final myProfile = await UserApi.getMyProfile();
          final myUserId = myProfile['data']['id'];
          final myFollowers = await UserApi.getFollowers(myUserId);
          final followerIds = myFollowers['data']?.map((u) => u['id']).toSet() ?? <int>{};

          setState(() {
            followings[index]['followStatus'] = 'NOT_FOLLOWING';
            followings[index]['isFollowing'] = false;
            followings[index]['isRequested'] = false;
            // 📡 백엔드 응답 기준: 상대방이 나를 팔로우하고 있는지
            followings[index]['isMutualFollow'] = followerIds.contains(userId);
          });
        } catch (e) {
          print('사용자 정보 업데이트 실패: $e');
          setState(() {
            followings[index]['followStatus'] = 'NOT_FOLLOWING';
            followings[index]['isFollowing'] = false;
            followings[index]['isRequested'] = false;
          });
        }
      } else if (currentStatus == 'NOT_FOLLOWING') {
        // 팔로우 요청
        final response = await UserApi.followUser(userId);
        final responseData = response['data'];

        setState(() {
          if (responseData['pending'] == true) {
            // 비공개 계정 - 요청 상태
            followings[index]['followStatus'] = 'REQUESTED';
            followings[index]['isFollowing'] = false;
            followings[index]['isRequested'] = true;
            // 📡 백엔드 응답에서 isFollower 값 사용
            followings[index]['isMutualFollow'] = responseData['isFollower'] ?? false;
          } else {
            // 공개 계정 - 즉시 팔로우
            followings[index]['followStatus'] = 'FOLLOWING';
            followings[index]['isFollowing'] = true;
            followings[index]['isRequested'] = false;
            // 📡 백엔드 응답에서 isFollower 값 사용
            followings[index]['isMutualFollow'] = responseData['isFollower'] ?? false;
          }
        });
      } else if (currentStatus == 'REQUESTED') {
        // 요청 취소 (언팔로우 API 사용)
        await UserApi.unfollowUser(userId);

        // 📡 백엔드에서 최신 상태 가져오기
        try {
          final myProfile = await UserApi.getMyProfile();
          final myUserId = myProfile['data']['id'];
          final myFollowers = await UserApi.getFollowers(myUserId);
          final followerIds = myFollowers['data']?.map((u) => u['id']).toSet() ?? <int>{};

          setState(() {
            followings[index]['followStatus'] = 'NOT_FOLLOWING';
            followings[index]['isFollowing'] = false;
            followings[index]['isRequested'] = false;
            // 📡 백엔드 응답 기준: 상대방이 나를 팔로우하고 있는지
            followings[index]['isMutualFollow'] = followerIds.contains(userId);
          });
        } catch (e) {
          print('사용자 정보 업데이트 실패: $e');
          setState(() {
            followings[index]['followStatus'] = 'NOT_FOLLOWING';
            followings[index]['isFollowing'] = false;
            followings[index]['isRequested'] = false;
          });
        }
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (widget.targetUserId == null) {
            // 내 팔로잉 목록 → 마이페이지로 이동
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const MyPageScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
            // 다른 유저 팔로잉 리스트 → 그냥 뒤로가기
            Navigator.pop(context);
          }
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
                              if (Navigator.canPop(context)) {
                                //친구 프로필에서 온 경우
                                Navigator.pop(context);
                              } else if (widget.targetUserId == null) {
                                // 내 팔로잉 목록에서 온 경우: MyPage로 이동
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
                                "팔로잉",
                                style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray950),
                              ),
                            ),
                          ),
                          SizedBox(width: scaleHeight(24)),
                        ],
                      ),
                    ),
                  ),

                  // 팔로잉 목록 또는 빈 상태
                  Expanded(
                    child: isLoading
                        ? Center(
                      child: CircularProgressIndicator(color: AppColors.pri900),
                    )
                        : followings.isEmpty
                        ? _buildEmptyState()
                        : _buildFollowingList(),
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
        "아직 팔로잉이 없어요",
        style: AppFonts.pretendard.head_sm_600(context).copyWith(color: AppColors.gray300),
      ),
    );
  }

  // 팔로잉 목록 위젯
  Widget _buildFollowingList() {
    return ListView.builder(
      itemCount: followings.length,
      itemBuilder: (context, index) {
        final following = followings[index];
        return _buildFollowingItem(following, index);
      },
    );
  }

  // 팔로잉 아이템 위젯
  Widget _buildFollowingItem(Map<String, dynamic> follower, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // 전체 Container를 하나의 GestureDetector로 감싸기
      onTap: () async {
        if (follower['isMe'] == true) {
          // 내가 맞으면 MyPage로 이동
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
              const MyPageScreen(
                fromNavigation: false, // 일반 뒤로가기 허용
                showBackButton: true, // 뒤로가기 버튼 표시
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else {
          // 다른 사람이면 FriendProfileScreen으로 이동
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FriendProfileScreen(userId: follower['userId']),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );

          if (result != null && result is Map) {
            if (result['needsRefresh'] == true) {
              final followStatus = result['followStatus'];
              final isBlocked = result['isBlocked'] ?? false;

              setState(() {
                if (isBlocked || followStatus != 'FOLLOWING') {
                  // 리스트에서 제거
                  followings.removeAt(index);
                } else {
                  // 상태만 업데이트
                  followings[index]['followStatus'] = followStatus;
                  followings[index]['isFollowing'] = followStatus == 'FOLLOWING';
                  followings[index]['isRequested'] = followStatus == 'REQUESTED';
                }
              });
            }
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: scaleHeight(74),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          child: Row(
            children: [
              // 프로필 이미지 - GestureDetector 제거됨
              ClipRRect(
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
              SizedBox(width: scaleWidth(12)),

              // 닉네임과 최애구단 컬럼 - GestureDetector 제거됨
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: scaleHeight(19), right: scaleWidth(10),),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 닉네임
                      FixedText(
                        follower['nickname'] ?? '알 수 없음',
                        style: AppFonts.pretendard.b3_sb(context).copyWith(color: Colors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: scaleHeight(6)),
                      // 최애 구단
                      FixedText(
                        "${follower['favTeam'] ?? '응원팀 없음'} 팬",
                        style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
              ),

              // 팔로우 버튼만 별도 처리
              if (follower['isMe'] != true)
                GestureDetector(
                  onTap: () => _handleFollow(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: scaleWidth(88),
                    height: scaleHeight(32),
                    decoration: BoxDecoration(
                      color: _getButtonBackgroundColor(follower),
                      borderRadius: BorderRadius.circular(scaleHeight(8)),
                    ),
                    child: Center(
                      child: FixedText(
                        _getButtonText(follower),
                        style: AppFonts.pretendard.c1_m(context).copyWith(
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
      ),
    );
  }

  // 버튼 배경색 결정
  Color _getButtonBackgroundColor(Map<String, dynamic> following) {
    final followStatus = following['followStatus'] ?? 'NOT_FOLLOWING';

    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray50;  // 팔로잉 상태
      case 'REQUESTED':
        return AppColors.gray50;  // 요청됨 상태 (팔로잉과 동일)
      default:
        return AppColors.gray600; // 팔로우 안 한 상태
    }
  }

  // 버튼 텍스트 결정
  String _getButtonText(Map<String, dynamic> following) {
    if (following['isMutualFollow'] == true &&
        following['followStatus'] == 'NOT_FOLLOWING') {
      return '맞팔로우';
    }
    final followStatus = following['followStatus'] ?? 'NOT_FOLLOWING';
    switch (followStatus) {
      case 'FOLLOWING': return '팔로잉';
      case 'REQUESTED': return '요청됨';
      default: return '팔로우';
    }
  }

  // 버튼 텍스트 색상 결정
  Color _getButtonTextColor(Map<String, dynamic> following) {
    final followStatus = following['followStatus'] ?? 'NOT_FOLLOWING';

    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray600;  // 팔로잉 상태일 때
      case 'REQUESTED':
        return AppColors.gray600;  // 요청됨 상태일 때
      default:
        return AppColors.gray20;   // 팔로우 안 한 상태일 때
    }
  }
}