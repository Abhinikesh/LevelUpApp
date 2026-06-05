class BadgeModel {
  final String id;
  final String badgeType;
  final String badgeName;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final String? rarity; // common / rare / epic / legendary

  const BadgeModel({
    required this.id,
    required this.badgeType,
    required this.badgeName,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.rarity,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      badgeType: json['badgeType'] as String? ?? '',
      badgeName: json['badgeName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏆',
      earnedAt: json['earnedAt'] != null
          ? DateTime.tryParse(json['earnedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      rarity: json['rarity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'badgeType': badgeType,
      'badgeName': badgeName,
      'description': description,
      'icon': icon,
      'earnedAt': earnedAt.toIso8601String(),
      'rarity': rarity,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BadgeModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BadgeModel($badgeName)';
}
