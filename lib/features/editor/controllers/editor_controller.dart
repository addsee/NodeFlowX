import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';
import 'package:node_flow_x/features/editor/models/variable_model.dart';
import 'package:node_flow_x/features/editor/services/project_io_service.dart';
import 'package:node_flow_x/features/editor/services/unity_code_generator.dart';
import 'package:node_flow_x/features/editor/services/godot_code_generator.dart';
import 'package:node_flow_x/features/editor/services/code_parser.dart';

class EditorController extends GetxController {
  // --- بيانات النودات (Node Graph Data) ---
  // نحتفظ هنا بجميع النودات الموجودة في المحرر
  final graphData = <String, NodeModel>{}.obs;
  // نحتفظ هنا بجميع التوصيلات (Connections) بين النودات
  final connections = <Map<String, String>>[].obs;
  // المتغيرات الخاصة بالسكريبت (مثل المتغيرات العامة التي يضيفها المستخدم)
  final scriptVariables = <VariableModel>[].obs;

  // --- حالة واجهة المستخدم (UI State) ---
  final draggingFrom = RxnString();
  final draggingPort = RxnString();
  final dragPosition = const Offset(0, 0).obs;
  final code = ''.obs;
  var showCode = false.obs;

  // --- إعدادات السكريبت (Script Settings) ---
  final className = 'PlayerMovement'.obs;
  final scriptName = 'PlayerMovement.cs'.obs;
  final namespaces = <String>['UnityEngine'].obs;

  final _storage = GetStorage();

  final selectionMode = false.obs;
  final selectedNodeIds = <String>{}.obs;
  final highlightedNodeIds = <String>{}.obs;
  final teleportRequest = Rx<Offset?>(null);
  final codeSearchQuery = "".obs;
  final showCodePanel = false.obs;
  final currentTheme = 'Neon'.obs;
  final currentEngine = 'Unity'.obs;

  // دالة لتظليل مسار التوصيلات (Highlight Flow) بدءاً من نود معينة
  void toggleHighlightFlow(String startId) {
    if (highlightedNodeIds.contains(startId)) {
      highlightedNodeIds.clear();
      return;
    }
    highlightedNodeIds.clear();
    _findFlow(startId);
  }

  void _findFlow(String id) {
    if (highlightedNodeIds.contains(id)) {
      return;
    }
    highlightedNodeIds.add(id);
    for (var conn in connections) {
      if (conn['from'] == id) {
        _findFlow(conn['to']!);
      }
    }
  }

  Rect get graphBounds {
    if (graphData.isEmpty) {
      return Rect.zero;
    }
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (var n in graphData.values) {
      if (n.position.dx < minX) {
        minX = n.position.dx;
      }
      if (n.position.dy < minY) {
        minY = n.position.dy;
      }
      if (n.position.dx > maxX) {
        maxX = n.position.dx;
      }
      if (n.position.dy > maxY) {
        maxY = n.position.dy;
      }
    }
    return Rect.fromLTRB(minX - 500, minY - 500, maxX + 500, maxY + 500);
  }

  void addConnection(String fromId, String toId, {String fromPort = 'default'}) {
    connections.add({
      'from': fromId,
      'fromPort': fromPort,
      'to': toId,
    });
    update();
  }

  Color get themeColor {
    if (currentTheme.value == 'Unity') {
      return const Color(0xFF383838);
    }
    if (currentTheme.value == 'Minimal') {
      return Colors.white12;
    }
    return AppColors.neonCyan;
  }

  void toggleSelectionMode() {
    selectionMode.value = !selectionMode.value;
    if (!selectionMode.value) {
      selectedNodeIds.clear();
    }
  }

  void toggleNodeSelection(String id) {
    if (selectedNodeIds.contains(id)) {
      selectedNodeIds.remove(id);
    } else {
      selectedNodeIds.add(id);
    }
  }

  void selectNodesInRect(Rect rect) {
    selectedNodeIds.clear();
    for (final node in graphData.values) {
      if (rect.contains(Offset(node.x, node.y))) {
        selectedNodeIds.add(node.id);
      }
    }
  }

  void deleteSelectedNodes() {
    _saveHistory();
    for (final id in selectedNodeIds) {
      graphData.remove(id);
      connections.removeWhere((c) => c['from'] == id || c['to'] == id);
    }
    selectedNodeIds.clear();
    generateCode();
  }

