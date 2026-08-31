class ActivityCategoryItem {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final int displayOrder;
  final DateTime? createdAt;

  const ActivityCategoryItem({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory ActivityCategoryItem.fromJson(Map<String, dynamic> json) {
    return ActivityCategoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'displayOrder': displayOrder,
    };
  }
}
