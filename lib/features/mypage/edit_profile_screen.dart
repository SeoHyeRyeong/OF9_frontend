import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/features/mypage/settings_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 사용자 정보 상태
  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  bool isLoading = true;

  // 닉네임 입력 관련
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  int _currentLength = 0;
  final int _maxLength = 15;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _nicknameController.addListener(_updateCharacterCount);
    _nicknameFocusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_updateCharacterCount);
    _nicknameFocusNode.removeListener(_updateFocusState);
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _currentLength = _nicknameController.text.length;
    });
  }

  void _updateFocusState() {
    setState(() {});
  }

  /// 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final response = await UserApi.getMyProfile();
      final userInfo = response['data'];
      setState(() {
        nickname = userInfo['nickname'] ?? '알 수 없음';
        favTeam = userInfo['favTeam'] ?? '응원팀 없음';
        profileImageUrl = userInfo['profileImageUrl'];

        // 닉네임 컨트롤러에 현재 닉네임 설정
        _nicknameController.text = nickname;
        _currentLength = nickname.length;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 뒤로가기 영역 + 타이틀
                  SizedBox(
                    height: screenHeight * 0.075,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.0225),
                            child: GestureDetector(
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
                              child: SvgPicture.asset(
                                AppImages.backBlack,
                                width: scaleHeight(24),
                                height: scaleHeight(24),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: screenHeight * 0.0225),
                              child: Center(
                                child: FixedText(
                                  "내 정보 수정",
                                  style: AppFonts.suite.b2_b(context).copyWith(
                                    color: AppColors.gray950,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: scaleHeight(24)), //균형을 위한 공간(크게 상관x)
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: scaleHeight(20)),

                  // 프로필 이미지 영역
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 프로필 이미지
                        ClipRRect(
                          borderRadius: BorderRadius.circular(scaleHeight(29.6)),
                          child: profileImageUrl != null
                              ? Image.network(
                            profileImageUrl!,
                            width: scaleWidth(100),
                            height: scaleHeight(100),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => SvgPicture.asset(
                              AppImages.profile,
                              width: scaleWidth(100),
                              height: scaleHeight(100),
                              fit: BoxFit.cover,
                            ),
                          )
                              : SvgPicture.asset(
                            AppImages.profile,
                            width: scaleWidth(100),
                            height: scaleHeight(100),
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 카메라 버튼 - 프로필 이미지 기준 위치
                        Positioned(
                          left: scaleWidth(78),
                          top: scaleHeight(80),
                          child: GestureDetector(
                            onTap: () {
                              // 프로필 사진 변경 로직 추가
                              print('프로필 사진 변경 버튼 클릭');
                            },
                            child: SvgPicture.asset(
                              AppImages.btn_camera,
                              width: scaleWidth(24),
                              height: scaleHeight(24),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: scaleHeight(36)),

                  // 닉네임 라벨
                  Padding(
                    padding: EdgeInsets.only(left: scaleWidth(20)),
                    child: Row(
                      children: [
                        FixedText(
                          "닉네임",
                          style: AppFonts.suite.b3_sb(context).copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(width: scaleWidth(2)),
                        FixedText(
                          "*",
                          style: AppFonts.suite.c1_b(context).copyWith(
                            color: AppColors.pri200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),

                  // 닉네임 입력 필드
                  Padding(
                    padding: EdgeInsets.only(left: scaleWidth(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: scaleWidth(320),
                          height: scaleHeight(54),
                          decoration: BoxDecoration(
                            color: AppColors.gray30,
                            borderRadius: BorderRadius.circular(scaleWidth(8)),
                          ),
                          child: TextField(
                            controller: _nicknameController,
                            focusNode: _nicknameFocusNode,
                            maxLength: _maxLength,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            decoration: InputDecoration(
                              isCollapsed: true,
                              contentPadding: EdgeInsets.only(
                                left: scaleWidth(16),
                                top: scaleHeight(15),
                                bottom: scaleHeight(15),
                              ),
                              border: InputBorder.none,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            style: AppFonts.pretendard.b3_sb_long(context).copyWith(
                              color: AppColors.black,
                            ),
                          ),
                        ),

                        SizedBox(height: scaleHeight(8)),

                        // 글자수 카운터
                        Container(
                          width: scaleWidth(320),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FixedText(
                                '$_currentLength',
                                style: AppFonts.suite.c1_m(context).copyWith(
                                  color: AppColors.pri900,
                                ),
                              ),
                              FixedText(
                                ' / $_maxLength',
                                style: AppFonts.suite.c1_m(context).copyWith(
                                  color: AppColors.gray300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}