import 'package:flutter/material.dart';
import 'package:pragatix/features/analytics/services/xp_analytics_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:intl/intl.dart';

class XpAnalyticsProvider with ChangeNotifier {
  final XpAnalyticsService _service = getIt<XpAnalyticsService>();

  XpAnalyticsProvider() {
    fetchDepartments();
  }

  bool _isLoading = false;
  String? _error;

  // Filters
  String? _academicYear;
  int? _departmentId;
  int? _stageId;
  int? _sectionId;
  DateTime? _startDate;
  DateTime? _endDate;

  // Heatmap specific filters
  String _heatmapMode = 'Month'; // 'Month' or 'Week'
  int? _heatmapYear;
  int? _heatmapMonth;
  int? _heatmapWeek;

  // Department & Section Data
  List<dynamic> departments = [];
  List<dynamic> sections = [];

  // Data
  List<dynamic>? _awardVsPenalty;
  List<dynamic>? _departmentRanking;
  List<dynamic>? _sectionRanking;
  List<dynamic>? _heatmap;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic>? get awardVsPenalty => _awardVsPenalty;
  List<dynamic>? get departmentRanking => _departmentRanking;
  List<dynamic>? get sectionRanking => _sectionRanking;
  List<dynamic>? get heatmap => _heatmap;

  String? get academicYear => _academicYear;
  int? get departmentId => _departmentId;
  int? get stageId => _stageId;
  int? get sectionId => _sectionId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  String get heatmapMode => _heatmapMode;
  int? get heatmapYear => _heatmapYear;
  int? get heatmapMonth => _heatmapMonth;
  int? get heatmapWeek => _heatmapWeek;

  void setHeatmapFilters({String? mode, int? year, int? month, int? week}) {
    if (mode != null) _heatmapMode = mode;
    if (year != null) _heatmapYear = year;
    if (month != null) _heatmapMonth = month;
    if (week != null) _heatmapWeek = week;
    
    // Auto-calculate start and end date based on these if we want to filter the heatmap API directly.
    // Assuming backend takes startDate/endDate for heatmap.
    if (_heatmapMode == 'Month' && _heatmapYear != null && _heatmapMonth != null) {
      _startDate = DateTime(_heatmapYear!, _heatmapMonth!, 1);
      _endDate = DateTime(_heatmapYear!, _heatmapMonth! + 1, 0); // last day of month
    } else if (_heatmapMode == 'Week' && _heatmapYear != null && _heatmapMonth != null && _heatmapWeek != null) {
      // Rough approximation for week filter (days 1-7, 8-14, etc.)
      int startDay = ((_heatmapWeek! - 1) * 7) + 1;
      _startDate = DateTime(_heatmapYear!, _heatmapMonth!, startDay);
      int endDay = startDay + 6;
      int maxDays = DateTime(_heatmapYear!, _heatmapMonth! + 1, 0).day;
      if (endDay > maxDays) endDay = maxDays;
      _endDate = DateTime(_heatmapYear!, _heatmapMonth!, endDay);
    }
    notifyListeners();
    fetchDashboardData();
  }

  Future<void> fetchDepartments() async {
    try {
      departments = await _service.getDepartments();
      if (departments.length == 1) {
        _departmentId = departments[0]['id'];
        fetchSections(_departmentId!);
      }
      notifyListeners();
    } catch (e) {
      // Ignore error for now
    }
  }

  Future<void> fetchSections(int departmentId) async {
    try {
      sections = await _service.getSections(departmentId.toString());
      notifyListeners();
    } catch (e) {
      sections = [];
      notifyListeners();
    }
  }

  void onDepartmentChanged(int? deptId) {
    _departmentId = deptId;
    _sectionId = null;
    sections = [];
    if (deptId != null) {
      fetchSections(deptId);
    }
    notifyListeners();
    fetchDashboardData();
  }

  void onSectionChanged(int? secId) {
    _sectionId = secId;
    notifyListeners();
    fetchDashboardData();
  }

  void setFilters({
    String? academicYear,
    int? departmentId,
    int? stageId,
    int? sectionId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _academicYear = academicYear ?? _academicYear;
    _departmentId = departmentId ?? _departmentId;
    _stageId = stageId ?? _stageId;
    _sectionId = sectionId ?? _sectionId;
    _startDate = startDate ?? _startDate;
    _endDate = endDate ?? _endDate;
    notifyListeners();
  }

  void clearFilters() {
    _academicYear = null;
    _departmentId = null;
    _stageId = null;
    _sectionId = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  Map<String, dynamic> _buildParams() {
    final params = <String, dynamic>{};
    if (_academicYear != null) params['academicYear'] = _academicYear;
    if (_departmentId != null) params['departmentId'] = _departmentId;
    if (_stageId != null) params['stageId'] = _stageId;
    if (_sectionId != null) params['sectionId'] = _sectionId;
    if (_startDate != null) params['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    if (_endDate != null) params['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    return params;
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = _buildParams();
      
      final results = await Future.wait([
        _service.getAwardVsPenalty(params).catchError((_) => []),
        _service.getDepartmentRanking(params).catchError((_) => []),
        _service.getSectionRanking(params).catchError((_) => []),
        _service.getMonthlyHeatmap(params).catchError((_) => []),
      ]);

      _awardVsPenalty = results[0] as List<dynamic>;
      _departmentRanking = results[1] as List<dynamic>;
      _sectionRanking = results[2] as List<dynamic>;
      _heatmap = results[3] as List<dynamic>;

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getExportUrl({String? activityName, String? type}) {
    final params = _buildParams();
    if (activityName != null) params['activityName'] = activityName;
    if (type != null) params['type'] = type;
    return _service.getExportUrl(params);
  }
}
