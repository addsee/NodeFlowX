import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/features/editor/views/widgets/code_import_dialog.dart';
import 'package:node_flow_x/core/controllers/settings_controller.dart';
import '../../editor/views/editor_screen.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/engine_card.dart';
import 'widgets/grid_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctr = Get.put(EditorController());
    final settings = Get.find<SettingsController>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Stack(
              children: [
                // ── الخلفية الشبكية والمضيئة ─────────────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridBackgroundPainter(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.1),
                      spacing: 40.0,
                      strokeWidth: 1.0,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  right: -150,
                  child: _buildGlow(
                    AppColors.neonMagenta.withValues(alpha: 0.1),
                  ),
                ),
                Positioned(
                  top: -100,
                  left: -100,
                  child: _buildGlow(AppColors.neonCyan.withValues(alpha: 0.06)),
                ),

                // ── أزرار الإعدادات (اللغة والسمة) ──────────────────────────────
                Positioned(
                  top: 20,
                  right: 20,
                  child: Obx(
                    () => Row(
                      children: [
                        TextButton.icon(
                          onPressed: settings.toggleLanguage,
                          icon: const Icon(Icons.language, size: 18),
                          label: Text('switch_lang'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: settings.toggleTheme,
                          icon: Icon(
                            settings.isDark
                                ? Icons.light_mode
                                : Icons.dark_mode,
                          ),
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── المحتوى الرئيسي ─────────────────────────────────────────────
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // الشعار والعنوان
                        _buildHeader(context),
                        SizedBox(height: isMobile ? 36 : 60),

                        // بطاقات اختيار المحرك
                        if (isMobile)
                          Column(
                            children: [
                              EngineCard(
                                isMobile: true,
                                title: "UNITY",
                                subtitle: 'unity_desc'.tr,
                                icon: Icons.view_in_ar,
                                color: AppColors.neonCyan,
                                onTap: () => _showStartOptions(
                                  context,
                                  ctr,
                                  'Unity',
                                  'PlayerMovement.cs',
                                  AppColors.neonCyan,
                                  "UNITY",
                                  isMobile,
                                ),
                              ),
                              const SizedBox(height: 16),
                              EngineCard(
                                isMobile: true,
                                title: "GODOT",
                                subtitle: 'godot_desc'.tr,
                                icon: Icons.smart_toy_outlined,
                                color: Colors.blueAccent,
                                onTap: () => _showStartOptions(
                                  context,
                                  ctr,
                                  'Godot',
                                  'PlayerMovement.gd',
                                  Colors.blueAccent,
                                  "GODOT",
                                  isMobile,
                                ),
                              ),
                            ],
                          )
                        else
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 32,
                            runSpacing: 32,
                            children: [
                              EngineCard(
                                title: "UNITY",
                                subtitle: 'unity_desc'.tr,
                                icon: Icons.view_in_ar,
                                color: AppColors.neonCyan,
                                onTap: () => _showStartOptions(
                                  context,
                                  ctr,
                                  'Unity',
                                  'PlayerMovement.cs',
                                  AppColors.neonCyan,
                                  "UNITY",
                                  isMobile,
                                ),
                              ),
                              EngineCard(
                                title: "GODOT",
                                subtitle: 'godot_desc'.tr,
                                icon: Icons.smart_toy_outlined,
                                color: Colors.blueAccent,
                                onTap: () => _showStartOptions(
                                  context,
                                  ctr,
                                  'Godot',
                                  'PlayerMovement.gd',
                                  Colors.blueAccent,
                                  "GODOT",
                                  isMobile,
                                ),
                              ),
                            ],
                          ),

                        SizedBox(height: isMobile ? 36 : 48),
                        _buildFooterHint(context),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  // ── الشعار ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_tree_rounded,
            color: AppColors.neonCyan,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'app_title'.tr,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.bodyLarge!.color,
            letterSpacing: 3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'app_subtitle'.tr,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── تلميح في الأسفل ──────────────────────────────────────────────────────
  Widget _buildFooterHint(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: 16,
          color: Theme.of(
            context,
          ).textTheme.bodyLarge!.color!.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 8),
        Text(
          'footer_hint'.tr,
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── نافذة خيارات البدء ───────────────────────────────────────────────────
  void _showStartOptions(
    BuildContext context,
    EditorController ctr,
    String engine,
    String scriptName,
    Color color,
    String title,
    bool isMobile,
  ) {
    // إعداد المحرك المختار
    void setEngine() {
      ctr.currentEngine.value = engine;
      ctr.scriptName.value = scriptName;
      ctr.generateCode();
    }

    Widget buildContent(BuildContext ctx) {
      return Container(
        width: isMobile ? double.infinity : 460,
        padding: EdgeInsets.all(isMobile ? 24 : 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(isMobile ? 32 : 24),
          border: isMobile
              ? null
              : Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            if (!isMobile)
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس النافذة
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    engine == 'Godot'
                        ? Icons.smart_toy_outlined
                        : Icons.view_in_ar,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'how_to_start'.tr,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.color!.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!isMobile)
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 24),

            // خيار 1: مشروع جديد
            _buildOptionTile(
              context: context,
              icon: Icons.add_circle_outline_rounded,
              color: color,
              title: 'new_project'.tr,
              description: 'new_project_desc'.tr,
              onTap: () {
                Navigator.pop(ctx);
                setEngine();
                ctr.clearProject();
                Get.to(() => const EditorScreen());
              },
            ),

            const SizedBox(height: 14),

            // خيار 2: استيراد من كود
            _buildOptionTile(
              context: context,
              icon: Icons.input_rounded,
              color: Colors.tealAccent,
              title: 'import_code'.tr,
              description: 'import_code_desc'.tr.replaceAll(
                '@engine',
                engine == "Godot" ? "GDScript" : "C#",
              ),
              onTap: () {
                Navigator.pop(ctx);
                setEngine();
                Get.to(() => const EditorScreen());
                Future.delayed(const Duration(milliseconds: 500), () {
                  Get.dialog(CodeImportDialog(ctr: ctr));
                });
              },
            ),

            if (isMobile) const SizedBox(height: 16),
          ],
        ),
      );
    }

    if (isMobile) {
      Get.bottomSheet(
        buildContent(context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: buildContent(ctx),
        ),
      );
    }
  }

  // ── خلية خيار ────────────────────────────────────────────────────────────
  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.color!.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.4),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
