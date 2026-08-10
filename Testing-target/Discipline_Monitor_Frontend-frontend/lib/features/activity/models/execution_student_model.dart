class ExecutionStudentModel {
  final int id;
  final String fullName;
  final String regNo;
  final String departmentName;
  final String sectionName;
  final int totalXp;
  final int score;

  ExecutionStudentModel({
    required this.id,
    required this.fullName,
    required this.regNo,
    required this.departmentName,
    required this.sectionName,
    required this.totalXp,
    required this.score,
  });

  factory ExecutionStudentModel.fromJson(Map<String, dynamic> json) {
    return ExecutionStudentModel(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      regNo: json['regNo'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      sectionName: json['sectionName'] as String? ?? '',
      totalXp: json['totalXp'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'regNo': regNo,
      'departmentName': departmentName,
      'sectionName': sectionName,
      'totalXp': totalXp,
      'score': score,
    };
  }
}

class ActivityExecutionDetailModel {
  final int id;
  final String name;
  final String description;
  final String department;
  final List<String> evidence;
  final String frequency;
  final String type;
  final bool awardEnabled;
  final int awardXp;
  final bool penaltyEnabled;
  final int penaltyXp;
  final String xpCategory;
  final int cap;
  final String? manualEvidenceName;

  List<String> get displayEvidence {
    return evidence.map((e) {
      if (e == 'Manual' && manualEvidenceName != null && manualEvidenceName!.isNotEmpty) {
        return manualEvidenceName!;
      }
      return e;
    }).toList();
  }

  ActivityExecutionDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.department,
    required this.evidence,
    required this.frequency,
    required this.type,
    required this.awardEnabled,
    required this.awardXp,
    required this.penaltyEnabled,
    required this.penaltyXp,
    required this.xpCategory,
    required this.cap,
    this.manualEvidenceName,
  });

  factory ActivityExecutionDetailModel.fromJson(Map<String, dynamic> json) {
    final listRaw = json['evidence'] as List<dynamic>? ?? [];
    final pAwardXp = (json['awardXp'] as num?)?.toInt() ?? 0;

    bool parsedAwardEnabled = true;
    bool parsedPenaltyEnabled = false;
    int parsedPenaltyXp = (json['penaltyXp'] as num?)?.toInt() ?? 0;

    if (json.containsKey('awardEnabled')) {
      parsedAwardEnabled = json['awardEnabled'] as bool? ?? true;
    }
    if (json.containsKey('penaltyEnabled')) {
      parsedPenaltyEnabled = json['penaltyEnabled'] as bool? ?? false;
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

    return ActivityExecutionDetailModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      department: json['department'] as String? ?? '',
      evidence: listRaw.map((e) => e.toString()).toList(),
      frequency: json['frequency'] as String? ?? '',
      type: json['type'] as String? ?? '',
      awardEnabled: parsedAwardEnabled,
      awardXp: pAwardXp,
      penaltyEnabled: parsedPenaltyEnabled,
      penaltyXp: parsedPenaltyXp,
      xpCategory: json['xpCategory'] as String? ?? '',
      cap: (json['cap'] as num?)?.toInt() ?? 1,
      manualEvidenceName: json['manualEvidenceName']?.toString(),
    );
  }
}

class AssignmentExecutionDetailModel {
  final int id;
  final String assignedBy;
  final String assignedAt;
  final String assignedFacultyName;
  final String assignmentMode;

  AssignmentExecutionDetailModel({
    required this.id,
    required this.assignedBy,
    required this.assignedAt,
    required this.assignedFacultyName,
    required this.assignmentMode,
  });

  factory AssignmentExecutionDetailModel.fromJson(Map<String, dynamic> json) {
    return AssignmentExecutionDetailModel(
      id: json['id'] as int? ?? 0,
      assignedBy: json['assignedBy'] as String? ?? '',
      assignedAt: json['assignedAt'] as String? ?? '',
      assignedFacultyName: json['assignedFacultyName'] as String? ?? '',
      assignmentMode: json['assignmentMode'] as String? ?? '',
    );
  }
}

class MyActivityStudentsResponseModel {
  final ActivityExecutionDetailModel activity;
  final List<ExecutionStudentModel> students;
  final int xpLimit;
  final AssignmentExecutionDetailModel assignment;

  MyActivityStudentsResponseModel({
    required this.activity,
    required this.students,
    required this.xpLimit,
    required this.assignment,
  });

  factory MyActivityStudentsResponseModel.fromJson(Map<String, dynamic> json) {
    final studentsRaw = json['students'] as List<dynamic>? ?? [];
    return MyActivityStudentsResponseModel(
      activity: ActivityExecutionDetailModel.fromJson(
        json['activity'] as Map<String, dynamic>? ?? {},
      ),
      students: studentsRaw
          .map((e) => ExecutionStudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      xpLimit: json['xpLimit'] as int? ?? 0,
      assignment: AssignmentExecutionDetailModel.fromJson(
        json['assignment'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
