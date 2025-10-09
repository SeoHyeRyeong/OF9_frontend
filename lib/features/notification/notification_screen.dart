import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/api/notification_api.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/components/custom_bottom_navbar.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabTexts = ["ALL", "친구의 직관 기록", "받은 공감", "소식"];
  final List<String> _categories = ["ALL", "FRIEND_RECORD", "REACTION", "NEWS"];

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int? _processingId;
  final Map<int, FollowButtonStatus> _followStatusMap = {};
  List<dynamic> _pendingFollowRequests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
      _notifications = [];
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final category = _categories[_selectedTabIndex];

      // a'ALL' 탭일 때만 팔로우 요청 목록을 함께 가져옴
      if (category == 'ALL') {
        final results = await Future.wait([
          NotificationApi.getNotificationsByCategory(category),
          UserApi.getFollowRequests(),
        ]);
        _notifications = results[0] as List<Map<String, dynamic>>;
        final followRequestsResponse = results[1] as Map<String, dynamic>;
        _pendingFollowRequests = followRequestsResponse['data'] as List<dynamic>? ?? [];
      } else {
        _notifications = await NotificationApi.getNotificationsByCategory(category);
      }

      for (var n in _notifications) {
        final userId = NotificationApi.extractUserIdFromNotification(n);
        if (userId != null && _followStatusMap[userId] == null) {
          final amIFollowing = n['amIFollowing'] ?? false;
          _followStatusMap[userId] = amIFollowing ? FollowButtonStatus.following : FollowButtonStatus.canFollow;
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
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


  Future<void> _handleAcceptFollow(int notificationId, int? requestId, int? userId) async {
    if (requestId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오류: 요청 정보가 없습니다.')));
      return;
    }
    setState(() => _processingId = notificationId);
    try {
      final result = await NotificationApi.acceptFollowRequest(requestId, userId);
      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        _loadData();
      }
    } catch (e) {
      debugPrint('팔로우 수락 실패: $e');
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _handleRejectFollow(int notificationId, int? requestId, int? userId) async {
    if (requestId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오류: 요청 정보가 없습니다.')));
      return;
    }
    setState(() => _processingId = notificationId);
    try {
      await NotificationApi.rejectFollowRequest(requestId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('팔로우 요청을 거절했습니다.')));
        _loadData();
      }
    } catch (e) {
      debugPrint('팔로우 거절 실패: $e');
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _handleFollowAction(int? userId, FollowButtonStatus currentStatus, {int? requestId}) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오류: 사용자 정보가 없습니다.')));
      return;
    }
    setState(() => _processingId = userId);
    try {
      FollowActionResult result;
      switch (currentStatus) {
        case FollowButtonStatus.canFollow:
          result = await NotificationApi.followUser(userId);
          break;
        case FollowButtonStatus.following:
          result = await NotificationApi.unfollowUser(userId);
          break;
        case FollowButtonStatus.requestSent:
          result = await NotificationApi.cancelFollowRequest(userId, requestId ?? 0);
          break;
      }
      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        setState(() => _followStatusMap[userId] = result.buttonState);
      }
    } catch (e) {
      debugPrint('팔로우 액션 실패: $e');
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
        title: Text("알림", style: AppFonts.suite.h3_b(context)),
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
        child: Text(
          "받은 알림이 없어요",
          style: AppFonts.suite.b1_sb(context).copyWith(color: AppColors.gray400),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.pri500,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20), vertical: scaleHeight(10)),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(_notifications[index]);
        },
      ),
    );
  }

  // notification_screen.dart 파일에서 이 함수를 교체해주세요.
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    int? userId = NotificationApi.extractUserIdFromNotification(notification);
    int? requestId = NotificationApi.extractRequestIdFromNotification(notification);
    final int notificationId = notification['id'] as int;
    final bool isRead = notification['isRead'] ?? true;

    if (notification['type'] == 'FOLLOW_REQUEST') {
      try {
        final matchingRequest = _pendingFollowRequests.firstWhere(
              (req) => req['requesterNickname'] == notification['userNickname'],
          orElse: () => null,
        );

        if (matchingRequest != null) {
          userId = matchingRequest['requesterId'];
          requestId = matchingRequest['requestId'];
        }
      } catch (e) {
        debugPrint("상세 요청 목록에서 일치하는 항목 찾기 실패: $e");
      }
    }

    final bool isProcessing = _processingId == notificationId || (_processingId == userId && userId != null);
    final Widget? trailingWidget = _buildTrailingWidget(notification, userId, requestId, notificationId, isProcessing);

    return Container(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(16)),
      color: isRead ? AppColors.white : AppColors.pri100.withOpacity(0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(notification),
          SizedBox(width: scaleWidth(12)),
          Expanded(
            // ✅ 1. Column을 제거하고 _buildNotificationText가 시간까지 모두 그리도록 변경
            child: _buildNotificationText(notification),
          ),
          if (trailingWidget != null) ...[
            SizedBox(width: scaleWidth(12)),
            trailingWidget,
          ]
        ],
      ),
    );
  }

  // notification_screen.dart 파일에서 이 함수를 아래 코드로 교체해주세요.

  Widget _buildNotificationText(Map<String, dynamic> notification) {
    final String type = notification['type'] ?? '';
    final String content = notification['content'] ?? '알림 내용이 없습니다.';
    final String nickname = notification['userNickname'] ?? '';
    final String timeAgo = notification['timeAgo'] ?? '';
    const double lineSpacing = 1.45; // 줄바꿈 시 간격

    // ✅ [수정] 오른쪽에 위젯이 없는 타입 (직관 기록, 소식 등)
    if (type == 'SYSTEM' || type == 'NEWS' || type == 'NEW_RECORD' || type == 'FRIEND_RECORD') {
      Widget mainText;

      // 시스템 알림은 닉네임 없이 content만 표시
      if (type == 'SYSTEM' || type == 'NEWS') {
        mainText = Text(
          content,
          style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray800, height: lineSpacing),
        );
      } else {
        // 직관 기록 알림은 닉네임과 내용을 조합
        String actionText = '님이 직관 기록을 업로드했어요.';
        mainText = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: nickname,
                style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray900, height: lineSpacing),
              ),
              TextSpan(
                text: actionText,
                style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray700, height: lineSpacing),
              ),
            ],
          ),
        );
      }

      // Column을 사용해 메인 텍스트와 시간을 분리하고 아랫줄에 배치
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainText,
          SizedBox(height: scaleHeight(6)), // 요청하신 간격 6 적용
          Text(
            timeAgo,
            style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400),
          ),
        ],
      );
    }

    // ✅ [수정] 오른쪽에 위젯이 있는 타입 (팔로우, 공감 등)
    // Text.rich를 사용해 텍스트와 시간을 한 줄에 표시
    String actionText = '';
    switch (type) {
      case 'REACTION':
        actionText = '님이 회원님의 기록에 공감했어요.';
        break;
      case 'FOLLOW':
        actionText = '님이 회원님을 팔로우합니다.';
        break;
      case 'FOLLOW_REQUEST':
        actionText = '님의 팔로우 요청';
        break;
      default:
        actionText = content;
        break;
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: nickname,
            style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray900, height: lineSpacing),
          ),
          TextSpan(
            text: actionText,
            style: AppFonts.suite.b3_r(context).copyWith(color: AppColors.gray700, height: lineSpacing),
          ),
          TextSpan(
            text: ' \u{00A0}$timeAgo', // 띄어쓰기
            style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400, height: lineSpacing),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> notification) {
    final String? imageUrl = notification['userProfileImage'];
    final bool isSystem = notification['type'] == 'SYSTEM' || notification['type'] == 'NEWS';

    return Container(
      width: scaleWidth(42),
      height: scaleWidth(42),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12.43),
        image: (imageUrl != null && !isSystem)
            ? DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: (imageUrl == null || isSystem)
          ? Center(
        child: isSystem
            ? SvgPicture.asset(AppImages.dodada, width: scaleWidth(24), color: AppColors.gray400)
            : Icon(Icons.person, color: AppColors.gray400, size: scaleWidth(24)),
      )
          : null,
    );
  }

  // ✅ [수정] 반환 타입을 Widget? (nullable)로 변경
  Widget? _buildTrailingWidget(Map<String, dynamic> notification, int? userId, int? requestId, int notificationId, bool isProcessing) {
    final String type = notification['type'] ?? 'NONE';

    if (type == 'FOLLOW_REQUEST' && userId != null && requestId != null) {
      return _buildAcceptRejectButtons(notificationId, requestId, userId, isProcessing);
    }

    if (type == 'FOLLOW' && userId != null) {
      return _buildFollowButton(userId, _followStatusMap[userId] ?? FollowButtonStatus.canFollow, requestId: requestId, isProcessing: isProcessing);
    }

    if (type == 'REACTION' && notification['reactionImageUrl'] != null) {
      return Image.network(
        notification['reactionImageUrl'],
        width: scaleWidth(40),
        height: scaleWidth(40),
        errorBuilder: (context, error, stackTrace) => Container(
          width: scaleWidth(40),
          height: scaleWidth(40),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFCB4BA)),
        ),
      );
    }

    // 위젯이 필요 없는 타입은 null을 반환
    return null;
  }

  Widget _buildAcceptRejectButtons(int notificationId, int requestId, int userId, bool isProcessing) {
    return isProcessing
        ? SizedBox(width: scaleWidth(108), child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : Row(
      children: [
        SizedBox(
          width: scaleWidth(50),
          height: scaleHeight(32),
          child: ElevatedButton(
            onPressed: () => _handleAcceptFollow(notificationId, requestId, userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.zero,
              elevation: 0,
            ),
            child: Text('수락', style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.white)),
          ),
        ),
        SizedBox(width: scaleWidth(4)),
        SizedBox(
          width: scaleWidth(50),
          height: scaleHeight(32),
          child: TextButton(
            onPressed: () => _handleRejectFollow(notificationId, requestId, userId),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.gray50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.zero,
            ),
            child: Text('삭제', style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray600)),
          ),
        ),
      ],
    );
  }

  // notification_screen.dart 파일에서 이 함수를 아래 코드로 교체해주세요.

  Widget _buildFollowButton(int userId, FollowButtonStatus status, {int? requestId, bool isProcessing = false}) {
    String text;
    Color buttonColor, textColor, borderColor;
    bool isOutlined; // OutlinedButton을 쓸지 여부
    VoidCallback? onPressed = isProcessing ? null : () => _handleFollowAction(userId, status, requestId: requestId);

    switch (status) {
      case FollowButtonStatus.canFollow:
        text = '맞팔로우';
        buttonColor = AppColors.gray700;
        textColor = AppColors.white;
        borderColor = Colors.transparent;
        isOutlined = false; // ElevatedButton 사용
        break;
      case FollowButtonStatus.following:
        text = '팔로잉';
        buttonColor = AppColors.gray50;
        textColor = AppColors.gray600;
        borderColor = Colors.transparent; // 테두리 없음
        isOutlined = false; // ✅ [수정] ElevatedButton을 사용하도록 변경
        break;
      case FollowButtonStatus.requestSent:
        text = '요청됨';
        buttonColor = AppColors.gray50;
        textColor = AppColors.gray400;
        borderColor = Colors.transparent; // 테두리 없음
        isOutlined = false; // ✅ [수정] ElevatedButton을 사용하도록 변경
        break;
    }

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
      backgroundColor: buttonColor,
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.zero,
    )
        : ElevatedButton.styleFrom(
      backgroundColor: buttonColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.zero,
      elevation: 0, // 그림자 제거
    );

    return SizedBox(
      width: scaleWidth(88),
      height: scaleHeight(32),
      child: TextButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: isProcessing
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isOutlined ? AppColors.gray600 : textColor))
            : Text(text, style: AppFonts.suite.c1_m(context).copyWith(color: textColor)),
      ),
    );
  }
}