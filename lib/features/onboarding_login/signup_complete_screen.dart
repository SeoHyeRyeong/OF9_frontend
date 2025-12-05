import 'package:flutter/material.dart';
import 'package:frontend/theme/app_imgs.dart';
import 'package:frontend/utils/size_utils.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/app_fonts.dart';
import 'package:frontend/utils/fixed_text.dart';
import 'package:frontend/features/report/report_screen.dart';

class SignupCompleteScreen extends StatefulWidget {
  final String? selectedTeam;

  const SignupCompleteScreen({Key? key, this.selectedTeam}) : super(key: key);

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen> {
  final Map<String, String> _teamImages = {
    '두산 베어스': AppImages.bears,
    '롯데 자이언츠': AppImages.giants,
    '삼성 라이온즈': AppImages.lions,
    '키움 히어로즈': AppImages.kiwoom,
    '한화 이글스': AppImages.eagles,
    'KIA 타이거즈': AppImages.tigers,
    'KT WIZ': AppImages.ktwiz,
    'LG 트윈스': AppImages.twins,
    'NC 다이노스': AppImages.dinos,
    'SSG 랜더스': AppImages.landers,
  };

  Widget _buildDashedLine() {
    return SizedBox(
      width: scaleWidth(1.5),
      height: scaleHeight(76),
      child: CustomPaint(
        painter: _VerticalDashedLinePainter(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: scaleHeight(76)),

            // Welcome 이미지
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(32)),
              child: AspectRatio(
                aspectRatio: 296 / 262,
                child: Image.asset(
                  AppImages.welcome,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            SizedBox(height: scaleHeight(35)),

            // 메인 타이틀
            FixedText(
              '두다다에 오신 것을\n환영합니다!',
              style: AppFonts.pretendard.title_lg_600(context).copyWith(color: Colors.black),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: scaleHeight(15)),

            // 서브 타이틀
            FixedText(
              '지금부터 나만의 직관 이야기를 기록해 보세요!',
              style: AppFonts.pretendard.body_sm_400(context).copyWith(color: AppColors.gray300),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: scaleHeight(32)),

            // 티켓 이미지
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleWidth(20)),
              child: SizedBox(
                height: scaleHeight(76),
                width: double.infinity,
                child: CustomPaint(
                  painter: _FavoriteTicketPainter(
                    backgroundColor: AppColors.gray50,
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: scaleWidth(30)),
                      FixedText(
                        '최애 구단',
                        style: AppFonts.suite.b2_m_long(context).copyWith(color: AppColors.gray800),
                      ),
                      SizedBox(width: scaleWidth(20)),
                      // 점선
                      _buildDashedLine(),
                      SizedBox(width: scaleWidth(16)),
                      if (widget.selectedTeam != null) ...[
                        Image.asset(
                          _teamImages[widget.selectedTeam!]!,
                          width: scaleWidth(40),
                          height: scaleWidth(40),
                        ),
                        SizedBox(width: scaleWidth(7)),
                        Flexible(
                          child: FixedText(
                            widget.selectedTeam!,
                            style: AppFonts.suite.b2_m_long(context).copyWith(color: AppColors.gray800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Spacer(),

            // 완료 버튼
            Container(
              width: double.infinity,
              height: scaleHeight(88),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.gray20,
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                top: scaleHeight(24),
                right: scaleWidth(20),
                bottom: scaleHeight(10),
                left: scaleWidth(20),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => const ReportScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleHeight(16)),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Center(
                  child: FixedText(
                    '완료',
                    style: AppFonts.pretendard.body_md_500(context).copyWith(color: AppColors.gray20),
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


class _FavoriteTicketPainter extends CustomPainter {
  final Color backgroundColor;

  const _FavoriteTicketPainter({
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double notchRadius = scaleWidth(13);
    final double cornerRadius = scaleWidth(12);

    final Paint backgroundPaint = Paint()..color = backgroundColor;
    final Path path = Path();

    // --- 1. 티켓 모양(외곽선 + 좌우 노치) 그리기 ---
    // 왼쪽 상단에서 시작
    path.moveTo(0, cornerRadius);

    // 왼쪽 상단 모서리 (둥글게)
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // 상단 가장자리
    path.lineTo(size.width - cornerRadius, 0);

    // 오른쪽 상단 모서리 (둥글게)
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // 오른쪽 가장자리 (상단 ~ 노치 시작)
    path.lineTo(size.width, size.height / 2 - notchRadius);

    // 오른쪽 노치 (반원)
    path.arcToPoint(
      Offset(size.width, size.height / 2 + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false, // 왼쪽으로 파인 모양
    );

    // 오른쪽 가장자리 (노치 끝 ~ 하단)
    path.lineTo(size.width, size.height - cornerRadius);

    // 오른쪽 하단 모서리 (둥글게)
    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);

    // 하단 가장자리
    path.lineTo(cornerRadius, size.height);

    // 왼쪽 하단 모서리 (둥글게)
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // 왼쪽 가장자리 (하단 ~ 노치 끝)
    path.lineTo(0, size.height / 2 + notchRadius);

    // 왼쪽 노치 (반원)
    path.arcToPoint(
      Offset(0, size.height / 2 - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false, // 오른쪽으로 파인 모양
    );

    // 왼쪽 가장자리 (노치 시작 ~ 상단)
    path.lineTo(0, cornerRadius);

    path.close();

    // --- 2. 배경 채우기 ---
    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _FavoriteTicketPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}

// 세로 점선을 그리는 CustomPainter
class _VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dashPaint = Paint()
      ..color = const Color(0xFFB1C4D3)
      ..strokeWidth = scaleWidth(1.5)
      ..style = PaintingStyle.stroke;

    final double dashHeight = scaleHeight(5);
    final double dashSpace = scaleHeight(8);
    final double dashStart = scaleHeight(8);
    final double dashEnd = size.height - scaleHeight(8);

    // 점선 6개를 균등하게 배치
    final double totalDashSpace = dashEnd - dashStart;
    final double totalDashHeight = dashHeight * 6;
    final double totalGapHeight = totalDashSpace - totalDashHeight;
    final double gap = totalGapHeight / 5; // 5개의 간격

    double currentY = dashStart;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width / 2, currentY),
        Offset(size.width / 2, currentY + dashHeight),
        dashPaint,
      );
      currentY += (dashHeight + gap);
    }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}