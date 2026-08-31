import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/core/services/loading_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/utils/export_utils.dart';
import '../models/admin_attendance_summary.dart';
import '../models/student_attendance_matrix_item.dart';
import '../services/attendance_service.dart';
import '../../admin/pages/attendance_settings_page.dart';
import '../../admin/pages/attendance_settings_year_selection_page.dart';
import 'package:pragatix/core/utils/error_handler.dart';

class AdminAttendanceTab extends StatefulWidget {
  const AdminAttendanceTab({Key? key}) : super(key: key);

  @override
  State<AdminAttendanceTab> createState() => _AdminAttendanceTabState();
}

class _AdminAttendanceTabState extends State<AdminAttendanceTab> {
  final AttendanceService _service = AttendanceService();

  DateTime _selectedDate = DateTime.now();
  int? _yearId;
  int? _departmentId;
  int? _sectionId;
  int? _period;

  List<dynamic> _years = [];
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];

  AdminAttendanceSummary? _summary;
  bool _isLoading = false;
  bool _isLoadingLookups = true;
  bool _isHoliday = false;
  String _attendanceFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  bool get isYearAdmin {
    final user = getIt<AuthProvider>().currentUser;
    final roles = user?['roles'] as List<dynamic>?;
    if (roles == null) return false;
    
    bool hasAdmin = false;
    bool hasSuperAdmin = false;
    
    for (var r in roles) {
      String roleName = '';
      if (r is String) roleName = r;
      if (r is Map) roleName = r['name']?.toString() ?? '';
      
      final upperRole = roleName.toUpperCase();
      if (upperRole == 'ROLE_ADMIN' || upperRole == 'ADMIN') hasAdmin = true;
      if (upperRole == 'ROLE_SUPER_ADMIN' || upperRole == 'ROLE_SUPERADMIN' || upperRole == 'SUPER_ADMIN' || upperRole == 'SUPERADMIN') hasSuperAdmin = true;
    }
    
    return hasAdmin && !hasSuperAdmin;
  }

  List<dynamic> _safeDecodeList(String body) {
    if (body.trim().startsWith('<')) {
      print('Warning: API returned HTML instead of JSON. Body: ${body.substring(0, body.length > 50 ? 50 : body.length)}');
      return [];
    }
    try {
      final decoded = jsonDecode(body);
      return decoded['data'] ?? [];
    } catch (e) {
      print('Warning: Failed to decode JSON. Error: $e');
      return [];
    }
  }

  Future<void> _loadLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments?type=MAIN'),
          headers: headers,
        ),
      ]);

      if (!mounted) return;

      final yearsList = _safeDecodeList(results[0].body);
      final deptsList = _safeDecodeList(results[1].body);

      setState(() {
        _years = yearsList;
        _departments = deptsList;

        if (_years.isNotEmpty && _yearId == null) {
          _yearId = _years.first['id'];
        }
        
        if (isYearAdmin) {
          if (_departments.isNotEmpty && _departmentId == null) {
            _departmentId = _departments.first['id'];
            _loadSections(_departmentId!);
          }
        } else {
          _departmentId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLookups = false);
      }
    }
  }

  Future<void> _loadSections(int departmentId) async {
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections?departmentId=$departmentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        setState(() {
          _sections = _safeDecodeList(res.body);
          _sectionId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sections = [];
          _sectionId = null;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    if ((!isYearAdmin && _yearId == null) || (isYearAdmin && _departmentId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Year and Department')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isHoliday = false;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final summary = await _service.getAdminSummary(
        dateStr,
        isYearAdmin ? -1 : _yearId!,
        _departmentId,
        sectionId: _sectionId,
        period: _period,
      );
      if (mounted) {
        setState(() {
          _summary = summary;
          _attendanceFilter = 'ALL';
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Holiday')) {
          setState(() {
            _summary = null;
            _isHoliday = true;
          });
        } else {
          ErrorHandler.showSnackBar(context, e);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportData() async {
    LoadingService.show(message: 'Exporting attendance...');
    try {
      final token = getIt<AuthProvider>().token ?? '';
      
      String yearNo = '';
      if (isYearAdmin) {
        yearNo = '-1';
      } else {
        if (_years.isNotEmpty) {
          final yearObj = _years.firstWhere((y) => y['id'] == _yearId, orElse: () => null);
          if (yearObj != null) {
            yearNo = yearObj['yearNo']?.toString() ?? yearObj['yearName']?.toString() ?? '';
          }
        }
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      String url = '${ApiConfig.baseUrl}/api/v1/analytics/attendance/export?yearNo=$yearNo&startDate=$dateStr&endDate=$dateStr';
      if (_departmentId != null) {
        url += '&departmentId=$_departmentId';
      }
      if (_sectionId != null) {
        url += '&sectionId=$_sectionId';
      }
      if (_period != null) {
        url += '&period=$_period';
      }
      
      await ExportUtils.downloadAndOpenExcel(context, url, token);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(context, e);
      }
    } finally {
      LoadingService.hide();
    }
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFF334155), size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          // Background mesh subtle gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE8F6),
                    Color(0xFFE8EFF9),
                    Color(0xFFF4F7FB),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Attendance Dashboard',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Daily & period-wise student attendance',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderActionButton(
                            icon: Icons.file_download_outlined,
                            tooltip: 'Export to Excel',
                            onPressed: () {
                              if (!isYearAdmin && _yearId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select Academic Year and Date to export.'),
                                  ),
                                );
                                return;
                              }
                              _exportData();
                            },
                          ),
                          const SizedBox(width: 6),
                          _buildHeaderActionButton(
                            icon: Icons.settings_outlined,
                            tooltip: 'Settings',
                            onPressed: () {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              if (auth.isSuperAdmin) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AttendanceSettingsYearSelectionPage(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AttendanceSettingsPage(),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          _buildHeaderActionButton(
                            icon: Icons.refresh_rounded,
                            tooltip: 'Refresh',
                            onPressed: () {
                              _loadLookups();
                              if (_yearId != null || isYearAdmin) {
                                _fetchSummary();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Body Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        _buildFilters(),
                        if (_isHoliday)
                          Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(Icons.beach_access_rounded, size: 48, color: Color(0xFFD97706)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Holiday',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'This date is configured as a Holiday.\nAttendance is not required.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_summary != null)
                          _buildDashboardContent()
                        else
                          const Padding(
                            padding: EdgeInsets.only(top: 40.0),
                            child: Center(
                              child: Text(
                                'Select filters and tap "Load Dashboard"',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: PragatiXLoader(
                message: 'Loading Attendance Dashboard...',
                fullScreen: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filteredSections = _sections
        .where(
          (s) =>
              s['departmentId'] == _departmentId ||
              s['department']?['id'] == _departmentId,
        )
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isYearAdmin) ...[
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: (_yearId != null && _years.any((y) => y['id'] == _yearId)) ? _yearId : null,
              decoration: InputDecoration(
                labelText: 'Academic Year',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _years.where((y) => y['id'] != null).map<DropdownMenuItem<int>>((y) {
                return DropdownMenuItem<int>(
                  value: y['id'] as int,
                  child: Text(y['yearName']?.toString() ?? y['yearNo']?.toString() ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _yearId = v),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: (_departmentId != null && _departments.any((d) => d['id'] == _departmentId)) ? _departmentId : null,
            decoration: InputDecoration(
              labelText: 'Department',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Departments'),
              ),
              ..._departments.where((d) => d['id'] != null).map<DropdownMenuItem<int?>>((d) {
                return DropdownMenuItem<int?>(
                  value: d['id'] as int,
                  child: Text(d['name']?.toString() ?? d['deptName']?.toString() ?? d['code']?.toString() ?? 'Unknown'),
                );
              }).toList(),
            ],
            onChanged: (v) {
              setState(() {
                _departmentId = v;
                _sectionId = null;
                _sections = [];
                if (v != null) {
                  _loadSections(v);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: (_sectionId != null &&
                    filteredSections.any((s) => s['id'] == _sectionId))
                ? _sectionId
                : null,
            decoration: InputDecoration(
              labelText: 'Section',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: _departmentId == null
                  ? 'Select Department First'
                  : (filteredSections.isEmpty ? 'No Sections Available' : 'All Sections'),
            ),
            items: _departmentId == null || filteredSections.isEmpty
                ? null
                : [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Sections'),
                    ),
                    ...filteredSections
                        .where((s) => s['id'] != null)
                        .map<DropdownMenuItem<int>>((s) {
                      return DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(s['sectionName']?.toString() ?? 'Unknown'),
                      );
                    }).toList(),
                  ],
            onChanged: _departmentId == null || filteredSections.isEmpty
                ? null
                : (v) => setState(() => _sectionId = v),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              title: const Text(
                'Date',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              subtitle: Text(
                DateFormat('yyyy-MM-dd').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              trailing: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 20),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: _period,
            decoration: InputDecoration(
              labelText: 'Period',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Periods'),
              ),
              ...List.generate(8, (i) => DropdownMenuItem<int?>(
                value: i + 1,
                child: Text('Period ${i + 1}'),
              )),
            ],
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_isLoading || _isLoadingLookups) ? null : _fetchSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            child: Text(
              _isLoadingLookups ? 'Preparing Filters...' : 'Load Dashboard',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  List<StudentAttendanceMatrixItem> get _filteredStudents {
    if (_summary == null) return [];
    final all = _summary!.students;
    if (_attendanceFilter == 'PRESENT') {
      if (_period != null) {
        return all.where((s) {
          final st = s.periodStatuses[_period];
          return st == 'P' || st == 'OD';
        }).toList();
      } else {
        return all.where((s) {
          return s.periodStatuses.values.any((st) => st == 'P' || st == 'OD');
        }).toList();
      }
    } else if (_attendanceFilter == 'ABSENT') {
      if (_period != null) {
        return all.where((s) {
          final st = s.periodStatuses[_period];
          return st == 'A' || st == 'L';
        }).toList();
      } else {
        return all.where((s) {
          return s.periodStatuses.values.any((st) => st == 'A' || st == 'L');
        }).toList();
      }
    }
    return all;
  }

  Widget _buildDashboardContent() {
    final students = _filteredStudents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            children: [
              _buildStatCard(
                title: 'Total',
                value: _summary!.totalStudents.toString(),
                color: const Color(0xFF3B82F6),
                isSelected: _attendanceFilter == 'ALL',
                onTap: () => setState(() => _attendanceFilter = 'ALL'),
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                title: 'Present',
                value: _summary!.totalPresent.toString(),
                color: const Color(0xFF22C55E),
                isSelected: _attendanceFilter == 'PRESENT',
                onTap: () => setState(() {
                  _attendanceFilter = _attendanceFilter == 'PRESENT' ? 'ALL' : 'PRESENT';
                }),
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                title: 'Absent',
                value: _summary!.totalAbsent.toString(),
                color: const Color(0xFFEF4444),
                isSelected: _attendanceFilter == 'ABSENT',
                onTap: () => setState(() {
                  _attendanceFilter = _attendanceFilter == 'ABSENT' ? 'ALL' : 'ABSENT';
                }),
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                title: 'Attendance',
                value: '${_summary!.attendancePercentage.toStringAsFixed(1)}%',
                color: const Color(0xFF8B5CF6),
                isSelected: false,
                onTap: () => setState(() => _attendanceFilter = 'ALL'),
              ),
            ],
          ),
        ),
        if (_attendanceFilter != 'ALL')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _attendanceFilter == 'PRESENT'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _attendanceFilter == 'PRESENT'
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _attendanceFilter == 'PRESENT'
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 14,
                        color: _attendanceFilter == 'PRESENT'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Showing ${_attendanceFilter == 'PRESENT' ? 'Present' : 'Absent'} Students (${students.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _attendanceFilter == 'PRESENT'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _attendanceFilter = 'ALL'),
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Show All', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        students.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    _attendanceFilter == 'PRESENT'
                        ? 'No students marked Present for the selected date/period.'
                        : _attendanceFilter == 'ABSENT'
                            ? 'No students marked Absent for the selected date/period.'
                            : 'No students found for the selected filters.',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF1F5F9),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    columnSpacing: 16,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 44,
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Reg. No')),
                      DataColumn(label: Text('Student Name')),
                      DataColumn(label: Text('P1')),
                      DataColumn(label: Text('P2')),
                      DataColumn(label: Text('P3')),
                      DataColumn(label: Text('P4')),
                      DataColumn(label: Text('P5')),
                      DataColumn(label: Text('P6')),
                      DataColumn(label: Text('P7')),
                      DataColumn(label: Text('P8')),
                    ],
                    rows: students.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final student = entry.value;
                      final isEven = idx % 2 == 0;
                      return DataRow(
                        color: WidgetStateProperty.all(
                          isEven
                              ? Colors.white
                              : const Color(0xFFF8FAFC),
                        ),
                        cells: [
                          DataCell(Text('${idx + 1}', style: const TextStyle(fontSize: 13))),
                          DataCell(Text(
                            student.registerNumber,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          )),
                          DataCell(SizedBox(
                            width: 160,
                            child: Text(
                              student.studentName,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                          ...List.generate(8, (i) {
                            final period = i + 1;
                            final status = student.periodStatuses[period] ?? '—';
                            return DataCell(_buildPeriodCell(status));
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPeriodCell(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'P':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'A':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case 'OD':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'L':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = Colors.grey;
    }
    return Container(
      width: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 6 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? color : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