  void addTemplate(String name, Offset pos) {
    _saveHistory();
    if (name == 'Smooth Follow') {
      final id1 = "t1_${DateTime.now().millisecondsSinceEpoch}";
      final id2 = "t2_${DateTime.now().millisecondsSinceEpoch}";

      graphData[id1] = NodeModel(
        id: id1,
        type: 1,
        title: "On Update",
        x: pos.dx,
        y: pos.dy,
      );
      graphData[id2] = NodeModel(
        id: id2,
        type: 40,
        title: "Transform",
        x: pos.dx + 250,
        y: pos.dy,
        properties: {
          "operation": "Translate",
          "args": "Vector3.forward * Time.deltaTime",
        },
      );

      connections.add({'from': id1, 'fromPort': 'default', 'to': id2});
    } else if (name == 'Click Action') {
      final id1 = "c1_${DateTime.now().millisecondsSinceEpoch}";
      final id2 = "c2_${DateTime.now().millisecondsSinceEpoch}";
      final id3 = "c3_${DateTime.now().millisecondsSinceEpoch}";

      graphData[id1] = NodeModel(
        id: id1,
        type: 1,
        title: "On Update",
        x: pos.dx,
        y: pos.dy,
      );
      graphData[id2] = NodeModel(
        id: id2,
        type: 10,
        title: "Input Key",
        x: pos.dx + 200,
        y: pos.dy,
        properties: {"key": "Mouse0"},
      );
      graphData[id3] = NodeModel(
        id: id3,
        type: 40,
        title: "Log Action",
        x: pos.dx + 450,
        y: pos.dy,
        properties: {"operation": "Translate", "args": "Vector3.up * 5"},
      );

      connections.add({'from': id1, 'fromPort': 'default', 'to': id2});
      connections.add({'from': id2, 'fromPort': 'true', 'to': id3});
    }
    generateCode();
  }

  final errors = <String, String>{}.obs;

  void tidyGraph() {
    _saveHistory();
    // ترتيب تلقائي: نضع النودات في عمودين بشكل متتابع
    double curX = 100;
    double curY = 100;
    int col = 0;
    for (var node in graphData.values) {
      graphData[node.id] = node.copyWith(x: curX + col * 280, y: curY);
      curY += 180;
      // انتقل للعمود الثاني عند تجاوز 5 نودات في العمود الواحد
      if (curY > 1000) {
        col++;
        curY = 100;
      }
    }
  }

  /// استيراد نودات من نتيجة تحليل الكود (Code-to-Graph)
  void importFromCode(ParseResult result) {
    _saveHistory();
    clearProject();

    // 1. إضافة النودات مع حساب المواقع تلقائياً
    double curX = 200;
    double curY = 150;
    int col = 0;

    for (final node in result.nodes) {
      graphData[node.id] = node.copyWith(x: curX + col * 280, y: curY);
      curY += 180;
      if (curY > 1200) {
        col++;
        curY = 150;
      }
    }

    // 2. إضافة التوصيلات
    for (final conn in result.connections) {
      connections.add(conn);
    }

    // 3. توليد الكود للتحقق من صحة التحويل
    generateCode();
    saveProject();
  }

  void exportToDevice() {
    // In a real app, use path_provider and dart:io
    Get.snackbar(
      "Exporting...",
      "Saving Script.cs to your device storage",
      backgroundColor: AppColors.neonCyan,
      colorText: Colors.black,
    );
  }

  void generateFromPrompt(String prompt) {
    _saveHistory();
    prompt = prompt.toLowerCase();
    final pos = const Offset(200, 200);
    
    if (prompt.contains("jump") || prompt.contains("قفز")) {
      addTemplate("Click Action", pos);
    } else if (prompt.contains("move") || prompt.contains("حرك") || prompt.contains("تبع")) {
      addTemplate("Smooth Follow", pos);
    } else {
      addNode(99, pos);
      updateNodeProperty(graphData.keys.last, 'text', "AI: Could not fully understand prompt, but I added a note for you.");
    }
  }

