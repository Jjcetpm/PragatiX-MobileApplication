class StudentAttendanceMatrixItem {
  final int studentId;
  final String studentName;
  final String registerNumber;
  final Map<int, String> periodStatuses;

  StudentAttendanceMatrixItem({
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.periodStatuses,
  });

  factory StudentAttendanceMatrixItem.fromJson(Map<String, dynamic> json) {
    Map<int, String> statuses = {};
    if (json['periodStatuses'] != null) {
      (json['periodStatuses'] as Map<String, dynamic>).forEach((key, value) {
        statuses[int.parse(key)] = value.toString();
      });
    }

    return StudentAttendanceMatrixItem(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String,
      registerNumber: json['registerNumber'] as String,
      periodStatuses: statuses,
    );
  }
}
