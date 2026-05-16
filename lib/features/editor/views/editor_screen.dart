import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';
import 'package:node_flow_x/features/editor/models/variable_model.dart';
import 'package:node_flow_x/features/editor/views/widgets/code_view.dart';
import 'package:node_flow_x/features/editor/views/widgets/graph_canvas.dart';
import 'package:node_flow_x/features/editor/views/widgets/code_import_dialog.dart';
import '../../../core/theme/app_colors.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EditorController>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, controller, isDesktop),

                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          if (isDesktop) _buildSidebar(controller),
                          Expanded(child: GraphCanvas(ctr: controller)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: !isDesktop
              ? FloatingActionButton(
                  onPressed: () => _showMobileNodesSheet(context, controller),
                  backgroundColor: AppColors.neonCyan,
                  child: const Icon(Icons.add, color: Colors.black),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    EditorController ctr,
    bool isDesktop,
  ) {
    return Container(
      height: 50,
      margin: EdgeInsets.all(isDesktop ? 10 : 8),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Obx(
            () => Text(
              "${ctr.currentEngine.value.toUpperCase()} VS",
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 12 : 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: () => _showNodeSearch(context, ctr),
            icon: const Icon(
              Icons.location_searching,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: 'find_node'.tr,
          ),
          const Spacer(),
          _buildActions(context, ctr, isDesktop),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    EditorController ctr,
    bool isDesktop,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => ctr.undo(),
          icon: const Icon(Icons.undo_rounded, color: Colors.white70, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'undo'.tr,
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => ctr.redo(),
          icon: const Icon(Icons.redo_rounded, color: Colors.white70, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'redo'.tr,
        ),
        if (isDesktop) ...[
          _vDivider(),
          IconButton(
            onPressed: () => _showAIWizard(context, ctr),
            icon: const Icon(
              Icons.auto_awesome,
              color: Colors.purpleAccent,
              size: 18,
            ),
            tooltip: "AI Wizard",
          ),
          IconButton(
            onPressed: () => ctr.tidyGraph(),
            icon: const Icon(
              Icons.auto_fix_high,
              color: Colors.greenAccent,
              size: 18,
            ),
            tooltip: "Tidy",
          ),
        ],
        _vDivider(),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).textTheme.bodyMedium!.color,
            size: 20,
          ),
          color: Theme.of(context).colorScheme.surface,
          offset: const Offset(0, 40),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (val) {
            switch (val) {
              case 'ai':
                _showAIWizard(context, ctr);
                break;
              case 'tidy':
                ctr.tidyGraph();
                break;
              case 'variables':
                _showVariablesDialog(context, ctr);
                break;
              case 'usings':
                _showUsingsDialog(context, ctr);
                break;
              case 'live_code':
                _showCodeDialog(context, ctr);
                break;
              case 'settings':
                _showSettingsDialog(context, ctr);
                break;
              case 'selection':
                ctr.toggleSelectionMode();
                break;
              case 'import_code':
                _showCodeImport(context, ctr);
                break;
              case 'export_json':
                ctr.exportJson();
                break;
              case 'import_json':
                ctr.importJson();
                break;
              case 'export_cs':
                ctr.exportToDevice();
                break;
              case 'clear':
                ctr.clearProject();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isDesktop) ...[
              _popItem(
                'ai',
                Icons.auto_awesome,
                "AI Wizard",
                Colors.purpleAccent,
              ),
              _popItem(
                'tidy',
                Icons.auto_fix_high,
                "Tidy Nodes",
                Colors.greenAccent,
              ),
              const PopupMenuDivider(height: 10),
            ],
            _popItem(
              'variables',
              Icons.data_object,
              "Variables",
              AppColors.neonAmber,
            ),
            _popItem(
              'usings',
              Icons.integration_instructions,
              "Usings",
              Colors.blueAccent,
            ),
            _popItem(
              'live_code',
              Icons.visibility,
              'view_code'.tr,
              Colors.orangeAccent,
            ),
            _popItem(
              'settings',
              Icons.settings,
              "Project Settings",
              Colors.white60,
            ),
            const PopupMenuDivider(height: 10),
            _popItem(
              'selection',
              Icons.highlight_alt_rounded,
              'selection_mode'.tr,
              AppColors.neonCyan,
            ),
            const PopupMenuDivider(height: 10),
            _popItem(
              'export_json',
              Icons.save_alt_rounded,
              'export_json'.tr,
              Colors.greenAccent,
            ),
            _popItem(
              'import_json',
              Icons.folder_open_rounded,
              'import_json'.tr,
              Colors.lightBlueAccent,
            ),
            _popItem(
              'import_code',
              Icons.input_rounded,
              'import_code_menu'.tr,
              Colors.tealAccent,
            ),
            _popItem(
              'export_cs',
              Icons.file_download,
              'export_cs'.tr,
              AppColors.neonCyan,
            ),
            const PopupMenuDivider(height: 10),
            _popItem(
              'clear',
              Icons.delete_sweep,
              "Clear Canvas",
              Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  // تم حذف _buildLiveCodePanel حسب طلب المستخدم ليصبح في نافذة منبثقة (Dialog) فقط.

  /// يفتح نافذة استيراد الكود وتحويله إلى بلوكات مرئية
  void _showCodeImport(BuildContext context, EditorController ctr) {
    showDialog(
      context: context,
      builder: (context) => CodeImportDialog(ctr: ctr),
    );
  }

  PopupMenuItem<String> _popItem(
    String val,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 5),
    color: Colors.white12,
  );

  void _showAIWizard(BuildContext context, EditorController ctr) {
    final promptCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "AI Logic Wizard",
          style: TextStyle(color: Colors.purpleAccent, fontSize: 16),
        ),
        content: TextField(
          controller: promptCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "مثلاً: اجعل اللاعب يقفز عند الضغط على مفتاح المسافة",
            hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
            ),
            onPressed: () {
              ctr.generateFromPrompt(promptCtrl.text);
              Get.back();
            },
            child: const Text(
              "Generate",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCodeDialog(BuildContext context, EditorController ctr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.2)),
        ),
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.code, color: AppColors.neonCyan),
                  const SizedBox(width: 10),
                  Obx(
                    () => Text(
                      ctr.currentEngine.value == 'Godot'
                          ? "كود GDSCRIPT المستخرج"
                          : "كود C# المستخرج",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white38),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 30),
              Expanded(child: CodeView(ctr: ctr)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ctr.code.value));
                    Get.snackbar(
                      "تم النسخ ✓",
                      "تم نسخ الكود إلى الحافظة",
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.neonCyan.withValues(
                        alpha: 0.7,
                      ),
                      colorText: Colors.black,
                      margin: const EdgeInsets.all(20),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text("نسخ الكود"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.neonCyan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(EditorController ctr) {
    return Container(
      width: 165,
      margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Events ─────────────────────────────────────────────────
            _sectionHeader("EVENTS"),
            Obx(
              () => _draggableNode(
                ctr.currentEngine.value == 'Godot' ? "_ready" : "On Start",
                0,
                Icons.rocket_launch,
                Colors.cyanAccent,
              ),
            ),
            Obx(
              () => _draggableNode(
                ctr.currentEngine.value == 'Godot' ? "_process" : "On Update",
                1,
                Icons.loop,
                Colors.cyanAccent,
              ),
            ),

            // ── Data ───────────────────────────────────────────────────
            _sectionHeader("DATA"),
            _draggableNode("Local Var", 31, Icons.add_box, Colors.amberAccent),
            _draggableNode("Set Variable", 30, Icons.edit, Colors.amberAccent),

            // ── Logic ──────────────────────────────────────────────────
            _sectionHeader("LOGIC"),
            _draggableNode("If", 4, Icons.alt_route, Colors.purpleAccent),
            Obx(
              () => _draggableNode(
                ctr.currentEngine.value == 'Godot'
                    ? "Input Action"
                    : "Input Key",
                10,
                Icons.keyboard,
                Colors.greenAccent,
              ),
            ),

            _draggableNode(
              "Transform",
              40,
              Icons.transform,
              Colors.lightBlueAccent,
            ),
            _sectionHeader("SPECIFICS"),
            Obx(
              () => ctr.currentEngine.value == 'Godot'
                  ? Column(
                      children: [
                        _draggableNode("Print", 50, Icons.print, Colors.white),
                        _draggableNode(
                          "Get Node",
                          51,
                          Icons.account_tree,
                          Colors.pinkAccent,
                        ),
                        _draggableNode(
                          "Move & Slide",
                          52,
                          Icons.directions_run,
                          Colors.orangeAccent,
                        ),
                        _draggableNode(
                          "Queue Free",
                          53,
                          Icons.delete_forever,
                          Colors.redAccent,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _draggableNode("Print", 50, Icons.print, Colors.white),
                        _draggableNode(
                          "Get Component",
                          51,
                          Icons.account_tree,
                          Colors.pinkAccent,
                        ),
                        _draggableNode(
                          "Move",
                          52,
                          Icons.directions_run,
                          Colors.orangeAccent,
                        ),
                        _draggableNode(
                          "Destroy",
                          53,
                          Icons.delete_forever,
                          Colors.redAccent,
                        ),
                      ],
                    ),
            ),
            _sectionHeader("ORGANIZATION"),
            _draggableNode(
              "Group Box",
              100,
              Icons.aspect_ratio,
              Colors.white60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _draggableNode(String label, int type, IconData icon, Color color) {
    return Draggable<int>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.7), size: 13),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileNodesSheet(BuildContext context, EditorController ctr) {
    final searchController = TextEditingController();
    final nodes = [
      {
        'label': ctr.currentEngine.value == 'Godot' ? '_ready' : 'On Start',
        'type': 0,
        'icon': Icons.rocket_launch,
        'color': Colors.cyanAccent,
        'cat': 'EVENTS',
      },
      {
        'label': ctr.currentEngine.value == 'Godot' ? '_process' : 'On Update',
        'type': 1,
        'icon': Icons.loop,
        'color': Colors.cyanAccent,
        'cat': 'EVENTS',
      },
      {
        'label': 'Local Var',
        'type': 31,
        'icon': Icons.add_box,
        'color': Colors.amberAccent,
        'cat': 'DATA',
      },
      {
        'label': 'Set Variable',
        'type': 30,
        'icon': Icons.edit,
        'color': Colors.amberAccent,
        'cat': 'DATA',
      },
      {
        'label': 'If',
        'type': 4,
        'icon': Icons.alt_route,
        'color': Colors.purpleAccent,
        'cat': 'LOGIC',
      },
      {
        'label': ctr.currentEngine.value == 'Godot'
            ? 'Input Action'
            : 'Input Key',
        'type': 10,
        'icon': Icons.keyboard,
        'color': Colors.greenAccent,
        'cat': 'LOGIC',
      },
      {
        'label': 'Transform',
        'type': 40,
        'icon': Icons.transform,
        'color': Colors.lightBlueAccent,
        'cat': 'TRANSFORM',
      },
      {
        'label': 'Print',
        'type': 50,
        'icon': Icons.print,
        'color': Colors.white,
        'cat': 'SPECIFICS',
      },
      {
        'label': ctr.currentEngine.value == 'Godot'
            ? 'Get Node'
            : 'Get Component',
        'type': 51,
        'icon': Icons.account_tree,
        'color': Colors.pinkAccent,
        'cat': 'SPECIFICS',
      },
      {
        'label': ctr.currentEngine.value == 'Godot' ? 'Move & Slide' : 'Move',
        'type': 52,
        'icon': Icons.directions_run,
        'color': Colors.orangeAccent,
        'cat': 'SPECIFICS',
      },
      {
        'label': ctr.currentEngine.value == 'Godot' ? 'Queue Free' : 'Destroy',
        'type': 53,
        'icon': Icons.delete_forever,
        'color': Colors.redAccent,
        'cat': 'SPECIFICS',
      },
      {
        'label': 'Note',
        'type': 99,
        'icon': Icons.sticky_note_2,
        'color': Colors.yellowAccent,
        'cat': 'UTILS',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final query = searchController.text.toLowerCase();
            final filtered = nodes
                .where(
                  (n) => (n['label'] as String).toLowerCase().contains(query),
                )
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DefaultTabController(
                    length: 2,
                    child: Expanded(
                      child: Column(
                        children: [
                          const TabBar(
                            indicatorColor: AppColors.neonCyan,
                            tabs: [
                              Tab(text: "Nodes"),
                              Tab(text: "Templates"),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Nodes Tab
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: searchController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: const InputDecoration(
                                          icon: Icon(
                                            Icons.search,
                                            color: Colors.white38,
                                            size: 20,
                                          ),
                                          hintText: "Search nodes...",
                                          hintStyle: TextStyle(
                                            color: Colors.white24,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (val) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          final n = filtered[index];
                                          final showCat =
                                              index == 0 ||
                                              filtered[index - 1]['cat'] !=
                                                  n['cat'];
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (showCat)
                                                _sectionHeader(
                                                  n['cat'] as String,
                                                ),
                                              _mobileNodeBtn(
                                                context,
                                                ctr,
                                                n['label'] as String,
                                                n['type'] as int,
                                                n['icon'] as IconData,
                                                n['color'] as Color,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                // Templates Tab
                                ListView(
                                  children: [
                                    _templateBtn(
                                      context,
                                      ctr,
                                      "Smooth Follow",
                                      Icons.videocam,
                                      Colors.lightBlueAccent,
                                    ),
                                    _templateBtn(
                                      context,
                                      ctr,
                                      "Click Action",
                                      Icons.touch_app,
                                      Colors.pinkAccent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _templateBtn(
    BuildContext context,
    EditorController ctr,
    String name,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(name, style: const TextStyle(color: Colors.white70)),
      subtitle: Text(
        "Inject $name logic",
        style: const TextStyle(color: Colors.white24, fontSize: 10),
      ),
      onTap: () {
        ctr.addTemplate(name, const Offset(200, 200));
        Get.back();
      },
    );
  }

  Widget _mobileNodeBtn(
    BuildContext context,
    EditorController ctr,
    String label,
    int type,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: () {
        final pos = const Offset(200, 200);
        ctr.addNode(type, pos);
        Get.back();
      },
    );
  }

  void _showVariablesDialog(BuildContext context, EditorController ctr) {
    showDialog(
      context: context,
      builder: (context) => Obx(
        () => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.2)),
          ),

          title: Row(
            children: [
              const Icon(
                Icons.data_object,
                color: AppColors.neonAmber,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                "إدارة المتغيرات",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ctr.scriptVariables.add(
                    VariableModel(
                      name: "newVar",
                      type: "float",
                      access: "public",
                      defaultValue: "0",
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.neonCyan,
                  size: 28,
                ),
              ),
            ],
          ),
          content: Container(
            width: min(600, MediaQuery.of(context).size.width - 32),
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ctr.scriptVariables.length,
              itemBuilder: (context, index) {
                final v = ctr.scriptVariables[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Access toggle: public / private
                      GestureDetector(
                        onTap: () {
                          v.access = (v.access == "public")
                              ? "private"
                              : "public";
                          ctr.scriptVariables.refresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (v.access == "public")
                                ? Colors.cyanAccent.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (v.access == "public")
                                  ? Colors.cyanAccent.withValues(alpha: 0.5)
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            v.access == "public" ? "pub" : "prv",
                            style: TextStyle(
                              color: v.access == "public"
                                  ? Colors.cyanAccent
                                  : Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Name",
                            labelStyle: TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          controller: TextEditingController(text: v.name)
                            ..selection = TextSelection.collapsed(
                              offset: v.name.length,
                            ),
                          onChanged: (val) {
                            v.name = val;
                            ctr.scriptVariables.refresh();
                          },
                        ),
                      ),
                      const VerticalDivider(color: Colors.white10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: v.type,
                          dropdownColor: AppColors.surface,
                          underline: const SizedBox(),
                          isExpanded: true,
                          items:
                              [
                                    "int",
                                    "float",
                                    "string",
                                    "bool",
                                    "Vector3",
                                    "Color",
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: AppColors.neonAmber,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            v.type = val!;
                            ctr.scriptVariables.refresh();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Value",
                            labelStyle: TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          controller:
                              TextEditingController(text: v.defaultValue)
                                ..selection = TextSelection.collapsed(
                                  offset: v.defaultValue.length,
                                ),
                          onChanged: (val) {
                            v.defaultValue = val;
                            ctr.scriptVariables.refresh();
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ctr.scriptVariables.removeAt(index);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                "إغلاق",
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUsingsDialog(BuildContext context, EditorController ctr) {
    showDialog(
      context: context,
      builder: (context) => Obx(
        () => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.25)),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.integration_instructions,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                "إدارة الـ Using",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ctr.namespaces.add("UnityEngine.UI");
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.blueAccent,
                  size: 28,
                ),
              ),
            ],
          ),
          content: Container(
            width: min(480, MediaQuery.of(context).size.width - 32),
            constraints: const BoxConstraints(maxHeight: 350),
            child: ctr.namespaces.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد using directives",
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: ctr.namespaces.length,
                    itemBuilder: (context, index) {
                      final ns = ctr.namespaces[index];
                      final ctrl = TextEditingController(
                        text: ns,
                      )..selection = TextSelection.collapsed(offset: ns.length);
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "using",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: ctrl,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  ctr.namespaces[index] = val;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () => ctr.namespaces.removeAt(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ctr.generateCode();
                Get.back();
              },
              child: const Text(
                "تطبيق وإغلاق",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, EditorController ctr) {
    final classCtrl = TextEditingController(text: ctr.className.value);
    final fileCtrl = TextEditingController(text: ctr.scriptName.value);
    final nsCtrl = TextEditingController(text: ctr.namespaces.join(", "));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "إعدادات السكريبت",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: classCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Class Name",
                labelStyle: TextStyle(color: Colors.white38),
              ),
            ),
            TextField(
              controller: fileCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Export File Name (.cs)",
                labelStyle: TextStyle(color: Colors.white38),
              ),
            ),
            TextField(
              controller: nsCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Namespaces (Comma separated)",
                labelStyle: TextStyle(color: Colors.white38),
                hintText: "UnityEngine, System.Collections",
                hintStyle: TextStyle(color: Colors.white10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              ctr.className.value = classCtrl.text;
              ctr.scriptName.value = fileCtrl.text;
              ctr.namespaces.value = nsCtrl.text
                  .split(",")
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Get.back();
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _showNodeSearch(BuildContext context, EditorController ctr) {
    final searchCtrl = TextEditingController();
    final results = <MapEntry<String, NodeModel>>[].obs;
    results.assignAll(ctr.graphData.entries.toList());

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: TextField(
          controller: searchCtrl,
          autofocus: true,
          onChanged: (val) {
            results.assignAll(
              ctr.graphData.entries
                  .where(
                    (e) =>
                        e.value.title.toLowerCase().contains(val.toLowerCase()),
                  )
                  .toList(),
            );
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search node title...",
            hintStyle: TextStyle(color: Colors.white24),
            prefixIcon: Icon(Icons.search, color: AppColors.neonCyan),
            border: InputBorder.none,
          ),
        ),
        content: SizedBox(
          width: 300,
          height: 400,
          child: Obx(
            () => ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final e = results[i];
                return ListTile(
                  leading: Icon(
                    _nodeIcon(e.value.type),
                    color: AppColors.neonCyan,
                    size: 16,
                  ),
                  title: Text(
                    e.value.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: Text(
                    "At (${e.value.x.toInt()}, ${e.value.y.toInt()})",
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                  onTap: () {
                    Get.back();
                    ctr.teleportRequest.value = Offset(e.value.x, e.value.y);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  IconData _nodeIcon(int type) {
    switch (type) {
      case 0:
      case 1:
        return Icons.play_arrow_rounded;
      case 4:
        return Icons.alt_route_rounded;
      case 10:
        return Icons.keyboard_rounded;
      case 30:
        return Icons.edit_rounded;
      case 31:
        return Icons.add_box_rounded;
      case 40:
        return Icons.transform_rounded;
      case 99:
        return Icons.note_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}
