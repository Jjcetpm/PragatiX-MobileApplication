class StudentDeletionRequest {
  final int id;
  final int? studentId;
  final String studentName;
  final String registerNumber;
  final String? departmentName;
  final String? academicYear;
  final String? sectionName;
  final String requestedBy;
  final String? requesterName;
  final String? requesterRole;
  final String reason;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final DateTime? requestedAt;
  final String? reviewedBy;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final String? reviewerRemarks;

  StudentDeletionRequest({
    required this.id,
    this.studentId,
    required this.studentName,
    required this.registerNumber,
    this.departmentName,
    this.academicYear,
    this.sectionName,
    required this.requestedBy,
    this.requesterName,
    this.requesterRole,
    required this.reason,
    required this.status,
    this.requestedAt,
    this.reviewedBy,
    this.reviewerName,
    this.reviewedAt,
    this.reviewerRemarks,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory StudentDeletionRequest.fromJson(Map<String, dynamic> json) {
    return StudentDeletionRequest(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      studentId: json['studentId'] is int
          ? json['studentId']
          : (json['studentId'] != null ? int.tryParse(json['studentId'].toString()) : null),
      studentName: json['studentName']?.toString() ?? '',
      registerNumber: json['registerNumber']?.toString() ?? '',
      departmentName: json['departmentName']?.toString(),
      academicYear: json['academicYear']?.toString(),
      sectionName: json['sectionName']?.toString(),
      requestedBy: json['requestedBy']?.toString() ?? '',
      requesterName: json['requesterName']?.toString(),
      requesterRole: json['requesterRole']?.toString(),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt'].toString()) : null,
      reviewedBy: json['reviewedBy']?.toString(),
      reviewerName: json['reviewerName']?.toString(),
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'].toString()) : null,
      reviewerRemarks: json['reviewerRemarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'registerNumber': registerNumber,
      'departmentName': departmentName,
      'academicYear': academicYear,
      'sectionName': sectionName,
      'requestedBy': requestedBy,
      'requesterName': requesterName,
      'requesterRole': requesterRole,
      'reason': reason,
      'status': status,
      'requestedAt': requestedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewerName': reviewerName,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewerRemarks': reviewerRemarks,
    };
  }
}
