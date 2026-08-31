class RecycleBinItem {
  final int id;
  final String entityType;
  final String entityName;
  final DateTime? deletedAt;
  final DateTime? permanentDeleteAt;
  final String? deletedBy;
  final String? originalLocation;
  final String? description;

  RecycleBinItem({
    required this.id,
    required this.entityType,
    required this.entityName,
    this.deletedAt,
    this.permanentDeleteAt,
    this.deletedBy,
    this.originalLocation,
    this.description,
  });

  factory RecycleBinItem.fromJson(Map<String, dynamic> json) {
    return RecycleBinItem(
      id: json['id'],
      entityType: json['entityType'] ?? '',
      entityName: json['entityName'] ?? '',
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      permanentDeleteAt: json['permanentDeleteAt'] != null ? DateTime.parse(json['permanentDeleteAt']) : null,
      deletedBy: json['deletedBy'],
      originalLocation: json['originalLocation'],
      description: json['description'],
    );
  }
}
