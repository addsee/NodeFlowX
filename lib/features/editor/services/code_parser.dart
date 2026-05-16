import 'package:node_flow_x/features/editor/models/node_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// CodeParser — محلل الكود العكسي (Code-to-Graph)
//
// الوظيفة:
//   يقوم بتحليل كود C# أو GDScript المُدخَل من المستخدم واستخراج الأنماط
//   (Patterns) الشائعة وتحويلها إلى نودات (Nodes) وتوصيلات (Connections).
//
// القيود:
//   هذا المحلل يتعرف على الأنماط المشابهة للنودات الموجودة في التطبيق فقط.
//   الأكواد المعقدة جداً (مثل Lambda) ستُتجاهل بأمان.
// ════════════════════════════════════════════════════════════════════════════

/// نتيجة التحليل — تحتوي على قائمة النودات المكتشفة وتوصيلاتها
class ParseResult {
  /// النودات المكتشفة من الكود
  final List<NodeModel> nodes;

  /// التوصيلات بين النودات
  final List<Map<String, String>> connections;

  /// رسائل للمستخدم تصف ما تم اكتشافه
  final List<String> messages;

  const ParseResult({
    required this.nodes,
    required this.connections,
    required this.messages,
  });

  bool get isEmpty => nodes.isEmpty;
}

