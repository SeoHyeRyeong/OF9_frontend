import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/features/mypage/mypage_screen.dart';
import 'package:frontend/features/mypage/edit_profile_screen.dart';
import 'package:frontend/features/onboarding_login/login_screen.dart';
import 'package:frontend/features/onboarding_login/kakao_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/components/custom_popup_dialog.dart';
import 'package:frontend/features/mypage/block_screen.dart';
import 'dart:math' as math;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/features/mypage/follower_screen.dart';
import 'package:frontend/features/mypage/following_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 사용자 정보 상태
  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  bool isLoading = true;
  int followingCount = 0;
  int followerCount = 0;

  // 푸시 알림 토글 상태
  bool isPushNotificationOn = false;

  // 계정 공개 토글 상태
  bool isAccountPublic = false;

  final kakaoAuthService = KakaoAuthService();
  List<dynamic> blockedUsers = [];
  String appVersion = "beta"; // 초기값

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadBlockedUsers();
    _loadAppVersion();
  }

  /// 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final response = await UserApi.getMyProfile();
      final userInfo = response['data'];

      print('🔍 받은 profileImageUrl: "${userInfo['profileImageUrl']}"');
      print('🔍 타입: ${userInfo['profileImageUrl'].runtimeType}');

      setState(() {
        nickname = userInfo['nickname'] ?? '알 수 없음';
        favTeam = userInfo['favTeam'] ?? '응원팀 없음';
        profileImageUrl = userInfo['profileImageUrl'];
        isAccountPublic = !(userInfo['isPrivate'] ?? false);
        followingCount = userInfo['followingCount'] ?? 0;
        followerCount = userInfo['followerCount'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 사용자 정보 불러오기 실패: $e');
      setState(() {
        nickname = "정보 불러오기 실패";
        favTeam = "정보 불러오기 실패";
        isLoading = false;
      });
    }
  }

  /// 계정 공개/비공개 설정 변경
  Future<void> _updateAccountPrivacy(bool isPublic) async {
    try {
      print('🔄 계정 공개/비공개 설정 변경 중: ${isPublic ? '공개' : '비공개'}');

      await UserApi.updateMyProfile(
        nickname: nickname,
        favTeam: favTeam.replaceAll(' 팬', ''),
        profileImageUrl: profileImageUrl,
        isPrivate: !isPublic,
      );

      setState(() {
        isAccountPublic = isPublic;
      });

      print('✅ 계정 공개/비공개 설정 변경 성공: ${isPublic ? '공개' : '비공개'}');
    } catch (e) {
      print('❌ 계정 공개/비공개 설정 변경 실패: $e');
      setState(() {
        isAccountPublic = !isPublic;
      });
    }
  }

  /// 차단된 계정 목록
  Future<void> _loadBlockedUsers() async {
    try {
      final response = await UserApi.getBlockedUsers();
      if (response['success'] == true) {
        setState(() {
          blockedUsers = response['data'] ?? [];
        });
      }
    } catch (e) {
      print('❌ 차단된 계정 목록 불러오기 실패: $e');
    }
  }

  // 로그아웃 확인 팝업
  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: "로그아웃 하시겠어요?",
        subtitle: "재접속 시, 다시 로그인 하셔야 해요.",
        leftButtonText: "취소",
        leftButtonAction: () => Navigator.of(context).pop(),
        rightButtonText: "로그아웃",
        rightButtonAction: () async {
          Navigator.of(context).pop();
          await _performLogout();
        },
      ),
    );
  }

  // 로그아웃 처리 로직
  Future<void> _performLogout() async {
    try {
      print('🚪 로그아웃 시작');
      await UserApi.logout();
      print('1. 백엔드 로그아웃 성공');
      await kakaoAuthService.clearTokens();
      print('2. 로컬 토큰 삭제 완료');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
      print('3. 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그아웃에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //  회원 탈퇴 확인 팝업
  Future<void> _handleAccountDeletion() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CustomConfirmDialog(
          title: "정말로 탈퇴 하시겠어요?",
          subtitle: "탈퇴 시, 기록한 정보는 모두 삭제돼요.",
          leftButtonText: "취소",
          leftButtonAction: () => Navigator.of(context).pop(false),
          rightButtonText: "탈퇴",
          rightButtonAction: () => Navigator.of(context).pop(true),
        );
      },
    );

    if (confirmed != true) return;
    await _performAccountDeletion();
  }

  // 회원 탈퇴 처리 로직
  Future<void> _performAccountDeletion() async {
    try {
      print('🗑️ 회원탈퇴 시작');
      await UserApi.deleteAccount();
      print('1. 백엔드 회원탈퇴 성공');
      await kakaoAuthService.unlinkKakaoAccount();
      print('2. 카카오 연결 해제 완료');
      await kakaoAuthService.clearTokens();
      print('3. 로컬 토큰 삭제 완료');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
      print('4. 회원탈퇴 완료');
    } catch (e) {
      print('❌ 회원탈퇴 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원탈퇴에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// URL 실행 메서드
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('URL을 열 수 없습니다: $url');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크를 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('URL 실행 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크를 열 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 재사용 가능한 메뉴 버튼 위젯
  Widget _buildMenuButton(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        height: scaleHeight(60),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: scaleWidth(16)),
            child: FixedText(
              title,
              style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray900),
            ),
          ),
        ),
      ),
    );
  }

  ///버전 관리
  Future<void> _loadAppVersion() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    String nowVersion = info.version; // "1.0.0"

    setState(() {
      // 디버깅 모드 = beta, 릴리스 = 실제 버전
      appVersion = kDebugMode ? "beta" : nowVersion;
    });
  }
  Widget _buildVersionContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scaleWidth(16),
          vertical: scaleHeight(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FixedText(
              "버전 정보",
              style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray900),
            ),
            FixedText(
              appVersion,  // "beta" 또는 "1.0.0"
              style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray700),
            ),
          ],
        ),
      ),
    );
  }

  /// 커스텀 토글 스위치 위젯
  Widget _buildCustomToggle(bool isOn, VoidCallback onToggle) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: scaleWidth(42),
        height: scaleHeight(24),
        decoration: BoxDecoration(
          color: isOn ? AppColors.pri600 : AppColors.gray200,
          borderRadius: BorderRadius.circular(scaleHeight(92.31)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isOn ? 0 : scaleWidth(3),
                  right: isOn ? scaleWidth(2) : 0,
                ),
                child: Container(
                  width: scaleWidth(20),
                  height: scaleHeight(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isOn ? scaleHeight(92.31) : scaleHeight(100)),
                    boxShadow: isOn ? [
                      BoxShadow(
                        color: const Color(0x26000000),
                        blurRadius: scaleHeight(7.38),
                        offset: Offset(0, scaleHeight(2.77)),
                      ),
                      BoxShadow(
                        color: const Color(0x0A000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: scaleHeight(0.92),
                      ),
                    ] : [
                      BoxShadow(
                        color: const Color(0x26000000),
                        blurRadius: scaleHeight(8),
                        offset: Offset(0, scaleHeight(3)),
                      ),
                      BoxShadow(
                        color: const Color(0x0A000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: scaleHeight(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        backgroundColor: AppColors.gray30,
        body: SafeArea(
          child: Column(
            children: [
              // 뒤로가기 영역
              Container(
                height: scaleHeight(60),
                color: AppColors.gray30,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: scaleWidth(20)),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        AppImages.backBlack,
                        width: scaleWidth(24),
                        height: scaleHeight(24),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // 스크롤 가능한 컨텐츠
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: scaleHeight(8)),
                      // 프로필 카드
                      Padding(
                        padding: EdgeInsets.only(left: scaleWidth(20), right:scaleWidth(18),),
                        child: Container(
                          height: scaleHeight(130),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 프로필 이미지
                                Padding(
                                  padding: EdgeInsets.only(top: scaleHeight(28)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                                        ? Image.network(
                                      profileImageUrl!,
                                      width: scaleWidth(80),
                                      height: scaleHeight(80),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => SvgPicture.asset(
                                        AppImages.profile,
                                        width: scaleWidth(80),
                                        height: scaleHeight(80),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : SvgPicture.asset(
                                      AppImages.profile,
                                      width: scaleWidth(80),
                                      height: scaleHeight(80),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                SizedBox(width: scaleWidth(18)),

                                // 사용자 정보
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: scaleHeight(35)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // 닉네임
                                        isLoading
                                            ? CircularProgressIndicator()
                                            : FixedText(
                                          nickname,
                                          style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.black),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: scaleHeight(5)),
                                        // 최애구단
                                        isLoading
                                            ? Container()
                                            : FixedText(
                                          "$favTeam 팬",
                                          style: AppFonts.pretendard.caption_re_400(context).copyWith(
                                              color: AppColors.gray400,
                                              fontSize: scaleFont(10)),
                                        ),
                                        SizedBox(height: scaleHeight(7)),
                                        // 팔로잉/팔로워
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                await Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                    const FollowingScreen(targetUserId: null),
                                                    transitionDuration: Duration.zero,
                                                    reverseTransitionDuration: Duration.zero,
                                                  ),
                                                );
                                                _loadUserInfo();
                                                _loadBlockedUsers();
                                              },
                                              child: Row(
                                                children: [
                                                  FixedText(
                                                    "팔로잉",
                                                    style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray500),
                                                  ),
                                                  SizedBox(width: scaleWidth(2)),
                                                  FixedText(
                                                    "$followingCount",
                                                    style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray900),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: scaleWidth(10)),
                                            GestureDetector(
                                              onTap: () async {
                                                await Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                    const FollowerScreen(targetUserId: null),
                                                    transitionDuration: Duration.zero,
                                                    reverseTransitionDuration: Duration.zero,
                                                  ),
                                                );
                                                _loadUserInfo();
                                                _loadBlockedUsers();
                                              },
                                              child: Row(
                                                children: [
                                                  FixedText(
                                                    "팔로워",
                                                    style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray500),
                                                  ),
                                                  SizedBox(width: scaleWidth(2)),
                                                  FixedText(
                                                    "$followerCount",
                                                    style: AppFonts.pretendard.caption_md_400(context).copyWith(color: AppColors.gray900),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 수정 버튼
                                Padding(
                                  padding: EdgeInsets.only(top: scaleHeight(35)),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation1, animation2) => const EditProfileScreen(),
                                          transitionDuration: Duration.zero,
                                          reverseTransitionDuration: Duration.zero,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: scaleWidth(42),
                                      height: scaleHeight(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.gray30,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: FixedText(
                                          "수정",
                                          style: AppFonts.pretendard.caption_re_400(context).copyWith(color: AppColors.pri800),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: scaleHeight(16)),

                      // 메인 컨텐츠
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                        child: Column(
                          children: [
                            // 푸시 알림 메뉴
                            Container(
                              height: scaleHeight(56),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                child: Row(
                                  children: [
                                    FixedText(
                                      "푸시 알림",
                                      style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray900),
                                    ),
                                    const Spacer(),
                                    _buildCustomToggle(isPushNotificationOn, () {
                                      setState(() {
                                        isPushNotificationOn = !isPushNotificationOn;
                                      });
                                      print('푸시 알림 토글: ${isPushNotificationOn ? 'ON' : 'OFF'}');
                                    }),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: scaleHeight(16)),

                            // 계정 공개 / 차단된 계정 메뉴
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  // 계정 공개
                                  Container(
                                    height: scaleHeight(56),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(16)),
                                      child: Row(
                                        children: [
                                          FixedText(
                                            "계정 공개",
                                            style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray900),
                                          ),
                                          const Spacer(),
                                          _buildCustomToggle(isAccountPublic, () {
                                            _updateAccountPrivacy(!isAccountPublic);
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // 차단된 계정
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation1, animation2) => const BlockScreen(),
                                          transitionDuration: Duration.zero,
                                          reverseTransitionDuration: Duration.zero,
                                        ),
                                      );
                                      _loadBlockedUsers();
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      height: scaleHeight(52),
                                      padding: EdgeInsets.only(right: scaleWidth(16)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // 왼쪽 텍스트
                                          Padding(
                                            padding: EdgeInsets.only(left: scaleWidth(16)),
                                            child: FixedText(
                                              "차단된 계정",
                                              style: AppFonts.pretendard.body_sm_500(context).copyWith(color: AppColors.gray900),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              FixedText(
                                                '${blockedUsers.length}',
                                                style: AppFonts.pretendard.caption_md_400(context).copyWith(
                                                  color: AppColors.gray700,
                                                ),
                                              ),
                                              SizedBox(width: scaleWidth(8)),
                                              Transform.rotate(
                                                angle: -math.pi / 2,
                                                child: SvgPicture.asset(
                                                  AppImages.dropdown,
                                                  color: AppColors.gray700,
                                                  width: scaleWidth(16),
                                                  height: scaleHeight(16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: scaleHeight(16)),

                            // 기타 설정 메뉴들
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  _buildVersionContainer(),
                                  _buildMenuButton("이용 약관", () {
                                    _launchUrl('https://www.notion.so/24bf22b2f4cd8027bf3ada45e3970e9e?source=copy_link');
                                  }),
                                  _buildMenuButton("개인정보 처리방침", () {
                                    _launchUrl('https://www.notion.so/24bf22b2f4cd80f0a0efeab79c6861ae?source=copy_link');
                                  }),
                                  _buildMenuButton("로그아웃", _handleLogout),
                                  _buildMenuButton("회원 탈퇴", _handleAccountDeletion),
                                ],
                              ),
                            ),
                            SizedBox(height: scaleHeight(20)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}