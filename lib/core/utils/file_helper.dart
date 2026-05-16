import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<void> exportScript(String content, String fileName) async {
    if (kIsWeb) {
      // In a real web app, we would use dart:html to trigger a download
      debugPrint("Web Export: $content");
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsString(content);
      debugPrint("File saved to: $path");
    } catch (e) {
      debugPrint("Error saving file: $e");
    }
  }
}
