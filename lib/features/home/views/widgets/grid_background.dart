import 'package:flutter/material.dart';

class GridBackgroundPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double strokeWidth;

  GridBackgroundPainter({
    required this.color,
    this.spacing = 40.0,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.spacing != spacing ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
