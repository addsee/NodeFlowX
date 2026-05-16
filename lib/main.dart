import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:node_flow_x/core/theme/app_theme.dart';
import 'package:node_flow_x/features/home/views/home_screen.dart';
import 'package:node_flow_x/core/localization/app_translations.dart';
import 'package:node_flow_x/core/controllers/settings_controller.dart';
import 'app_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  Get.put(SettingsController()); // تهيئة الإعدادات

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return GetMaterialApp(
      title: 'NodeFlowX',
      defaultGlobalState: true,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      translations: AppTranslations(),
      locale: Locale(settings.lang),
      fallbackLocale: const Locale('en'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
