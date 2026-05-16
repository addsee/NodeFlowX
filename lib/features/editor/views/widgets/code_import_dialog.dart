import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/features/editor/services/code_parser.dart';

// ════════════════════════════════════════════════════════════════════════════
// CodeImportDialog — نافذة استيراد الكود وتحويله إلى بلوكات
//
// الوظيفة:
//   تسمح للمستخدم بلصق كود C# أو GDScript، ثم تحوّله تلقائياً
//   إلى نودات مرئية على لوحة المحرر.
// ════════════════════════════════════════════════════════════════════════════
class CodeImportDialog extends StatefulWidget {
  final EditorController ctr;

  const CodeImportDialog({super.key, required this.ctr});

  @override
  State<CodeImportDialog> createState() => _CodeImportDialogState();
}

class _CodeImportDialogState extends State<CodeImportDialog> {
  final _codeController = TextEditingController();

  // نتيجة التحليل — null تعني أنه لم يتم التحليل بعد
  ParseResult? _result;

  // هل نحن في حالة تحميل؟
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ── تنفيذ التحليل ─────────────────────────────────────────────────────────
  void _analyze() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    // نؤخر قليلاً لإعطاء انطباع بالمعالجة
    Future.delayed(const Duration(milliseconds: 400), () {
      final result = CodeParser.parse(code, widget.ctr.currentEngine.value);
      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    });
  }

  // ── تطبيق النودات على اللوحة ─────────────────────────────────────────────
  void _applyToCanvas() {
    if (_result == null || _result!.isEmpty) return;
    widget.ctr.importFromCode(_result!);
    Get.back();
    Get.snackbar(
      'import_success_title'.tr,
      'import_success_msg'.tr.replaceAll('@count', '${_result!.nodes.length}'),
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.neonCyan.withValues(alpha: 0.85),
      colorText: Colors.black,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.ctr.currentEngine.value;
    final isGodot = engine == 'Godot';
    final accentColor = isGodot ? Colors.tealAccent : AppColors.neonCyan;
    final langLabel = isGodot ? 'GDScript' : 'C#';
    final placeholder = isGodot ? _gdscriptExample : _csharpExample;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            _buildHeader(context, accentColor, langLabel),
            Divider(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.1), height: 1),

            // ── Body ───────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // مربع إدخال الكود
                    _buildCodeInput(context, placeholder, accentColor),
                    const SizedBox(height: 16),

                    // زر التحليل
                    _buildAnalyzeButton(context, accentColor),

                    // منطقة النتائج
                    if (_isAnalyzing) _buildLoadingIndicator(context, accentColor),
                    if (_result != null) _buildResults(context, accentColor),
                  ],
                ),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            _buildFooter(context, accentColor),
          ],
        ),
      ),
    );
  }

  // ── الرأس ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Color accent, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.input_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'import_dialog_title'.tr,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'import_dialog_subtitle'.tr.replaceAll('@lang', lang),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.close_rounded,
              color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── حقل إدخال الكود ──────────────────────────────────────────────────────
  Widget _buildCodeInput(BuildContext context, String placeholder, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.code_rounded, color: accent, size: 14),
            const SizedBox(width: 6),
            Text(
              'code_input_label'.tr,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _codeController.text = placeholder),
              icon: Icon(
                Icons.auto_fix_high,
                size: 13,
                color: accent.withValues(alpha: 0.7),
              ),
              label: Text(
                'example'.tr,
                style: TextStyle(
                  color: accent.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: TextField(
            controller: _codeController,
            onChanged: (_) => setState(() {}), // تحديث حالة الزر عند الكتابة
            maxLines: 14,
            minLines: 8,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.18),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── زر التحليل ───────────────────────────────────────────────────────────
  Widget _buildAnalyzeButton(BuildContext context, Color accent) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _codeController.text.trim().isEmpty ? null : _analyze,
        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
        label: Text('analyze_btn'.tr),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  // ── مؤشر التحميل ─────────────────────────────────────────────────────────
  Widget _buildLoadingIndicator(BuildContext context, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: accent, strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              'analyzing'.tr,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── منطقة نتائج التحليل ──────────────────────────────────────────────────
  Widget _buildResults(BuildContext context, Color accent) {
    final result = _result!;
    final hasNodes = !result.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان النتائج
          Row(
            children: [
              Icon(
                hasNodes
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: hasNodes ? Colors.greenAccent : Colors.orangeAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                hasNodes
                    ? 'nodes_found'.tr.replaceAll('@nodes', '${result.nodes.length}').replaceAll('@connections', '${result.connections.length}')
                    : 'no_nodes_found'.tr,
                style: TextStyle(
                  color: hasNodes ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // قائمة النودات المكتشفة
          if (result.messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.messages
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.7),
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── الذيل ────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, Color accent) {
    final canApply = _result != null && !_result!.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.24), size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'import_warning'.tr,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.24), fontSize: 10.5),
            ),
          ),
          const SizedBox(width: 12),
          if (canApply)
            ElevatedButton.icon(
              onPressed: _applyToCanvas,
              icon: const Icon(Icons.done_all_rounded, size: 15),
              label: Text('apply_canvas'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── أمثلة للكود ──────────────────────────────────────────────────────────
const _csharpExample = '''void Start() {
    float speed = 5;
}

void Update() {
    if (Input.GetKey(KeyCode.W)) {
        transform.Translate(Vector3.forward * Time.deltaTime);
    }
    if (Input.GetKey(KeyCode.Space)) {
        Debug.Log("Jump!");
    }
}''';

const _gdscriptExample = '''func _ready():
    var speed = 5.0

func _process(delta):
    if Input.is_action_pressed("ui_right"):
        translate(Vector3.RIGHT * delta)
    if Input.is_action_pressed("ui_accept"):
        print("Jump!")''';
