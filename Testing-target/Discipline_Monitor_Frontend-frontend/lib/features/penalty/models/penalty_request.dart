class PenaltyRequest {
  final int id;
  final String? studentName;
  final String? regNo;
  final String? department;
  final String? year;
  final String? section;
  final String? penaltyActivity;
  final int penaltyXP;
  final String? reason;
  final String? submittedBy;
  final DateTime? submittedTime;
  final String status;
  final String? approvedBy;
  final DateTime? approvalTime;
  final String? rejectedReason;

  PenaltyRequest({
    required this.id,
    this.studentName,
    this.regNo,
    this.department,
    this.year,
    this.section,
    this.penaltyActivity,
    required this.penaltyXP,
    this.reason,
    this.submittedBy,
    this.submittedTime,
    required this.status,
    this.approvedBy,
    this.approvalTime,
    this.rejectedReason,
  });

  factory PenaltyRequest.fromJson(Map<String, dynamic> json) {
    return PenaltyRequest(
      id: json['id'],
      studentName: json['studentName'],
      regNo: json['regNo'],
      department: json['department'],
      year: json['year'],
      section: json['section'],
      penaltyActivity: json['penaltyActivity'],
      penaltyXP: json['penaltyXP'] ?? 0,
      reason: json['reason'],
      submittedBy: json['submittedBy'],
      submittedTime: json['submittedTime'] != null
          ? DateTime.parse(json['submittedTime'])
          : null,
      status: json['status'] ?? 'PENDING',
      approvedBy: json['approvedBy'],
      approvalTime: json['approvalTime'] != null
          ? DateTime.parse(json['approvalTime'])
          : null,
      rejectedReason: json['rejectedReason'],
    );
  }
}
