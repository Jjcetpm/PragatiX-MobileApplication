class StudentAttendanceHistory {
  final String date;
  final int period;
  final String status;
  final String? remarks;

  StudentAttendanceHistory({
    required this.date,
    required this.period,
    required this.status,
    this.remarks,
  });

  factory StudentAttendanceHistory.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceHistory(
      date: json['date'] as String,
      period: json['period'] as int,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
    );
  }
}
