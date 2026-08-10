import 'package:flutter/foundation.dart';
import 'package:pragatix/features/analytics/services/attendance_analytics_service.dart';

class AttendanceAnalyticsProvider with ChangeNotifier {
  final AttendanceAnalyticsService _service;

  AttendanceAnalyticsProvider(String token) : _service = AttendanceAnalyticsService(token) {
    fetchDepartments();
  }

  bool isLoading = false;
  String? error;

  Map<String, dynamic>? overview;
  List<dynamic>? trend;
  Map<String, dynamic>? distribution;
  List<dynamic>? departmentWise;
  List<dynamic>? lowAttendanceStudents;
  List<dynamic>? sectionWise;
  List<dynamic>? summaryTable;

  List<dynamic> departments = [];
  List<dynamic> sections = [];

  // Filters
  String? selectedAcademicYear;
  String? selectedDepartmentId;
  String? selectedStageId;
  String? selectedSectionId;
  String? startDate;
  String? endDate;
  String? selectedPeriod;
  double attendanceThreshold = 75.0;

  void setThreshold(double threshold) {
    attendanceThreshold = threshold;
    fetchDashboardData();
  }

  void setAcademicYear(String? year) {
    selectedAcademicYear = year;
    fetchDashboardData();
  }

  void setFilters({
    String? departmentId,
    String? stageId,
    String? sectionId,
    String? start,
    String? end,
    String? period,
  }) {
    selectedDepartmentId = departmentId;
    selectedStageId = stageId;
    selectedSectionId = sectionId;
    startDate = start;
    endDate = end;
    selectedPeriod = period;
    selectedPeriod = period;
    fetchDashboardData();
  }

  void resetFilters() {
    selectedDepartmentId = null;
    selectedStageId = null;
    selectedSectionId = null;
    startDate = null;
    endDate = null;
    selectedPeriod = null;
    sections = [];
    fetchDashboardData();
  }

  Future<void> fetchDepartments() async {
    try {
      departments = await _service.getDepartments();
      if (departments.length == 1) {
        selectedDepartmentId = departments[0]['id']?.toString();
        fetchSections(selectedDepartmentId!);
      }
      notifyListeners();
    } catch (e) {
      // Ignore error for now
    }
  }

  Future<void> fetchSections(String departmentId) async {
    try {
      sections = await _service.getSections(departmentId);
      notifyListeners();
    } catch (e) {
      sections = [];
      notifyListeners();
    }
  }

  void onDepartmentChanged(String? deptId) {
    selectedDepartmentId = deptId;
    selectedSectionId = null;
    sections = [];
    if (deptId != null) {
      fetchSections(deptId);
    }
    fetchDashboardData();
  }

  void onSectionChanged(String? sectionId) {
    selectedSectionId = sectionId;
    fetchDashboardData();
  }

  Map<String, dynamic> _buildFilters() {
    return {
      'academicYear': selectedAcademicYear,
      'departmentId': selectedDepartmentId,
      'stageId': selectedStageId,
      'sectionId': selectedSectionId,
      'startDate': startDate,
      'endDate': endDate,
      'period': selectedPeriod,
    };
  }

  String getExportUrl() {
    return _service.getExportUrl(_buildFilters());
  }

  Future<void> fetchDashboardData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final filters = _buildFilters();
      
      // Trend must always show history; strip date filters for trend API call
      final trendFilters = Map<String, dynamic>.from(filters);
      trendFilters.remove('startDate');
      trendFilters.remove('endDate');
      
      final results = await Future.wait([
        _service.getOverview(filters),
        _service.getTrend(trendFilters),
        _service.getDistribution(filters),
        _service.getDepartmentWise(filters),
        _service.getLowAttendanceStudents(filters, attendanceThreshold),
        _service.getSectionWise(filters),
        _service.getSummaryTable(filters),
      ]);

      overview = results[0] as Map<String, dynamic>;
      trend = results[1] as List<dynamic>;
      distribution = results[2] as Map<String, dynamic>;
      departmentWise = results[3] as List<dynamic>;
      lowAttendanceStudents = results[4] as List<dynamic>;
      sectionWise = results[5] as List<dynamic>;
      summaryTable = results[6] as List<dynamic>;

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
