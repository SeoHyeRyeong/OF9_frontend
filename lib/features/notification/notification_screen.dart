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
  final int? relatedRecordId;
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
        relatedRecordId = json['relatedRecordId'],
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
  final List<String> _tabTexts = ["ALL", "친구의 직관 기록", "반응", "소식"];
  final List<String> _categories = ["ALL", "FRIEND_RECORD", "REACTION", "NEWS"];

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int? _processingId;
  final Map<String, FollowButtonStatus> _followStatusMap = {};
  bool? _isMyAccountPrivate;
  bool _isAutoAccepting = false;
  Set<String> _currentFollowerNicknames = {};

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

  Future<void> _autoAcceptAllRequests() async {
    if (_isAutoAccepting) return;
    setState(() => _isAutoAccepting = true);
    try {
      final requests = await UserApi.getFollowRequests();
      final pendingRequests = requests['data'] as List<dynamic>;

      if (pendingRequests.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${pendingRequests.length}개의 팔로우 요청을 자동으로 수락하고 있습니다...'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.pri500,
              )
          );
        }

        int acceptedCount = 0;
        final acceptFutures = pendingRequests.map((request) async {
          try {
            await UserApi.acceptFollowRequest(request['requestId']);
            acceptedCount++;
          } catch (e) {
            print('❌ 자동 수락 실패: ${request['requesterNickname']} - $e');
          }
        });

        await Future.wait(acceptFutures);

        if (mounted && acceptedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ${acceptedCount}개의 팔로우 요청을 자동으로 수락했습니다!'),
                backgroundColor: AppColors.pri500,
                duration: const Duration(seconds: 2),
              )
          );
        }
        if (mounted) _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('자동 수락 처리 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    } finally {
      if (mounted) setState(() => _isAutoAccepting = false);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _followStatusMap.clear();
      _currentFollowerNicknames.clear();
    });

    try {
      final category = _categories[_selectedTabIndex];
      final myProfile = await UserApi.getMyProfile();
      final myUserId = myProfile['data']['id'];
      final newPrivateStatus = myProfile['data']['isPrivate'] ?? false;

      if (_isMyAccountPrivate != null && _isMyAccountPrivate != newPrivateStatus) {
        if (_isMyAccountPrivate == true && newPrivateStatus == false) {
          if (mounted) _autoAcceptAllRequests();
        }
      }
      _isMyAccountPrivate = newPrivateStatus;

      final results = await Future.wait([
        NotificationApi.getNotificationsByCategory(category),
        UserApi.getFollowing(myUserId),
        UserApi.getFollowers(myUserId),
      ]);

      final notificationsData = results[0] as List<Map<String, dynamic>>;
      final followingResponse = results[1] as Map<String, dynamic>;
      final followersResponse = results[2] as Map<String, dynamic>;

      final List<dynamic> followingListRaw = followingResponse['data'] ?? [];
      final Set<String> iFollowTheseNicknames = followingListRaw
          .where((user) => user != null && user['nickname'] != null)
          .map((user) => user['nickname'] as String)
          .toSet();

      final List<dynamic> followersListRaw = followersResponse['data'] ?? [];

      final Map<String, String> followerStatusMap = {};
      for (var follower in followersListRaw) {
        if (follower != null && follower['nickname'] != null) {
          final nickname = follower['nickname'] as String;
          followerStatusMap[nickname] = follower['followStatus'] ?? 'NOT_FOLLOWING';
          _currentFollowerNicknames.add(nickname);
        }
      }

      print('👥 현재 나를 팔로우하는 사용자들: $_currentFollowerNicknames');

      List<NotificationModel> newNotifications = notificationsData.map((data) => NotificationModel.fromJson(data)).toList();

      for (var notification in newNotifications) {
        if (notification.userNickname != null) {
          final nickname = notification.userNickname!;
          if (iFollowTheseNicknames.contains(nickname)) {
            _followStatusMap[nickname] = FollowButtonStatus.following;
          } else {
            final status = followerStatusMap[nickname] ?? 'NOT_FOLLOWING';
            if (status == 'REQUESTED') {
              _followStatusMap[nickname] = FollowButtonStatus.requestSent;
            } else {
              _followStatusMap[nickname] = FollowButtonStatus.canFollow;
            }
          }
        }
      }

      if (mounted) {
        setState(() => _notifications = newNotifications);
        if (_isMyAccountPrivate == false && !_isAutoAccepting) {
          final followRequests = await UserApi.getFollowRequests();
          if ((followRequests['data'] as List<dynamic>).isNotEmpty) {
            if (mounted) _autoAcceptAllRequests();
          }
        }
      }
    } catch (e) {
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
    if (notification.requestId == null || notification.userId == null) return;
    setState(() => _processingId = notification.id);
    try {
      final result = await NotificationApi.acceptFollowRequest(notification.requestId!, notification.userId!);
      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          setState(() {
            _notifications[index].type = 'FOLLOW';
            if (notification.userNickname != null) {
              _followStatusMap[notification.userNickname!] = FollowButtonStatus.canFollow;
              _currentFollowerNicknames.add(notification.userNickname!);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('팔로우 수락 실패: $e')));
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
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('팔로우 요청을 거절했습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('요청 거절에 실패했습니다: $e')));
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _handleFollowAction(NotificationModel notification, FollowButtonStatus currentStatus) async {
    if (notification.userId == null) return;
    setState(() => _processingId = notification.userId);
    try {
      final result = await (currentStatus == FollowButtonStatus.canFollow
          ? NotificationApi.followUser(notification.userId!)
          : NotificationApi.unfollowUser(notification.userId!));

      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        if (notification.userNickname != null) {
          setState(() => _followStatusMap[notification.userNickname!] = result.buttonState);
        }
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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text("알림", style: AppFonts.suite.h3_b(context)),
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
      color: notification.isRead ? Colors.white : AppColors.pri100.withOpacity(0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(notification),
          SizedBox(width: scaleWidth(12)),
          Expanded(child: _buildNotificationText(notification)),
          if (trailingWidget != null) ...[
            SizedBox(width: scaleWidth(20)),
            trailingWidget,
          ]
        ],
      ),
    );
  }

  Widget _buildNotificationText(NotificationModel notification) {
    final double lineSpacing = 1.45;

    final nicknameStyle = AppFonts.suite.b3_sb(context).copyWith(color: AppColors.black, height: lineSpacing);
    final actionStyle = AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray600, height: lineSpacing);
    final timeStyle = AppFonts.suite.c1_r(context).copyWith(color: AppColors.gray300, height: lineSpacing);

    final unbreakableTimeAgo = notification.timeAgo
        .replaceAll(' ', '\u{00A0}')
        .replaceAllMapped(
        RegExp(r'(\d)([가-힣])'), (match) => '${match.group(1)}\u{2060}${match.group(2)}');

    final actionText = _getActionText(notification);

    return Text.rich(
      TextSpan(
        children: [
          if (notification.userNickname != null)
            TextSpan(text: notification.userNickname, style: nicknameStyle),

          // 공백을 포함한 본문 텍스트 Span
          TextSpan(text: '$actionText  ', style: actionStyle),

          // 시간 텍스트만 포함하는 WidgetSpan
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Text(
              unbreakableTimeAgo,
              style: timeStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _getActionText(NotificationModel notification) {
    return notification.content;
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
          ? Center(child: isSystem ? SvgPicture.asset(AppImages.dodada, width: scaleWidth(24), color: AppColors.gray400) : SvgPicture.asset(AppImages.profile, width: scaleWidth(42), height: scaleWidth(42)))
          : null,
    );
  }

  Widget? _buildTrailingWidget(NotificationModel notification, bool isProcessing) {
    switch(notification.type) {
      case 'FOLLOW_REQUEST':
        return _buildAcceptRejectButtons(notification, isProcessing);
      case 'FOLLOW':
        if(notification.userNickname == null) return null;

        final isStillFollower = _currentFollowerNicknames.contains(notification.userNickname!);

        if (!isStillFollower) {
          print('🚫 ${notification.userNickname} 님은 현재 팔로워가 아니므로 버튼을 표시하지 않습니다.');
          return null;
        }

        final status = _followStatusMap[notification.userNickname] ?? FollowButtonStatus.canFollow;
        return _buildFollowButton(notification, status, isProcessing);

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
                backgroundColor: AppColors.gray600,
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
        text = '요청됨'; buttonColor = AppColors.gray50; textColor = AppColors.gray600;
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