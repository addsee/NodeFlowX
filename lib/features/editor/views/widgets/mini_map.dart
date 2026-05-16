import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';

class MiniMap extends StatelessWidget {
  final EditorController ctr;
  const MiniMap({super.key, required this.ctr});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bounds = ctr.graphBounds;
      if (bounds == Rect.zero) return const SizedBox.shrink();

      return GestureDetector(
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox;
          final localPos = box.globalToLocal(details.globalPosition);
          
          final scaleX = localPos.dx / 150;
          final scaleY = localPos.dy / 150;
          
          final worldX = bounds.left + bounds.width * scaleX;
          final worldY = bounds.top + bounds.height * scaleY;
          
          ctr.teleportRequest.value = Offset(worldX, worldY);
        },
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                blurRadius: 15,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _MiniMapPainter(ctr: ctr, bounds: bounds),
            ),
          ),
        ),
      );
    });
  }
}

class _MiniMapPainter extends CustomPainter {
  final EditorController ctr;
  final Rect bounds;
  _MiniMapPainter({required this.ctr, required this.bounds});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.translate(
      (size.width - bounds.width * scale) / 2,
      (size.height - bounds.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);

    final paint = Paint()..style = PaintingStyle.fill;

    for (var node in ctr.graphData.values) {
      paint.color = node.type < 10 ? AppColors.neonCyan.withValues(alpha: 0.5) : Colors.amber.withValues(alpha: 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(node.position.dx, node.position.dy, 150, 100),
          const Radius.circular(20),
        ),
        paint,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
      
    for (var conn in ctr.connections) {
      final from = ctr.graphData[conn['from']];
      final to = ctr.graphData[conn['to']];
      if (from != null && to != null) {
        canvas.drawLine(from.position + const Offset(150, 50), to.position + const Offset(0, 50), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
