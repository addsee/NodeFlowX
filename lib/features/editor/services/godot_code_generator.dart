import 'package:node_flow_x/features/editor/models/node_model.dart';
import 'package:node_flow_x/features/editor/models/variable_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// مولّد أكواد Godot (GodotCodeGenerator)
//
// الوظيفة:
//   يقوم بتحويل النودات والروابط المرئية إلى كود GDScript حقيقي 
//   جاهز للاستخدام مباشرة في محرك Godot.
// ════════════════════════════════════════════════════════════════════════════
class GodotCodeGenerator {
  static String generate(
    Map<String, NodeModel> graphData,
    List<Map<String, String>> connections, {
    String className = 'GeneratedScript',
    List<String> namespaces = const [], // not really used in GDScript the same way
    List<VariableModel> variables = const [],
  }) {
    final sb = StringBuffer();

    // 1. تعريف الكلاس (في جودو نستخدم extends Node)
    sb.writeln('extends Node');
    if (className.isNotEmpty && className != 'GeneratedScript') {
      sb.writeln('class_name $className');
    }
    sb.writeln('');

    // 2. المتغيرات (متغيرات عامة أو خاصة)
    for (final v in variables) {
      String varType = '';
      if (v.type == 'int') varType = ': int';
      if (v.type == 'float') varType = ': float';
      if (v.type == 'string') varType = ': String';
      if (v.type == 'bool') varType = ': bool';

      String decl = 'var ${v.name}$varType';
      if (v.access == 'public') {
        decl = '@export $decl';
      }
      
      if (v.defaultValue.isNotEmpty) {
        String val = v.defaultValue;
        if (v.type == 'string' && !val.startsWith('"') && !val.startsWith("'")) {
          val = '"$val"';
        }
        decl += ' = $val';
      }
      sb.writeln(decl);
    }
    sb.writeln('');

    // 3. دالة البداية _ready() ─ تمر على جميع نودات البدء (نوع 0)
    bool hasReady = graphData.values.any((n) => n.type == 0);
    if (hasReady) {
      sb.writeln('func _ready():');
      for (final n in graphData.values.where((n) => n.type == 0)) {
        bool wroteAny = _writeActions(sb, n.id, '\t', 'default', graphData, connections);
        if (!wroteAny) {
          sb.writeln('\tpass');
        }
      }
      sb.writeln('');
    }

    // 4. دالة التحديث _process(delta) ─ تمر على جميع نودات التحديث (نوع 1)
    bool hasProcess = graphData.values.any((n) => n.type == 1);
    if (hasProcess) {
      sb.writeln('func _process(delta):');
      for (final n in graphData.values.where((n) => n.type == 1)) {
        bool wroteAny = _writeActions(sb, n.id, '\t', 'default', graphData, connections);
        if (!wroteAny) {
          sb.writeln('\tpass');
        }
      }
      sb.writeln('');
    }

    return sb.toString();
  }

