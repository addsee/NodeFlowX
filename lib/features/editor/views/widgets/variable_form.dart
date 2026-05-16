import 'package:flutter/material.dart';
import 'package:node_flow_x/core/theme/app_colors.dart';
import 'package:node_flow_x/features/editor/controllers/editor_controller.dart';
import 'package:node_flow_x/features/editor/models/node_model.dart';

class VariableForm extends StatefulWidget {
  final String id;
  final NodeModel node;
  final EditorController ctr;
  const VariableForm({
    super.key,
    required this.id,
    required this.node,
    required this.ctr,
  });


  @override
  State<VariableForm> createState() => _VariableFormState();
}

class _VariableFormState extends State<VariableForm> {
  late TextEditingController _nameController;
  late TextEditingController _valController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.node.properties["varName"],
    );
    _valController = TextEditingController(
      text: widget.node.properties["defaultValue"] ?? "",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: "Variable Name",
            labelStyle: TextStyle(color: Colors.white24, fontSize: 10),
            isDense: true,
            border: InputBorder.none,
          ),
          onChanged: (v) =>
              widget.ctr.updateNodeProperty(widget.id, "varName", v),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _valController,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: "Default Value",
            labelStyle: TextStyle(color: Colors.white24, fontSize: 9),
            isDense: true,
            border: InputBorder.none,
          ),
          onChanged: (v) =>
              widget.ctr.updateNodeProperty(widget.id, "defaultValue", v),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: widget.node.properties["access"],
                items: ["public", "private", "[SerializeField] private"],
                color: AppColors.neonCyan,
                onChanged: (v) => widget.ctr.updateNodeProperty(widget.id, "access", v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(
                value: widget.node.properties["varType"],
                items: ["int", "float", "string", "bool", "Vector3", "Color", "GameObject", "Transform"],
                color: AppColors.neonAmber,
                onChanged: (v) => widget.ctr.updateNodeProperty(widget.id, "varType", v),
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white10),
      ],
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Color color, required Function(String) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        dropdownColor: AppColors.surface,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}

