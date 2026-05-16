import 'package:flutter/material.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';

// ════════════════════════════════════════════════════════════════════════════
// MinimapPainter
//
// Draws a scaled-down bird's-eye view of all nodes on the canvas.
// Each node is drawn as a small coloured rectangle, colour-coded by category.
//
// Virtual canvas is 6000 × 5000 units.  The minimap widget itself is
// 160 × 110 px, so the scale is roughly 1:37.
// ════════════════════════════════════════════════════════════════════════════
class MinimapPainter extends CustomPainter {
  final Map<String, NodeModel> nodes;
  final Size canvasSize;        // virtual canvas dimensions (6000 × 5000)
  final Rect? viewportRect;     // current visible rectangle in canvas coords

  const MinimapPainter({
    required this.nodes,
    this.canvasSize = const Size(6000, 5000),
    this.viewportRect,
  });

  // ── Colour per node category ──────────────────────────────────────────
  Color _colorFor(int type) {
    if (type == 0 || type == 1) return AppColors.neonCyan;
    if (type == 4)               return AppColors.neonMagenta;
    if (type == 10)              return Colors.greenAccent;
    if (type == 30 || type == 31)return AppColors.neonAmber;
    if (type == 40)              return Colors.lightBlueAccent;
    if (type >= 6 && type <= 9)  return Colors.orangeAccent;
    return AppColors.neonCyan;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width  / canvasSize.width;
    final scaleY = size.height / canvasSize.height;

    // ── Background ──────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xCC060A0F),
    );

    // ── Grid dots (light) ───────────────────────────────────────────────
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const gridStep = 40.0; // virtual units between dots
    for (double vx = 0; vx < canvasSize.width; vx += gridStep) {
      for (double vy = 0; vy < canvasSize.height; vy += gridStep) {
        canvas.drawCircle(
          Offset(vx * scaleX, vy * scaleY),
          0.5,
          gridPaint,
        );
      }
    }

    // ── Nodes ────────────────────────────────────────────────────────────
    for (final node in nodes.values) {
      final color = _colorFor(node.type);
      final nodeW = 200 * scaleX; // node width in minimap pixels
      final nodeH = 80  * scaleY; // approximate node height
      final rect  = Rect.fromLTWH(
        node.x * scaleX,
        node.y * scaleY,
        nodeW,
        nodeH,
      );

      // Shadow glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(1.5), const Radius.circular(3)),
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Node body
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
        Paint()..color = const Color(0xFF0B0E14),
      );

      // Left accent strip
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top, 1.5, rect.height),
          const Radius.circular(1),
        ),
        Paint()..color = color.withValues(alpha: 0.9),
      );

      // Node colour dot (top-right)
      canvas.drawCircle(
        Offset(rect.right - 2, rect.top + 2),
        1.5,
        Paint()..color = color,
      );
    }

    // ── Viewport rectangle ───────────────────────────────────────────────
    if (viewportRect != null) {
      final vr = Rect.fromLTWH(
        viewportRect!.left   * scaleX,
        viewportRect!.top    * scaleY,
        viewportRect!.width  * scaleX,
        viewportRect!.height * scaleY,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(vr, const Radius.circular(3)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(vr, const Radius.circular(3)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // ── Border ───────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(8),
      ),
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(MinimapPainter old) =>
      old.nodes != nodes || old.viewportRect != viewportRect;
}

// ════════════════════════════════════════════════════════════════════════════
// Minimap widget — fixed-size overlay placed in the canvas corner
// ════════════════════════════════════════════════════════════════════════════
class Minimap extends StatelessWidget {
  final Map<String, NodeModel> nodes;
  final Rect? viewportRect;
  final Function(Offset)? onTap;

  const Minimap({super.key, required this.nodes, this.viewportRect, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (onTap != null) {
          final box = context.findRenderObject() as RenderBox;
          onTap!(box.globalToLocal(details.globalPosition));
        }
      },
      child: Container(
        width: 170,
        height: 115,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 12,
            ),
          ],
        ),
        child: CustomPaint(
          painter: MinimapPainter(nodes: nodes, viewportRect: viewportRect),
        ),
      ),
    );
  }
}