  // هذه الدالة تمر عبر الروابط وتكتب الأكواد للنودات المرتبطة
  // تعيد true إذا قامت بكتابة أي كود فعلي
  static bool _writeActions(
    StringBuffer sb,
    String from,
    String indent,
    String port,
    Map<String, NodeModel> graphData,
    List<Map<String, String>> connections,
  ) {
    bool wroteLines = false;
    
    for (final c in connections) {
      if (c['from'] != from || c['fromPort'] != port) continue;

      final toNode = graphData[c['to']];
      if (toNode == null) continue;

      switch (toNode.type) {
        // LOGIC NODES
        case 4: // If / Else Branch
          final cond = toNode.properties['condition'] ?? 'true';
          sb.writeln('${indent}if $cond:');
          wroteLines = true;
          bool wroteTrue = _writeActions(sb, toNode.id, '$indent\t', 'true',  graphData, connections);
          if (!wroteTrue) sb.writeln('$indent\tpass');
          
          sb.writeln('${indent}else:');
          bool wroteFalse = _writeActions(sb, toNode.id, '$indent\t', 'false', graphData, connections);
          if (!wroteFalse) sb.writeln('$indent\tpass');
          break;

        case 10: // Input Key
          final key = toNode.properties['key'] ?? 'ui_accept'; // Default to a godot action map
          // In Godot, you usually check actions like: Input.is_action_pressed("ui_accept")
          sb.writeln('${indent}if Input.is_action_pressed("$key"):');
          wroteLines = true;
          bool wroteInput = _writeActions(sb, toNode.id, '$indent\t', 'default', graphData, connections);
          if (!wroteInput) sb.writeln('$indent\tpass');
          break;

        // DATA NODES
        case 31: // Declare Local Variable
          final varName = toNode.properties['varName'] ?? 'my_var';
          final initVal = toNode.properties['initialValue'] ?? '0';
          final varType = toNode.properties['varType'] ?? 'float';
          final safeVal = (varType == 'string' && !initVal.startsWith('"')) ? '"$initVal"' : initVal;
          sb.writeln('${indent}var $varName = $safeVal');
          wroteLines = true;
          _writeActions(sb, toNode.id, indent, 'default', graphData, connections);
          break;

        case 30: // Set Variable
          final selVar = toNode.properties['selectedVar'] ?? '';
          final newVal = toNode.properties['newValue']    ?? '0';
          final op     = toNode.properties['operator']   ?? '=';
          if (selVar.isNotEmpty) {
            sb.writeln('$indent$selVar $op $newVal');
            wroteLines = true;
          }
          break;

        // TRANSFORM
        case 40:
          final tfOp   = toNode.properties['operation'] ?? 'Translate';
          final tfArgs = toNode.properties['args']      ?? '';
          // Try to map Unity's Translate/Rotate to Godot's translate/rotate
          String godotOp = tfOp.toLowerCase();
          String godotArgs = tfArgs.replaceAll('Vector3.forward', 'Vector3.FORWARD')
                                   .replaceAll('Vector3.up', 'Vector3.UP')
                                   .replaceAll('Vector3.right', 'Vector3.RIGHT')
                                   .replaceAll('Time.deltaTime', 'delta');
          sb.writeln('$indent$godotOp($godotArgs)');
          wroteLines = true;
          break;

        // PHYSICS / COMPONENT NODES
        case 11: // Add Force
          sb.writeln('${indent}apply_central_impulse(Vector3.UP * 500)');
          wroteLines = true;
          break;

        case 12: // Play Audio
          sb.writeln('$indent\$AudioStreamPlayer.play()');
          wroteLines = true;
          break;

        case 50: // Print
          final msg = toNode.properties['message'] ?? '"Hello World!"';
          sb.writeln('${indent}print($msg)');
          wroteLines = true;
          break;

        case 51: // Get Node
          final nodePath = toNode.properties['nodePath'] ?? '\$Sprite';
          sb.writeln('${indent}var node = get_node("$nodePath")');
          wroteLines = true;
          break;

        case 52: // Move & Slide
          sb.writeln('${indent}move_and_slide()');
          wroteLines = true;
          break;

        case 13: // Destroy
        case 53: // Queue Free
          sb.writeln('${indent}queue_free()');
          wroteLines = true;
          break;

        default:
          if (toNode.type >= 6 && toNode.type <= 9) {
            final mathOp = ['+', '-', '*', '/'][toNode.type - 6];
            sb.writeln('$indent# Math ($mathOp) — wire this into a Set Variable node');
            wroteLines = true;
          } else if (toNode.type == 99) { // Note
             final text = toNode.properties['text'] ?? '';
             sb.writeln('$indent# NOTE: $text');
             wroteLines = true;
          }
      }

      final isBranching = toNode.type == 4 || toNode.type == 10;
      final alreadyContinued = toNode.type == 31;
      if (!isBranching && !alreadyContinued) {
        bool nestedWrote = _writeActions(sb, toNode.id, indent, 'default', graphData, connections);
        if (nestedWrote) wroteLines = true;
      }
    }
    
    return wroteLines;
  }
}
