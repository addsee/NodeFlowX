import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';

class CodeView extends StatelessWidget {
  final EditorController ctr;
  const CodeView({super.key, required this.ctr});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Obx(
                () => SelectableText.rich(
                  _highlightCSharp(ctr.code.value),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _highlightCSharp(String code) {
    final List<TextSpan> spans = [];
    final query = ctr.codeSearchQuery.value.toLowerCase();
    
    // Simple C# Tokenizer
    final keywords = RegExp(r'\b(public|private|protected|class|void|static|using|new|if|else|return|var|float|int|string|bool|override|base)\b');
    final types = RegExp(r'\b(MonoBehaviour|Transform|Vector3|GameObject|Input|Time|Quaternion|Space)\b');
    final strings = RegExp(r'".*?"');
    final comments = RegExp(r'//.*');

    final combined = RegExp('${keywords.pattern}|${types.pattern}|${strings.pattern}|${comments.pattern}');
    
    int lastMatchEnd = 0;
    for (final match in combined.allMatches(code)) {
      // Add text before match (and check for search query inside it)
      if (match.start > lastMatchEnd) {
        final text = code.substring(lastMatchEnd, match.start);
        _addWithSearch(spans, text, query, const TextStyle(color: Colors.white70));
      }

      final matchedText = match.group(0)!;
      TextStyle style = const TextStyle(color: Colors.white70);
      
      if (keywords.hasMatch(matchedText)) {
        style = const TextStyle(color: Color(0xFFD7BA7D)); // Gold
      } else if (types.hasMatch(matchedText)) {
        style = const TextStyle(color: Color(0xFF4EC9B0)); // Teal
      } else if (strings.hasMatch(matchedText)) {
        style = const TextStyle(color: Color(0xFFCE9178)); // Terracotta
      } else if (comments.hasMatch(matchedText)) {
        style = const TextStyle(color: Color(0xFF6A9955)); // Green
      }

      _addWithSearch(spans, matchedText, query, style);
      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < code.length) {
      _addWithSearch(spans, code.substring(lastMatchEnd), query, const TextStyle(color: Colors.white70));
    }

    return TextSpan(children: spans);
  }

  void _addWithSearch(List<TextSpan> spans, String text, String query, TextStyle style) {
    if (query.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }

    final lowerText = text.toLowerCase();
    int start = 0;
    int index = lowerText.indexOf(query);

    while (index != -1) {
      // Before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      // Match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(backgroundColor: AppColors.neonCyan.withValues(alpha: 0.3), color: Colors.white),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(query, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
  }
}
