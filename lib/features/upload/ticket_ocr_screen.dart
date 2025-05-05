import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'ticket_info_extractor.dart'; // 티켓 정보 추출기 import
import 'ticket_info_form_screen.dart'; // 티켓 정보 입력폼 import

class TicketOcrScreen extends StatefulWidget {
  const TicketOcrScreen({Key? key}) : super(key: key);

  @override
  State<TicketOcrScreen> createState() => _TicketOcrScreenState();
}

class _TicketOcrScreenState extends State<TicketOcrScreen> {
  File? _pickedImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  //final textRecognizer = TextRecognizer();
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);


  /// 카메라 권한 요청
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('카메라 권한이 필요합니다'),
          content: const Text('티켓 촬영을 위해 카메라 권한이 필요합니다.\n설정 화면으로 이동할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        ),
      );
      return false;
    } else {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
  }

  /// 사진 촬영 후 OCR + 추출 + 화면 이동
  Future<void> _pickImageAndRecognizeText() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _pickedImage = File(image.path);
      _isLoading = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      final extracted = TicketInfoExtractor.extractTicketInfo(recognizedText.text);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketInfoFormScreen(
            homeTeam: extracted['homeTeam'],
            awayTeam: extracted['awayTeam'],
            dateTime: extracted['dateTime'],
            seatInfo: extracted['seatInfo'],
            recognizedText: recognizedText.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR 분석 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray20,
      appBar: AppBar(
        title: Text('티켓 인식', style: AppFonts.b2_b.copyWith(color: AppColors.gray900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _pickedImage != null
                ? Image.file(_pickedImage!, height: 300.h, fit: BoxFit.cover)
                : Container(
              height: 300.h,
              color: AppColors.gray100,
              child: Center(
                child: Text(
                  '티켓 사진을 찍어주세요',
                  style: AppFonts.b3_m.copyWith(color: AppColors.gray500),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _pickImageAndRecognizeText,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pri500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text('티켓 스캔하기', style: AppFonts.b2_b.copyWith(color: Colors.white)),
            ),
            SizedBox(height: 24.h),
            if (_isLoading)
              const CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}
