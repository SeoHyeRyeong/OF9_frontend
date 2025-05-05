import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';

class TicketInfoFormScreen extends StatefulWidget {
  final String? homeTeam;
  final String? awayTeam;
  final String? dateTime;
  final String? seatInfo;
  final String recognizedText; // OCR 원본 텍스트 추가

  const TicketInfoFormScreen({
    Key? key,
    this.homeTeam,
    this.awayTeam,
    this.dateTime,
    this.seatInfo,
    required this.recognizedText, // required로 받음
  }) : super(key: key);

  @override
  State<TicketInfoFormScreen> createState() => _TicketInfoFormScreenState();
}

class _TicketInfoFormScreenState extends State<TicketInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _homeController;
  late TextEditingController _awayController;
  late TextEditingController _dateTimeController;
  late TextEditingController _seatController;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(text: widget.homeTeam ?? '');
    _awayController = TextEditingController(text: widget.awayTeam ?? '');
    _dateTimeController = TextEditingController(text: widget.dateTime ?? '');
    _seatController = TextEditingController(text: widget.seatInfo ?? '');
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    _dateTimeController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray20,
      appBar: AppBar(
        title: Text('티켓 정보 확인', style: AppFonts.b2_b.copyWith(color: AppColors.gray900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 16.h),

              // OCR 인식된 텍스트 표시
              Text('인식된 원본 텍스트', style: AppFonts.b3_sb.copyWith(color: AppColors.gray700)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  widget.recognizedText,
                  style: AppFonts.b3_m.copyWith(color: AppColors.gray800),
                ),
              ),

              SizedBox(height: 24.h),
              _buildLabel('홈 구단 *'),
              _buildTextField(_homeController, '홈 구단 입력'),

              SizedBox(height: 16.h),
              _buildLabel('원정 구단 *'),
              _buildTextField(_awayController, '원정 구단 입력'),

              SizedBox(height: 16.h),
              _buildLabel('일시 *'),
              _buildTextField(_dateTimeController, '예: 2025-04-15 14:00'),

              SizedBox(height: 16.h),
              _buildLabel('좌석 *'),
              _buildTextField(_seatController, '좌석 정보 입력'),

              SizedBox(height: 40.h),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: 저장 로직
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장 완료')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pri500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('완료', style: AppFonts.b2_b.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppFonts.b3_sb.copyWith(color: AppColors.gray700));
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.gray50,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? '필수 입력입니다' : null,
    );
  }
}
