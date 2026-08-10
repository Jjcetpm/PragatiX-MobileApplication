class ActivityCompletionRequest {
  final int id;
  final String? studentName;
  final String? regNo;
  final String? department;
  final String? year;
  final String? section;
  final int activityId;
  final String? activityName;
  final int? teamId;
  final String? teamName;
  final String? proofUrl;
  final String? reason;
  final String status;
  final DateTime? requestedDate;
  final DateTime? approvedDate;
  final String? approvedBy;
  final String? rejectedReason;

  ActivityCompletionRequest({
    required this.id,
    this.studentName,
    this.regNo,
    this.department,
    this.year,
    this.section,
    required this.activityId,
    this.activityName,
    this.teamId,
    this.teamName,
    this.proofUrl,
    this.reason,
    required this.status,
    this.requestedDate,
    this.approvedDate,
    this.approvedBy,
    this.rejectedReason,
  });

  factory ActivityCompletionRequest.fromJson(Map<String, dynamic> json) {
    return ActivityCompletionRequest(
      id: json['id'] as int,
      studentName: json['studentName']?.toString(),
      regNo: json['regNo']?.toString(),
      department: json['department']?.toString(),
      year: json['year']?.toString(),
      section: json['section']?.toString(),
      activityId: json['activityId'] as int,
      activityName: json['activityName']?.toString(),
      teamId: json['teamId'] as int?,
      teamName: json['teamName']?.toString(),
      proofUrl: json['proofUrl']?.toString(),
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      requestedDate: json['requestedDate'] != null
          ? DateTime.parse(json['requestedDate'].toString())
          : null,
      approvedDate: json['approvedDate'] != null
          ? DateTime.parse(json['approvedDate'].toString())
          : null,
      approvedBy: json['approvedBy']?.toString(),
      rejectedReason: json['rejectedReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'regNo': regNo,
      'department': department,
      'year': year,
      'section': section,
      'activityId': activityId,
      'activityName': activityName,
      'teamId': teamId,
      'teamName': teamName,
      'proofUrl': proofUrl,
      'reason': reason,
      'status': status,
      'requestedDate': requestedDate?.toIso8601String(),
      'approvedDate': approvedDate?.toIso8601String(),
      'approvedBy': approvedBy,
      'rejectedReason': rejectedReason,
    };
  }
}
