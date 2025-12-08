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

      int targetUserId = widget.targetUserId ?? myUserId!;

      // 1. 팔로워 목록
      final response = await UserApi.getFollowers(targetUserId);
      final followersData = response['data'] as List? ?? [];

      // 2. 내 팔로잉 목록 (맞팔 확인용)
      final myFollowingResponse = await UserApi.getFollowing(myUserId!);
      final myFollowingData = myFollowingResponse['data'] as List? ?? [];
      final Set<int> iFollowTheseIds = myFollowingData
          .where((user) => user['id'] != null)
          .map((user) => user['id'] as int)
          .toSet();

      setState(() {
        followers = followersData.map((follower) {
          String followStatus = follower['followStatus'] ?? 'NOT_FOLLOWING';
          final userId = follower['id'] ?? follower['userId'];
          final isMutualFollow = followStatus == 'NOT_FOLLOWING' &&
              !iFollowTheseIds.contains(userId);

          return {
            'userId': userId,
            'nickname': follower['nickname'] ?? '알 수 없음',
            'favTeam': follower['favTeam'] ?? '응원팀 없음',
            'profileImageUrl': follower['profileImageUrl'],
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
      print('❌ 팔로워 목록 불러오기 실패: $e');
      setState(() {
        followers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('팔로워 목록을 불러오는데 실패했습니다.'), backgroundColor: Colors.red),
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

        // 📡 follower 화면에서는 상대방이 확실히 나를 팔로우하고 있으므로 isMutualFollow = true
        setState(() {
          followers[index]['followStatus'] = 'NOT_FOLLOWING';
          followers[index]['isFollowing'] = false;
          followers[index]['isRequested'] = false;
          followers[index]['isMutualFollow'] = true;
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
            // 📡 백엔드 응답에서 isFollower 값 사용 (follower 화면이므로 항상 true일 것)
            followers[index]['isMutualFollow'] = responseData['isFollower'] ?? true;
          } else {
            // 공개 계정 - 즉시 팔로우
            followers[index]['followStatus'] = 'FOLLOWING';
            followers[index]['isFollowing'] = true;
            followers[index]['isRequested'] = false;
            // 📡 백엔드 응답에서 isFollower 값 사용 (follower 화면이므로 항상 true일 것)
            followers[index]['isMutualFollow'] = responseData['isFollower'] ?? true;
          }
        });
      } else if (currentStatus == 'REQUESTED') {
        // 요청 취소 (언팔로우 API 사용)
        await UserApi.unfollowUser(userId);

        // 📡 follower 화면에서는 상대방이 확실히 나를 팔로우하고 있으므로 isMutualFollow = true
        setState(() {
          followers[index]['followStatus'] = 'NOT_FOLLOWING';
          followers[index]['isFollowing'] = false;
          followers[index]['isRequested'] = false;
          followers[index]['isMutualFollow'] = true;
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (widget.targetUserId == null) {
            //
            // 내 팔로워 목록 → 마이페이지로 이동
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1,
                    animation2) => const MyPageScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
            // 다른 유저 팔로워 리스트 → 그냥 뒤로가기
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
                                style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray900),
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
        style: AppFonts.pretendard.head_sm_600(context).copyWith(color: AppColors.gray400),
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // 전체 영역에 탭 제스처 추가
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
                if (isBlocked) {
                  // 차단 시 리스트에서 제거
                  followers.removeAt(index);
                } else {
                  // 팔로우 상태만 업데이트
                  followers[index]['followStatus'] = followStatus;
                  followers[index]['isFollowing'] = followStatus == 'FOLLOWING';
                  followers[index]['isRequested'] = followStatus == 'REQUESTED';
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
              // 프로필 이미지
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

              // 닉네임과 최애구단 컬럼
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

              // 팔로우 버튼
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
    if (follower['isMutualFollow'] == true &&
        follower['followStatus'] == 'NOT_FOLLOWING') {
      return '맞팔로우';
    }

    final followStatus = follower['followStatus'] ?? 'NOT_FOLLOWING';
    switch (followStatus) {
      case 'FOLLOWING': return '팔로잉';
      case 'REQUESTED': return '요청됨';
      default: return '팔로우';
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