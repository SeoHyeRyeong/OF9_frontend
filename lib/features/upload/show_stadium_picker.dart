import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';

/// 구장 선택용 BottomSheet
Future<String?> showStadiumPicker({
  required BuildContext context,
  required String title,      // "구장"
  required List<Map<String, dynamic>> stadiums,
  String? initial,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) {
      return _StadiumPickerModal(
        title: title,
        stadiums: stadiums,
        initial: initial,
      );
    },
  );
}

class _StadiumPickerModal extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> stadiums;
  final String? initial;

  const _StadiumPickerModal({
    required this.title,
    required this.stadiums,
    this.initial,
  });

  @override
  _StadiumPickerModalState createState() => _StadiumPickerModalState();
}

class _StadiumPickerModalState extends State<_StadiumPickerModal> {
  String? selected;
  bool isInputMode = false;
  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selected = widget.initial;

    // 초기값이 "직접 작성하기"로 입력된 값인지 확인
    if (widget.initial != null && !_isPreDefinedStadium(widget.initial!)) {
      // 미리 정의된 구장이 아니면 직접 입력 모드로 설정
      isInputMode = true;
      selected = '직접 작성하기';
      inputController.text = widget.initial!;
    }
  }

  // 미리 정의된 구장인지 확인하는 함수
  bool _isPreDefinedStadium(String stadiumName) {
    return widget.stadiums.any((stadium) => stadium['name'] == stadiumName);
  }

  @override
  void dispose() {
    inputController.dispose();
    inputFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInset = MediaQuery.of(context).viewInsets.bottom;
    final adjustedInset = viewInset * 0.5; // 원래대로 복원
    final screenHeight = MediaQuery.of(context).size.height;
    const baseH = 800;
    final sheetHeight = screenHeight * (537 / baseH);

    return Padding(
      padding: EdgeInsets.only(bottom: adjustedInset),
      child: Container(
        width: 360.w,
        height: sheetHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Stack(
          children: [
            // 헤더 영역
            Positioned(
              top: 0,
              left: 0,
              width: 360.w,
              height: screenHeight * (60 / baseH),
              child: Stack(
                children: [
                  Positioned(
                    top: screenHeight * (18 / baseH),
                    left: 20.w,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        AppImages.backBlack,
                        width: 24.w,
                        height: screenHeight * (24 / baseH),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * (22 / baseH),
                    left: 158.w,
                    child: FixedText(
                      widget.title,
                      style: AppFonts.b2_b(context).copyWith(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            // 리스트 영역
            Positioned(
              top: screenHeight * (60 / baseH),
              left: 0,
              right: 0,
              height: (isInputMode && viewInset > 0) ? screenHeight * (290 / baseH) : screenHeight * (365 / baseH), // 입력 모드이면서 키보드가 보일 때만 4개 항목
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(0, screenHeight * (12 / baseH), 0, screenHeight * (12 / baseH)),
                  itemCount: widget.stadiums.length,
                  separatorBuilder: (context, index) => SizedBox(height: screenHeight * (8 / baseH)),
                  itemBuilder: (context, idx) {
                    final stadium = widget.stadiums[idx]['name']! as String;
                    final imagesData = widget.stadiums[idx]['images'];
                    final images = imagesData != null ? List<String>.from(imagesData) : <String>[];
                    final isSel = stadium == selected;
                    final hasImages = images.isNotEmpty;
                    final isDirectInput = stadium == '직접 작성하기';

                    // 직접 작성하기가 선택되고 입력 모드인 경우
                    if (isDirectInput && isSel && isInputMode) {
                      return Container(
                        key: ValueKey('input_field'),
                        width: 320.w,
                        height: screenHeight * (64 / baseH),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.pri300,
                            width: 2,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Center(
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                            child: TextField(
                              controller: inputController,
                              focusNode: inputFocusNode,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppFonts.b3_sb_long(context),
                              textAlign: TextAlign.left,
                              onChanged: (value) {
                                setState(() {}); // 완료 버튼 활성화 상태 업데이트
                              },
                            ),
                          ),
                        ),
                      );
                    }

                    // 일반 구장 선택 항목
                    return GestureDetector(
                      key: ValueKey('stadium_$idx'),
                      onTap: () {
                        if (isDirectInput) {
                          // 직접 작성하기 선택 시 입력 모드로 전환
                          setState(() {
                            selected = stadium;
                            isInputMode = true;
                            inputController.clear();
                          });
                          // 리스트 맨 아래로 스크롤 (직접 작성하기가 보이도록)
                          Future.delayed(Duration(milliseconds: 100), () {
                            if (mounted && scrollController.hasClients) {
                              scrollController.animateTo(
                                scrollController.position.maxScrollExtent,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                          // 포커스 요청
                          Future.delayed(Duration(milliseconds: 500), () {
                            if (mounted) {
                              inputFocusNode.requestFocus();
                            }
                          });
                        } else {
                          // 일반 구장 선택
                          setState(() {
                            selected = selected == stadium ? null : stadium;
                            isInputMode = false;
                          });
                          inputFocusNode.unfocus();
                        }
                      },
                      child: Container(
                        width: 320.w,
                        height: screenHeight * (64 / baseH),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isSel && !isInputMode ? AppColors.pri300: Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            // 이미지가 있는 경우만 표시
                            if (hasImages) ...[
                              if (images.length == 1)
                                Image.asset(
                                  images[0],
                                  width: screenHeight * (35 / baseH),
                                  height: screenHeight * (35 / baseH),
                                  fit: BoxFit.contain,
                                )
                              else
                                Row(
                                  children: [
                                    for (int i = 0; i < images.length; i++) ...[
                                      Image.asset(
                                        images[i],
                                        width: screenHeight * (30 / baseH),
                                        height: screenHeight * (30 / baseH),
                                        fit: BoxFit.contain,
                                      ),
                                      if (i < images.length - 1) SizedBox(width: 5.w),
                                    ],
                                  ],
                                ),
                              SizedBox(width: 8.w),
                            ],
                            // 텍스트 표시
                            Expanded(
                              child: FixedText(
                                stadium,
                                style: AppFonts.b3_sb(context).copyWith(
                                  color: hasImages ? AppColors.gray900 : AppColors.pri300,
                                ),
                              ),
                            ),
                            // 이미지가 없는 경우 펜 아이콘 추가
                            if (!hasImages)
                              Icon(
                                Icons.edit,
                                color: AppColors.pri300,
                                size: 20.w,
                              ),
                            // 체크 아이콘 (입력 모드가 아닐 때만)
                            if (isSel && !isInputMode)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.pri300,
                                size: 24.w,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 완료 버튼 영역
            Positioned(
              top: screenHeight * (425 / baseH),
              left: 0,
              right: 0,
              height: screenHeight * (88 / baseH),
              child: Container(
                width: 360.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gray20,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20.w, screenHeight * (24 / baseH), 20.w, screenHeight * (10 / baseH)),
                child: SizedBox(
                  width: 320.w,
                  height: screenHeight * (54 / baseH),
                  child: ElevatedButton(
                    onPressed: (selected != null && (!isInputMode || inputController.text.trim().isNotEmpty))
                        ? () {
                      if (isInputMode) {
                        // 입력 모드일 때는 입력된 텍스트 반환
                        final inputText = inputController.text.trim();
                        Navigator.pop(context, inputText);
                      } else {
                        // 일반 선택 모드일 때는 선택된 구장 반환
                        Navigator.pop(context, selected);
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (selected != null && (!isInputMode || inputController.text.trim().isNotEmpty))
                          ? AppColors.gray700
                          : AppColors.gray200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      elevation: 0,
                    ),
                    child: FixedText(
                      '완료',
                      style: AppFonts.b2_b(context).copyWith(
                        color: AppColors.gray20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}