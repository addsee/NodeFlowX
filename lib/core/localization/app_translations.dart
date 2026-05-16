import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar': {
      // HomeScreen
      'app_title': 'NodeFlowX',
      'app_subtitle': 'اختر محرك اللعبة للبدء',
      'footer_hint': 'اضغط على المحرك لعرض خيارات البدء',
      'unity_desc': 'برمجة C#',
      'godot_desc': 'برمجة GDScript',
      'click_to_start': 'اضغط للبدء',
      'how_to_start': 'كيف تريد البدء؟',
      'new_project': 'مشروع جديد',
      'new_project_desc': 'ابدأ بلوحة فارغة وأنشئ نوداتك من الصفر',
      'import_code': 'استيراد من كود',
      'import_code_desc': 'الصق كود @engine وحوّله إلى بلوكات تلقائياً',

      // EditorScreen
      'run': 'تشغيل',
      'undo': 'تراجع',
      'redo': 'إعادة',
      'view_code': 'عرض الكود',
      'selection_mode': 'وضع التحديد',
      'export_json': 'تصدير JSON',
      'import_json': 'استيراد JSON',
      'import_code_menu': 'استيراد كود ← بلوكات',
      'export_cs': 'تصدير .cs',
      'find_node': 'البحث عن نود',

      // CodeImportDialog
      'import_dialog_title': 'استيراد الكود ← بلوكات',
      'import_dialog_subtitle': 'الصق كود @lang وسيتم تحليله وتحويله إلى نودات',
      'code_input_label': 'الكود البرمجي',
      'example': 'مثال',
      'analyze_btn': 'تحليل الكود وتحويله',
      'analyzing': 'جاري تحليل الكود...',
      'nodes_found': 'تم اكتشاف @nodes نود و @connections توصيل',
      'no_nodes_found': 'لم يتم التعرف على أنماط معروفة في هذا الكود',
      'import_warning':
          'الأنماط غير المعروفة ستُتجاهل. الكود المُصدَّر من هذا التطبيق مضمون التحليل.',
      'apply_canvas': 'تطبيق على اللوحة',
      'import_success_title': '✅ تم الاستيراد',
      'import_success_msg': 'تم تحويل @count نود بنجاح إلى اللوحة',

      // Settings
      'switch_lang': 'English',
    },
    'en': {
      // HomeScreen
      'app_title': 'NodeFlowX',
      'app_subtitle': 'Select your game engine to start',
      'footer_hint': 'Click an engine to show start options',
      'unity_desc': 'C# Scripting',
      'godot_desc': 'GDScript',
      'click_to_start': 'Click to Start',
      'how_to_start': 'How do you want to start?',
      'new_project': 'New Project',
      'new_project_desc':
          'Start with a blank canvas and create nodes from scratch',
      'import_code': 'Import from Code',
      'import_code_desc':
          'Paste @engine code to convert it to blocks automatically',

      // EditorScreen
      'run': 'Run',
      'undo': 'Undo',
      'redo': 'Redo',
      'view_code': 'View Code',
      'selection_mode': 'Selection Mode',
      'export_json': 'Export JSON',
      'import_json': 'Import JSON',
      'import_code_menu': 'Import Code ← Blocks',
      'export_cs': 'Export .cs',
      'find_node': 'Find Node',

      // CodeImportDialog
      'import_dialog_title': 'Import Code ← Blocks',
      'import_dialog_subtitle':
          'Paste @lang code to be analyzed and converted to nodes',
      'code_input_label': 'Source Code',
      'example': 'Example',
      'analyze_btn': 'Analyze & Convert Code',
      'analyzing': 'Analyzing code...',
      'nodes_found': 'Discovered @nodes nodes and @connections connections',
      'no_nodes_found': 'No known patterns recognized in this code',
      'import_warning':
          'Unknown patterns will be ignored. Code exported from this app is guaranteed to parse.',
      'apply_canvas': 'Apply to Canvas',
      'import_success_title': '✅ Import Successful',
      'import_success_msg': 'Successfully converted @count nodes to the canvas',

      // Settings
      'switch_lang': 'عربي',
    },
  };
}
