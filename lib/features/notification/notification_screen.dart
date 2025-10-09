import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/api/notification_api.dart';
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
  int selectedTabIndex = 0;
  final List<String> tabTexts = ["ALL", "친구의 직관 기록", "받은 공감", "소식"];
  final List<String> categories = ["ALL", "FRIEND_RECORD", "REACTION", "NEWS"];

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  int? _processingId; // 사용자 ID 또는 알림 ID를 저장하여 중복 처리 방지

  // UI의 버튼 상태를 직접 관리하는 Map (userId, buttonStatus)
  Map<int, FollowButtonStatus> _followButtonStatusMap = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _onTabChanged(int index) {
    if (selectedTabIndex == index) return;
    setState(() => selectedTabIndex = index);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final category = categories[selectedTabIndex];
      final data = await NotificationApi.getNotificationsByCategory(category);
      if (mounted) {
        setState(() {
          notifications = data;
          // 알림 로드 후 팔로우 버튼 상태 초기화
          _initializeFollowButtonStates(data);
        });
      }
    } catch (e) {
      // 에러 처리
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// 알림 데이터를 기반으로 팔로우 버튼의 초기 상태를 설정
  void _initializeFollowButtonStates(List<Map<String, dynamic>> notifications) {
    for (var notification in notifications) {
      if (notification['type'] == 'FOLLOW' && notification['userId'] != null) {
        final userId = notification['userId'];
        // API 더미 데이터에 'amIFollowing' 키가 있으므로 활용
        // TODO: 실제 API 응답에 이와 유사한 필드가 없다면, 별도의 getFollowStatus API 호출 필요
        final amIFollowing = notification['amIFollowing'] ?? false;
        _followButtonStatusMap[userId] = amIFollowing ? FollowButtonStatus.following : FollowButtonStatus.canFollow;
      }
    }
  }

  // --- 비즈니스 로직 핸들러 ---

  Future<void> _handleAcceptFollow(int nId, int reqId, int uId) async {
    setState(() => _processingId = nId);
    try {
      final result = await NotificationApi.acceptFollowRequest(reqId, uId);
      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        setState(() {
          notifications.removeWhere((n) => n['id'] == nId);
          // 팔로우 수락 후, 상대방에 대한 내 팔로우 버튼 상태 업데이트
          _followButtonStatusMap[uId] = result.myFollowStatus;
        });
      }
    } catch (e) {
      // 에러 처리
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _handleRejectFollow(int nId, int reqId, int uId) async {
    setState(() => _processingId = nId);
    try {
      await NotificationApi.rejectFollowRequest(reqId, uId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('팔로우 요청을 거절했습니다.')));
        setState(() => notifications.removeWhere((n) => n['id'] == nId));
      }
    } catch (e) {
      // 에러 처리
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _handleFollowAction(int userId, FollowButtonStatus currentStatus, {int? requestId}) async {
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
        // 요청 취소를 위해 requestId가 필요. API 구조상 userId만으로도 가능할 수 있음
          result = await NotificationApi.cancelFollowRequest(userId, requestId ?? 0);
          break;
      }
      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        // API 결과에 따라 버튼 상태를 정확하게 업데이트
        setState(() => _followButtonStatusMap[userId] = result.buttonState);
      }
    } catch (e) {
      // 에러 처리
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              padding: EdgeInsets.fromLTRB(scaleWidth(20), scaleHeight(10), scaleWidth(20), scaleHeight(10)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabTexts.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(right: scaleWidth(6)),
                      child: _buildTabButton(index),
                    );
                  }),
                ),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.pri400));
    }
    if (notifications.isEmpty) {
      return Center(child: Text("받은 알림이 없어요", style: AppFonts.suite.b1_sb(context).copyWith(color: AppColors.gray400)));
    }
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.pri400,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20), vertical: scaleHeight(10)),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(notifications[index]);
        },
      ),
    );
  }

  // --- UI 위젯 빌더 ---

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final int nId = notification['id'];
    final int? reqId = notification['requestId'];
    final int? uId = notification['userId'];
    final String actionButtonType = notification['actionButton'] ?? '';
    final bool isProcessing = _processingId == nId || _processingId == uId;

    return Container(
      margin: EdgeInsets.only(bottom: scaleHeight(16)),
      padding: EdgeInsets.all(scaleWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaleWidth(12)),
        border: Border.all(color: AppColors.gray50),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProfileImage(notification['type'], notification['userProfileImage']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification['userNickname'] ?? '알 수 없는 사용자', style: AppFonts.suite.b3_b(context)),
                    const SizedBox(height: 4),
                    Text(notification['timeAgo'] ?? '', style: AppFonts.suite.c2_m(context).copyWith(color: AppColors.gray400)),
                  ],
                ),
              ),
              _buildTrailingWidget(notification),
            ],
          ),
          const SizedBox(height: 12),
          Text(notification['content'] ?? '알림 내용이 없습니다.', style: AppFonts.suite.b3_m(context).copyWith(color: AppColors.gray700)),

          if (actionButtonType == 'ACCEPT_REJECT' && reqId != null && uId != null)
            _buildAcceptRejectButtons(nId, reqId, uId, isProcessing),

          if (actionButtonType == 'FOLLOW_BUTTON' && uId != null)
            _buildFollowButton(uId, reqId, isProcessing),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String type, String? imageUrl) {
    bool isSystem = type == 'SYSTEM';
    return CircleAvatar(
      radius: scaleWidth(21),
      backgroundColor: AppColors.gray50,
      backgroundImage: (imageUrl != null && !isSystem) ? NetworkImage(imageUrl) : null,
      child: isSystem
          ? SvgPicture.asset(AppImages.dodada, width: scaleWidth(30), color: AppColors.gray300)
          : (imageUrl == null ? Icon(Icons.person, color: AppColors.gray400, size: scaleWidth(22)) : null),
    );
  }

  Widget _buildTrailingWidget(Map<String, dynamic> notification) {
    if (notification['badge'] == 'NEW') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(8), vertical: scaleHeight(4)),
        decoration: BoxDecoration(color: AppColors.pri400, borderRadius: BorderRadius.circular(scaleWidth(8))),
        child: Text('NEW', style: AppFonts.suite.c3_sb(context).copyWith(color: Colors.white)),
      );
    }
    if (notification['type'] == 'REACTION') {
      return Container(
        width: scaleWidth(36),
        height: scaleWidth(36),
        decoration: const BoxDecoration(color: Color(0xFFFCB4BA), shape: BoxShape.circle),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAcceptRejectButtons(int nId, int reqId, int uId, bool isProcessing) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Expanded(child: ElevatedButton(onPressed: isProcessing ? null : () => _handleAcceptFollow(nId, reqId, uId), style: ElevatedButton.styleFrom(backgroundColor: AppColors.pri400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleWidth(8)))), child: isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('수락', style: AppFonts.suite.b3_b(context).copyWith(color: Colors.white)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: isProcessing ? null : () => _handleRejectFollow(nId, reqId, uId), style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.gray300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleWidth(8)))), child: Text('거절', style: AppFonts.suite.b3_b(context).copyWith(color: AppColors.gray700)))),
        ],
      ),
    );
  }

  /// 3가지 상태(팔로우, 팔로잉, 요청됨)를 모두 처리하는 지능형 버튼
  Widget _buildFollowButton(int userId, int? requestId, bool isProcessing) {
    final status = _followButtonStatusMap[userId] ?? FollowButtonStatus.canFollow;

    String text;
    Color buttonColor, textColor;
    bool isOutlined = false;

    switch (status) {
      case FollowButtonStatus.canFollow:
        text = '팔로우';
        buttonColor = AppColors.gray600;
        textColor = Colors.white;
        break;
      case FollowButtonStatus.following:
        text = '팔로잉';
        buttonColor = AppColors.gray50;
        textColor = AppColors.gray600;
        isOutlined = true;
        break;
      case FollowButtonStatus.requestSent:
        text = '요청됨';
        buttonColor = AppColors.gray50;
        textColor = AppColors.gray600;
        isOutlined = true;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: SizedBox(
        width: double.infinity,
        height: scaleHeight(40),
        child: isOutlined
            ? OutlinedButton(
          onPressed: isProcessing ? null : () => _handleFollowAction(userId, status, requestId: requestId),
          style: OutlinedButton.styleFrom(
            backgroundColor: buttonColor,
            side: BorderSide(color: AppColors.gray100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(text, style: AppFonts.suite.b3_b(context).copyWith(color: textColor)),
        )
            : ElevatedButton(
          onPressed: isProcessing ? null : () => _handleFollowAction(userId, status, requestId: requestId),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(text, style: AppFonts.suite.b3_b(context).copyWith(color: textColor)),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index) {
    final bool isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleWidth(14), vertical: scaleHeight(10)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray600 : AppColors.gray30,
          borderRadius: BorderRadius.circular(68),
        ),
        child: Center(
          child: Text(
            tabTexts[index],
            style: isSelected
                ? AppFonts.suite.c1_b(context).copyWith(color: Colors.white)
                : AppFonts.suite.c1_m(context).copyWith(color: AppColors.gray500),
          ),
        ),
      ),
    );
  }
}