import 'package:node_flow_x/features/editor/models/node_model.dart';
import 'package:node_flow_x/features/editor/models/variable_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// مولّد أكواد Unity (UnityCodeGenerator)
//
// الوظيفة:
//   يقوم بتحويل النودات والروابط المرئية إلى كود C# حقيقي 
//   جاهز للاستخدام مباشرة داخل سكربت MonoBehaviour في Unity.
//
// طريقة العمل:
//   1. يكتب مكتبات using في الأعلى.
//   2. يعرّف الكلاس والمتغيرات العامة/الخاصة (من scriptVariables).
//   3. يبحث عن نودات البداية OnStart (نوع 0) ويولد دالة void Start() { … }.
//   4. يبحث عن نودات التحديث OnUpdate (نوع 1) ويولد دالة void Update() { … }.
//   5. تمر دالة _writeActions() على الروابط وتكتب أكواد الـ C# المناسبة لكل نود.
// ════════════════════════════════════════════════════════════════════════════
class UnityCodeGenerator {
  // ── Public entry point ────────────────────────────────────────────────────
  static String generate(
    Map<String, NodeModel> graphData,
    List<Map<String, String>> connections, {
    String className = 'GeneratedScript',
    List<String> namespaces = const ['UnityEngine'],
    List<VariableModel> variables = const [],
  }) {
    final sb = StringBuffer();

    // 1. استدعاء المكاتب (using directives) ──────────────────────────────────
    for (final ns in namespaces) {
      sb.writeln('using $ns;');
    }
    sb.writeln('');

    // 2. تعريف الكلاس ────────────────────────────────────────────────────────
    sb.writeln('public class $className : MonoBehaviour {');

    // 3. تعريف المتغيرات (عبر نافذة Variables) ───────────────────────────────
    for (final v in variables) {
      String decl = '    ${v.access} ${v.type} ${v.name}';
      if (v.defaultValue.isNotEmpty) {
        String val = v.defaultValue;
        if (v.type == 'string' && !val.startsWith('"')) val = '"$val"';
        decl += ' = $val';
      }
      sb.writeln('$decl;');
    }
    sb.writeln('');

    // 4. دالة Start() ─ تمر على نودات OnStart ───────────────────────────────
    for (final n in graphData.values) {
      if (n.type == 0) {
        sb.writeln('    void Start() {');
        _writeActions(sb, n.id, '        ', 'default', graphData, connections);
        sb.writeln('    }\n');
      }
    }

    // 5. دالة Update() ─ تمر على نودات OnUpdate ─────────────────────────────
    for (final n in graphData.values) {
      if (n.type == 1) {
        sb.writeln('    void Update() {');
        _writeActions(sb, n.id, '        ', 'default', graphData, connections);
        sb.writeln('    }\n');
      }
    }

    sb.writeln('}');
    return sb.toString();
  }

