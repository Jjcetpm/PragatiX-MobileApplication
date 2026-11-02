class ScannedStudentProfileModel {
  final int id;
  final String sprNo;
  final String? regNo;
  final String fullName;
  final String? email;
  final int? departmentId;
  final String? departmentName;
  final String? year;
  final String? academicYear;
  final int? sectionId;
  final String? sectionName;
  final int? teamId;
  final String? teamName;
  final String? teamRole;
  final bool isCaptain;
  final int currentStage;
  final String stageName;
  final int currentXp;
  final int lifetimeXp;
  final String? avatar;

  ScannedStudentProfileModel({
    required this.id,
    required this.sprNo,
    this.regNo,
    required this.fullName,
    this.email,
    this.departmentId,
    this.departmentName,
    this.year,
    this.academicYear,
    this.sectionId,
    this.sectionName,
    this.teamId,
    this.teamName,
    this.teamRole,
    this.isCaptain = false,
    required this.currentStage,
    required this.stageName,
    required this.currentXp,
    required this.lifetimeXp,
    this.avatar,
  });

  factory ScannedStudentProfileModel.fromJson(Map<String, dynamic> json) {
    return ScannedStudentProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sprNo: json['sprNo']?.toString() ?? '',
      regNo: json['regNo']?.toString(),
      fullName: json['fullName']?.toString() ?? 'Student',
      email: json['email']?.toString(),
      departmentId: json['departmentId'] is int ? json['departmentId'] : int.tryParse(json['departmentId']?.toString() ?? ''),
      departmentName: json['departmentName']?.toString(),
      year: json['year']?.toString(),
      academicYear: json['academicYear']?.toString(),
      sectionId: json['sectionId'] is int ? json['sectionId'] : int.tryParse(json['sectionId']?.toString() ?? ''),
      sectionName: json['sectionName']?.toString(),
      teamId: json['teamId'] is int ? json['teamId'] : int.tryParse(json['teamId']?.toString() ?? ''),
      teamName: json['teamName']?.toString(),
      teamRole: json['teamRole']?.toString() ?? (json['captain'] == true ? 'Captain' : 'Member'),
      isCaptain: json['captain'] == true || json['isCaptain'] == true,
      currentStage: json['currentStage'] is int ? json['currentStage'] : int.tryParse(json['currentStage']?.toString() ?? '1') ?? 1,
      stageName: json['stageName']?.toString() ?? 'Stage 1',
      currentXp: json['currentXp'] is int ? json['currentXp'] : int.tryParse(json['currentXp']?.toString() ?? '0') ?? 0,
      lifetimeXp: json['lifetimeXp'] is int ? json['lifetimeXp'] : int.tryParse(json['lifetimeXp']?.toString() ?? '0') ?? 0,
      avatar: json['avatar']?.toString(),
    );
  }
}

class EligibleActivityModel {
  final int activityId;
  final int? assignmentId;
  final String activityName;
  final String? description;
  final String scope;
  final String scopeLabel;
  final bool isVariableXp;
  final bool awardEnabled;
  final int awardXp;
  final int minXp;
  final int maxXp;
  final bool penaltyEnabled;
  final int penaltyXp;
  final bool repeatAllowed;
  final bool alreadyCompleted;
  final String eligibilityStatus; // ELIGIBLE, COMPLETED, INELIGIBLE
  final String? eligibilityMessage;

  EligibleActivityModel({
    required this.activityId,
    this.assignmentId,
    required this.activityName,
    this.description,
    required this.scope,
    required this.scopeLabel,
    required this.isVariableXp,
    required this.awardEnabled,
    required this.awardXp,
    required this.minXp,
    required this.maxXp,
    required this.penaltyEnabled,
    required this.penaltyXp,
    required this.repeatAllowed,
    required this.alreadyCompleted,
    required this.eligibilityStatus,
    this.eligibilityMessage,
  });

