import 'dart:ui';

class NodeModel {
  String id;
  int type;
  String title;
  double x;
  double y;
  Map<String, dynamic> properties;

  Offset get position => Offset(x, y);

  NodeModel({
    required this.id,
    required this.type,
    required this.title,
    required this.x,
    required this.y,
    this.properties = const {},
  });

  NodeModel copyWith({
    double? x,
    double? y,
    Map<String, dynamic>? properties,
  }) {
    return NodeModel(
      id: id,
      type: type,
      title: title,
      x: x ?? this.x,
      y: y ?? this.y,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'x': x,
      'y': y,
      'properties': properties,
    };
  }

  factory NodeModel.fromMap(Map<String, dynamic> map) {
    return NodeModel(
      id: map['id'] as String,
      type: map['type'] as int,
      title: map['title'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      properties: Map<String, dynamic>.from(map['properties'] as Map? ?? {}),
    );
  }
}
