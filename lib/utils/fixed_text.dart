import 'package:flutter/material.dart';

/// 시스템 글자 크기 설정을 무시한 안전한 텍스트 위젯
class FixedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const FixedText(
      this.data, {
        super.key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textScaleFactor: 1.0, // ✅ 핵심: 시스템 폰트 크기 무시
    );
  }
}
