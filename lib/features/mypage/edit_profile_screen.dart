import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/api/user_api.dart';
import 'package:frontend/api/record_api.dart';
import 'package:frontend/features/mypage/settings_screen.dart';
import 'package:frontend/features/upload/show_team_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/components/custom_action_sheet.dart';

class EditProfileScreen extends StatefulWidget {
  final String? previousRoute; // 이전 화면 구분용 파라미터 추가

  const EditProfileScreen({Key? key, this.previousRoute}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 사용자 정보 상태
  String nickname = "로딩중...";
  String favTeam = "로딩중...";
  String? profileImageUrl;
  bool isLoading = true;

  // 이미지 변경 관련 상태
  final ImagePicker _picker = ImagePicker();
  XFile? _newProfileImageFile;
  bool _isProfileImageDeleted = false;

  // 원본 정보 저장 (변경 감지용)
  String originalNickname = "";
  String originalFavTeam = "";
  String? originalProfileImageUrl;

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

    _debounceTimer?.cancel();
    final currentNickname = _nicknameController.text.trim();
    if (currentNickname.isEmpty || currentNickname == originalNickname.trim()) {
      setState(() {
        _isNicknameAvailable = true;
      });
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _checkNicknameAvailability();
      });
    }
  }

  void _updateFocusState() {
    setState(() {});
  }

  bool _isNicknameEmpty() {
    return _nicknameController.text.trim().isEmpty;
  }

  bool _hasNicknameError() {
    if (isLoading) return false;
    return _isNicknameEmpty() || !_isNicknameAvailable;
  }

  Future<void> _checkNicknameAvailability() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || nickname == originalNickname.trim()) {
      setState(() {
        _isNicknameAvailable = true;
      });
      return;
    }
    try {
      final response = await UserApi.checkNickname(nickname);
      setState(() {
        _isNicknameAvailable = response['data']['available'] ?? false;
      });
    } catch (e) {
      print('❌ 닉네임 중복 확인 실패: $e');
      setState(() {
        _isNicknameAvailable = true;
      });
    }
  }

  bool _canComplete() {
    return !_isNicknameEmpty() && _isNicknameAvailable && _hasChanges();
  }

  bool _hasChanges() {
    return _nicknameController.text.trim() != originalNickname.trim() ||
        favTeam != originalFavTeam ||
        _newProfileImageFile != null ||
        _isProfileImageDeleted;
  }

  Future<void> _loadUserInfo() async {
    try {
      final response = await UserApi.getMyProfile();
      final userInfo = response['data'];
      setState(() {
        nickname = userInfo['nickname'] ?? '알 수 없음';
        favTeam = userInfo['favTeam'] ?? '정보 불러오기 실패';
        profileImageUrl = userInfo['profileImageUrl'];
        originalNickname = nickname;
        originalFavTeam = favTeam;
        originalProfileImageUrl = profileImageUrl;
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
    }
  }

  void _showImageSourceActionSheet() {
    showCustomActionSheet(
      context: context,
      options: [
        ActionSheetOption(
          text: '앨범에서 사진 선택',
          textColor: AppColors.gray950,
          onTap: () {
            Navigator.pop(context);
            _pickImageFromGallery();
          },
        ),
        ActionSheetOption(
          text: '현재 사진 삭제',
          textColor: AppColors.error,
          onTap: () {
            Navigator.pop(context);
            _deleteProfileImage();
          },
        ),
      ],
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final fileSize = await File(pickedFile.path).length();
        print('📷 선택된 이미지 크기: ${(fileSize / 1024).toStringAsFixed(2)} KB');

        setState(() {
          _newProfileImageFile = pickedFile;
          _isProfileImageDeleted = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 접근 권한이 필요합니다.')));
    }
  }

  void _deleteProfileImage() {
    setState(() {
      _newProfileImageFile = null;
      profileImageUrl = null;
      _isProfileImageDeleted = true;
    });
  }

  Future<String?> _uploadProfileImageToS3(XFile imageFile) async {
    try {
      print('📤 프로필 이미지 S3 업로드 시작');

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final urlData = await RecordApi.getPresignedUrl(
        domain: 'profiles',
        fileName: fileName,
      );

      await RecordApi.uploadFileToS3(
        presignedUrl: urlData['presignedUrl']!,
        file: File(imageFile.path),
      );

      final finalUrl = urlData['finalUrl']!;
      print('✅ 프로필 이미지 업로드 성공: $finalUrl');
      return finalUrl;

    } catch (e) {
      print('❌ 프로필 이미지 S3 업로드 실패: $e');
      return null;
    }
  }

  Future<void> _onCompletePressed() async {
    if (!_canComplete()) return;
    setState(() => isLoading = true);

    try {
      String? updatedImageUrl;

      if (_newProfileImageFile != null) {
        updatedImageUrl = await _uploadProfileImageToS3(_newProfileImageFile!);
        if (updatedImageUrl == null) throw Exception('이미지 업로드 실패');
      } else if (_isProfileImageDeleted) {
        updatedImageUrl = null;
      }

      await UserApi.updateMyProfile(
        nickname: _nicknameController.text.trim(),
        favTeam: favTeam == "정보 불러오기 실패" ? null : favTeam,
        profileImageUrl: (_newProfileImageFile != null || _isProfileImageDeleted)
            ? updatedImageUrl
            : originalProfileImageUrl,
      );

      if (mounted) {
        // 이전 화면에 따라 분기 처리
        if (widget.previousRoute == 'mypage') {
          // 마이페이지에서 온 경우
          Navigator.pop(context); // 단순히 뒤로가기
        } else {
          // 설정 화면에서 온 경우 (기본값)
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SettingsScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('프로필 수정에 실패했습니다.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 뒤로가기 처리도 동일하게 분기
  void _goBackToPreviousScreen() {
    if (widget.previousRoute == 'mypage') {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const SettingsScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
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
          _goBackToPreviousScreen();
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
                  Container(
                    width: double.infinity,
                    height: scaleHeight(60),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _goBackToPreviousScreen,
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
                                "내 정보 수정",
                                style: AppFonts.suite.b2_b(context).copyWith(color: AppColors.gray950),
                              ),
                            ),
                          ),
                          SizedBox(width: scaleHeight(24)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: scaleHeight(22)),

                  // 프로필 이미지 영역
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(scaleHeight(29.59)),
                            child: SizedBox(
                              width: scaleWidth(100),
                              height: scaleHeight(100),
                              child: _buildProfileImage(),
                            ),
                          ),
                          // 카메라 아이콘 오버레이 (우측 하단)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: SvgPicture.asset(
                              AppImages.btn_camera,
                              width: scaleWidth(24),
                              height: scaleHeight(24),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: scaleHeight(40)),

                  // 닉네임 라벨
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: Row(
                      children: [
                        FixedText(
                          "닉네임",
                          style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray600),
                        ),
                        SizedBox(width: scaleWidth(2)),
                        FixedText(
                          "*",
                          style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri200),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),

                  // 닉네임 입력 필드
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: scaleHeight(54),
                          decoration: BoxDecoration(
                            color: AppColors.gray30,
                            borderRadius: BorderRadius.circular(scaleWidth(8)),
                            border: _hasNicknameError()
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
                            buildCounter: (
                                context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) =>
                            null,
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
                            style: AppFonts.pretendard.b3_r_long(context).copyWith(color: AppColors.black),
                          ),
                        ),
                        SizedBox(height: scaleHeight(8)),
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _hasNicknameError()
                                  ? FixedText(
                                _isNicknameEmpty()
                                    ? '닉네임을 작성해 주세요.'
                                    : '이미 등록된 닉네임이에요.',
                                style: AppFonts.pretendard.c1_m(context).copyWith(color: AppColors.error),
                              )
                                  : const SizedBox.shrink(),
                              _hasNicknameError()
                                  ? FixedText(
                                '$_currentLength / $_maxLength',
                                style: AppFonts.pretendard.c1_m(context).copyWith(color: AppColors.error),
                              )
                                  : FixedText(
                                '$_currentLength / $_maxLength',
                                style: AppFonts.suite.c1_m(context).copyWith(color: AppColors.pri900),
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
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: Row(
                      children: [
                        FixedText(
                          "최애 구단",
                          style: AppFonts.suite.b3_sb(context).copyWith(color: AppColors.gray600),
                        ),
                        SizedBox(width: scaleWidth(2)),
                        FixedText(
                          "*",
                          style: AppFonts.suite.c1_b(context).copyWith(color: AppColors.pri200),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),

                  // 최애구단 선택 필드
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
                    child: GestureDetector(
                      onTap: _selectFavTeam,
                      child: Container(
                        width: double.infinity,
                        height: scaleHeight(54),
                        decoration: BoxDecoration(
                          color: AppColors.gray30,
                          borderRadius: BorderRadius.circular(scaleWidth(8)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleWidth(16),),
                          child: Row(
                            children: [
                              Expanded(
                                child: FixedText(
                                  favTeam == "정보 불러오기 실패"
                                      ? "최애 구단을 선택해주세요"
                                      : favTeam,
                                  style: AppFonts.pretendard.b3_r_long(context).copyWith(
                                    color: favTeam == "정보 불러오기 실패"
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

                  const Spacer(),

                  // 완료 버튼
                  Container(
                    width: double.infinity,
                    height: scaleHeight(88),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.gray20, width: 1)),
                    ),
                    padding: EdgeInsets.only(
                      top: scaleHeight(24),
                      right: scaleWidth(20),
                      bottom: scaleHeight(10),
                      left: scaleWidth(20),
                    ),
                    child: ElevatedButton(
                      onPressed: canComplete ? _onCompletePressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canComplete
                            ? AppColors.gray700
                            : AppColors.gray200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(scaleHeight(16)),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: Center(
                        child: FixedText(
                          '완료',
                          style: AppFonts.suite
                              .body_md_500(context)
                              .copyWith(color: AppColors.gray20),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_newProfileImageFile != null) {
      return Image.file(File(_newProfileImageFile!.path), fit: BoxFit.cover);
    }
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return Image.network(profileImageUrl!,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultProfileImage());
    }
    return _defaultProfileImage();
  }

  Widget _defaultProfileImage() {
    return SvgPicture.asset(
      AppImages.profile,
      fit: BoxFit.cover,
    );
  }
}
