import 'package:get/get.dart'; // مكتبة إدارة الحالة
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';

// هذا الملف مسؤول عن تجهيز "المتحكمات" عند بداية تشغيل التطبيق
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // تجهيز متحكم المحرر (EditorController) ليكون متاحاً في كل الصفحات
    Get.put(EditorController());
  }
}

