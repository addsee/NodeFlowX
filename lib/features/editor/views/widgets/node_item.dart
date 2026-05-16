import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// NODE COLOUR + ICON HELPERS
// Each category of node has a distinct accent colour so the canvas is easy
// to read at a glance.
// ════════════════════════════════════════════════════════════════════════════

Color _nodeColor(int type) {
  if (type == 0 || type == 1) return AppColors.neonCyan; // Events
  if (type == 4) return AppColors.neonMagenta; // If/Else
  if (type == 10) return Colors.greenAccent; // Input Key
  if (type == 30 || type == 31) return AppColors.neonAmber; // Data
  if (type == 40) return Colors.lightBlueAccent; // Transform
  if (type == 99) return Colors.yellowAccent; // Note
  if (type >= 6 && type <= 9) return Colors.orangeAccent; // Math
  return AppColors.neonCyan;
}

IconData _nodeIcon(int type) {
  switch (type) {
    case 0:
      return Icons.rocket_launch;
    case 1:
      return Icons.loop;
    case 4:
      return Icons.alt_route;
    case 10:
      return Icons.keyboard;
    case 30:
      return Icons.edit_note;
    case 31:
      return Icons.data_object;
    case 40:
      return Icons.transform;
    case 6:
      return Icons.add;
    case 7:
      return Icons.remove;
    case 8:
      return Icons.close;
    case 9:
      return Icons.percent;
    case 99:
      return Icons.sticky_note_2;
    default:
      return Icons.widgets_outlined;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GRAPH-TRAVERSAL HELPERS (used by Set Variable to find vars in scope)
// ════════════════════════════════════════════════════════════════════════════

/// Walk backwards from [nodeId] — collect every ancestor (including itself).
Set<String> _ancestorsOf(String nodeId, List<Map<String, String>> conns) {
  final visited = <String>{};
  void walk(String id) {
    if (!visited.add(id)) return;
    for (final c in conns) {
      if (c['to'] == id) walk(c['from']!);
    }
  }

  walk(nodeId);
  return visited;
}

/// Walk forward from [nodeId] — collect every descendant (including itself).
Set<String> _descendantsOf(String nodeId, List<Map<String, String>> conns) {
  final visited = <String>{};
  void walk(String id) {
    if (!visited.add(id)) return;
    for (final c in conns) {
      if (c['from'] == id) walk(c['to']!);
    }
  }

  walk(nodeId);
  return visited;
}

/// Returns the names of all Local Var nodes that are "in scope" for the
/// Set Variable node at [setVarId].  A var is in scope if it shares the
/// same root event (OnStart / OnUpdate) chain as this Set Variable.
List<String> _localVarsInScope(
  String setVarId,
  Map<String, NodeModel> graphData,
  List<Map<String, String>> conns,
) {
  final ancestors = _ancestorsOf(setVarId, conns);

  final rootEventIds = ancestors.where((id) {
    final t = graphData[id]?.type;
    return t == 0 || t == 1;
  }).toSet();

  final inChain = <String>{...ancestors};
  for (final rootId in rootEventIds) {
    inChain.addAll(_descendantsOf(rootId, conns));
  }

  return graphData.entries
      .where((e) => e.value.type == 31 && inChain.contains(e.key))
      .map((e) => e.value.properties['varName'] as String? ?? '')
      .where((n) => n.isNotEmpty)
      .toSet()
      .toList();
}

// ════════════════════════════════════════════════════════════════════════════
// NODE ITEM  —  the draggable visual block that represents a single node
// ════════════════════════════════════════════════════════════════════════════
class NodeItem extends StatelessWidget {
  final String id;
  final NodeModel node;
  final EditorController ctr;
  final GlobalKey canvasKey;

  const NodeItem({
    super.key,
    required this.id,
    required this.node,
    required this.ctr,
    required this.canvasKey,
  });

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor(node.type);
    final isEventNode =
        node.type == 0 || node.type == 1 || node.type == 2 || node.type == 3;

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => !isEventNode,
      onAcceptWithDetails: (d) => ctr.endConnect(d.data, id),
      builder: (context, _, _) => LongPressDraggable<String>(
        data: id,
        delay: const Duration(milliseconds: 300),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 10),
              ],
            ),
          ),
        ),
        onDragStarted: () => ctr.startConnect(id, 'default'),
        onDragUpdate: (d) {
          final box = canvasKey.currentContext!.findRenderObject() as RenderBox;
          ctr.dragPosition.value = box.globalToLocal(d.globalPosition);
        },
        onDragEnd: (_) => ctr.cancelDrag(),
        child: GestureDetector(
          onDoubleTap: () => _showSmartTooltip(
            context,
            color,
          ), // نقلنا الشرح إلى النقر المزدوج
          onPanStart: (d) => ctr.startMove(),
          onPanUpdate: (d) => ctr.moveNode(id, d.delta.dx, d.delta.dy),
          onPanEnd: (d) => ctr.finishMove(),
          onTap: () {
            if (ctr.selectionMode.value) {
              ctr.toggleNodeSelection(id);
            } else {
              ctr.toggleHighlightFlow(id);
            }
          },
          child: Obx(() {
            final isSelected = ctr.selectedNodeIds.contains(id);
            final isHighlighted = ctr.highlightedNodeIds.contains(id);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _NodeShell(
                  color: isSelected
                      ? Colors.white
                      : (isHighlighted ? AppColors.neonCyan : color),
                  isSelected: isSelected,
                  isHighlighted: isHighlighted,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NodeHeader(id: id, node: node, color: color, ctr: ctr),
                      _NodeBody(
                        id: id,
                        node: node,
                        color: color,
                        ctr: ctr,
                        canvasKey: canvasKey,
                        isEventNode: isEventNode,
                      ),
                    ],
                  ),
                ),
                if (ctr.errors.containsKey(id))
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Tooltip(
                      message: ctr.errors[id]!,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.priority_high,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showSmartTooltip(BuildContext context, Color color) {
    final descriptions = {
      1: "Event: On Start - Runs once when the script starts.",
      2: "Event: On Update - Runs every frame.",
      3: "Event: On Collision - Runs when something hits this object.",
      4: "Control: If - Checks a condition and branches the logic flow.",
      10: "Input: Key Pressed - Detects if a specific keyboard key is held.",
      30: "Logic: Set Variable - Updates the value of an existing variable.",
      31: "Logic: Create Variable - Defines a local variable for this script.",
      40: "Action: Transform - Manipulates position, rotation, or scale.",
      99: "Note: A sticky note for leaving comments in your graph.",
    };

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(_nodeIcon(node.type), color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              node.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          descriptions[node.type] ?? "A logic node for visual scripting.",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Got it",
              style: TextStyle(color: AppColors.neonCyan),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NODE SHELL  —  the outer rounded card with glow + left accent strip
// ════════════════════════════════════════════════════════════════════════════
class _NodeShell extends StatelessWidget {
  final Color color;
  final Widget child;
  final bool isSelected;
  final bool isHighlighted;
  const _NodeShell({
    required this.color,
    required this.child,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : (isHighlighted
                    ? AppColors.neonCyan
                    : color.withValues(alpha: 0.28)),
          width: (isSelected || isHighlighted) ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : (isHighlighted
                      ? AppColors.neonCyan.withValues(alpha: 0.4)
                      : color.withValues(alpha: 0.15)),
            blurRadius: (isSelected || isHighlighted) ? 20 : 16,
            spreadRadius: (isSelected || isHighlighted) ? 2 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(color: color.withValues(alpha: 0.7)),
            ),
            Padding(padding: const EdgeInsets.only(left: 3), child: child),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NODE HEADER  —  icon · title · delete button
// ════════════════════════════════════════════════════════════════════════════
class _NodeHeader extends StatelessWidget {
  final String id;
  final NodeModel node;
  final Color color;
  final EditorController ctr;

  const _NodeHeader({
    required this.id,
    required this.node,
    required this.color,
    required this.ctr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(_nodeIcon(node.type), color: color, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              node.title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ctr.removeNode(id),
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NODE BODY  —  node-specific controls + input/output port dots
// ════════════════════════════════════════════════════════════════════════════
class _NodeBody extends StatelessWidget {
  final String id;
  final NodeModel node;
  final Color color;
  final EditorController ctr;
  final GlobalKey canvasKey;
  final bool isEventNode;

  const _NodeBody({
    required this.id,
    required this.node,
    required this.color,
    required this.ctr,
    required this.canvasKey,
    required this.isEventNode,
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Styled text-input field used by multiple node types.
  Widget _field({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    Color textColor = Colors.white,
    double fontSize = 10,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 8.5,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 3),
        ),
        style: TextStyle(color: textColor, fontSize: fontSize, height: 1.4),
        maxLines: maxLines,
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
      ),
    );
  }

  /// Styled dropdown used by multiple node types.
  Widget _dropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    Color itemColor = AppColors.neonAmber,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: hint != null
            ? Text(
                hint,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              )
            : null,
        dropdownColor: const Color(0xFF131820),
        underline: const SizedBox(),
        isExpanded: true,
        icon: Icon(
          Icons.unfold_more_rounded,
          color: Colors.white.withValues(alpha: 0.25),
          size: 13,
        ),
        style: TextStyle(color: itemColor, fontSize: 11),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // ── Node-type-specific widgets ────────────────────────────────────────────

  Widget _localVarBody() {
    return Column(
      children: [
        _dropdown<String>(
          value: node.properties['varType'],
          items: [
            'int',
            'float',
            'string',
            'bool',
            'Vector3',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => ctr.updateNodeProperty(id, 'varType', val),
        ),
        _field(
          label: 'Variable name',
          value: node.properties['varName'] ?? '',
          textColor: AppColors.neonAmber,
          onChanged: (val) => ctr.updateNodeProperty(id, 'varName', val),
        ),
        _field(
          label: 'Initial value',
          value: node.properties['initialValue'] ?? '',
          textColor: Colors.white60,
          onChanged: (val) => ctr.updateNodeProperty(id, 'initialValue', val),
        ),
      ],
    );
  }

  Widget _setVarBody() {
    const operators = ['=', '+=', '-=', '*=', '/='];
    return Obx(() {
      final conns = List<Map<String, String>>.from(ctr.connections);
      final varNames = _localVarsInScope(id, Map.from(ctr.graphData), conns);

      final selVar = varNames.contains(node.properties['selectedVar'])
          ? node.properties['selectedVar'] as String
          : null;

      final selOp = node.properties['operator'] as String? ?? '=';
      final validOp = operators.contains(selOp) ? selOp : '=';

      return Column(
        children: [
          // Variable picker
          _dropdown<String>(
            value: selVar,
            hint: varNames.isEmpty ? 'No vars in scope' : 'Variable…',
            items: varNames
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (val) => ctr.updateNodeProperty(id, 'selectedVar', val),
          ),
          // Operator row + value on same line
          Row(
            children: [
              SizedBox(
                width: 62,
                child: _dropdown<String>(
                  value: validOp,
                  itemColor: Colors.purpleAccent,
                  items: operators
                      .map(
                        (op) => DropdownMenuItem(
                          value: op,
                          child: Text(
                            op,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      ctr.updateNodeProperty(id, 'operator', val),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _field(
                  label: 'Value',
                  value: node.properties['newValue'] ?? '',
                  textColor: Colors.white70,
                  onChanged: (val) =>
                      ctr.updateNodeProperty(id, 'newValue', val),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _ifBody() => _field(
    label: 'Condition  (e.g. speed > 5)',
    value: node.properties['condition'] ?? '',
    textColor: Colors.white70,
    onChanged: (val) => ctr.updateNodeProperty(id, 'condition', val),
  );

  Widget _inputKeyBody() => _dropdown<String>(
    value: node.properties['key'] ?? 'W',
    itemColor: Colors.greenAccent,
    items: const [
      'W',
      'A',
      'S',
      'D',
      'Space',
      'LeftShift',
      'LeftControl',
      'E',
      'Q',
      'F',
      'R',
      'Alpha1',
      'Alpha2',
      'Alpha3',
      'UpArrow',
      'DownArrow',
      'LeftArrow',
      'RightArrow',
      'Mouse0',
      'Mouse1',
    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: (val) => ctr.updateNodeProperty(id, 'key', val),
  );

  /// Single Transform node — choose the operation then write raw args.
  Widget _transformBody() {
    const ops = ['Translate', 'Rotate', 'LookAt', 'SetPosition', 'SetScale'];
    final selOp = node.properties['operation'] as String? ?? 'Translate';
    final validOp = ops.contains(selOp) ? selOp : 'Translate';

    // Friendly placeholder that shows what args are expected
    final hints = {
      'Translate': 'new Vector3(0,0,1) * Time.deltaTime, Space.World',
      'Rotate': 'new Vector3(0,90,0) * Time.deltaTime',
      'LookAt': 'targetTransform',
      'SetPosition': 'new Vector3(0,0,0)',
      'SetScale': 'new Vector3(1,1,1)',
    };

    return Column(
      children: [
        _dropdown<String>(
          value: validOp,
          itemColor: Colors.lightBlueAccent,
          items: ops
              .map((op) => DropdownMenuItem(value: op, child: Text(op)))
              .toList(),
          onChanged: (val) =>
              ctr.updateNodeProperty(id, 'operation', val ?? 'Translate'),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
          decoration: BoxDecoration(
            color: Colors.lightBlueAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.lightBlueAccent.withValues(alpha: 0.15),
            ),
          ),
          child: TextField(
            decoration: InputDecoration(
              labelText: '.$validOp( … )',
              labelStyle: TextStyle(
                color: Colors.lightBlueAccent.withValues(alpha: 0.5),
                fontSize: 8.5,
              ),
              hintText: hints[validOp],
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.18),
                fontSize: 10,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 3),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.4,
            ),
            maxLines: 2,
            minLines: 1,
            controller:
                TextEditingController(
                    text: node.properties['args'] as String? ?? '',
                  )
                  ..selection = TextSelection.collapsed(
                    offset: (node.properties['args'] as String? ?? '').length,
                  ),
            onChanged: (val) => ctr.updateNodeProperty(id, 'args', val),
          ),
        ),
      ],
    );
  }

  Widget _noteBody() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(),
      child: TextField(
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Enter your note here...",
          hintStyle: TextStyle(color: Colors.white24, fontSize: 10),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 11),
        maxLines: null,
        controller: TextEditingController(
          text: node.properties['text'] as String? ?? '',
        ),
        onChanged: (val) => ctr.updateNodeProperty(id, 'text', val),
      ),
    );
  }

  // ── Ports ─────────────────────────────────────────────────────────────────

  Widget _inPort() {
    final isData = node.type == 30 || node.type == 31;
    final pColor = isData ? AppColors.neonAmber : AppColors.neonCyan;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pColor.withValues(alpha: 0.15),
        border: Border.all(color: pColor, width: 2),
      ),
    );
  }

  Widget _buildOutPorts() {
    if (node.type == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _portDot(AppColors.neonCyan, 'true', 'T'),
          const SizedBox(height: 8),
          _portDot(AppColors.neonMagenta, 'false', 'F'),
        ],
      );
    }
    final isData = node.type == 30 || node.type == 31;
    final pColor = isData ? AppColors.neonAmber : AppColors.neonCyan;
    return _portDot(pColor, 'default', null);
  }

  Widget _portDot(Color c, String portId, String? label) {
    return Draggable<String>(
      data: id,
      feedback: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
      onDragStarted: () => ctr.startConnect(id, portId),
      onDragUpdate: (d) {
        final box = canvasKey.currentContext!.findRenderObject() as RenderBox;
        ctr.dragPosition.value = box.globalToLocal(d.globalPosition);
      },
      onDragEnd: (_) => ctr.cancelDrag(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label,
                style: TextStyle(
                  color: c.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.2),
                border: Border.all(color: c, width: 2),
                boxShadow: [
                  BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Node-specific controls
          if (node.type == 31) _localVarBody(),
          if (node.type == 30) _setVarBody(),
          if (node.type == 4) _ifBody(),
          if (node.type == 10) _inputKeyBody(),
          if (node.type == 40) _transformBody(),
          if (node.type == 99) _noteBody(),
          if (node.type == 100)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "Group Box (Organization)",
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ),
            ),
          if (node.type != 31 &&
              node.type != 30 &&
              node.type != 4 &&
              node.type != 10 &&
              node.type != 40 &&
              node.type != 99 &&
              node.type != 100)
            const SizedBox(height: 20),

          const SizedBox(height: 4),

          // Port row: input on left, output(s) on right
          if (node.type != 99) // Notes don't have ports
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isEventNode) _inPort() else const SizedBox(width: 11),
                const Spacer(),
                _buildOutPorts(),
              ],
            ),
        ],
      ),
    );
  }
}
