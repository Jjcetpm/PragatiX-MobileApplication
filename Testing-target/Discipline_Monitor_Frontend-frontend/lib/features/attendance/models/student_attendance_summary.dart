class StudentAttendanceSummary {
  final double attendancePercentage;
  final double monthlyAttendancePercentage;
  final int currentStreak;
  final int totalPresentDays;
  final int totalAbsentDays;

  StudentAttendanceSummary({
    required this.attendancePercentage,
    required this.monthlyAttendancePercentage,
    required this.currentStreak,
    required this.totalPresentDays,
    required this.totalAbsentDays,
  });

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceSummary(
      attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
      monthlyAttendancePercentage: (json['monthlyAttendancePercentage'] as num)
          .toDouble(),
      currentStreak: json['currentStreak'] as int,
      totalPresentDays: json['totalPresentDays'] as int,
      totalAbsentDays: json['totalAbsentDays'] as int,
    );
  }
}
