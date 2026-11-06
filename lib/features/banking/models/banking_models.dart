class BankModel {
  final int id;
  final String bankName;
  final String bankCode;
  final String? description;
  final String startDate;
  final String endDate;
  final List<String> applicableDepartments;
  final List<String> applicableAcademicYears;
  final String status;
  final String? executionStatus;
  final String? lastExecutionAt;
  final String? createdByName;
  final String? lastResetAt;
  final String? lastResetBy;
  final String? lastResetStatus;
  final String? lastRestoredAt;
  final String? lastRestoredBy;
  final String? lastRestoredStatus;
  final bool isRestored;

  BankModel({
    required this.id,
    required this.bankName,
    required this.bankCode,
    this.description,
    required this.startDate,
    required this.endDate,
    this.applicableDepartments = const [],
    this.applicableAcademicYears = const [],
    required this.status,
    this.executionStatus,
    this.lastExecutionAt,
    this.createdByName,
    this.lastResetAt,
    this.lastResetBy,
    this.lastResetStatus,
    this.lastRestoredAt,
    this.lastRestoredBy,
    this.lastRestoredStatus,
    this.isRestored = false,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'] as int? ?? 0,
      bankName: json['bankName'] as String? ?? '',
      bankCode: json['bankCode'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      applicableDepartments: (json['applicableDepartments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      applicableAcademicYears:
          (json['applicableAcademicYears'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      status: json['status'] as String? ?? 'DRAFT',
      executionStatus: json['executionStatus'] as String?,
      lastExecutionAt: json['lastExecutionAt'] as String?,
      createdByName: json['createdByName'] as String?,
      lastResetAt: json['lastResetAt'] as String?,
      lastResetBy: json['lastResetBy'] as String?,
      lastResetStatus: json['lastResetStatus'] as String?,
      lastRestoredAt: json['lastRestoredAt'] as String?,
      lastRestoredBy: json['lastRestoredBy'] as String?,
      lastRestoredStatus: json['lastRestoredStatus'] as String?,
      isRestored: json['isRestored'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'bankCode': bankCode,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'applicableDepartments': applicableDepartments,
      'applicableAcademicYears': applicableAcademicYears,
      'status': status,
      'executionStatus': executionStatus,
      'lastExecutionAt': lastExecutionAt,
      'createdByName': createdByName,
      'lastResetAt': lastResetAt,
      'lastResetBy': lastResetBy,
      'lastResetStatus': lastResetStatus,
      'lastRestoredAt': lastRestoredAt,
      'lastRestoredBy': lastRestoredBy,
      'lastRestoredStatus': lastRestoredStatus,
      'isRestored': isRestored,
    };
  }
}

class BankStageModel {
  final int id;
  final int bankId;
  final String stageName;
  final String stageCode;
  final String? description;
  final String startDate;
  final String endDate;
  final int displayOrder;
  final String status;

  BankStageModel({
    required this.id,
    required this.bankId,
    required this.stageName,
    required this.stageCode,
    this.description,
    required this.startDate,
    required this.endDate,
    this.displayOrder = 1,
    this.status = 'ACTIVE',
  });

  factory BankStageModel.fromJson(Map<String, dynamic> json) {
    return BankStageModel(
      id: json['id'] as int? ?? 0,
      bankId: json['bankId'] as int? ?? 0,
      stageName: json['stageName'] as String? ?? '',
      stageCode: json['stageCode'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      displayOrder: json['displayOrder'] as int? ?? 1,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class BankSubgroupModel {
  final int id;
  final int stageId;
  final String subgroupName;
  final String subgroupCode;
  final String? description;
  final int displayOrder;
  final String status;

  BankSubgroupModel({
    required this.id,
    required this.stageId,
    required this.subgroupName,
    required this.subgroupCode,
    this.description,
    this.displayOrder = 1,
    this.status = 'ACTIVE',
  });

  factory BankSubgroupModel.fromJson(Map<String, dynamic> json) {
    return BankSubgroupModel(
      id: json['id'] as int? ?? 0,
      stageId: json['stageId'] as int? ?? 0,
      subgroupName: json['subgroupName'] as String? ?? '',
      subgroupCode: json['subgroupCode'] as String? ?? '',
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 1,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class BankingPreviewModel {
  final int bankId;
  final String bankName;
  final String startDate;
  final String endDate;
  final int eligibleStudentsCount;
  final int totalXpAwards;
  final int totalXpPenalties;
  final int totalXpAdjustments;
  final int totalNetXp;
  final bool hasOverlappingBanks;
  final List<String> overlappingBankNames;

  BankingPreviewModel({
    required this.bankId,
    required this.bankName,
    required this.startDate,
    required this.endDate,
    required this.eligibleStudentsCount,
    required this.totalXpAwards,
    required this.totalXpPenalties,
    required this.totalXpAdjustments,
    required this.totalNetXp,
    this.hasOverlappingBanks = false,
    this.overlappingBankNames = const [],
  });

  factory BankingPreviewModel.fromJson(Map<String, dynamic> json) {
    return BankingPreviewModel(
      bankId: json['bankId'] as int? ?? 0,
      bankName: json['bankName'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      eligibleStudentsCount: json['eligibleStudentsCount'] as int? ?? 0,
      totalXpAwards: json['totalXpAwards'] as int? ?? 0,
      totalXpPenalties: json['totalXpPenalties'] as int? ?? 0,
      totalXpAdjustments: json['totalXpAdjustments'] as int? ?? 0,
      totalNetXp: json['totalNetXp'] as int? ?? 0,
      hasOverlappingBanks: json['hasOverlappingBanks'] as bool? ?? false,
      overlappingBankNames: (json['overlappingBankNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class StudentBankStageSummaryModel {
  final int stageId;
  final String stageName;
  final String stageCode;
  final int xpAwards;
  final int xpPenalties;
  final int netXp;

  StudentBankStageSummaryModel({
    required this.stageId,
    required this.stageName,
    required this.stageCode,
    required this.xpAwards,
    required this.xpPenalties,
    required this.netXp,
  });

  factory StudentBankStageSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentBankStageSummaryModel(
      stageId: json['stageId'] as int? ?? 0,
      stageName: json['stageName'] as String? ?? '',
      stageCode: json['stageCode'] as String? ?? '',
      xpAwards: json['xpAwards'] as int? ?? 0,
      xpPenalties: json['xpPenalties'] as int? ?? 0,
      netXp: json['netXp'] as int? ?? 0,
    );
  }
}

class StudentRecentTransactionModel {
  final int transactionId;
  final int points;
  final String type;
  final String activityTitle;
  final String createdAt;

  StudentRecentTransactionModel({
    required this.transactionId,
    required this.points,
    required this.type,
    required this.activityTitle,
    required this.createdAt,
  });

  factory StudentRecentTransactionModel.fromJson(Map<String, dynamic> json) {
    return StudentRecentTransactionModel(
      transactionId: json['transactionId'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      type: json['type'] as String? ?? 'AWARD',
      activityTitle: json['activityTitle'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class StudentBankingTransactionModel {
  final int id;
  final int? sourceTransactionId;
  final int? activityId;
  final String activityName;
  final String? category;
  final int xpPoints;
  final bool isPenalty;
  final String status;
  final String transactionDate;
  final String? approvedBy;
  final String? evidenceUrl;
  final int? stageOrder;
  final String? stageName;
  final int? subgroupId;
  final String? subgroupName;
  final String? executionId;
  final bool isBanked;

  StudentBankingTransactionModel({
    required this.id,
    this.sourceTransactionId,
    this.activityId,
    required this.activityName,
    this.category,
    required this.xpPoints,
    required this.isPenalty,
    required this.status,
    required this.transactionDate,
    this.approvedBy,
    this.evidenceUrl,
    this.stageOrder,
    this.stageName,
    this.subgroupId,
    this.subgroupName,
    this.executionId,
    this.isBanked = false,
  });

  factory StudentBankingTransactionModel.fromJson(Map<String, dynamic> json) {
    return StudentBankingTransactionModel(
      id: json['id'] as int? ?? 0,
      sourceTransactionId: json['sourceTransactionId'] as int?,
      activityId: json['activityId'] as int?,
      activityName: json['activityName'] as String? ?? 'Activity',
      category: json['category'] as String?,
      xpPoints: json['xpPoints'] as int? ?? 0,
      isPenalty: json['isPenalty'] as bool? ?? (json['penalty'] as bool? ?? false),
      status: json['status'] as String? ?? 'APPROVED',
      transactionDate: json['transactionDate'] as String? ?? '',
      approvedBy: json['approvedBy'] as String?,
      evidenceUrl: json['evidenceUrl'] as String?,
      stageOrder: json['stageOrder'] as int?,
      stageName: json['stageName'] as String?,
      subgroupId: json['subgroupId'] as int?,
      subgroupName: json['subgroupName'] as String?,
      executionId: json['executionId'] as String?,
      isBanked: json['isBanked'] as bool? ?? false,
    );
  }
}

class StudentBankSummaryModel {
  final int? bankId;
  final String bankName;
  final String bankCode;
  final String? description;
  final String startDate;
  final String endDate;
  final String bankStatus;
  final String? executionStatus;
  final bool isFinalized;
  final int currentPeriodAwards;
  final int currentPeriodPenalties;
  final int currentPeriodAdjustments;
  final int netCurrentPeriodXp;
  final int bankedXp;
  final int lifetimeXp;
  final String? studentName;
  final String? regNo;
  final String? departmentName;
  final String? sectionName;
  final String? academicYear;
  final String? semester;
  final String? executionId;
  final String? bankingTimestamp;
  final int? bankRank;
  final int? totalBankedStudents;
  final List<StudentBankStageSummaryModel> stageSummaries;
  final List<StudentRecentTransactionModel> recentTransactions;

  StudentBankSummaryModel({
    this.bankId,
    required this.bankName,
    required this.bankCode,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.bankStatus,
    this.executionStatus,
    this.isFinalized = false,
    required this.currentPeriodAwards,
    required this.currentPeriodPenalties,
    required this.currentPeriodAdjustments,
    required this.netCurrentPeriodXp,
    required this.bankedXp,
    required this.lifetimeXp,
    this.studentName,
    this.regNo,
    this.departmentName,
    this.sectionName,
    this.academicYear,
    this.semester,
    this.executionId,
    this.bankingTimestamp,
    this.bankRank,
    this.totalBankedStudents,
    this.stageSummaries = const [],
    this.recentTransactions = const [],
  });

  factory StudentBankSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentBankSummaryModel(
      bankId: json['bankId'] as int?,
      bankName: json['bankName'] as String? ?? '',
      bankCode: json['bankCode'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      bankStatus: json['bankStatus'] as String? ?? 'ACTIVE',
      executionStatus: json['executionStatus'] as String?,
      isFinalized: json['isFinalized'] as bool? ?? (json['isBanked'] as bool? ?? false),
      currentPeriodAwards: json['periodAwardsXp'] as int? ?? (json['currentPeriodAwards'] as int? ?? 0),
      currentPeriodPenalties: json['periodPenaltiesXp'] as int? ?? (json['currentPeriodPenalties'] as int? ?? 0),
      currentPeriodAdjustments: json['totalAdjustments'] as int? ?? (json['currentPeriodAdjustments'] as int? ?? 0),
      netCurrentPeriodXp: json['periodNetXp'] as int? ?? (json['netCurrentPeriodXp'] as int? ?? 0),
      bankedXp: json['bankedXp'] as int? ?? 0,
      lifetimeXp: json['lifetimeXp'] as int? ?? 0,
      studentName: json['studentName'] as String?,
      regNo: json['regNo'] as String?,
      departmentName: json['departmentName'] as String?,
      sectionName: json['sectionName'] as String?,
      academicYear: json['academicYear'] as String?,
      semester: json['semester'] as String?,
      executionId: json['executionId'] as String?,
      bankingTimestamp: json['bankingTimestamp'] as String?,
      bankRank: json['bankRank'] as int?,
      totalBankedStudents: json['totalBankedStudents'] as int?,
      stageSummaries: ((json['stageBreakdown'] ?? json['stageSummaries']) as List<dynamic>?)
              ?.map((e) {
                final map = e as Map<String, dynamic>;
                return StudentBankStageSummaryModel(
                  stageId: map['stageId'] as int? ?? 0,
                  stageName: map['stageName'] as String? ?? '',
                  stageCode: map['stageCode'] as String? ?? '',
                  xpAwards: map['xpAwards'] as int? ?? (map['earnedXp'] as int? ?? 0),
                  xpPenalties: map['xpPenalties'] as int? ?? 0,
                  netXp: map['netXp'] as int? ?? (map['earnedXp'] as int? ?? 0),
                );
              })
              .toList() ??
          [],
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) {
                final map = e as Map<String, dynamic>;
                final bool isPen = map['penalty'] as bool? ?? (map['isPenalty'] as bool? ?? false);
                final int pts = map['xpPoints'] as int? ?? (map['points'] as int? ?? 0);
                return StudentRecentTransactionModel(
                  transactionId: map['transactionId'] as int? ?? 0,
                  points: pts.abs(),
                  type: map['type'] as String? ?? (isPen ? 'PENALTY' : 'AWARD'),
                  activityTitle: map['activityName'] as String? ?? (map['activityTitle'] as String? ?? 'Activity'),
                  createdAt: map['submittedAt'] as String? ?? (map['createdAt'] as String? ?? ''),
                );
              })
              .toList() ??
          [],
    );
  }
}

class StudentBankingRecordModel {
  final int id;
  final int studentId;
  final String studentName;
  final String? registerNumber;
  final String? departmentName;
  final String? academicYear;
  final int xpAwards;
  final int xpPenalties;
  final int netXpBanked;
  final int lifetimeXpSnapshot;
  final String bankedAt;
  final int? bankRank;

  StudentBankingRecordModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.registerNumber,
    this.departmentName,
    this.academicYear,
    required this.xpAwards,
    required this.xpPenalties,
    required this.netXpBanked,
    required this.lifetimeXpSnapshot,
    required this.bankedAt,
    this.bankRank,
  });

  factory StudentBankingRecordModel.fromJson(Map<String, dynamic> json) {
    return StudentBankingRecordModel(
      id: json['id'] as int? ?? 0,
      studentId: json['studentId'] as int? ?? 0,
      studentName: json['studentName'] as String? ?? '',
      registerNumber: json['registerNumber'] as String?,
      departmentName: json['departmentName'] as String?,
      academicYear: json['academicYear'] as String?,
      xpAwards: json['xpAwards'] as int? ?? 0,
      xpPenalties: json['xpPenalties'] as int? ?? 0,
      netXpBanked: json['netXpBanked'] as int? ?? 0,
      lifetimeXpSnapshot: json['lifetimeXpSnapshot'] as int? ?? 0,
      bankedAt: json['bankedAt'] as String? ?? '',
      bankRank: json['bankRank'] as int?,
    );
  }
}

class ResetHistoryModel {
  final int id;
  final int bankId;
  final String scope;
  final int? targetId;
  final String reason;
  final String resetByName;
  final int affectedStudentCount;
  final String resetAt;

  ResetHistoryModel({
    required this.id,
    required this.bankId,
    required this.scope,
    this.targetId,
    required this.reason,
    required this.resetByName,
    required this.affectedStudentCount,
    required this.resetAt,
  });

  factory ResetHistoryModel.fromJson(Map<String, dynamic> json) {
    return ResetHistoryModel(
      id: json['id'] as int? ?? 0,
      bankId: json['bankId'] as int? ?? 0,
      scope: json['scope'] as String? ?? 'ENTIRE_BANK',
      targetId: json['targetId'] as int?,
      reason: json['reason'] as String? ?? '',
      resetByName: json['resetByName'] as String? ?? '',
      affectedStudentCount: json['affectedStudentCount'] as int? ?? 0,
      resetAt: json['resetAt'] as String? ?? '',
    );
  }
}

class BankDashboardStatsModel {
  final int totalBanks;
  final int draftBanks;
  final int activeBanks;
  final int completedBanks;
  final int totalStudentsBanked;
  final int totalXpBanked;
  final int totalXpPenalties;
  final int totalNetXpBanked;
  final String? lastExecutionStatus;
  final String? lastExecutionAt;

  BankDashboardStatsModel({
    this.totalBanks = 0,
    this.draftBanks = 0,
    this.activeBanks = 0,
    this.completedBanks = 0,
    this.totalStudentsBanked = 0,
    this.totalXpBanked = 0,
    this.totalXpPenalties = 0,
    this.totalNetXpBanked = 0,
    this.lastExecutionStatus,
    this.lastExecutionAt,
  });

  factory BankDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return BankDashboardStatsModel(
      totalBanks: json['totalBanks'] as int? ?? 0,
      draftBanks: json['draftBanks'] as int? ?? 0,
      activeBanks: json['activeBanks'] as int? ?? 0,
      completedBanks: json['completedBanks'] as int? ?? 0,
      totalStudentsBanked: json['totalStudentsBanked'] as int? ?? 0,
      totalXpBanked: json['totalXpBanked'] as int? ?? 0,
      totalXpPenalties: json['totalXpPenalties'] as int? ?? 0,
      totalNetXpBanked: json['totalNetXpBanked'] as int? ?? 0,
      lastExecutionStatus: json['lastExecutionStatus'] as String?,
      lastExecutionAt: json['lastExecutionAt'] as String?,
    );
  }
}

class BankSettingsModel {
  final int bankId;
  final String bankName;
  final String bankCode;
  final String? description;
  final String startDate;
  final String endDate;
  final String? academicYear;
  final String? semester;
  final String status;
  final String? executionStatus;
  final String? lastExecutedAt;
  final String? lastExecutedBy;
  final String? lastResetAt;
  final String? lastResetBy;
  final String? lastResetStatus;
  final String? lastRestoredAt;
  final String? lastRestoredBy;
  final String? lastRestoredStatus;
  final bool isRestored;
  final int totalStudentsBanked;
  final int totalXpBanked;
  final int totalPenaltiesBanked;
  final int netXpBanked;
  final int currentEligibleStudentsCount;
  final int currentPeriodNetXp;
  final int totalStagesCount;
  final int totalSubgroupsCount;

  BankSettingsModel({
    required this.bankId,
    required this.bankName,
    required this.bankCode,
    this.description,
    required this.startDate,
    required this.endDate,
    this.academicYear,
    this.semester,
    required this.status,
    this.executionStatus,
    this.lastExecutedAt,
    this.lastExecutedBy,
    this.lastResetAt,
    this.lastResetBy,
    this.lastResetStatus,
    this.lastRestoredAt,
    this.lastRestoredBy,
    this.lastRestoredStatus,
    this.isRestored = false,
    this.totalStudentsBanked = 0,
    this.totalXpBanked = 0,
    this.totalPenaltiesBanked = 0,
    this.netXpBanked = 0,
    this.currentEligibleStudentsCount = 0,
    this.currentPeriodNetXp = 0,
    this.totalStagesCount = 0,
    this.totalSubgroupsCount = 0,
  });

  factory BankSettingsModel.fromJson(Map<String, dynamic> json) {
    return BankSettingsModel(
      bankId: json['bankId'] as int? ?? 0,
      bankName: json['bankName'] as String? ?? '',
      bankCode: json['bankCode'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      academicYear: json['academicYear'] as String?,
      semester: json['semester'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      executionStatus: json['executionStatus'] as String?,
      lastExecutedAt: json['lastExecutedAt'] as String?,
      lastExecutedBy: json['lastExecutedBy'] as String?,
      lastResetAt: json['lastResetAt'] as String?,
      lastResetBy: json['lastResetBy'] as String?,
      lastResetStatus: json['lastResetStatus'] as String?,
      lastRestoredAt: json['lastRestoredAt'] as String?,
      lastRestoredBy: json['lastRestoredBy'] as String?,
      lastRestoredStatus: json['lastRestoredStatus'] as String?,
      isRestored: json['isRestored'] as bool? ?? false,
      totalStudentsBanked: json['totalStudentsBanked'] as int? ?? 0,
      totalXpBanked: json['totalXpBanked'] as int? ?? 0,
      totalPenaltiesBanked: json['totalPenaltiesBanked'] as int? ?? 0,
      netXpBanked: json['netXpBanked'] as int? ?? 0,
      currentEligibleStudentsCount: json['currentEligibleStudentsCount'] as int? ?? 0,
      currentPeriodNetXp: json['currentPeriodNetXp'] as int? ?? 0,
      totalStagesCount: json['totalStagesCount'] as int? ?? 0,
      totalSubgroupsCount: json['totalSubgroupsCount'] as int? ?? 0,
    );
  }
}

class ResetPreviewModel {
  final int bankId;
  final String bankName;
  final String bankCode;
  final String scope;
  final int? targetStageId;
  final String? targetStageName;
  final int? targetSubgroupId;
  final String? targetSubgroupName;
  final int? targetStudentId;
  final String? targetStudentRegNo;
  final String? targetStudentName;
  final int affectedStudentCount;
  final int currentPeriodXpTotal;
  final int bankedXpTotal;
  final String executionStatus;
  final bool canReset;
  final String preservationNotice;
  final List<String> warnings;

  ResetPreviewModel({
    required this.bankId,
    required this.bankName,
    required this.bankCode,
    required this.scope,
    this.targetStageId,
    this.targetStageName,
    this.targetSubgroupId,
    this.targetSubgroupName,
    this.targetStudentId,
    this.targetStudentRegNo,
    this.targetStudentName,
    required this.affectedStudentCount,
    required this.currentPeriodXpTotal,
    required this.bankedXpTotal,
    required this.executionStatus,
    required this.canReset,
    required this.preservationNotice,
    this.warnings = const [],
  });

  factory ResetPreviewModel.fromJson(Map<String, dynamic> json) {
    return ResetPreviewModel(
      bankId: json['bankId'] as int? ?? 0,
      bankName: json['bankName'] as String? ?? '',
      bankCode: json['bankCode'] as String? ?? '',
      scope: json['scope'] as String? ?? 'ENTIRE_BANK',
      targetStageId: json['targetStageId'] as int?,
      targetStageName: json['targetStageName'] as String?,
      targetSubgroupId: json['targetSubgroupId'] as int?,
      targetSubgroupName: json['targetSubgroupName'] as String?,
      targetStudentId: json['targetStudentId'] as int?,
      targetStudentRegNo: json['targetStudentRegNo'] as String?,
      targetStudentName: json['targetStudentName'] as String?,
      affectedStudentCount: json['affectedStudentCount'] as int? ?? 0,
      currentPeriodXpTotal: json['currentPeriodXpTotal'] as int? ?? 0,
      bankedXpTotal: json['bankedXpTotal'] as int? ?? 0,
      executionStatus: json['executionStatus'] as String? ?? 'IDLE',
      canReset: json['canReset'] as bool? ?? false,
      preservationNotice: json['preservationNotice'] as String? ?? '',
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class RestorePreviewModel {
  final int bankId;
  final String bankName;
  final String bankCode;
  final String startDate;
  final String endDate;
  final String scope;
  final int? targetStageId;
  final String? targetStageName;
  final int? targetSubgroupId;
  final String? targetSubgroupName;
  final int? targetStudentId;
  final String? targetStudentRegNo;
  final String? targetStudentName;
  final int affectedStudentCount;
  final int totalXpToRestore;
  final int transactionsToReactivateCount;
  final int currentPeriodTotalXp;
  final int expectedResultingTotalXp;
  final bool alreadyRestored;
  final String? lastRestoredAt;
  final String? lastRestoredBy;
  final bool wasReset;
  final String? lastResetAt;
  final bool canRestore;
  final String preservationNotice;
  final List<String> warnings;

  RestorePreviewModel({
    required this.bankId,
    required this.bankName,
    required this.bankCode,
    required this.startDate,
    required this.endDate,
    required this.scope,
    this.targetStageId,
    this.targetStageName,
    this.targetSubgroupId,
    this.targetSubgroupName,
    this.targetStudentId,
    this.targetStudentRegNo,
    this.targetStudentName,
    required this.affectedStudentCount,
    required this.totalXpToRestore,
    required this.transactionsToReactivateCount,
    required this.currentPeriodTotalXp,
    required this.expectedResultingTotalXp,
    required this.alreadyRestored,
    this.lastRestoredAt,
    this.lastRestoredBy,
    required this.wasReset,
    this.lastResetAt,
    required this.canRestore,
    required this.preservationNotice,
    this.warnings = const [],
  });

  factory RestorePreviewModel.fromJson(Map<String, dynamic> json) {
    return RestorePreviewModel(
      bankId: json['bankId'] as int? ?? 0,
      bankName: json['bankName'] as String? ?? '',
      bankCode: json['bankCode'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      scope: json['scope'] as String? ?? 'ENTIRE_BANK',
      targetStageId: json['targetStageId'] as int?,
      targetStageName: json['targetStageName'] as String?,
      targetSubgroupId: json['targetSubgroupId'] as int?,
      targetSubgroupName: json['targetSubgroupName'] as String?,
      targetStudentId: json['targetStudentId'] as int?,
      targetStudentRegNo: json['targetStudentRegNo'] as String?,
      targetStudentName: json['targetStudentName'] as String?,
      affectedStudentCount: json['affectedStudentCount'] as int? ?? 0,
      totalXpToRestore: json['totalXpToRestore'] as int? ?? 0,
      transactionsToReactivateCount:
          json['transactionsToReactivateCount'] as int? ?? 0,
      currentPeriodTotalXp: json['currentPeriodTotalXp'] as int? ?? 0,
      expectedResultingTotalXp: json['expectedResultingTotalXp'] as int? ?? 0,
      alreadyRestored: json['alreadyRestored'] as bool? ?? false,
      lastRestoredAt: json['lastRestoredAt'] as String?,
      lastRestoredBy: json['lastRestoredBy'] as String?,
      wasReset: json['wasReset'] as bool? ?? false,
      lastResetAt: json['lastResetAt'] as String?,
      canRestore: json['canRestore'] as bool? ?? true,
      preservationNotice: json['preservationNotice'] as String? ?? '',
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class RestoreHistoryModel {
  final int id;
  final int bankId;
  final String scope;
  final int? targetStageId;
  final int? targetSubgroupId;
  final int? targetStudentId;
  final String? targetStudentRegNo;
  final int affectedStudentCount;
  final int totalXpRestored;
  final String reason;
  final String? executedByName;
  final String? executedByUsername;
  final String status;
  final String? idempotencyKey;
  final String createdAt;

  RestoreHistoryModel({
    required this.id,
    required this.bankId,
    required this.scope,
    this.targetStageId,
    this.targetSubgroupId,
    this.targetStudentId,
    this.targetStudentRegNo,
    required this.affectedStudentCount,
    required this.totalXpRestored,
    required this.reason,
    this.executedByName,
    this.executedByUsername,
    required this.status,
    this.idempotencyKey,
    required this.createdAt,
  });

  factory RestoreHistoryModel.fromJson(Map<String, dynamic> json) {
    return RestoreHistoryModel(
      id: json['id'] as int? ?? json['restoreId'] as int? ?? 0,
      bankId: json['bankId'] as int? ?? (json['bank'] != null ? json['bank']['id'] as int? ?? 0 : 0),
      scope: json['scope'] as String? ?? json['restoreScope'] as String? ?? 'ENTIRE_BANK',
      targetStageId: json['targetStageId'] as int?,
      targetSubgroupId: json['targetSubgroupId'] as int?,
      targetStudentId: json['targetStudentId'] as int?,
      targetStudentRegNo: json['targetStudentRegNo'] as String?,
      affectedStudentCount: json['affectedStudentCount'] as int? ?? 0,
      totalXpRestored: json['totalXpRestored'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      executedByName: json['executedByName'] as String?,
      executedByUsername: json['executedByUsername'] as String?,
      status: json['status'] as String? ?? 'SUCCESS',
      idempotencyKey: json['idempotencyKey'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
