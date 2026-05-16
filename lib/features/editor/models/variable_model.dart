class VariableModel {
  String name;
  String type;
  String access;
  String defaultValue;

  VariableModel({
    required this.name,
    this.type = "float",
    this.access = "public",
    this.defaultValue = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'access': access,
      'defaultValue': defaultValue,
    };
  }

  factory VariableModel.fromMap(Map<String, dynamic> map) {
    return VariableModel(
      name: map['name'],
      type: map['type'],
      access: map['access'],
      defaultValue: map['defaultValue'] ?? "",
    );
  }
}
