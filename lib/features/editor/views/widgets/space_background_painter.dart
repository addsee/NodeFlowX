import 'package:flutter/material.dart';

class SpaceBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Just a flat dark color for the space
    final paint = Paint()..color = const Color(0xFF06090D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