// ════════════════════════════════════════════════════════════════════════════
// الكلاس الرئيسي للمحلل
// ════════════════════════════════════════════════════════════════════════════
class CodeParser {
  // ── نقطة الدخول الرئيسية ─────────────────────────────────────────────────
  /// يحلل الكود ويعيد نتيجة تحتوي على النودات والتوصيلات.
  /// [code] الكود المُدخَل من المستخدم
  /// [engine] المحرك المستخدم: 'Unity' أو 'Godot'
  static ParseResult parse(String code, String engine) {
    if (engine == 'Godot') {
      return _parseGdScript(code);
    } else {
      return _parseCSharp(code);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // محلل C# (Unity)
  // ══════════════════════════════════════════════════════════════════════════
  static ParseResult _parseCSharp(String code) {
    final nodes = <NodeModel>[];
    final connections = <Map<String, String>>[];
    final messages = <String>[];

    // تقسيم الكود إلى أسطر ونظّفها
    final lines = code.split('\n').map((l) => l.trim()).toList();

    String? currentEventId;  // معرّف الحدث الحالي (Start أو Update)
    String? lastNodeId;       // آخر نود تمت إضافته (لربط التوصيلات)
    String? pendingIfId;      // نود If/Else في انتظار أبنائه

    // ── تعابير RegEx للتعرف على الأنماط ──────────────────────────────────
    final reStart    = RegExp(r'void\s+Start\s*\(\s*\)');
    final reUpdate   = RegExp(r'void\s+Update\s*\(\s*\)');
    final reInputKey = RegExp(r'Input\.GetKey\s*\(\s*KeyCode\.(\w+)\s*\)');
    final reIfSimple = RegExp(r'^if\s*\((.+)\)\s*\{?$');
    final reTranslate = RegExp(r'transform\.(Translate|Rotate|LookAt|SetPosition)\s*\((.+?)\)');
    final reLog      = RegExp(r'Debug\.Log\s*\((.+)\)');
    final rePrint    = RegExp(r'\bprint\s*\((.+)\)');
    final reDestroy  = RegExp(r'Destroy\s*\(');
    final reVarDecl  = RegExp(r'^(?:public|private|protected)?\s*(?:var|int|float|string|bool|double|Vector3)\s+(\w+)\s*=\s*(.+?)\s*;');
    final reVarSet   = RegExp(r'^(\w+)\s*(\+|-|\*|\/)?=(?!=)\s*(.+?)\s*;');
    final reFuncClose = RegExp(r'^\}');

    int depth = 0; // عمق الأقواس الحالي

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty || line.startsWith('//') || line.startsWith('using ') || line.startsWith('public class')) continue;

      // --- اكتشاف void Start() ---
      if (reStart.hasMatch(line)) {
        currentEventId = _makeId();
        lastNodeId = currentEventId;
        pendingIfId = null;
        depth = 0;
        nodes.add(_makeNode(currentEventId, 0, 'On Start', {}));
        messages.add('✅ اكتُشفت دالة Start()');
        continue;
      }

      // --- اكتشاف void Update() ---
      if (reUpdate.hasMatch(line)) {
        currentEventId = _makeId();
        lastNodeId = currentEventId;
        pendingIfId = null;
        depth = 0;
        nodes.add(_makeNode(currentEventId, 1, 'On Update', {}));
        messages.add('✅ اكتُشفت دالة Update()');
        continue;
      }

      // تتبع عمق الأقواس
      depth += '{'.allMatches(line).length - '}'.allMatches(line).length;
      if (depth < 0) depth = 0;

      // --- إغلاق الدالة الرئيسية ---
      if (reFuncClose.hasMatch(line) && depth == 0) {
        currentEventId = null;
        lastNodeId = null;
        pendingIfId = null;
        continue;
      }

      if (currentEventId == null) continue; // خارج دالة معروفة

      // --- اكتشاف Input.GetKey ---
      final mInput = reInputKey.firstMatch(line);
      if (mInput != null) {
        final id = _makeId();
        final key = mInput.group(1) ?? 'W';
        nodes.add(_makeNode(id, 10, 'Input Key', {'key': key}));
        _connect(connections, lastNodeId, id);
        lastNodeId = id;
        pendingIfId = id;
        messages.add('✅ اكتُشف مفتاح إدخال: $key');
        continue;
      }

      // --- اكتشاف if بشكل عام ---
      final mIf = reIfSimple.firstMatch(line);
      if (mIf != null && pendingIfId == null) {
        final id = _makeId();
        final cond = mIf.group(1) ?? 'true';
        nodes.add(_makeNode(id, 4, 'If', {'condition': cond}));
        _connect(connections, lastNodeId, id);
        lastNodeId = id;
        pendingIfId = id;
        messages.add('✅ اكتُشف شرط if');
        continue;
      }

      // --- اكتشاف Transform ---
      final mTf = reTranslate.firstMatch(line);
      if (mTf != null) {
        final id = _makeId();
        final op   = mTf.group(1) ?? 'Translate';
        final args = mTf.group(2) ?? '';
        nodes.add(_makeNode(id, 40, 'Transform', {'operation': op, 'args': args}));
        _connect(connections, lastNodeId, id, port: pendingIfId != null ? 'true' : 'default');
        lastNodeId = id;
        pendingIfId = null;
        messages.add('✅ اكتُشف Transform.$op');
        continue;
      }

      // --- اكتشاف Debug.Log أو print ---
      final mLog = reLog.firstMatch(line) ?? rePrint.firstMatch(line);
      if (mLog != null) {
        final id = _makeId();
        final msg = mLog.group(1) ?? '"Hello"';
        nodes.add(_makeNode(id, 50, 'Print', {'message': msg}));
        _connect(connections, lastNodeId, id, port: pendingIfId != null ? 'true' : 'default');
        lastNodeId = id;
        pendingIfId = null;
        messages.add('✅ اكتُشف طباعة: $msg');
        continue;
      }

      // --- اكتشاف Destroy ---
      if (reDestroy.hasMatch(line)) {
        final id = _makeId();
        nodes.add(_makeNode(id, 53, 'Destroy', {}));
        _connect(connections, lastNodeId, id, port: pendingIfId != null ? 'true' : 'default');
        lastNodeId = id;
        pendingIfId = null;
        messages.add('✅ اكتُشف Destroy');
        continue;
      }

      // --- اكتشاف إعلان متغير (var x = 0;) ---
      final mVarDecl = reVarDecl.firstMatch(line);
      if (mVarDecl != null) {
        final id = _makeId();
        final name = mVarDecl.group(1) ?? 'myVar';
        final val  = mVarDecl.group(2) ?? '0';
        // استنتاج النوع
        String vType = 'float';
        if (val == 'true' || val == 'false') {
          vType = 'bool';
        } else if (val.startsWith('"')) {
          vType = 'string';
        } else if (val.contains('.')) {
          vType = 'float';
        } else if (int.tryParse(val) != null) {
          vType = 'int';
        }
        nodes.add(_makeNode(id, 31, 'Local Var', {'varName': name, 'varType': vType, 'initialValue': val}));
        _connect(connections, lastNodeId, id);
        lastNodeId = id;
        messages.add('✅ اكتُشف متغير: $name = $val');
        continue;
      }

      // --- اكتشاف إسناد متغير (x = 5;) ---
      final mVarSet = reVarSet.firstMatch(line);
      if (mVarSet != null) {
        final name = mVarSet.group(1) ?? '';
        final opSuffix = mVarSet.group(2) ?? '';
        final val  = mVarSet.group(3) ?? '0';
        // تجاهل الكلمات المحجوزة
        if (!['return', 'var', 'int', 'float', 'bool', 'string', 'if', 'else'].contains(name)) {
          final id = _makeId();
          final op = opSuffix.isEmpty ? '=' : '$opSuffix=';
          nodes.add(_makeNode(id, 30, 'Set Variable', {'selectedVar': name, 'newValue': val, 'operator': op}));
          _connect(connections, lastNodeId, id);
          lastNodeId = id;
          messages.add('✅ اكتُشف إسناد: $name $op $val');
        }
        continue;
      }
    }

    return ParseResult(nodes: nodes, connections: connections, messages: messages);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // محلل GDScript (Godot)
  // ══════════════════════════════════════════════════════════════════════════
  static ParseResult _parseGdScript(String code) {
    final nodes     = <NodeModel>[];
    final connections = <Map<String, String>>[];
    final messages  = <String>[];

    final lines = code.split('\n').toList();

    String? currentEventId;
    String? lastNodeId;
    String? pendingIfId;

    final reReady    = RegExp(r'^func\s+_ready\s*\(\s*\)\s*:');
    final reProcess  = RegExp(r'^func\s+_process\s*\(.*\)\s*:');
    final reInput    = RegExp(r'Input\.is_action_pressed\s*\(\s*"(.+?)"\s*\)');
    final reIf       = RegExp(r'^(\s*)if\s+(.+?)\s*:');
    final rePrint    = RegExp(r'print\s*\((.+)\)');
    final reTranslate = RegExp(r'(translate|rotate|look_at|global_translate)\s*\((.+?)\)');
    final reMoveSlide = RegExp(r'move_and_slide\s*\(');
    final reQueueFree = RegExp(r'queue_free\s*\(');
    final reGetNode  = RegExp(r'get_node\s*\(\s*"(.+?)"\s*\)');
    final reVarDecl  = RegExp(r'^(\s*)var\s+(\w+)\s*(?::\s*\w+)?\s*=\s*(.+)');
    final reVarSet   = RegExp(r'^(\s*)(\w+)\s*(\+|-|\*|\/)?=(?!=)\s*(.+)');
    final reFuncDecl = RegExp(r'^func\s+\w+');

    for (int i = 0; i < lines.length; i++) {
      final raw  = lines[i];
      final line = raw.trimLeft();
      final indent = raw.length - line.length;

      if (line.isEmpty || line.startsWith('#')) continue;

      // إغلاق الدالة عند العودة لمستوى العنصر الرئيسي
      if (currentEventId != null && reFuncDecl.hasMatch(line) && indent == 0) {
        currentEventId = null;
        lastNodeId = null;
        pendingIfId = null;
      }

      // --- func _ready(): ---
      if (reReady.hasMatch(line)) {
        currentEventId = _makeId();
        lastNodeId = currentEventId;
        pendingIfId = null;
        nodes.add(_makeNode(currentEventId, 0, '_ready', {}));
        messages.add('✅ اكتُشفت دالة _ready()');
        continue;
      }

      // --- func _process(delta): ---
      if (reProcess.hasMatch(line)) {
        currentEventId = _makeId();
        lastNodeId = currentEventId;
        pendingIfId = null;
        nodes.add(_makeNode(currentEventId, 1, '_process', {}));
        messages.add('✅ اكتُشفت دالة _process()');
        continue;
      }

      if (currentEventId == null) continue;

      // --- Input.is_action_pressed ---
      final mInput = reInput.firstMatch(line);
      if (mInput != null) {
        final id  = _makeId();
        final key = mInput.group(1) ?? 'ui_accept';
        nodes.add(_makeNode(id, 10, 'Input Action', {'key': key}));
        _connect(connections, lastNodeId, id);
        lastNodeId = id;
        pendingIfId = id;
        messages.add('✅ اكتُشف إدخال: $key');
        continue;
      }

      // --- if condition: ---
      final mIf = reIf.firstMatch(raw);
      if (mIf != null && pendingIfId == null) {
        final id   = _makeId();
        final cond = mIf.group(2) ?? 'true';
        nodes.add(_makeNode(id, 4, 'If', {'condition': cond}));
        _connect(connections, lastNodeId, id);
        lastNodeId = id;
        pendingIfId = id;
        messages.add('✅ اكتُشف شرط if: $cond');
        continue;
      }

      // --- print(...) ---
      final mPrint = rePrint.firstMatch(line);
      if (mPrint != null) {
        final id  = _makeId();
        final msg = mPrint.group(1) ?? '"Hello"';
        nodes.add(_makeNode(id, 50, 'Print', {'message': msg}));
        _connect(connections, lastNodeId, id, port: pendingIfId != null ? 'true' : 'default');
        lastNodeId = id;
        pendingIfId = null;
        messages.add('✅ اكتُشف print: $msg');
        continue;
      }

      // --- translate / rotate ---
      final mTf = reTranslate.firstMatch(line);
      if (mTf != null) {
        final id   = _makeId();
        final op   = mTf.group(1) ?? 'translate';
        final args = mTf.group(2) ?? '';
        nodes.add(_makeNode(id, 40, 'Transform', {'operation': op, 'args': args}));
        _connect(connections, lastNodeId, id, port: pendingIfId != null ? 'true' : 'default');
        lastNodeId = id;
        pendingIfId = null;
        messages.add('✅ اكتُشف Transform: $op($args)');
        continue;
      }

      // --- move_and_slide() ---
      if (reMoveSlide.hasMatch(line)) {
        final id = _makeId();
        nodes.add(_makeNode(id, 52, 'Move & Slide', {}));
        _connect(connections, lastNodeId, id, port: pendingIfId != null ? 'true' : 'default');
        lastNodeId = id;
        pendingIfId = null;
        messages.add('✅ اكتُشف move_and_slide()');
        continue;
      }

      // --- queue_free() ---
      if (reQueueFree.hasMatch(line)) {
        final id = _makeId();
        nodes.add(_makeNode(id, 53, 'Queue Free', {}));
        _connect(connections, lastNodeId, id, port: pendingIfId != null ? 'true' : 'default');
        lastNodeId = id;
        pendingIfId = null;
        messages.add('✅ اكتُشف queue_free()');
        continue;
      }

      // --- get_node("...") ---
      final mGetNode = reGetNode.firstMatch(line);
      if (mGetNode != null) {
        final id   = _makeId();
        final path = mGetNode.group(1) ?? '\$Node';
        nodes.add(_makeNode(id, 51, 'Get Node', {'nodePath': path}));
        _connect(connections, lastNodeId, id);
        lastNodeId = id;
        messages.add('✅ اكتُشف get_node: $path');
        continue;
      }

      // --- var x = value ---
      final mVarDecl = reVarDecl.firstMatch(raw);
      if (mVarDecl != null) {
        final id   = _makeId();
        final name = mVarDecl.group(2) ?? 'myVar';
        final val  = mVarDecl.group(3)?.trim() ?? '0';
        String vType = 'float';
        if (val == 'true' || val == 'false') {
          vType = 'bool';
        } else if (val.startsWith('"')) {
          vType = 'string';
        } else if (val.contains('.')) {
          vType = 'float';
        }
        nodes.add(_makeNode(id, 31, 'Local Var', {'varName': name, 'varType': vType, 'initialValue': val}));
        _connect(connections, lastNodeId, id);
        lastNodeId = id;
        messages.add('✅ اكتُشف متغير: $name = $val');
        continue;
      }

      // --- x = value / x += value ---
      final mVarSet = reVarSet.firstMatch(raw);
      if (mVarSet != null) {
        final name = mVarSet.group(2) ?? '';
        final opS  = mVarSet.group(3) ?? '';
        final val  = mVarSet.group(4)?.trim() ?? '0';
        if (!['return', 'var', 'if', 'elif', 'else', 'for', 'while'].contains(name)) {
          final id = _makeId();
          final op = opS.isEmpty ? '=' : '$opS=';
          nodes.add(_makeNode(id, 30, 'Set Variable', {'selectedVar': name, 'newValue': val, 'operator': op}));
          _connect(connections, lastNodeId, id);
          lastNodeId = id;
          messages.add('✅ اكتُشف إسناد: $name $op $val');
        }
        continue;
      }
    }

    return ParseResult(nodes: nodes, connections: connections, messages: messages);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ══════════════════════════════════════════════════════════════════════════

  /// توليد معرّف فريد للنود
  static String _makeId() => 'imp_${DateTime.now().microsecondsSinceEpoch}';

  /// إنشاء نود جديد
  static NodeModel _makeNode(String id, int type, String title, Map<String, dynamic> props) {
    return NodeModel(id: id, type: type, title: title, x: 0, y: 0, properties: props);
  }

  /// إضافة توصيل من نود لآخر
  static void _connect(
    List<Map<String, String>> connections,
    String? from,
    String to, {
    String port = 'default',
  }) {
    if (from == null) return;
    connections.add({'from': from, 'fromPort': port, 'to': to});
  }
}
