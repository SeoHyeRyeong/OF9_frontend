import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/features/mypage/settings_screen.dart';
import 'package:frontend/features/upload/show_team_picker.dart';

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

  // 원본 정보 저장 (변경 감지용)
  String originalNickname = "";
  String originalFavTeam = "";

  // 닉네임 입력 관련
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  int _currentLength = 0;
  final int _maxLength = 15;
  bool _isNicknameAvailable = true;
  Timer? _debounceTimer;

  final List<Map<String, String>> teamListWithImages = [
    {'name': '두산 베어스', 'image': AppImages.bears},
    {'name': '롯데 자이언츠', 'image': AppImages.giants},
    {'name': '삼성 라이온즈', 'image': AppImages.lions},
    {'name': '키움 히어로즈', 'image': AppImages.kiwoom},
    {'name': '한화 이글스', 'image': AppImages.eagles},
    {'name': 'KIA 타이거즈', 'image': AppImages.tigers},
    {'name': 'KT WIZ', 'image': AppImages.ktwiz},
    {'name': 'LG 트윈스', 'image': AppImages.twins},
    {'name': 'NC 다이노스', 'image': AppImages.dinos},
    {'name': 'SSG 랜더스', 'image': AppImages.landers},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _nicknameController.addListener(_updateCharacterCount);
    _nicknameFocusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

    // 디바운스 타이머 취소 후 새로 설정
    _debounceTimer?.cancel();

    final currentNickname = _nicknameController.text.trim();

    // 원래 닉네임과 같거나 비어있으면 중복 확인 안함
    if (currentNickname.isEmpty || currentNickname == originalNickname.trim()) {
      setState(() {
        _isNicknameAvailable = true;
      });
    } else {
      // 중복 확인
      _debounceTimer = Timer(Duration(milliseconds: 300), () {
        _checkNicknameAvailability();
      });
    }
  }

  void _updateFocusState() {
    setState(() {});
  }

  ///닉네임이 비어있는지 확인
  bool _isNicknameEmpty() {
    return _nicknameController.text.trim().isEmpty;
  }

  ///닉네임에 오류가 있는지 확인 (로딩 중이면 에러 아님)
  bool _hasNicknameError() {
    if (isLoading) return false; // 로딩 중에는 에러 표시 안함
    return _isNicknameEmpty() || !_isNicknameAvailable;
  }

  ///닉네임 중복 확인
  Future<void> _checkNicknameAvailability() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || nickname == originalNickname.trim()) {
      setState(() {
        _isNicknameAvailable = true;
      });
      return;
    }

    try {
      print('🔍 닉네임 중복 확인: $nickname');
      final response = await UserApi.checkNickname(nickname);
      print('📥 중복 확인 응답: $response');

      setState(() {
        _isNicknameAvailable = response['data']['available'] ?? false;
      });

      print('✅ 닉네임 사용 가능: $_isNicknameAvailable');
    } catch (e) {
      print('❌ 닉네임 중복 확인 실패: $e');
      setState(() {
        _isNicknameAvailable = true;
      });
    }
  }

  ///완료 버튼 활성화 조건 확인
  bool _canComplete() {
    return !_isNicknameEmpty() && _isNicknameAvailable && _hasChanges();
  }

  ///정보가 변경되었는지 확인
  bool _hasChanges() {
    return _nicknameController.text != originalNickname ||
        favTeam != originalFavTeam;
  }

  ///사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final response = await UserApi.getMyProfile();
      final userInfo = response['data'];
      setState(() {
        nickname = userInfo['nickname'] ?? '알 수 없음';
        favTeam = userInfo['favTeam'] ?? '정보 불러오기 실패';
        profileImageUrl = userInfo['profileImageUrl'];

        // 원본 정보 저장
        originalNickname = nickname;
        originalFavTeam = favTeam;

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
        originalNickname = nickname;
        originalFavTeam = favTeam;
        isLoading = false;
      });
    }
  }

  ///최애구단 선택
  Future<void> _selectFavTeam() async {
    final selectedTeam = await showTeamPicker(
      context: context,
      title: "최애 구단",
      teams: teamListWithImages,
      initial: favTeam == "정보 불러오기 실패" ? null : favTeam,
    );

    if (selectedTeam != null) {
      setState(() {
        favTeam = selectedTeam;
      });
      print('선택된 팀: $selectedTeam');
    }
  }

  ///완료 버튼 클릭 시 실행될 함수
  Future<void> _onCompletePressed() async {
    if (!_canComplete()) {
      return;
    }

    try {
      // 프로필 정보 업데이트 API 호출 (이미지 제외)
      await UserApi.updateMyProfile(
        nickname: _nicknameController.text,
        profileImageUrl: null,
        favTeam: favTeam == "정보 불러오기 실패" ? null : favTeam,
      );

      print('프로필 수정 성공');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필이 성공적으로 수정되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation1, animation2) => const SettingsScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      print('프로필 수정 실패: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 수정에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canComplete = _canComplete();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation1, animation2) => const SettingsScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;

              return Column(
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
                            padding: EdgeInsets.only(
                              top: screenHeight * 0.0225,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (context, animation1, animation2) =>
                                            const SettingsScreen(),
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
                              padding: EdgeInsets.only(
                                top: screenHeight * 0.0225,
                              ),
                              child: Center(
                                child: FixedText(
                                  "내 정보 수정",
                                  style: AppFonts.suite
                                      .b2_b(context)
                                      .copyWith(color: AppColors.gray950),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: scaleHeight(24)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: scaleHeight(22)),

                  // 프로필 이미지 영역 (수정 불가능한 표시용)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(scaleHeight(29.6)),
                      child:
                          profileImageUrl != null
                              ? Image.network(
                                profileImageUrl!,
                                width: scaleWidth(100),
                                height: scaleHeight(100),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => SvgPicture.asset(
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
                  ),

                  SizedBox(height: scaleHeight(40)),

                  // 닉네임 라벨
                  Padding(
                    padding: EdgeInsets.only(left: scaleWidth(20)),
                    child: Row(
                      children: [
                        FixedText(
                          "닉네임",
                          style: AppFonts.suite
                              .b3_sb(context)
                              .copyWith(color: AppColors.gray600),
                        ),
                        SizedBox(width: scaleWidth(2)),
                        FixedText(
                          "*",
                          style: AppFonts.suite
                              .c1_b(context)
                              .copyWith(color: AppColors.pri200),
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
                            border:
                                _hasNicknameError()
                                    ? Border.all(
                                      color: AppColors.error,
                                      width: 1,
                                    )
                                    : null,
                          ),
                          child: TextField(
                            controller: _nicknameController,
                            focusNode: _nicknameFocusNode,
                            maxLength: _maxLength,
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
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
                            style: AppFonts.pretendard
                                .b3_r_long(context)
                                .copyWith(color: AppColors.black),
                          ),
                        ),

                        SizedBox(height: scaleHeight(8)),

                        // 에러 메시지와 글자수 카운터 같은 줄
                        Container(
                          width: scaleWidth(320),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 에러 메시지 (좌측)
                              _hasNicknameError()
                                  ? FixedText(
                                    _isNicknameEmpty()
                                        ? '닉네임을 작성해 주세요.'
                                        : '이미 등록된 닉네임이에요.',
                                    style: AppFonts.pretendard
                                        .c1_m(context)
                                        .copyWith(color: AppColors.error),
                                  )
                                  : SizedBox.shrink(),
                              // 글자수 카운터 (우측)
                              _hasNicknameError()
                                  ? FixedText(
                                    '$_currentLength / $_maxLength',
                                    style: AppFonts.pretendard
                                        .c1_m(context)
                                        .copyWith(color: AppColors.error),
                                  )
                                  : FixedText(
                                    '$_currentLength / $_maxLength',
                                    style: AppFonts.suite
                                        .c1_m(context)
                                        .copyWith(color: AppColors.pri900),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: scaleHeight(24)),

                  // 최애 구단 라벨
                  Padding(
                    padding: EdgeInsets.only(left: scaleWidth(20)),
                    child: Row(
                      children: [
                        FixedText(
                          "최애 구단",
                          style: AppFonts.suite
                              .b3_sb(context)
                              .copyWith(color: AppColors.gray600),
                        ),
                        SizedBox(width: scaleWidth(2)),
                        FixedText(
                          "*",
                          style: AppFonts.suite
                              .c1_b(context)
                              .copyWith(color: AppColors.pri200),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),

                  // 최애구단 선택 필드
                  Padding(
                    padding: EdgeInsets.only(left: scaleWidth(20)),
                    child: GestureDetector(
                      onTap: _selectFavTeam,
                      child: Container(
                        width: scaleWidth(320),
                        height: scaleHeight(54),
                        decoration: BoxDecoration(
                          color: AppColors.gray30,
                          borderRadius: BorderRadius.circular(scaleWidth(8)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: scaleWidth(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: FixedText(
                                  favTeam == "정보 불러오기 실패"
                                      ? "최애 구단을 선택해주세요"
                                      : favTeam,
                                  style: AppFonts.pretendard
                                      .b3_r_long(context)
                                      .copyWith(
                                        color:
                                            favTeam == "정보 불러오기 실패"
                                                ? AppColors.gray400
                                                : AppColors.black,
                                      ),
                                ),
                              ),
                              Transform.rotate(
                                angle: -1.5708,
                                child: SvgPicture.asset(
                                  AppImages.backBlack,
                                  width: scaleWidth(20),
                                  height: scaleHeight(20),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Spacer로 공간 확보
                  Spacer(),

                  // 완료 버튼
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: SizedBox(
                      width: scaleWidth(320),
                      height: scaleHeight(54),
                      child: ElevatedButton(
                        onPressed: canComplete ? _onCompletePressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canComplete
                                  ? AppColors.gray700
                                  : AppColors.gray200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              scaleHeight(16),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: scaleWidth(18),
                          ),
                          elevation: 0,
                        ),
                        child: FixedText(
                          '완료',
                          style: AppFonts.suite
                              .b2_b(context)
                              .copyWith(color: AppColors.gray20),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: scaleHeight(30)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
