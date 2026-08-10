// ─────────────────────────────────────────────────────────────────────────────
// Activity module – domain model.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityModel {
  final int id;
  final String name;
  final String description;
  final String ownerDepartment;
  final String departmentId;
  final String teacherId;
  final String ownerSubrole;
  final List<String> evidence;
  final String xp;
  final String type;
  final String justification;
  final List<Map<String, dynamic>> assignmentSummary;
  final String xpCategory;
  final int displayOrder;
  final String status;
  final int awardXp;
  final bool awardEnabled;
  final bool penaltyEnabled;
  final int penaltyXp;
  final String awardType;
  // ── Refactored Award Rules ─────────────────────────────────────────────────
  final int cap; // max awards per frequency window
  final String awardFrequency; // One Time | Daily | Weekly | Monthly | Manual
  final List<String> awardDays; // working days (Weekly only)
  final String xpType;
  final String assignmentMode; // MANUAL | GLOBAL | CLASS_COORDINATOR
  final String? subgroup;
  final List<Map<String, dynamic>> mappedStages;
  final bool allowStudentRequest;
  
  // ── Attendance Engine Mapping ──────────────────────────────────────────────
  final bool attendanceEngineEnabled;
  final String? attendanceRule;
  
  final String? manualEvidenceName;
  final bool streakEnabled;

  String get frequency => awardFrequency;
  String get resetPeriod => awardFrequency;
  int get maximumAwards => cap;
  bool get repeatAllowed => awardFrequency.toLowerCase() != 'one time';

  List<String> get displayEvidence {
    return evidence.map((e) {
      if (e == 'Manual' && manualEvidenceName != null && manualEvidenceName!.isNotEmpty) {
        return manualEvidenceName!;
      }
      return e;
    }).toList();
  }

  const ActivityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerDepartment,
    required this.departmentId,
    required this.teacherId,
    required this.ownerSubrole,
    required this.evidence,
    required this.xp,
    required this.type,
    required this.justification,
    required this.assignmentSummary,
    required this.xpCategory,
    required this.displayOrder,
    required this.status,
    required this.awardXp,
    required this.awardEnabled,
    required this.penaltyEnabled,
    required this.penaltyXp,
    required this.awardType,
    required this.cap,
    required this.awardFrequency,
    required this.awardDays,
    required this.xpType,
    this.assignmentMode = 'MANUAL',
    this.subgroup,
    this.mappedStages = const [],
    this.allowStudentRequest = false,
    this.attendanceEngineEnabled = false,
    this.attendanceRule,
    this.manualEvidenceName,
    this.streakEnabled = false,
  });
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final raw = json['evidence'];
    final List<String> evidenceList;
    if (raw is List) {
      evidenceList = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.isNotEmpty) {
      evidenceList = raw.split(',').map((e) => e.trim()).toList();
    } else {
      evidenceList = [];
    }

    final rawSummary = json['assignmentSummary'];
    final List<Map<String, dynamic>> summaryList;
    if (rawSummary is List) {
      summaryList = rawSummary
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      summaryList = [];
    }

    final parsedAwardXp =
        (json['awardXp'] as num?)?.toInt() ??
        (json['xp'] != null ? int.tryParse(json['xp'].toString()) ?? 0 : 0);
    bool parsedAwardEnabled = true;
    bool parsedPenaltyEnabled = false;
    int parsedPenaltyXp = (json['penaltyXp'] as num?)?.toInt() ?? 0;

    if (json.containsKey('awardEnabled')) {
      parsedAwardEnabled = json['awardEnabled'] as bool? ?? true;
    } else {
      if (json['xpType']?.toString().toLowerCase() == 'penalty' ||
          json['xpType']?.toString().toLowerCase() == 'discipline') {
        parsedAwardEnabled = false;
      }
    }
    if (json.containsKey('penaltyEnabled')) {
      parsedPenaltyEnabled = json['penaltyEnabled'] as bool? ?? false;
    } else {
      if (json['xpType']?.toString().toLowerCase() == 'penalty' ||
          json['xpType']?.toString().toLowerCase() == 'discipline' ||
          json['xpType']?.toString().toLowerCase() == 'mixed') {
        parsedPenaltyEnabled = true;
        parsedPenaltyXp = parsedAwardXp;
      }
    }
    if (!json.containsKey('awardEnabled') &&
        !json.containsKey('penaltyEnabled')) {
      final pX = (json['passXp'] as num?)?.toInt() ?? 0;
      final fX = (json['failXp'] as num?)?.toInt() ?? 0;
      if (pX > 0 || fX > 0) {
        parsedAwardEnabled = pX > 0;
        parsedPenaltyEnabled = fX > 0;
        parsedPenaltyXp = fX;
      }
    }

    // Award Frequency — support both new and legacy field names
    final parsedFrequency =
        (json['awardFrequency'] as String?)?.isNotEmpty == true
        ? json['awardFrequency'] as String
        : (json['resetPeriod'] as String?)?.isNotEmpty == true
        ? json['resetPeriod'] as String
        : (json['frequency'] as String?)?.isNotEmpty == true
        ? json['frequency'] as String
        : 'One Time';

    // Cap — support both new and legacy field names
    final parsedCap = (json['cap'] is num)
        ? (json['cap'] as num).toInt()
        : (json['maximumAwards'] is num)
        ? (json['maximumAwards'] as num).toInt()
        : int.tryParse(json['cap']?.toString() ?? '1') ?? 1;

    // Award Days
    final rawDays = json['awardDays'];
    final List<String> parsedDays;
    if (rawDays is List) {
      parsedDays = rawDays.map((e) => e.toString()).toList();
    } else if (rawDays is String && rawDays.isNotEmpty) {
      parsedDays = rawDays.split(',').map((e) => e.trim()).toList();
    } else {
      parsedDays = [];
    }

    final rawMappedStages = json['mappedStages'];
    final List<Map<String, dynamic>> mappedStagesList;
    if (rawMappedStages is List) {
      mappedStagesList = rawMappedStages
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      mappedStagesList = [];
    }

    return ActivityModel(
      id: (json['id'] as num).toInt(),
      name:
          json['name']?.toString() ??
          json['activityName']?.toString() ??
          'Unnamed',
      description:
          json['description']?.toString() ??
          json['activityDescription']?.toString() ??
          '',
      ownerDepartment: json['ownerDepartment']?.toString() ?? 'General',
      departmentId: json['departmentId']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      ownerSubrole: json['ownerSubrole']?.toString() ?? 'Any',
      evidence: evidenceList,
      xp: parsedAwardXp.toString(),
      type:
          json['type']?.toString() ?? json['modeType']?.toString() ?? 'General',
      justification: json['justification']?.toString() ?? '',
      assignmentSummary: summaryList,
      xpCategory: json['xpCategory']?.toString() ?? 'General',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'ACTIVE',
      awardXp: parsedAwardXp,
      awardEnabled: parsedAwardEnabled,
      penaltyEnabled: parsedPenaltyEnabled,
      penaltyXp: parsedPenaltyXp,
      awardType: json['awardType']?.toString() ?? 'Fixed XP',
      cap: parsedCap,
      awardFrequency: parsedFrequency,
      awardDays: parsedDays,
      xpType: json['xpType']?.toString() ?? 'Reward',
      assignmentMode: json['assignmentMode']?.toString() ?? 'MANUAL',
      subgroup: json['subgroup'] is Map ? json['subgroup']['name']?.toString() : json['subgroup']?.toString(),
      mappedStages: mappedStagesList,
      allowStudentRequest: json['allowStudentRequest'] as bool? ?? false,
      attendanceEngineEnabled: json['attendanceEngineEnabled'] as bool? ?? false,
      attendanceRule: json['attendanceRule']?.toString(),
      manualEvidenceName: json['manualEvidenceName']?.toString(),
      streakEnabled: json['streakEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'ownerDepartment': ownerDepartment,
    'departmentId': departmentId,
    'teacherId': teacherId,
    'ownerSubrole': ownerSubrole,
    'evidence': evidence.join(', '),
    'xp': awardXp.toString(),
    'type': type,
    'justification': justification,
    'assignmentSummary': assignmentSummary,
    'xpCategory': xpCategory,
    'displayOrder': displayOrder,
    'status': status,
    'awardXp': awardXp,
    'awardEnabled': awardEnabled,
    'penaltyEnabled': penaltyEnabled,
    'penaltyXp': penaltyXp,
    'awardType': awardType,
    'cap': cap,
    'awardFrequency': awardFrequency,
    'awardDays': awardDays,
    'xpType': xpType,
    'assignmentMode': assignmentMode,
    'subgroup': subgroup,
    'allowStudentRequest': allowStudentRequest,
    'attendanceEngineEnabled': attendanceEngineEnabled,
    'attendanceRule': attendanceRule,
    if (manualEvidenceName != null) 'manualEvidenceName': manualEvidenceName,
  };
  ActivityModel copyWith({
    int? id,
    String? name,
    String? description,
    String? ownerDepartment,
    String? departmentId,
    String? teacherId,
    String? ownerSubrole,
    List<String>? evidence,
    String? xp,
    String? type,
    String? justification,
    List<Map<String, dynamic>>? assignmentSummary,
    String? xpCategory,
    int? displayOrder,
    String? status,
    int? awardXp,
    bool? awardEnabled,
    bool? penaltyEnabled,
    int? penaltyXp,
    String? awardType,
    int? cap,
    String? awardFrequency,
    List<String>? awardDays,
    String? xpType,
    String? assignmentMode,
    String? subgroup,
    bool? allowStudentRequest,
    bool? attendanceEngineEnabled,
    String? attendanceRule,
    String? manualEvidenceName,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerDepartment: ownerDepartment ?? this.ownerDepartment,
      departmentId: departmentId ?? this.departmentId,
      teacherId: teacherId ?? this.teacherId,
      ownerSubrole: ownerSubrole ?? this.ownerSubrole,
      evidence: evidence ?? this.evidence,
      xp: xp ?? this.xp,
      type: type ?? this.type,
      justification: justification ?? this.justification,
      assignmentSummary: assignmentSummary ?? this.assignmentSummary,
      xpCategory: xpCategory ?? this.xpCategory,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
      awardXp: awardXp ?? this.awardXp,
      awardEnabled: awardEnabled ?? this.awardEnabled,
      penaltyEnabled: penaltyEnabled ?? this.penaltyEnabled,
      penaltyXp: penaltyXp ?? this.penaltyXp,
      awardType: awardType ?? this.awardType,
      cap: cap ?? this.cap,
      awardFrequency: awardFrequency ?? this.awardFrequency,
      awardDays: awardDays ?? this.awardDays,
      xpType: xpType ?? this.xpType,
      assignmentMode: assignmentMode ?? this.assignmentMode,
      subgroup: subgroup ?? this.subgroup,
      allowStudentRequest: allowStudentRequest ?? this.allowStudentRequest,
      attendanceEngineEnabled: attendanceEngineEnabled ?? this.attendanceEngineEnabled,
      attendanceRule: attendanceRule ?? this.attendanceRule,
      manualEvidenceName: manualEvidenceName ?? this.manualEvidenceName,
    );
  }
}
