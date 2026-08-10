import 'package:pragatix/features/activity/models/activity_model.dart';

class GroupedActivityModel {
  final String subgroup;
  final List<ActivityOptionModel> activities;

  GroupedActivityModel({required this.subgroup, required this.activities});

  factory GroupedActivityModel.fromJson(Map<String, dynamic> json) {
    return GroupedActivityModel(
      subgroup: json['subgroup'] as String? ?? 'Uncategorized',
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map(
                (e) => ActivityOptionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class ActivityOptionModel {
  final int id;
  final String name;
  final String description;
  final int awardXp;
  final String awardFrequency;
  final String type;
  final bool alreadyMapped;

  ActivityOptionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.awardXp,
    required this.awardFrequency,
    required this.type,
    this.alreadyMapped = false,
  });

  factory ActivityOptionModel.fromJson(Map<String, dynamic> json) {
    return ActivityOptionModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      awardXp: json['awardXp'] as int? ?? 0,
      awardFrequency: json['awardFrequency'] as String? ?? '',
      type: json['type'] as String? ?? '',
      alreadyMapped: json['alreadyMapped'] as bool? ?? false,
    );
  }

  // Helper to map to ActivityModel if needed for existing functions
  ActivityModel toActivityModel() {
    return ActivityModel(
      id: id,
      name: name,
      description: description,
      awardXp: awardXp,
      penaltyXp: 0,
      cap: 0,
      awardFrequency: awardFrequency,
      type: type,
      xpCategory: 'General',
      awardEnabled: true,
      penaltyEnabled: false,
      assignmentSummary: const [],
      ownerDepartment: 'General',
      departmentId: '',
      teacherId: '',
      ownerSubrole: 'Any',
      evidence: const [],
      xp: awardXp.toString(),
      justification: '',
      displayOrder: 0,
      status: 'ACTIVE',
      awardType: 'Fixed XP',
      awardDays: const [],
      xpType: 'Reward',
    );
  }
}
