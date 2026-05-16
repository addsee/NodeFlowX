class BlockModel {
  String id;
  String title;
  int type; // (0: OnStart, 1: OnUpdate, 2: Move, 3: Rotate, 4: If, 5: Variable, etc.)
  Map<String, dynamic> properties;
  
  // Linking for vertical sequence
  String? nextBlockId;
  String? parentBlockId; // Optional: To easily traverse back up the tree

  // Nesting logic for branches
  String? trueBranchHeadId;
  String? falseBranchHeadId;

  BlockModel({
    required this.id,
    required this.title,
    required this.type,
    this.properties = const {},
    this.nextBlockId,
    this.parentBlockId,
    this.trueBranchHeadId,
    this.falseBranchHeadId,
  });

  BlockModel copyWith({
    String? nextBlockId,
    String? parentBlockId,
    String? trueBranchHeadId,
    String? falseBranchHeadId,
    Map<String, dynamic>? properties,
  }) {
    return BlockModel(
      id: id,
      title: title,
      type: type,
      properties: properties ?? this.properties,
      nextBlockId: nextBlockId ?? this.nextBlockId,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      trueBranchHeadId: trueBranchHeadId ?? this.trueBranchHeadId,
      falseBranchHeadId: falseBranchHeadId ?? this.falseBranchHeadId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'properties': properties,
      'nextBlockId': nextBlockId,
      'parentBlockId': parentBlockId,
      'trueBranchHeadId': trueBranchHeadId,
      'falseBranchHeadId': falseBranchHeadId,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as int,
      properties: Map<String, dynamic>.from(map['properties'] as Map? ?? {}),
      nextBlockId: map['nextBlockId'] as String?,
      parentBlockId: map['parentBlockId'] as String?,
      trueBranchHeadId: map['trueBranchHeadId'] as String?,
      falseBranchHeadId: map['falseBranchHeadId'] as String?,
    );
  }
}
