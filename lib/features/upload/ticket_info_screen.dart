import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/models/game_response.dart';
import 'package:frontend/utils/ticket_info_extractor.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';

class TicketInfoScreen extends StatefulWidget {
  final String imagePath; // 이미지 경로 받기

  const TicketInfoScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<TicketInfoScreen> createState() => _TicketInfoScreenState();
}

class _TicketInfoScreenState extends State<TicketInfoScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    // 이미지 OCR 시작
    _processImage(widget.imagePath); // 이미지 처리 시작
  }

  Future<void> _processImage(String path) async {
    final inputImage = InputImage.fromFile(File(path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final recognizedText = await textRecognizer.processImage(inputImage);

    final text = recognizedText.text;
    print('📄 OCR 결과:\n$text');

    _extractTicketInfo(text);        // 날짜, 시간, 팀 추출
    await _findMatchingGame();       // DB에서 매치된 경기 조회

    setState(() {
      _selectedImage = XFile(path); // UI에 표시할 이미지 저장
    });
  }

  final Map<String, String> _teamToCorp = {
    'KIA 타이거즈': 'KIA', 'KIA': 'KIA', '두산 베어스': '두산', '두산': '두산',
    '롯데 자이언츠': '롯데', '롯데': '롯데', '삼성 라이온즈': '삼성', '삼성': '삼성',
    '키움 히어로즈': '키움', '키움': '키움', '한화 이글스': '한화', '한화': '한화',
    'KT WIZ': 'KT', 'KT': 'KT', 'LG 트윈스': 'LG', 'LG': 'LG', 'NC 다이노스': 'NC', 'NC': 'NC',
    'SSG 랜더스': 'SSG', 'SSG': 'SSG', '자이언츠': '롯데', '타이거즈': 'KIA',
    '라이온즈': '삼성', '히어로즈': '키움', '이글스': '한화', 'WIZ': 'KT',
    '트윈스': 'LG', '다이노스': 'NC', '랜더스': 'SSG', '베어스': '두산', 'Eagles': '한화'
  };

  final List<String> _teamKeywords = [
    'KIA 타이거즈', '두산 베어스', '롯데 자이언츠', '삼성 라이온즈', '키움 히어로즈', '한화 이글스',
    'KT WIZ', 'LG 트윈스', 'NC 다이노스', 'SSG 랜더스', '자이언츠', '타이거즈', '라이온즈',
    '히어로즈', '이글스', '트윈스', '다이노스', '랜더스', '베어스', 'Eagles', 'KIA', '두산',
    '롯데', '삼성', '키움', '한화', 'KT', 'LG', 'NC', 'SSG', 'WIZ'
  ];

  String? extractedAwayTeam;
  String? extractedDate;
  String? extractedTime;
  String? extractedSeat;

  List<GameResponse> matchedGames = [];

  // 📌 현재는 사용하지 않지만 추후 사진보관함에서 티켓 사진을 불러오는 기능을 위해 보존
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _selectedImage = pickedFile);

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    final text = recognizedText.text;
    print('📄 OCR 결과:\n$text');

    _extractTicketInfo(text);
    await _findMatchingGame();
    setState(() {});
  }

  void _extractTicketInfo(String text) {
    final lines = text.split('\n');
    String? awayTeam, date, time;

    final vsRegex = RegExp(r'[vV][sS]\s*(.+)');
    for (final line in lines) {
      final match = vsRegex.firstMatch(line.replaceAll(' ', ''));
      if (match != null) {
        final candidate = match.group(1)!.trim();
        for (final keyword in _teamKeywords) {
          if (candidate.contains(keyword.replaceAll(' ', ''))) {
            awayTeam = _teamToCorp[keyword];
            break;
          }
        }
        if (awayTeam != null) break;
      }
    }

    for (final line in lines) {
      date = extractDate(line) ?? date;
      time = extractTime(line) ?? time;
    }

    extractedAwayTeam = awayTeam;
    extractedDate = date;
    extractedTime = time;

    print('🔎 추출 결과 → awayTeam: $extractedAwayTeam, date: $extractedDate, time: $extractedTime');
  }

  Future<void> _findMatchingGame() async {
    matchedGames = [];
    if (extractedAwayTeam != null && extractedDate != null && extractedTime != null) {
      try {
        final game = await GameApi.searchGame(
          awayTeam: extractedAwayTeam!,
          date: extractedDate!,
          time: extractedTime!,
        );
        matchedGames = [game];
        debugMatchResult(
          isMatched: true,
          homeTeam: game.homeTeam,
          awayTeam: game.awayTeam,
          date: DateFormat('yyyy-MM-dd').format(game.date),
          time: extractedTime!,
        );
      } catch (e) {
        print('❌ 오류: $e');
        debugMatchResult(isMatched: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('티켓 정보 확인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🎟️ 이미지 미리보기
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: _selectedImage != null
                    ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                    : const Center(child: Text('이미지 분석 중입니다...')),
              ),
              const SizedBox(height: 20),

              // 🏟️ 구단 정보 입력 필드
              _buildLabelText('홈 구단'),
              GestureDetector(
                onTap: () {
                  // 구단 클릭 시 동작
                  print('홈 구단 선택');
                },
                child: _buildClickableTextField('구단을 선택해 주세요', matchedGames.isNotEmpty ? matchedGames[0].homeTeam : ''),
              ),
              _buildLabelText('원정 구단'),
              GestureDetector(
                onTap: () {
                  // 원정 구단 클릭 시 동작
                  print('원정 구단 선택');
                },
                child: _buildClickableTextField('구단을 선택해 주세요', extractedAwayTeam ?? ''),
              ),

              // 🗓️ 날짜 및 시간 입력
              _buildLabelText('일시'),
              GestureDetector(
                onTap: () {
                  // 날짜 클릭 시 동작
                  print('날짜 선택');
                },
                child: _buildClickableTextField('경기 날짜를 선택해 주세요', extractedDate != null && extractedTime != null ? '$extractedDate $extractedTime' : ''),
              ),
              _buildLabelText('좌석'),
              _buildClickableTextField('좌석 정보를 작성해 주세요', extractedSeat ?? ''),

              // ✅ 완료 버튼
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: 저장 및 이동 로직 추가
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('저장 완료')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pri500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('완료', style: AppFonts.b2_b(context).copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Text(
      label,
      style: AppFonts.b3_sb(context).copyWith(color: AppColors.gray700),
    );
  }

  Widget _buildClickableTextField(String label, String value) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: value.isEmpty ? AppColors.gray200 : AppColors.gray50, // 값이 없으면 연한 회색으로 표시
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray300),
          ),
          child: Text(
            value.isNotEmpty ? value : label,
            style: AppFonts.b3_m(context).copyWith(color: value.isEmpty ? AppColors.gray500 : AppColors.gray800),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
