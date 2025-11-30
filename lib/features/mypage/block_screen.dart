import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/features/mypage/settings_screen.dart';
import 'package:frontend/features/mypage/friend_profile_screen.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/components/custom_toast.dart';
import 'package:frontend/api/user_api.dart';
import 'dart:async';

class BlockScreen extends StatefulWidget {
  const BlockScreen({Key? key}) : super(key: key);

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  List<Map<String, dynamic>> blockedUsers = [];
  bool isLoading = true;
  int? myUserId;

  // 각 사용자별 차단 해제 대기 상태 추적
  Map<int, bool> unblockPendingMap = {};
  Map<int, bool> cancelledMap = {};
  Map<int, Timer?> unblockTimerMap = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    // 모든 타이머 정리
    unblockTimerMap.values.forEach((timer) => timer?.cancel());
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final myProfile = await UserApi.getMyProfile();
      myUserId = myProfile['data']['id'];
    } catch (e) {
      print('❌ 현재 사용자 ID 조회 실패: $e');
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response = await UserApi.getBlockedUsers();
      final blockedData = response['data'] as List? ?? [];
      setState(() {
        blockedUsers = blockedData.map((user) {
          return {
            'userId': user['userId'] as int,
            'nickname': user['nickname'] ?? '알 수 없음',
            'favTeam': user['favTeam'] ?? '응원팀 없음',
            'profileImageUrl': user['profileImageUrl'],
            'isBlocked': true,
            'followStatus': 'NOT_FOLLOWING',
          };
        }).toList();
        isLoading = false;
      });
      print('✅ 차단된 사용자 목록 조회 성공: ${blockedUsers.length}명');
    } catch (e) {
      print('❌ 차단된 사용자 목록 불러오기 실패: $e');
      setState(() {
        blockedUsers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단된 계정 목록을 불러오는데 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future _handleUnblock(int index) async {
    final user = blockedUsers[index];
    final userId = user['userId'];
    final nickname = user['nickname'];
    final profileImageUrl = user['profileImageUrl'];

    if (unblockPendingMap[userId] == true) {
      print('⚠️ 이미 진행 중: $nickname');
      return;
    }

    unblockPendingMap[userId] = true;

    setState(() {
      blockedUsers[index]['isBlocked'] = false;
      blockedUsers[index]['followStatus'] = 'NOT_FOLLOWING';
    });

    try {
      await UserApi.unblockUser(userId);
      print('✅ 차단 해제 성공: $nickname');
    } catch (e) {
      print('❌ 차단 해제 실패: $e');
      setState(() {
        blockedUsers[index]['isBlocked'] = true;
        blockedUsers[index]['followStatus'] = 'NOT_FOLLOWING';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('차단 해제 실패'), backgroundColor: Colors.red),
      );
      unblockPendingMap[userId] = false;
      return;
    }

    CustomToast.showWithProfile(
      context: context,
      profileImageUrl: profileImageUrl,
      defaultIconAsset: AppImages.profile,
      nickname: nickname,
      message: '차단이 해제되었습니다',
      duration: Duration(seconds: 3),
      onCancel: () async {
        try {
          await UserApi.blockUser(userId);
          // UI 복구
          setState(() {
            blockedUsers[index]['isBlocked'] = true;
            blockedUsers[index]['followStatus'] = 'NOT_FOLLOWING';
          });
        } catch (e) {
        }
        unblockPendingMap[userId] = false;
      },
    );

    unblockPendingMap[userId] = false;
  }

  Future<void> _handleFollow(int index) async {
    try {
      final user = blockedUsers[index];
      final userId = user['userId'];
      final currentStatus = user['followStatus'];

      // 🎯 토스트 대기 중이면 즉시 차단 해제 API 호출
      if (unblockPendingMap[userId] == true) {
        print('⚡ 토스트 대기 중 팔로우 버튼 클릭 감지 -> 즉시 차단 해제 실행');

        // 🔑 Timer 취소
        unblockTimerMap[userId]?.cancel();
        unblockTimerMap[userId] = null;

        // cancelled를 false로 유지 (= 취소 안 함)
        cancelledMap[userId] = false;

        // 즉시 차단 해제 API 호출
        try {
          await UserApi.unblockUser(userId);
          print('✅ 즉시 차단 해제 성공');

          // 대기 상태 해제
          unblockPendingMap[userId] = false;

        } catch (e) {
          print('❌ 즉시 차단 해제 실패: $e');
          // 실패하면 상태 복구하고 리턴
          setState(() {
            blockedUsers[index]['isBlocked'] = true;
            blockedUsers[index]['followStatus'] = 'NOT_FOLLOWING';
          });
          unblockPendingMap[userId] = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('차단 해제에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // 🔄 일반적인 팔로우/언팔로우 처리
      if (currentStatus == 'FOLLOWING') {
        await UserApi.unfollowUser(userId);
        setState(() {
          blockedUsers[index]['followStatus'] = 'NOT_FOLLOWING';
        });
        print('✅ 언팔로우 성공');
      } else if (currentStatus == 'NOT_FOLLOWING') {
        final response = await UserApi.followUser(userId);
        final responseData = response['data'];
        setState(() {
          if (responseData['pending'] == true) {
            blockedUsers[index]['followStatus'] = 'REQUESTED';
          } else {
            blockedUsers[index]['followStatus'] = 'FOLLOWING';
          }
        });
        print('✅ 팔로우 성공');
      } else if (currentStatus == 'REQUESTED') {
        await UserApi.unfollowUser(userId);
        setState(() {
          blockedUsers[index]['followStatus'] = 'NOT_FOLLOWING';
        });
        print('✅ 팔로우 요청 취소 성공');
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
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const SettingsScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: scaleHeight(60),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => const SettingsScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
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
                            "차단된 계정",
                            style: AppFonts.suite.b2_b(context)
                                .copyWith(color: AppColors.gray950),
                          ),
                        ),
                      ),
                      SizedBox(width: scaleHeight(24)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(
                  child: CircularProgressIndicator(color: AppColors.pri900),
                )
                    : blockedUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildBlockedUserList(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(currentIndex: 4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FixedText(
        "차단된 계정이 없어요",
        style: AppFonts.suite.head_sm_700(context)
            .copyWith(color: AppColors.gray400),
      ),
    );
  }

  Widget _buildBlockedUserList() {
    return ListView.builder(
      itemCount: blockedUsers.length,
      itemBuilder: (context, index) {
        final user = blockedUsers[index];
        return _buildBlockedUserItem(user, index);
      },
    );
  }

  Widget _buildBlockedUserItem(Map<String, dynamic> user, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FriendProfileScreen(userId: user['userId']),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        ).then((_) => _loadBlockedUsers());
      },
      child: Container(
        width: double.infinity,
        height: scaleHeight(74),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(scaleHeight(12.43)),
                child: user['profileImageUrl'] != null
                    ? Image.network(
                  user['profileImageUrl']!,
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: scaleHeight(19)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FixedText(
                        user['nickname'] ?? '알 수 없음',
                        style: AppFonts.pretendard.b3_sb(context)
                            .copyWith(color: Colors.black),
                      ),
                      SizedBox(height: scaleHeight(6)),
                      FixedText(
                        "${user['favTeam'] ?? '응원팀 없음'} 팬",
                        style: AppFonts.suite.caption_re_400(context)
                            .copyWith(color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (user['isBlocked'] == true) {
                    _handleUnblock(index);
                  } else {
                    _handleFollow(index);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: scaleWidth(88),
                  height: scaleHeight(32),
                  decoration: BoxDecoration(
                    color: _getButtonBackgroundColor(user),
                    borderRadius: BorderRadius.circular(scaleHeight(8)),
                    border: user['isBlocked'] == true
                        ? Border.all(color: AppColors.error, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: FixedText(
                      _getButtonText(user),
                      style: AppFonts.pretendard.c1_m(context).copyWith(
                        color: _getButtonTextColor(user),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getButtonBackgroundColor(Map<String, dynamic> user) {
    if (user['isBlocked'] == true) {
      return Colors.transparent;
    }

    final followStatus = user['followStatus'] ?? 'NOT_FOLLOWING';
    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray50;
      case 'REQUESTED':
        return AppColors.gray50;
      default:
        return AppColors.gray600;
    }
  }

  String _getButtonText(Map<String, dynamic> user) {
    if (user['isBlocked'] == true) {
      return '차단됨';
    }

    final followStatus = user['followStatus'] ?? 'NOT_FOLLOWING';
    switch (followStatus) {
      case 'FOLLOWING':
        return '팔로잉';
      case 'REQUESTED':
        return '요청됨';
      default:
        return '팔로우';
    }
  }

  Color _getButtonTextColor(Map<String, dynamic> user) {
    if (user['isBlocked'] == true) {
      return AppColors.error;
    }

    final followStatus = user['followStatus'] ?? 'NOT_FOLLOWING';
    switch (followStatus) {
      case 'FOLLOWING':
        return AppColors.gray600;
      case 'REQUESTED':
        return AppColors.gray600;
      default:
        return AppColors.gray20;
    }
  }
}
