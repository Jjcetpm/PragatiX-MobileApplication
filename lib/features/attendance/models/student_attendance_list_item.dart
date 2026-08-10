class StudentAttendanceListItem {
  final int studentId;
  final String studentName;
  final String registerNumber;
  final String status;
  final String? remarks;

  StudentAttendanceListItem({
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.status,
    this.remarks,
  });

  factory StudentAttendanceListItem.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceListItem(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String,
      registerNumber: json['registerNumber'] as String,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
    );
  }

  StudentAttendanceListItem copyWith({String? status, String? remarks}) {
    return StudentAttendanceListItem(
      studentId: this.studentId,
      studentName: this.studentName,
      registerNumber: this.registerNumber,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {'studentId': studentId, 'status': status, 'remarks': remarks};
  }
}