  // ── دالة خاصة: تمر على النودات بشكل متسلسل وتولد الكود لكل نود ─────────────
  //
  //  sb          → حافظة النصوص التي يتم بناء الكود بداخلها
  //  from        → معرّف (ID) النود الذي نتحقق من مخرجاته
  //  indent      → مسافات الترتيب والمسافات البادئة
  //  port        → مسار المخرج المطلوب اتباعه: "default", "true", أو "false"
  //  graphData   → جميع النودات الموجودة في المحرر
  //  connections → جميع الروابط بين النودات
  static void _writeActions(
    StringBuffer sb,
    String from,
    String indent,
    String port,
    Map<String, NodeModel> graphData,
    List<Map<String, String>> connections,
  ) {
    for (final c in connections) {
      // Only follow connections that leave the correct port of `from`
      if (c['from'] != from || c['fromPort'] != port) continue;

      final toNode = graphData[c['to']];
      if (toNode == null) continue;

      // ── Emit the correct C# statement(s) for this node type ─────────────
      switch (toNode.type) {

        // ────────────────────────────────────────────────────────────────────
        // LOGIC NODES
        // ────────────────────────────────────────────────────────────────────

        case 4: // If / Else Branch
          //   if (condition) { … } else { … }
          final cond = toNode.properties['condition'] ?? 'true';
          sb.writeln('$indent if ($cond) {');
          _writeActions(sb, toNode.id, '$indent    ', 'true',  graphData, connections);
          sb.writeln('$indent } else {');
          _writeActions(sb, toNode.id, '$indent    ', 'false', graphData, connections);
          sb.writeln('$indent }');
          break;

        case 10: // Input.GetKey check
          //   if (Input.GetKey(KeyCode.W)) { … }
          final key = toNode.properties['key'] ?? 'W';
          sb.writeln('$indent if (Input.GetKey(KeyCode.$key)) {');
          _writeActions(sb, toNode.id, '$indent    ', 'default', graphData, connections);
          sb.writeln('$indent }');
          break;

        // ────────────────────────────────────────────────────────────────────
        // DATA NODES
        // ────────────────────────────────────────────────────────────────────

        case 31: // Declare Local Variable
          //   float myVar = 0f;
          final varType = toNode.properties['varType']      ?? 'float';
          final varName = toNode.properties['varName']      ?? 'myVar';
          final initVal = toNode.properties['initialValue'] ?? '0';
          final safeVal = (varType == 'string' && !initVal.startsWith('"'))
              ? '"$initVal"'
              : initVal;
          sb.writeln('$indent $varType $varName = $safeVal;');
          // Continue the sequence inline (the var is in scope for the rest)
          _writeActions(sb, toNode.id, indent, 'default', graphData, connections);
          break;

        case 30: // Set Variable
          //   myVar += newValue;   (operator chosen by user: =, +=, -=, *=, /=)
          final selVar = toNode.properties['selectedVar'] ?? '';
          final newVal = toNode.properties['newValue']    ?? '0';
          final op     = toNode.properties['operator']   ?? '=';
          if (selVar.isNotEmpty) {
            sb.writeln('$indent $selVar $op $newVal;');
          }
          break;

        // ── TRANSFORM ────────────────────────────────────────────────────────
        case 40: // Single unified Transform node
          // Emits:  transform.Translate(args);  /  transform.Rotate(args);  etc.
          final tfOp   = toNode.properties['operation'] ?? 'Translate';
          final tfArgs = toNode.properties['args']      ?? '';
          sb.writeln('$indent transform.$tfOp($tfArgs);');
          break;

        // ────────────────────────────────────────────────────────────────────
        // PHYSICS / COMPONENT NODES
        // ────────────────────────────────────────────────────────────────────

        case 11: // Add Force (Rigidbody)
          sb.writeln('$indent GetComponent<Rigidbody>().AddForce(Vector3.up * 500f);');
          break;

        case 12: // Play Audio
          sb.writeln('$indent GetComponent<AudioSource>().Play();');
          break;

        case 13: // Destroy this GameObject
        case 53:
          sb.writeln('$indent Destroy(gameObject);');
          break;

        case 50: // Print
          final msg = toNode.properties['message'] ?? '"Hello World!"';
          sb.writeln('$indent Debug.Log($msg);');
          break;

        case 51: // Get Node/Component
          final comp = toNode.properties['nodePath'] ?? 'GetComponent<SpriteRenderer>()';
          sb.writeln('$indent var comp = $comp;');
          break;

        case 52: // Move & Slide / Move
          sb.writeln('$indent // Implement CharacterController.Move or Rigidbody movement here');
          break;

        // ────────────────────────────────────────────────────────────────────
        // MATH NODES (placeholder — connect output to Set Variable)
        // ────────────────────────────────────────────────────────────────────
        default:
          if (toNode.type >= 6 && toNode.type <= 9) {
            final mathOp = ['+', '-', '*', '/'][toNode.type - 6];
            sb.writeln('$indent // Math ($mathOp) — wire this into a Set Variable node');
          }
      }

      // ── Continue the sequence for non-branching nodes ────────────────────
      // Branching nodes (If=4, InputKey=10) already recurse into their own
      // children above, so we skip the generic continuation for them.
      // Declare Var (31) also continues inline, so skip it here too.
      final isBranching      = toNode.type == 4 || toNode.type == 10;
      final alreadyContinued = toNode.type == 31;
      if (!isBranching && !alreadyContinued) {
        _writeActions(sb, toNode.id, indent, 'default', graphData, connections);
      }
    }
  }

  // ── Helper: format a numeric string as a C# float literal ────────────────
  //
  // Examples:
  //   "1"           → "1f"
  //   "1.5"         → "1.5f"
  //   "1f"          → "1f"   (already has suffix)
  //   "Time.deltaTime" → "Time.deltaTime"  (not a plain number, leave as-is)
  static String f(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return '0f';
    if (trimmed.endsWith('f') || trimmed.contains(RegExp(r'[a-zA-Z]'))) {
      return trimmed; // already formatted or is an expression
    }
    return '${trimmed}f';
  }
}
