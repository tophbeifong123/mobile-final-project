import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Rocket Badge with online status dot
class RocketBadge extends StatelessWidget {
  const RocketBadge({super.key, this.size = 54});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: NeoColors.skyBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: NeoColors.inkSolid, width: 2.2),
            boxShadow: NeoShadows.elevation2,
          ),
          child: Center(
            child: CustomPaint(
              size: Size(size * 0.55, size * 0.55),
              painter: _RocketPainter(),
            ),
          ),
        ),
        // Green status indicator dot
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: NeoColors.onlineGreen,
              shape: BoxShape.circle,
              border: Border.all(color: NeoColors.inkSolid, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _RocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = NeoColors.inkSolid
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left Wing
    final leftWingPath = Path()
      ..moveTo(w * 0.32, h * 0.6)
      ..lineTo(w * 0.1, h * 0.78)
      ..lineTo(w * 0.3, h * 0.78)
      ..close();
    final wingPaint = Paint()
      ..color = NeoColors.pastelCoral
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftWingPath, wingPaint);
    canvas.drawPath(leftWingPath, borderPaint);

    // Right Wing
    final rightWingPath = Path()
      ..moveTo(w * 0.68, h * 0.6)
      ..lineTo(w * 0.9, h * 0.78)
      ..lineTo(w * 0.7, h * 0.78)
      ..close();
    canvas.drawPath(rightWingPath, wingPaint);
    canvas.drawPath(rightWingPath, borderPaint);

    // Fuselage
    final bodyPath = Path()
      ..moveTo(w * 0.5, h * 0.12)
      ..cubicTo(w * 0.75, h * 0.3, w * 0.75, h * 0.65, w * 0.7, h * 0.8)
      ..lineTo(w * 0.3, h * 0.8)
      ..cubicTo(w * 0.25, h * 0.65, w * 0.25, h * 0.3, w * 0.5, h * 0.12)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, borderPaint);

    // Window Porch
    final windowPaint = Paint()
      ..color = NeoColors.butterYellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.46), w * 0.14, windowPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.46), w * 0.14, borderPaint);

    // Flame
    final flamePath = Path()
      ..moveTo(w * 0.4, h * 0.82)
      ..lineTo(w * 0.5, h * 0.98)
      ..lineTo(w * 0.6, h * 0.82)
      ..close();
    final flamePaint = Paint()
      ..color = NeoColors.errorBorder
      ..style = PaintingStyle.fill;
    canvas.drawPath(flamePath, flamePaint);
    canvas.drawPath(flamePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