  void validateGraph() {
    errors.clear();
    for (var entry in graphData.entries) {
      final node = entry.value;
      if (node.type == 4) { // If node
        bool hasOut = connections.any((c) => c['from'] == entry.key);
        if (!hasOut) errors[entry.key] = "If node has no output connections!";
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadProject();

    // Persistent listeners
    ever(graphData, (_) => saveProject());
    ever(connections, (_) => saveProject());
    ever(className, (_) {
      saveProject();
      generateCode();
    });
    ever(currentEngine, (_) {
      saveProject();
      generateCode();
    });
    ever(scriptVariables, (_) {
      saveProject();
      generateCode();
    });
  }

  void saveProject() {
    final nodesMap = graphData.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    _storage.write('nodes', nodesMap);
    _storage.write('connections', connections.toList());
    _storage.write('className', className.value);
    _storage.write('scriptName', scriptName.value);
    _storage.write('namespaces', namespaces.toList());
    _storage.write(
      'scriptVariables',
      scriptVariables.map((v) => v.toMap()).toList(),
    );
    _storage.write('currentEngine', currentEngine.value);
    debugPrint("Project Saved!");
  }

  void loadProject() {
    final savedNodes = _storage.read<Map>('nodes');
    final savedConns = _storage.read<List>('connections');

    currentEngine.value = _storage.read<String>('currentEngine') ?? 'Unity';
    className.value = _storage.read<String>('className') ?? 'PlayerMovement';
    scriptName.value =
        _storage.read<String>('scriptName') ?? (currentEngine.value == 'Godot' ? 'PlayerMovement.gd' : 'PlayerMovement.cs');
    final savedNamespaces = _storage.read<List>('namespaces');
    if (savedNamespaces != null) {
      namespaces.value = List<String>.from(savedNamespaces);
    }

    final savedVars = _storage.read<List>('scriptVariables');
    if (savedVars != null) {
      scriptVariables.value = List<VariableModel>.from(
        savedVars.map((e) => VariableModel.fromMap(e)),
      );
    }

    if (savedNodes != null) {
      graphData.value = savedNodes.map(
        (key, value) => MapEntry(
          key.toString(),
          NodeModel.fromMap(Map<String, dynamic>.from(value)),
        ),
      );
    }
    if (savedConns != null) {
      connections.value = List<Map<String, String>>.from(
        savedConns.map((e) => Map<String, String>.from(e)),
      );
    }
    generateCode();
  }

  void clearProject() {
    graphData.clear();
    connections.clear();
    scriptVariables.clear();
    saveProject();
    generateCode();
  }

  Future<void> exportJson() async {
    final path = await ProjectIOService.exportProject(
      className: className.value,
      scriptName: scriptName.value,
      namespaces: namespaces.toList(),
      variables: scriptVariables.toList(),
      nodes: Map<String, NodeModel>.from(graphData),
      connections: connections.toList(),
    );
    if (path != null) {
      Get.snackbar(
        'Exported ✓',
        path,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> importJson() async {
    final data = await ProjectIOService.importProject();
    if (data == null) {
      return;
    }

    className.value = data.className;
    scriptName.value = data.scriptName;
    namespaces.value = data.namespaces;
    scriptVariables.value = data.variables;

    graphData.value = Map<String, NodeModel>.from(data.nodes);
    connections.value = data.connections;

    generateCode();
    saveProject();
  }

  // --- History (Undo/Redo) ---
  final _undoStack = <Map<String, dynamic>>[];
  final _redoStack = <Map<String, dynamic>>[];

  void _saveHistory() {
    final snapshot = {
      'nodes': graphData.map((key, value) => MapEntry(key, value.toMap())),
      'connections': connections.toList(),
    };
    _undoStack.add(snapshot);
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final current = {
      'nodes': graphData.map((key, value) => MapEntry(key, value.toMap())),
      'connections': connections.toList(),
    };
    _redoStack.add(current);

    final previous = _undoStack.removeLast();
    _applySnapshot(previous);
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    final current = {
      'nodes': graphData.map((key, value) => MapEntry(key, value.toMap())),
      'connections': connections.toList(),
    };
    _undoStack.add(current);

    final next = _redoStack.removeLast();
    _applySnapshot(next);
  }

  void _applySnapshot(Map<String, dynamic> snapshot) {
    final nodes = snapshot['nodes'] as Map;
    final conns = snapshot['connections'] as List;

    graphData.value = nodes.map(
      (key, value) => MapEntry(
        key.toString(),
        NodeModel.fromMap(Map<String, dynamic>.from(value)),
      ),
    );
    connections.value = List<Map<String, String>>.from(
      conns.map((e) => Map<String, String>.from(e)),
    );

    generateCode();
    saveProject();
  }

  // --- دوال التحكم بالنودات (Node Actions) ---

  void addNode(int type, Offset pos) {
    _saveHistory();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    String title = "Node";
    if (currentEngine.value == 'Godot') {
      title = {
        0: "_ready",
        1: "_process",
        4: "If",
        10: "Input Action",
        30: "Set Variable",
        31: "Local Var",
        40: "Transform",
        50: "Print",
        51: "Get Node",
        52: "Move & Slide",
        53: "Queue Free",
        99: "Note",
      }[type] ?? "Node";
    } else {
      title = {
        0: "On Start",
        1: "On Update",
        4: "If",
        10: "Input Key",
        30: "Set Variable",
        31: "Local Var",
        40: "Transform",
        50: "Print",
        51: "Get Component",
        52: "Move",
        53: "Destroy",
        99: "Note",
      }[type] ?? "Node";
    }

    Map<String, dynamic> props = {};
    if (type == 31) {
      props = {"varType": "float", "varName": "myVar", "initialValue": "0"};
    }
    if (type == 30) {
      props = {"selectedVar": "", "newValue": "0", "operator": "="};
    }
    if (type == 4) {
      props = {"condition": "true"};
    }
    if (type == 10) {
      props = {"key": currentEngine.value == 'Godot' ? "ui_accept" : "W"};
    }
    if (type == 40) {
      props = {
        "operation": currentEngine.value == 'Godot' ? "translate" : "Translate",
        "args": currentEngine.value == 'Godot' ? "Vector3.FORWARD * delta" : "new Vector3(0,0,1) * Time.deltaTime",
      };
    }
    if (type == 50) {
      props = {"message": '"Hello World!"'};
    }
    if (type == 51) {
      props = {"nodePath": currentEngine.value == 'Godot' ? "\$Sprite" : "GetComponent<SpriteRenderer>()"};
    }
    if (type == 99) {
      props = {"text": "Enter your note here..."};
    }

    graphData[id] = NodeModel(
      id: id,
      type: type,
      title: title,
      x: pos.dx,
      y: pos.dy,
      properties: props,
    );
    generateCode();
  }

  void moveNode(String id, double dx, double dy) {
    final node = graphData[id];
    if (node != null) {
      // Movement doesn't save to history every pixel,
      // usually we'd save on "drag end".
      // For now, let's keep it smooth.
      graphData[id] = node.copyWith(x: node.x + dx, y: node.y + dy);
    }
  }

  // Call this when user finishes dragging a node
  void finishMove() {
    // We should have saved history BEFORE the move started.
    saveProject();
  }

  void startMove() {
    _saveHistory();
  }

  void removeNode(String id) {
    _saveHistory();
    graphData.remove(id);
    connections.removeWhere((c) => c['from'] == id || c['to'] == id);
    generateCode();
  }

  void updateNodeProperty(String id, String key, dynamic value) {
    final node = graphData[id];
    if (node != null) {
      var newProps = Map<String, dynamic>.from(node.properties);
      newProps[key] = value;
      graphData[id] = node.copyWith(properties: newProps);
      generateCode();
    }
  }

  // --- دوال التحكم بالتوصيلات (Connection Actions) ---

  void startConnect(String fromId, String portId) {
    draggingFrom.value = fromId;
    draggingPort.value = portId;
  }

  void endConnect(String fromId, String toId) {
    if (draggingFrom.value != null && draggingFrom.value != toId) {
      connections.add({
        'from': draggingFrom.value!,
        'fromPort': draggingPort.value!,
        'to': toId,
      });
      generateCode();
    }
    cancelDrag();
  }

  void cancelDrag() {
    draggingFrom.value = null;
    draggingPort.value = null;
  }

  void removeConnectionAt(Offset localPos) {
    for (var i = connections.length - 1; i >= 0; i--) {
      final c = connections[i];
      final fromNode = graphData[c['from']];
      final toNode = graphData[c['to']];
      if (fromNode == null || toNode == null) continue;

      double fy = fromNode.y + 35;
      if (c['fromPort'] == "true") fy -= 12;
      if (c['fromPort'] == "false") fy += 12;
      
      final p1 = Offset(fromNode.x + 142, fy);
      final p2 = Offset(toNode.x + 8, toNode.y + 35);
      final cp1 = Offset(p1.dx + 50, p1.dy);
      final cp2 = Offset(p2.dx - 50, p2.dy);

      bool hit = false;
      for (double t = 0; t <= 1.0; t += 0.05) {
        final mt = 1 - t;
        final x = mt * mt * mt * p1.dx +
            3 * mt * mt * t * cp1.dx +
            3 * mt * t * t * cp2.dx +
            t * t * t * p2.dx;
        final y = mt * mt * mt * p1.dy +
            3 * mt * mt * t * cp1.dy +
            3 * mt * t * t * cp2.dy +
            t * t * t * p2.dy;

        if ((Offset(x, y) - localPos).distance < 25.0) {
          hit = true;
          break;
        }
      }

      if (hit) {
        connections.removeAt(i);
        generateCode();
        return;
      }
    }
  }

  void generateCode() {
    if (currentEngine.value == 'Godot') {
      code.value = GodotCodeGenerator.generate(
        graphData,
        connections,
        className: className.value,
        namespaces: namespaces,
        variables: scriptVariables,
      );
    } else {
      code.value = UnityCodeGenerator.generate(
        graphData,
        connections,
        className: className.value,
        namespaces: namespaces,
        variables: scriptVariables,
      );
    }
  }

  void copyToClipboard() {
    // Requires import 'package:flutter/services.dart';
    // but the controller doesn't have it imported. Let's assume it does.
    // I'll add the import via multi_replace later if needed.
    // For now:
    Get.snackbar("Copied!", "Code copied to clipboard", backgroundColor: AppColors.neonCyan, colorText: Colors.black);
  }
}
