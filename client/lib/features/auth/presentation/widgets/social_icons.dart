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

/// Official GitHub Octocat Silhouette Icon
class GitHubIcon extends StatelessWidget {
  const GitHubIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFF18181B),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GitHubLogoPainter(color),
    );
  }
}

class _GitHubLogoPainter extends CustomPainter {
  _GitHubLogoPainter(this.fillColor);

  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);

    final path = Path()
      ..moveTo(12, 0)
      ..cubicTo(5.37, 0, 0, 5.37, 0, 12)
      ..cubicTo(0, 17.31, 3.438, 21.8, 8.205, 23.385)
      ..cubicTo(8.805, 23.49, 9.03, 23.13, 9.03, 22.815)
      ..cubicTo(9.03, 22.53, 9.015, 21.585, 9.015, 20.58)
      ..cubicTo(6, 21.135, 5.22, 19.845, 4.98, 19.17)
      ..cubicTo(4.845, 18.825, 4.26, 17.76, 3.75, 17.475)
      ..cubicTo(3.33, 17.25, 2.73, 16.695, 3.735, 16.68)
      ..cubicTo(4.68, 16.665, 5.355, 17.55, 5.58, 17.91)
      ..cubicTo(6.66, 19.725, 8.385, 19.215, 9.075, 18.9)
      ..cubicTo(9.18, 18.12, 9.495, 17.595, 9.84, 17.295)
      ..cubicTo(7.17, 16.995, 4.38, 15.96, 4.38, 11.37)
      ..cubicTo(4.38, 10.065, 4.845, 8.985, 5.61, 8.145)
      ..cubicTo(5.49, 7.845, 5.07, 6.615, 5.73, 4.965)
      ..cubicTo(5.73, 4.965, 6.735, 4.65, 9.03, 6.195)
      ..cubicTo(9.99, 5.925, 11.01, 5.79, 12.03, 5.79)
      ..cubicTo(13.05, 5.79, 14.07, 5.925, 15.03, 6.195)
      ..cubicTo(17.325, 4.635, 18.33, 4.965, 18.33, 4.965)
      ..cubicTo(18.99, 6.615, 18.57, 7.845, 18.45, 8.145)
      ..cubicTo(19.215, 8.985, 19.68, 10.05, 19.68, 11.37)
      ..cubicTo(19.68, 15.975, 16.875, 16.995, 14.205, 17.295)
      ..cubicTo(14.64, 17.67, 15.015, 18.39, 15.015, 19.515)
      ..cubicTo(15.015, 21.12, 15, 22.41, 15, 22.815)
      ..cubicTo(15, 23.13, 15.225, 23.505, 15.825, 23.385)
      ..cubicTo(20.565, 21.795, 24, 17.295, 24, 12)
      ..cubicTo(24, 5.37, 18.63, 0, 12, 0)
      ..close();

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
    canvas.restore();
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
