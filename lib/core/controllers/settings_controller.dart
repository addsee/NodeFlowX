import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final _storage = GetStorage();
  
  final _isDark = true.obs;
  bool get isDark => _isDark.value;

  final _lang = 'ar'.obs;
  String get lang => _lang.value;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    _isDark.value = _storage.read('isDark') ?? true;
    _lang.value = _storage.read('lang') ?? 'ar';
    
    Get.changeThemeMode(_isDark.value ? ThemeMode.dark : ThemeMode.light);
    Get.updateLocale(Locale(_lang.value));
  }

  void toggleTheme() {
    _isDark.value = !_isDark.value;
    _storage.write('isDark', _isDark.value);
    Get.changeThemeMode(_isDark.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleLanguage() {
    _lang.value = _lang.value == 'ar' ? 'en' : 'ar';
    _storage.write('lang', _lang.value);
    Get.updateLocale(Locale(_lang.value));
  }
}
