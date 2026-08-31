class ActivityEvidenceItem {
  final int id;
  final String name;
  final String? description;
  final int displayOrder;

  ActivityEvidenceItem({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder = 0,
  });

  factory ActivityEvidenceItem.fromJson(Map<String, dynamic> json) {
    return ActivityEvidenceItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      displayOrder: json['displayOrder'] is int
          ? json['displayOrder']
          : int.tryParse(json['displayOrder']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'displayOrder': displayOrder,
    };
  }
}
