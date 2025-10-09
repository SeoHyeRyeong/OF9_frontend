import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/api/notification_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';

class NotificationModel {
  final int id;
  String type;
  final String content;
  final String timeAgo;
  final String? userNickname;
  final String? userProfileImage;
  final String? reactionImageUrl;
  final bool isRead;
  final bool? isPrivateAccount;
  int? userId;
  int? requestId;

  NotificationModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'] ?? 'UNKNOWN',
        content = json['content'] ?? '',
        timeAgo = json['timeAgo'] ?? '',
        userNickname = json['userNickname'],
        userProfileImage = json['userProfileImage'],
        reactionImageUrl = json['reactionImageUrl'],
        isRead = json['isRead'] ?? true,
        isPrivateAccount = json['isPrivateAccount'],
        userId = json['userId'],
        requestId = json['requestId'];
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  final List<String> _tabTexts = ["ALL", "친구의 직관 기록", "받은 공감", "소식"];
  final List<String> _categories = ["ALL", "FRIEND_RECORD", "REACTION", "NEWS"];

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int? _processingId;
  final Map<String, FollowButtonStatus> _followStatusMap = {};
  bool? _isMyAccountPrivate; // ✅ null로 초기화
  bool _isAutoAccepting = false; // ✅ 자동 수락 상태

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 앱 포그라운드 복귀 - 알림 데이터 새로고침');
      _loadData();
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    print('🔄 탭 변경: ${_tabTexts[index]}');
    setState(() {
      _selectedTabIndex = index;
      _notifications = [];
    });
    _loadData();
  }

  // ✅ 자동 팔로우 수락 처리
  Future<void> _autoAcceptAllRequests() async {
    if (_isAutoAccepting) return;

    setState(() => _isAutoAccepting = true);

    try {
      print('🔄 자동 팔로우 수락 시작');
      final requests = await UserApi.getFollowRequests();
      final pendingRequests = requests['data'] as List<dynamic>;

      if (pendingRequests.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${pendingRequests.length}개의 팔로우 요청을 자동으로 수락하고 있습니다...'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.pri500,
              )
          );
        }

        int acceptedCount = 0;
        for (var request in pendingRequests) {
          try {
            final requestId = request['requestId'];
            await UserApi.acceptFollowRequest(requestId);
            acceptedCount++;
            print('✅ 자동 수락 완료: ${request['requesterNickname']}');
          } catch (e) {
            print('❌ 자동 수락 실패: ${request['requesterNickname']} - $e');
          }
        }

        if (mounted && acceptedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ${acceptedCount}개의 팔로우 요청을 자동으로 수락했습니다!'),
                backgroundColor: AppColors.pri500,
                duration: const Duration(seconds: 3),
              )
          );
        }

        // 잠깐 기다린 후 데이터 새로고침
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          _loadData();
        }
      } else {
        print('📭 자동 수락할 팔로우 요청이 없음');
      }
    } catch (e) {
      print('❌ 자동 수락 처리 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('자동 수락 처리 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAutoAccepting = false);
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _followStatusMap.clear();

    try {
      final category = _categories[_selectedTabIndex];
      print('🔄 _loadData 시작: category=$category');

      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];
      final newPrivateStatus = myProfile['data']['isPrivate'] ?? false;

      print('🧪 디버그: _isMyAccountPrivate = $_isMyAccountPrivate');
      print('🧪 디버그: newPrivateStatus = $newPrivateStatus');

      // ✅ 계정 상태 변화 감지
      if (_isMyAccountPrivate != null && _isMyAccountPrivate != newPrivateStatus) {
        print('🔄 계정 상태 변화 감지: $_isMyAccountPrivate → $newPrivateStatus');
        if (_isMyAccountPrivate == true && newPrivateStatus == false) {
          print('🔓 비공개 → 공개 변경 감지! 자동 수락 처리 시작');
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _autoAcceptAllRequests();
            }
          });
        }
      }
      _isMyAccountPrivate = newPrivateStatus;

      print('👤 내 계정 정보: userId=$myUserId, isPrivate=$_isMyAccountPrivate');

      final results = await Future.wait([
        NotificationApi.getNotificationsByCategory(category),
        UserApi.getFollowing(myUserId),
        UserApi.getFollowers(myUserId),
      ]);

      final notificationsData = results[0] as List<Map<String, dynamic>>;
      final followingResponse = results[1] as Map<String, dynamic>;
      final followersResponse = results[2] as Map<String, dynamic>;

      print('📊 받은 알림 데이터: ${notificationsData.length}개');

      // 팔로잉 상태 확인
      final List<dynamic> followingListRaw = followingResponse['data'] ?? [];
      final Set<String> iFollowTheseNicknames = followingListRaw
          .where((user) => user != null && user['nickname'] != null)
          .map((user) => user['nickname'] as String)
          .toSet();

      // 팔로워 목록에서 followStatus 추출
      final List<dynamic> followersListRaw = followersResponse['data'] ?? [];
      final Map<String, String> followerStatusMap = {};
      for (var follower in followersListRaw) {
        if (follower != null && follower['nickname'] != null) {
          followerStatusMap[follower['nickname']] = follower['followStatus'] ?? 'NOT_FOLLOWING';
        }
      }

      print('👥 내가 팔로우하는 사용자들: $iFollowTheseNicknames');
      print('👥 팔로워 상태 맵: $followerStatusMap');

      List<NotificationModel> newNotifications = notificationsData.map((data) => NotificationModel.fromJson(data)).toList();

      // followStatus 기반 정확한 상태 설정
      for (var notification in newNotifications) {
        if (notification.userNickname != null) {
          final nickname = notification.userNickname!;

          if (iFollowTheseNicknames.contains(nickname)) {
            _followStatusMap[nickname] = FollowButtonStatus.following;
            print('  → 팔로잉 상태: $nickname');
          } else {
            final status = followerStatusMap[nickname] ?? 'NOT_FOLLOWING';
            if (status == 'REQUESTED') {
              _followStatusMap[nickname] = FollowButtonStatus.requestSent;
              print('  → 요청됨 상태: $nickname');
            } else {
              _followStatusMap[nickname] = FollowButtonStatus.canFollow;
              print('  → 팔로우 가능 상태: $nickname');
            }
          }
        }
      }

      print('🗺️ 최종 팔로우 상태 맵: $_followStatusMap');

      if (mounted) {
        setState(() => _notifications = newNotifications);
        print('🎨 UI 업데이트 완료: ${_notifications.length}개 알림 표시');

        // ✅ 추가 로직: 공개 계정이고 팔로우 요청이 있으면 자동 수락 (fallback)
        if (_isMyAccountPrivate == false && !_isAutoAccepting) {
          final followRequests = await UserApi.getFollowRequests();
          final pendingRequests = followRequests['data'] as List<dynamic>;

          if (pendingRequests.isNotEmpty) {
            print('🧪 추가 체크: 공개 계정 + 팔로우 요청 존재 → 자동 수락 실행');
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted) {
                _autoAcceptAllRequests();
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ _loadData 에러: $e');
      debugPrint('데이터 로딩 실패: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAcceptFollow(NotificationModel notification) async {
    if (notification.requestId == null || notification.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오류: 요청 정보가 없습니다.'))
      );
      return;
    }

    setState(() => _processingId = notification.id);
    try {
      print('✅ 팔로우 요청 수락: ${notification.userNickname}');
      final result = await NotificationApi.acceptFollowRequest(
          notification.requestId!,
          notification.userId!
      );

      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message))
        );

        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          setState(() {
            _notifications[index].type = 'FOLLOW';
            if (notification.userNickname != null) {
              _followStatusMap[notification.userNickname!] = FollowButtonStatus.canFollow;
            }
          });
          print('🔄 수락 후 타입 변경: FOLLOW_REQUEST → FOLLOW');
        }
      }
    } catch (e) {
      print('❌ 팔로우 수락 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('팔로우 수락 실패: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _handleRejectFollow(NotificationModel notification) async {
    if (notification.requestId == null || notification.userId == null) return;
    setState(() => _processingId = notification.id);
    try {
      print('❌ 팔로우 요청 거절: ${notification.userNickname}');
      await NotificationApi.rejectFollowRequest(notification.requestId!, notification.userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('팔로우 요청을 거절했습니다.')));
        _loadData();
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _handleFollowAction(NotificationModel notification, FollowButtonStatus currentStatus) async {
    if (notification.userId == null) return;
    setState(() => _processingId = notification.userId);

    try {
      print('👥 팔로우 액션: ${notification.userNickname} - $currentStatus');

      final result = await (currentStatus == FollowButtonStatus.canFollow
          ? NotificationApi.followUser(notification.userId!)
          : NotificationApi.unfollowUser(notification.userId!));

      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        if (notification.userNickname != null) {
          setState(() => _followStatusMap[notification.userNickname!] = result.buttonState);
        }
        print('🔄 팔로우 상태 변경: $currentStatus → ${result.buttonState}');
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: scaleWidth(22),
        title: Row(
          children: [
            Text("알림", style: AppFonts.suite.h3_b(context)),
            // ✅ 자동 수락 진행 상태 표시
            if (_isAutoAccepting) ...[
              SizedBox(width: scaleWidth(8)),
              SizedBox(
                width: scaleWidth(16),
                height: scaleWidth(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.pri500),
                ),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20), vertical: scaleHeight(10)),
              child: SizedBox(
                height: scaleHeight(40),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabTexts.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(right: scaleWidth(6)),
                    child: _buildTabButton(index),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildTabButton(int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(14), vertical: scaleHeight(10)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray700 : AppColors.gray30,
          borderRadius: BorderRadius.circular(68),
        ),
        child: Center(
          child: Text(
            _tabTexts[index],
            style: isSelected
                ? AppFonts.suite.c1_b(context).copyWith(color: AppColors.white)
                : AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray500),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.pri500));
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Text("받은 알림이 없어요", style: AppFonts.suite.b1_sb(context).copyWith(color: AppColors.gray400)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.pri500,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20), vertical: scaleHeight(10)),
        itemCount: _notifications.length,
        itemBuilder: (context, index) => _buildNotificationItem(_notifications[index]),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final isProcessing = _processingId == notification.id || (_processingId == notification.userId && notification.userId != null);
    final trailingWidget = _buildTrailingWidget(notification, isProcessing);

    return Container(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(16)),
      color: notification.isRead ? AppColors.white : AppColors.pri100.withOpacity(0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(notification),
          SizedBox(width: scaleWidth(12)),
          Expanded(child: _buildNotificationText(notification)),
          if (trailingWidget != null) ...[
            SizedBox(width: scaleWidth(12)),
            trailingWidget,
          ]
        ],
      ),
    );
  }

  Widget _buildNotificationText(NotificationModel notification) {
    const double lineSpacing = 1.45;
    final bool isTextOnly = ['SYSTEM', 'NEWS', 'NEW_RECORD', 'FRIEND_RECORD'].contains(notification.type);

    final mainText = Text.rich(
      _buildTextSpans(notification, lineSpacing),
      textAlign: TextAlign.left,
    );

    if (isTextOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainText,
          SizedBox(height: scaleHeight(6)),
          Text(notification.timeAgo, style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400)),
        ],
      );
    } else {
      return mainText;
    }
  }

  InlineSpan _buildTextSpans(NotificationModel notification, double lineSpacing) {
    if (notification.type == 'SYSTEM' || notification.type == 'NEWS') {
      return TextSpan(
        text: notification.content,
        style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray800, height: lineSpacing),
      );
    }

    return TextSpan(
      children: [
        if (notification.userNickname != null)
          TextSpan(
            text: notification.userNickname,
            style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray900, height: lineSpacing),
          ),
        TextSpan(
          text: _getActionText(notification),
          style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray700, height: lineSpacing),
        ),
        if (!['SYSTEM', 'NEWS', 'NEW_RECORD', 'FRIEND_RECORD'].contains(notification.type))
          TextSpan(
            text: ' \u{00A0}${notification.timeAgo}',
            style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400, height: lineSpacing),
          ),
      ],
    );
  }

  String _getActionText(NotificationModel notification) {
    switch (notification.type) {
      case 'NEW_RECORD':
      case 'FRIEND_RECORD':
        return '님이 직관 기록을 업로드했어요.';
      case 'REACTION':
        return '님이 회원님의 기록에 공감했어요.';
      case 'FOLLOW':
        return '님이 회원님을 팔로우합니다.';
      case 'FOLLOW_REQUEST':
        return '님의 팔로우 요청';
      default:
        return notification.content;
    }
  }

  Widget _buildProfileImage(NotificationModel notification) {
    final isSystem = notification.type == 'SYSTEM' || notification.type == 'NEWS';
    return Container(
      width: scaleWidth(42),
      height: scaleWidth(42),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12.43),
        image: (notification.userProfileImage != null && !isSystem)
            ? DecorationImage(image: NetworkImage(notification.userProfileImage!), fit: BoxFit.cover)
            : null,
      ),
      child: (notification.userProfileImage == null || isSystem)
          ? Center(child: isSystem ? SvgPicture.asset(AppImages.dodada, width: scaleWidth(24), color: AppColors.gray400) : Icon(Icons.person, color: AppColors.gray400, size: scaleWidth(24)))
          : null,
    );
  }

  Widget? _buildTrailingWidget(NotificationModel notification, bool isProcessing) {
    switch(notification.type) {
      case 'FOLLOW_REQUEST':
        return _buildAcceptRejectButtons(notification, isProcessing);
      case 'FOLLOW':
        if(notification.userNickname == null) return null;
        final status = _followStatusMap[notification.userNickname] ?? FollowButtonStatus.canFollow;
        return _buildFollowButton(notification, status, isProcessing);
      case 'REACTION':
        if(notification.reactionImageUrl != null) {
          return Image.network(
            notification.reactionImageUrl!,
            width: scaleWidth(40),
            height: scaleWidth(40),
            errorBuilder: (context, error, stackTrace) => Container(
              width: scaleWidth(40),
              height: scaleWidth(40),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFCB4BA)),
            ),
          );
        }
        return null;
      default:
        return null;
    }
  }

  Widget _buildAcceptRejectButtons(NotificationModel notification, bool isProcessing) {
    return isProcessing
        ? SizedBox(width: scaleWidth(108), child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : Row(
      children: [
        SizedBox(
          width: scaleWidth(50),
          height: scaleHeight(32),
          child: ElevatedButton(
            onPressed: () => _handleAcceptFollow(notification),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gray50,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
                elevation: 0
            ),
            child: Text('수락', style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.white)),
          ),
        ),
        SizedBox(width: scaleWidth(4)),
        SizedBox(
          width: scaleWidth(50),
          height: scaleHeight(32),
          child: TextButton(
            onPressed: () => _handleRejectFollow(notification),
            style: TextButton.styleFrom(
                backgroundColor: AppColors.gray50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero
            ),
            child: Text('삭제', style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray600)),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(NotificationModel notification, FollowButtonStatus status, bool isProcessing) {
    String text;
    Color buttonColor, textColor;

    switch (status) {
      case FollowButtonStatus.canFollow:
        text = '맞팔로우'; buttonColor = AppColors.gray600; textColor = AppColors.white;
        break;
      case FollowButtonStatus.following:
        text = '팔로잉'; buttonColor = AppColors.gray50; textColor = AppColors.gray600;
        break;
      case FollowButtonStatus.requestSent:
        text = '요청됨'; buttonColor = AppColors.gray50; textColor = AppColors.gray400;
        break;
    }

    return SizedBox(
      width: scaleWidth(88),
      height: scaleHeight(32),
      child: ElevatedButton(
        onPressed: isProcessing ? null : () => _handleFollowAction(notification, status),
        style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
            elevation: 0
        ),
        child: isProcessing
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
            : Text(text, style: AppFonts.suite.c1_m(context).copyWith(color: textColor)),
      ),
    );
  }
}
