class BadgeRequest {
  final int id;
  final int studentId;
  final String studentName;
  final String regNo;
  final int badgeId;
  final String badgeName;
  final String badgeIcon;
  final String departmentName;
  final String sectionName;
  final String status;
  final String requestedAt;
  final String? reviewedAt;
  final String? reviewedBy;
  final String? remarks;
  final String? proofLink;

  BadgeRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.regNo,
    required this.badgeId,
    required this.badgeName,
    required this.badgeIcon,
    required this.departmentName,
    required this.sectionName,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.remarks,
    this.proofLink,
  });

  factory BadgeRequest.fromJson(Map<String, dynamic> json) {
    return BadgeRequest(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      studentId: json['studentId'] is int ? json['studentId'] : int.tryParse(json['studentId']?.toString() ?? '0') ?? 0,
      studentName: json['studentName']?.toString() ?? '',
      regNo: json['regNo']?.toString() ?? '',
      badgeId: json['badgeId'] is int ? json['badgeId'] : int.tryParse(json['badgeId']?.toString() ?? '0') ?? 0,
      badgeName: json['badgeName']?.toString() ?? '',
      badgeIcon: json['badgeIcon']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      sectionName: json['sectionName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      requestedAt: json['requestedAt']?.toString() ?? '',
      reviewedAt: json['reviewedAt']?.toString(),
      reviewedBy: json['reviewedBy']?.toString(),
      remarks: json['remarks']?.toString(),
      proofLink: json['proofLink']?.toString() ??
          json['proofUrl']?.toString() ??
          json['proofFile']?.toString() ??
          json['attachmentUrl']?.toString(),
    );
  }
}