  factory EligibleActivityModel.fromJson(Map<String, dynamic> json) {
    return EligibleActivityModel(
      activityId: json['activityId'] is int ? json['activityId'] : int.tryParse(json['activityId']?.toString() ?? '0') ?? 0,
      assignmentId: json['assignmentId'] is int ? json['assignmentId'] : int.tryParse(json['assignmentId']?.toString() ?? ''),
      activityName: json['activityName']?.toString() ?? 'Activity',
      description: json['description']?.toString(),
      scope: json['scope']?.toString() ?? 'GLOBAL',
      scopeLabel: json['scopeLabel']?.toString() ?? 'Institution-Wide',
      isVariableXp: json['isVariableXp'] == true || json['variableXp'] == true,
      awardEnabled: json['awardEnabled'] != false,
      awardXp: json['awardXp'] is int ? json['awardXp'] : int.tryParse(json['awardXp']?.toString() ?? '0') ?? 0,
      minXp: json['minXp'] is int ? json['minXp'] : int.tryParse(json['minXp']?.toString() ?? '1') ?? 1,
      maxXp: json['maxXp'] is int ? json['maxXp'] : int.tryParse(json['maxXp']?.toString() ?? '100') ?? 100,
      penaltyEnabled: json['penaltyEnabled'] == true,
      penaltyXp: json['penaltyXp'] is int ? json['penaltyXp'] : int.tryParse(json['penaltyXp']?.toString() ?? '0') ?? 0,
      repeatAllowed: json['repeatAllowed'] != false,
      alreadyCompleted: json['alreadyCompleted'] == true,
      eligibilityStatus: json['eligibilityStatus']?.toString() ?? 'ELIGIBLE',
      eligibilityMessage: json['eligibilityMessage']?.toString(),
    );
  }
}

class ScannerAwardModel {
  final int studentId;
  final int activityId;
  final int? assignmentId;
  final int xp;
  final String? remarks;
  final String idempotencyKey;

  ScannerAwardModel({
    required this.studentId,
    required this.activityId,
    this.assignmentId,
    required this.xp,
    this.remarks,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'activityId': activityId,
      if (assignmentId != null) 'assignmentId': assignmentId,
      'xp': xp,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      'idempotencyKey': idempotencyKey,
    };
  }
}

class ScannerPenaltyModel {
  final int studentId;
  final int activityId;
  final int? assignmentId;
  final int penaltyXp;
  final String reason;
  final String idempotencyKey;

  ScannerPenaltyModel({
    required this.studentId,
    required this.activityId,
    this.assignmentId,
    required this.penaltyXp,
    required this.reason,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'activityId': activityId,
      if (assignmentId != null) 'assignmentId': assignmentId,
      'penaltyXp': penaltyXp,
      'reason': reason,
      'idempotencyKey': idempotencyKey,
    };
  }
}

class ScannerTransactionResultModel {
  final bool success;
  final String message;
  final int? transactionId;
  final String transactionType; // AWARD, PENALTY
  final int xpPoints;
  final int studentId;
  final String sprNo;
  final String studentName;
  final int newCurrentXp;
  final int newLifetimeXp;
  final String? timestamp;

  ScannerTransactionResultModel({
    required this.success,
    required this.message,
    this.transactionId,
    required this.transactionType,
    required this.xpPoints,
    required this.studentId,
    required this.sprNo,
    required this.studentName,
    required this.newCurrentXp,
    required this.newLifetimeXp,
    this.timestamp,
  });

  factory ScannerTransactionResultModel.fromJson(Map<String, dynamic> json) {
    return ScannerTransactionResultModel(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      transactionId: json['transactionId'] is int ? json['transactionId'] : int.tryParse(json['transactionId']?.toString() ?? ''),
      transactionType: json['transactionType']?.toString() ?? 'AWARD',
      xpPoints: json['xpPoints'] is int ? json['xpPoints'] : int.tryParse(json['xpPoints']?.toString() ?? '0') ?? 0,
      studentId: json['studentId'] is int ? json['studentId'] : int.tryParse(json['studentId']?.toString() ?? '0') ?? 0,
      sprNo: json['sprNo']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      newCurrentXp: json['newCurrentXp'] is int ? json['newCurrentXp'] : int.tryParse(json['newCurrentXp']?.toString() ?? '0') ?? 0,
      newLifetimeXp: json['newLifetimeXp'] is int ? json['newLifetimeXp'] : int.tryParse(json['newLifetimeXp']?.toString() ?? '0') ?? 0,
      timestamp: json['timestamp']?.toString(),
    );
  }
}

