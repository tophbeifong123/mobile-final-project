import 'package:flutter/material.dart';

/// Multi-color Google "G" Icon Painter
class GoogleGIcon extends StatelessWidget {
  const GoogleGIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleGLogoPainter());
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red arc (Top)
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -2.356, 1.571, false)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // Yellow arc (Left)
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -3.927, 1.571, false)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Green arc (Bottom)
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 0.785, 1.571, false)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Blue arc (Right)
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -0.785, 1.571, false)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Inner white circle
    final innerWhite = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, innerWhite);

    // Blue bar horizontal
    final blueBar = Rect.fromLTWH(
      center.dx,
      center.dy - (radius * 0.22),
      radius,
      radius * 0.44,
    );
    canvas.drawRect(blueBar, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4-color Microsoft / University SSO Grid Logo
class SsoGridIcon extends StatelessWidget {
  const SsoGridIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    final boxSize = (size - 2) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _colorBox(const Color(0xFFF25022), boxSize), // Red-Orange
              _colorBox(const Color(0xFF7FBA00), boxSize), // Green
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _colorBox(const Color(0xFF00A4EF), boxSize), // Blue
              _colorBox(const Color(0xFFFFB900), boxSize), // Yellow
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorBox(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
