import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';
import 'package:node_flow_x/features/editor/models/variable_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// ProjectIOService
//
// Handles saving and loading the full editor project as a .json file.
//
// JSON schema:
// {
//   "version": 1,
//   "className": "PlayerMovement",
//   "scriptName": "PlayerMovement.cs",
//   "namespaces": ["UnityEngine"],
//   "variables": [ { "name":…, "type":…, "access":…, "defaultValue":… } ],
//   "nodes": { "<id>": { "id":…, "title":…, "type":…, "x":…, "y":…, "properties":{} } },
//   "connections": [ { "from":…, "to":…, "fromPort":… } ]
// }
// ════════════════════════════════════════════════════════════════════════════
class ProjectIOService {
  static const int _schemaVersion = 1;

  // ── Export ──────────────────────────────────────────────────────────────
  /// Serialises the full project to a .json file chosen by the user.
  /// Returns the saved file path on success, or null if cancelled / failed.
  static Future<String?> exportProject({
    required String className,
    required String scriptName,
    required List<String> namespaces,
    required List<VariableModel> variables,
    required Map<String, NodeModel> nodes,
    required List<Map<String, String>> connections,
  }) async {
    // 1. Build the JSON object
    final data = {
      'version': _schemaVersion,
      'className': className,
      'scriptName': scriptName,
      'namespaces': namespaces,
      'variables': variables.map((v) => v.toMap()).toList(),
      'nodes': nodes.map((k, v) => MapEntry(k, v.toMap())),
      'connections': connections,
    };

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(data);

    // 2. Let the user pick where to save
    try {
      if (kIsWeb) {
        // Web: not supported in this build
        return null;
      }

      // Get a default directory
      final docsDir = await getApplicationDocumentsDirectory();
      final defaultName = '${scriptName.replaceAll('.cs', '')}_project.json';

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Project',
        fileName: defaultName,
        initialDirectory: docsDir.path,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (savePath == null) return null; // user cancelled

      final file = File(savePath);
      await file.writeAsString(jsonString, flush: true);
      debugPrint('Project exported to: $savePath');
      return savePath;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────
  /// Opens a file picker, reads the chosen .json and returns a parsed
  /// [ProjectData] object, or null if the user cancelled / file is invalid.
  static Future<ProjectData?> importProject() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Open Project',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      String content;
      if (result.files.first.bytes != null) {
        // Web / bytes mode
        content = utf8.decode(result.files.first.bytes!);
      } else {
        final file = File(result.files.first.path!);
        content = await file.readAsString();
      }

      final Map<String, dynamic> json = jsonDecode(content);
      return ProjectData.fromJson(json);
    } catch (e) {
      debugPrint('Import error: $e');
      return null;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ProjectData  —  plain Dart object returned after a successful import
// ════════════════════════════════════════════════════════════════════════════
class ProjectData {
  final String className;
  final String scriptName;
  final List<String> namespaces;
  final List<VariableModel> variables;
  final Map<String, NodeModel> nodes;
  final List<Map<String, String>> connections;

  const ProjectData({
    required this.className,
    required this.scriptName,
    required this.namespaces,
    required this.variables,
    required this.nodes,
    required this.connections,
  });

  factory ProjectData.fromJson(Map<String, dynamic> json) {
    // Nodes
    final rawNodes = json['nodes'] as Map<String, dynamic>? ?? {};
    final nodes = rawNodes.map(
      (key, value) => MapEntry(
        key,
        NodeModel.fromMap(Map<String, dynamic>.from(value as Map)),
      ),
    );

    // Connections
    final rawConns = json['connections'] as List? ?? [];
    final connections = rawConns
        .map((c) => Map<String, String>.from(c as Map))
        .toList();

    // Variables
    final rawVars = json['variables'] as List? ?? [];
    final variables = rawVars
        .map((v) => VariableModel.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();

    return ProjectData(
      className:   json['className']  as String? ?? 'GeneratedScript',
      scriptName:  json['scriptName'] as String? ?? 'GeneratedScript.cs',
      namespaces:  List<String>.from(json['namespaces'] as List? ?? ['UnityEngine']),
      variables:   variables,
      nodes:       nodes,
      connections: connections,
    );
  }
}
