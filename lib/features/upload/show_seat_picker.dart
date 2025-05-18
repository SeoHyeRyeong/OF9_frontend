import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/api/game_api.dart';
import 'package:frontend/models/game_response.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/fixed_text.dart';

/// 좌석 입력용 다이얼로그
Future<String?> showSeatInputDialog(BuildContext context, {String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: FixedText('좌석을 입력하세요'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: '예: 12블럭 5열 8번'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: FixedText('취소')),
        TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text('확인')),
      ],
    ),
  );
}
