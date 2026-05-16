import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';
import 'package:node_flow_x/features/editor/views/widgets/grid_painter.dart';
import 'package:node_flow_x/features/editor/views/widgets/space_background_painter.dart';
import 'package:node_flow_x/features/editor/views/widgets/connection_painter.dart';
import 'package:node_flow_x/features/editor/views/widgets/minimap.dart';
import 'node_item.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';

// Virtual canvas dimensions (must match values in minimap.dart + controller)
const double _canvasW = 6000;
const double _canvasH = 5000;

class GraphCanvas extends StatefulWidget {
  final EditorController ctr;
  const GraphCanvas({super.key, required this.ctr});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas>
    with TickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();

  // TransformationController lets us read the current viewport transform
  final TransformationController _transformCtrl = TransformationController();
  late AnimationController _pulseCtrl;

  // Cached viewport rect in canvas coordinates (updated on transform change)
  Rect? _viewportRect;
  Size _widgetSize = Size.zero;
  Offset _lassoStart = Offset.zero;
  Offset _lassoEnd = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Listen for pan/zoom changes to update the minimap viewport rectangle
    _transformCtrl.addListener(_onTransformChanged);
    ever(widget.ctr.teleportRequest, (Offset? pos) {
      if (pos != null) {
        final currentScale = _transformCtrl.value.getMaxScaleOnAxis();
        final tx = -pos.dx * currentScale + (_widgetSize.width / 2);
        final ty = -pos.dy * currentScale + (_widgetSize.height / 2);
        _transformCtrl.value = Matrix4.identity()
          ..setTranslationRaw(tx, ty, 0)
          ..scaleByDouble(currentScale, currentScale, 1.0, 1.0);
        _onTransformChanged();
        widget.ctr.teleportRequest.value = null; // Reset
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _transformCtrl.removeListener(_onTransformChanged);
    _transformCtrl.dispose();
    super.dispose();
  }

  // Converts the current InteractiveViewer transform into a canvas-space Rect
  void _onTransformChanged() {
    if (_widgetSize == Size.zero) return;
    final m = _transformCtrl.value;
    // The scale is stored at m[0] (assuming uniform scale)
    final scale = m.getMaxScaleOnAxis();
    // Translation in widget pixels
    final tx = m.getTranslation().x;
    final ty = m.getTranslation().y;
    // Top-left of the visible area in canvas coords
    final left = -tx / scale;
    final top = -ty / scale;
    final width = _widgetSize.width / scale;
    final height = _widgetSize.height / scale;
    setState(() {
      _viewportRect = Rect.fromLTWH(left, top, width, height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.1),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Static space background ─────────────────────────────
                Positioned.fill(
                  child: CustomPaint(painter: SpaceBackgroundPainter()),
                ),

                // ── Main interactive canvas ───────────────────────────────
                Obx(() {
                  final nodes = Map<String, NodeModel>.from(
                    widget.ctr.graphData,
                  );
                  final conns = List<Map<String, String>>.from(
                    widget.ctr.connections,
                  );
                  final dragFrom = widget.ctr.draggingFrom.value;
                  final dragPos = widget.ctr.dragPosition.value;
                  final dragPort = widget.ctr.draggingPort.value;

                  return DragTarget<int>(
                    onAcceptWithDetails: (d) {
                      final box =
                          _key.currentContext!.findRenderObject() as RenderBox;
                      widget.ctr.addNode(d.data, box.globalToLocal(d.offset));
                    },
                    builder: (context, _, _) => GestureDetector(
                      onSecondaryTapDown: (details) =>
                          _showContextMenu(context, details.globalPosition),
                      onLongPressStart: (details) =>
                          _showContextMenu(context, details.globalPosition),
                      onDoubleTapDown: (details) {
                        final box =
                            _key.currentContext!.findRenderObject()
                                as RenderBox;
                        widget.ctr.removeConnectionAt(
                          box.globalToLocal(details.globalPosition),
                        );
                      },
                      child: InteractiveViewer(
                        transformationController: _transformCtrl,
                        constrained: false,
                        minScale: 0.1,
                        maxScale: 3.0,
                        child: SizedBox(
                          width: _canvasW,
                          height: _canvasH,
                          child: Stack(
                            key: _key,
                            children: [
                              // Dot grid
                              Positioned.fill(
                                child: CustomPaint(painter: GridPainter()),
                              ),

                              // Lasso Selection Layer
                              if (widget.ctr.selectionMode.value)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onPanStart: (d) {
                                      _lassoStart = d.localPosition;
                                      setState(
                                        () => _lassoEnd = d.localPosition,
                                      );
                                    },
                                    onPanUpdate: (d) {
                                      setState(
                                        () => _lassoEnd = d.localPosition,
                                      );
                                      widget.ctr.selectNodesInRect(
                                        Rect.fromPoints(_lassoStart, _lassoEnd),
                                      );
                                    },
                                    onPanEnd: (d) {
                                      setState(() {
                                        _lassoStart = Offset.zero;
                                        _lassoEnd = Offset.zero;
                                      });
                                    },
                                    child: CustomPaint(
                                      painter: LassoPainter(
                                        start: _lassoStart,
                                        end: _lassoEnd,
                                      ),
                                    ),
                                  ),
                                ),
                              // Connection curves + drag preview
                              AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, _) => CustomPaint(
                                  size: const Size(_canvasW, _canvasH),
                                  painter: ConnectionPainter(
                                    nodes: nodes,
                                    conns: conns,
                                    dragFrom: dragFrom,
                                    dragPort: dragPort,
                                    dragPos: dragPos,
                                    pulseProgress: _pulseCtrl.value,
                                  ),
                                ),
                              ),
                              // Node items
                              ...nodes.entries.map(
                                (e) => Positioned(
                                  left: e.value.x,
                                  top: e.value.y,
                                  child: NodeItem(
                                    id: e.key,
                                    node: e.value,
                                    ctr: widget.ctr,
                                    canvasKey: _key,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // ── Minimap — bottom-right corner ─────────────────────────
                if (MediaQuery.of(context).size.width > 600)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Obx(() {
                      final nodes = Map<String, NodeModel>.from(
                        widget.ctr.graphData,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Label
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, right: 2),
                            child: Text(
                              'MINIMAP',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Minimap(
                            nodes: nodes,
                            viewportRect: _viewportRect,
                            onTap: (localPos) {
                              // Convert minimap localPos to virtual canvas coords
                              final double scaleX = 6000 / 170;
                              final double scaleY = 5000 / 115;
                              final double vx = localPos.dx * scaleX;
                              final double vy = localPos.dy * scaleY;

                              // Center the viewport on this point
                              final currentScale = _transformCtrl.value
                                  .getMaxScaleOnAxis();
                              final tx =
                                  -vx * currentScale + (_widgetSize.width / 2);
                              final ty =
                                  -vy * currentScale + (_widgetSize.height / 2);

                              // Apply new transform
                              _transformCtrl.value = Matrix4.identity()
                                ..setTranslationRaw(tx, ty, 0)
                                ..scaleByDouble(
                                  currentScale,
                                  currentScale,
                                  1.0,
                                  1.0,
                                );
                              _onTransformChanged();
                            },
                          ),
                        ],
                      );
                    }),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Right-click context menu ───────────────────────────────────────────────
  void _showContextMenu(BuildContext context, Offset globalPos) {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(globalPos);

    showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx + 1,
        globalPos.dy + 1,
      ),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      items: <PopupMenuEntry<int>>[
        _menuHeader('EVENTS'),
        _menuItem(
          0,
          'On Start',
          Icons.rocket_launch,
          Colors.cyanAccent,
          localPos,
        ),
        _menuItem(1, 'On Update', Icons.loop, Colors.cyanAccent, localPos),
        const PopupMenuDivider(height: 1),
        _menuHeader('DATA'),
        _menuItem(
          31,
          'Local Var',
          Icons.data_object,
          Colors.amberAccent,
          localPos,
        ),
        _menuItem(30, 'Set Variable', Icons.edit, Colors.amberAccent, localPos),
        const PopupMenuDivider(height: 1),
        _menuHeader('LOGIC'),
        _menuItem(
          4,
          'If / Else',
          Icons.alt_route,
          Colors.purpleAccent,
          localPos,
        ),
        _menuItem(
          10,
          'Input Key',
          Icons.keyboard,
          Colors.greenAccent,
          localPos,
        ),
        const PopupMenuDivider(height: 1),
        _menuHeader('TRANSFORM'),
        _menuItem(
          40,
          'Transform',
          Icons.transform,
          Colors.lightBlueAccent,
          localPos,
        ),
      ],
    );
  }

  PopupMenuItem<int> _menuHeader(String label) => PopupMenuItem<int>(
    enabled: false,
    height: 26,
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white24,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ),
  );

  PopupMenuItem<int> _menuItem(
    int type,
    String label,
    IconData icon,
    Color color,
    Offset pos,
  ) {
    return PopupMenuItem<int>(
      onTap: () => widget.ctr.addNode(type, pos),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 13),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class LassoPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  LassoPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == Offset.zero || end == Offset.zero) return;
    final rect = Rect.fromPoints(start, end);
    final paint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant LassoPainter old) =>
      old.start != start || old.end != end;
}
