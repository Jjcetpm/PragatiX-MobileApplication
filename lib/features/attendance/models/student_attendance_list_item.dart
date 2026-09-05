class StudentAttendanceListItem {
  final int studentId;
  final String studentName;
  final String registerNumber;
  final String status;
  final String? remarks;
  final String? markedByFacultyName;
  final String? markedByFacultyDepartment;
  final String? markedAt;

  StudentAttendanceListItem({
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.status,
    this.remarks,
    this.markedByFacultyName,
    this.markedByFacultyDepartment,
    this.markedAt,
  });

  factory StudentAttendanceListItem.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceListItem(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String,
      registerNumber: json['registerNumber'] as String,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      markedByFacultyName: json['markedByFacultyName'] as String?,
      markedByFacultyDepartment: json['markedByFacultyDepartment'] as String?,
      markedAt: json['markedAt'] as String?,
    );
  }

  StudentAttendanceListItem copyWith({
    String? status,
    String? remarks,
    String? markedByFacultyName,
    String? markedByFacultyDepartment,
    String? markedAt,
  }) {
    return StudentAttendanceListItem(
      studentId: this.studentId,
      studentName: this.studentName,
      registerNumber: this.registerNumber,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      markedByFacultyName: markedByFacultyName ?? this.markedByFacultyName,
      markedByFacultyDepartment: markedByFacultyDepartment ?? this.markedByFacultyDepartment,
      markedAt: markedAt ?? this.markedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'status': status,
      'remarks': remarks,
      'markedByFacultyName': markedByFacultyName,
      'markedByFacultyDepartment': markedByFacultyDepartment,
      'markedAt': markedAt,
    };
  }
}
