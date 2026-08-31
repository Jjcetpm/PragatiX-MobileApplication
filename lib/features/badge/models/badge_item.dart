class BadgeItem {
  final int id;
  final String name;
  final String tier;
  final String description;
  final int xpRequired;
  final String iconUrl;
  final String approvalAuthority;
  final String rarity;
  final bool proofRequired;

  BadgeItem({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    required this.xpRequired,
    required this.iconUrl,
    required this.approvalAuthority,
    required this.rarity,
    required this.proofRequired,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      tier: json['tier']?.toString() ?? 'ACHIEVEMENT',
      description: json['description']?.toString() ?? '',
      xpRequired: json['xpRequired'] is int
          ? json['xpRequired']
          : int.tryParse(json['xpRequired']?.toString() ?? '0') ?? 0,
      iconUrl: json['iconUrl']?.toString() ?? '',
      approvalAuthority: json['approvalAuthority']?.toString() ?? 'Admin',
      rarity: json['rarity']?.toString() ?? 'COMMON',
      proofRequired: json['proofRequired'] is bool
          ? json['proofRequired']
          : (json['proofRequired'] != null &&
              (json['proofRequired'].toString().toLowerCase() == 'true' ||
               json['proofRequired'].toString() == '1')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'description': description,
      'xpRequired': xpRequired,
      'iconUrl': iconUrl,
      'approvalAuthority': approvalAuthority,
      'rarity': rarity,
      'proofRequired': proofRequired,
    };
  }
}
