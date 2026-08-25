class PendingDepartment {
  final int id;
  final String name;
  final String deptCode;

  PendingDepartment({
    required this.id,
    required this.name,
    required this.deptCode,
  });

  factory PendingDepartment.fromJson(Map<String, dynamic> json) {
    return PendingDepartment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      deptCode: json['deptCode']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

class PendingStudent {
  final int id;
  final String fullName;
  final String maskedMobile;
  final int? departmentId;
  final String departmentName;
  final String deptCode;

  PendingStudent({
    required this.id,
    required this.fullName,
    required this.maskedMobile,
    this.departmentId,
    required this.departmentName,
    required this.deptCode,
  });

  factory PendingStudent.fromJson(Map<String, dynamic> json) {
    return PendingStudent(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      maskedMobile: json['maskedMobile']?.toString() ?? '******',
      departmentId: json['departmentId'] != null ? (json['departmentId'] is int ? json['departmentId'] : int.tryParse(json['departmentId'].toString())) : null,
      departmentName: json['departmentName']?.toString() ?? '',
      deptCode: json['deptCode']?.toString() ?? '',
    );
  }
}

class EnrollmentItem {
  final int id;
  final String fullName;
  final String gender;
  final String email;
  final String mobile;
  final String maskedMobile;
  final int? departmentId;
  final String departmentName;
  final String deptCode;
  final String status;
  final int? enrolledStudentId;
  final String? enrolledStudentRegNo;
  final String? enrolledAt;
  final String? createdBy;
  final String? createdAt;

  EnrollmentItem({
    required this.id,
    required this.fullName,
    required this.gender,
    required this.email,
    required this.mobile,
    required this.maskedMobile,
    this.departmentId,
    required this.departmentName,
    required this.deptCode,
    required this.status,
    this.enrolledStudentId,
    this.enrolledStudentRegNo,
    this.enrolledAt,
    this.createdBy,
    this.createdAt,
  });

  factory EnrollmentItem.fromJson(Map<String, dynamic> json) {
    return EnrollmentItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      maskedMobile: json['maskedMobile']?.toString() ?? json['mobile']?.toString() ?? '',
      departmentId: json['departmentId'] != null ? (json['departmentId'] is int ? json['departmentId'] : int.tryParse(json['departmentId'].toString())) : null,
      departmentName: json['departmentName']?.toString() ?? '',
      deptCode: json['deptCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      enrolledStudentId: json['enrolledStudentId'] != null ? (json['enrolledStudentId'] is int ? json['enrolledStudentId'] : int.tryParse(json['enrolledStudentId'].toString())) : null,
      enrolledStudentRegNo: json['enrolledStudentRegNo']?.toString(),
      enrolledAt: json['enrolledAt']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class EnrollmentImportResult {
  final int totalRows;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  EnrollmentImportResult({
    required this.totalRows,
    required this.importedCount,
    required this.skippedCount,
    required this.errors,
  });

  factory EnrollmentImportResult.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['errors'];
    List<String> parsedErrors = [];
    if (rawErrors is List) {
      parsedErrors = rawErrors.map((e) => e.toString()).toList();
    }
    return EnrollmentImportResult(
      totalRows: json['totalRows'] is int ? json['totalRows'] : int.tryParse(json['totalRows'].toString()) ?? 0,
      importedCount: json['importedCount'] is int ? json['importedCount'] : int.tryParse(json['importedCount'].toString()) ?? 0,
      skippedCount: json['skippedCount'] is int ? json['skippedCount'] : int.tryParse(json['skippedCount'].toString()) ?? 0,
      errors: parsedErrors,
    );
  }
}
