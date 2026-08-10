import 'student_attendance_matrix_item.dart';

class AdminAttendanceSummary {
  final int totalStudents;
  final int totalPresent;
  final int totalAbsent;
  final double attendancePercentage;
  final List<StudentAttendanceMatrixItem> students;

  AdminAttendanceSummary({
    required this.totalStudents,
    required this.totalPresent,
    required this.totalAbsent,
    required this.attendancePercentage,
    required this.students,
  });

  factory AdminAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceSummary(
      totalStudents: json['totalStudents'] as int,
      totalPresent: json['totalPresent'] as int,
      totalAbsent: json['totalAbsent'] as int,
      attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
      students: (json['students'] as List)
          .map(
            (e) =>
                StudentAttendanceMatrixItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
