import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';

class CommandPalette extends StatefulWidget {
  final EditorController ctr;
  const CommandPalette({super.key, required this.ctr});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filteredNodes = [];

  final List<Map<String, dynamic>> _allNodes = [
    {'name': 'On Start', 'type': 0, 'icon': Icons.rocket_launch, 'color': Colors.cyanAccent},
    {'name': 'On Update', 'type': 1, 'icon': Icons.loop, 'color': Colors.cyanAccent},
    {'name': 'If', 'type': 4, 'icon': Icons.alt_route, 'color': Colors.purpleAccent},
    {'name': 'Input Key', 'type': 10, 'icon': Icons.keyboard, 'color': Colors.greenAccent},
    {'name': 'Transform', 'type': 40, 'icon': Icons.transform, 'color': Colors.lightBlueAccent},
    {'name': 'Set Variable', 'type': 30, 'icon': Icons.edit, 'color': Colors.amberAccent},
  ];

  @override
  void initState() {
    super.initState();
    _filteredNodes = _allNodes;
  }

  void _filter(String query) {
    setState(() {
      _filteredNodes = _allNodes
          .where((n) => n['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Search nodes...",
              hintStyle: TextStyle(color: Colors.white24),
              prefixIcon: Icon(Icons.search, color: AppColors.neonCyan),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(15),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredNodes.length,
              itemBuilder: (context, index) {
                final node = _filteredNodes[index];
                return ListTile(
                  leading: Icon(node['icon'], color: node['color'], size: 18),
                  title: Text(node['name'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  onTap: () {
                    widget.ctr.addNode(node['type'], const Offset(300, 300));
                    Get.back();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
