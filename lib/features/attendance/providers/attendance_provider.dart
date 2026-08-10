import 'package:flutter/material.dart';
import '../models/student_attendance_summary.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  StudentAttendanceSummary? _summary;
  bool _isLoading = false;
  String? _error;

  StudentAttendanceSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get currentStreak => _summary?.currentStreak ?? 0;

  Future<void> fetchSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _service.getStudentSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
