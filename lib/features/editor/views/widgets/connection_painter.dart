import 'package:flutter/material.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';

class ConnectionPainter extends CustomPainter {
  final Map<String, NodeModel> nodes;
  final List<Map<String, String>> conns;
  final String? dragFrom;
  final String? dragPort;
  final Offset? dragPos;
  final double pulseProgress;

  ConnectionPainter({
    required this.nodes,
    required this.conns,
    this.dragFrom,
    this.dragPort,
    this.dragPos,
    this.pulseProgress = 0,
  }) : super(repaint: Listenable.merge([])); // We'll pass the animation in GraphCanvas

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.15)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final base = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final pulsePaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var c in conns) {
      final f = nodes[c["from"]];
      final t = nodes[c["to"]];
      if (f != null && t != null) {
        _drawPath(canvas, _out(f, c["fromPort"]!), _in(t), glow, base, pulsePaint, true);
      }
    }
    
    if (dragFrom != null && dragPos != null) {
      final f = nodes[dragFrom];
      if (f != null) {
        _drawPath(canvas, _out(f, dragPort!), dragPos!, glow, base, pulsePaint, false);
      }
    }
  }

  void _drawPath(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint glow,
    Paint base,
    Paint pulsePaint,
    bool showPulse,
  ) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(p1.dx + 50, p1.dy, p2.dx - 50, p2.dy, p2.dx, p2.dy);
    
    canvas.drawPath(path, glow);
    canvas.drawPath(path, base);

    if (showPulse) {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final length = metric.length;
        final start = length * pulseProgress;
        final pulseLen = 20.0; // Length of the pulse
        
        final extract = metric.extractPath(start, start + pulseLen);
        canvas.drawPath(extract, pulsePaint);
        
        // Loop pulse (draw another part if it wraps around)
        if (start + pulseLen > length) {
           final wrapExtract = metric.extractPath(0, (start + pulseLen) - length);
           canvas.drawPath(wrapExtract, pulsePaint);
        }
      }
    }
  }

  Offset _out(NodeModel n, String port) {
    double y = n.y + 35;
    if (port == "true") y -= 12;
    if (port == "false") y += 12;
    return Offset(n.x + 142, y);
  }

  Offset _in(NodeModel n) => Offset(n.x + 8, n.y + 35);

  @override
  bool shouldRepaint(covariant ConnectionPainter old) => true; // Always repaint for animation
}
