import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/utils/export_utils.dart';
import '../models/admin_attendance_summary.dart';
import '../services/attendance_service.dart';
import '../../admin/pages/attendance_settings_page.dart';
import '../../admin/pages/attendance_settings_year_selection_page.dart';

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

  Future<void> _loadLookups() async {
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments'),
          headers: headers,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _years = jsonDecode(results[0].body)['data'] ?? [];
        _departments = jsonDecode(results[1].body)['data'] ?? [];

        if (_years.isNotEmpty) _yearId = _years.first['id'];
        
        if (isYearAdmin) {
          if (_departments.isNotEmpty) {
            _departmentId = _departments.first['id'];
            _loadSections(_departmentId!);
          }
        } else {
          _departmentId = null;
        }

        _isLoadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLookups = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading filters: $e')));
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
          _sections = jsonDecode(res.body)['data'] ?? [];
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
        isYearAdmin ? -1 : _yearId!, // Use a dummy value if year admin, backend will override
        _departmentId,
        sectionId: _sectionId,
        period: _period,
      );
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      if (e.toString().contains('Holiday')) {
        setState(() {
          _summary = null;
          _isHoliday = true;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    try {
      final token = getIt<AuthProvider>().token ?? '';
      
      // Find yearNo from _yearId
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
      // Do NOT pass token in URL anymore! ExportUtils handles Authorization header.
      
      await ExportUtils.downloadAndOpenExcel(context, url, token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Export to Excel',
            onPressed: () {
              if (!isYearAdmin && _yearId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select Academic Year and Date to export.')),
                );
                return;
              }
              _exportData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
        ],
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                const Divider(),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_isHoliday)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Holiday', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          SizedBox(height: 8),
                          Text('This date is configured as a Holiday.\nAttendance cannot be taken.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                else if (_summary != null)
                  Expanded(child: _buildDashboardContent())
                else
                  const Expanded(
                    child: Center(
                      child: Text('Select filters and load dashboard'),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (!isYearAdmin) ...[
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: (_yearId != null && _years.any((y) => y['id'] == _yearId)) ? _yearId : null,
              decoration: const InputDecoration(labelText: 'Academic Year'),
              items: _years.where((y) => y['id'] != null).map<DropdownMenuItem<int>>((y) {
                return DropdownMenuItem<int>(
                  value: y['id'] as int,
                  child: Text(y['yearName']?.toString() ?? y['yearNo']?.toString() ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _yearId = v),
            ),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: (_departmentId != null && _departments.any((d) => d['id'] == _departmentId)) ? _departmentId : null,
            decoration: const InputDecoration(labelText: 'Department'),
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
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: (_sectionId != null &&
                    filteredSections.any((s) => s['id'] == _sectionId))
                ? _sectionId
                : null,
            decoration: InputDecoration(
              labelText: 'Section',
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
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date'),
            subtitle: Text(
              DateFormat('yyyy-MM-dd').format(_selectedDate),
            ),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
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
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: _period,
            decoration: const InputDecoration(labelText: 'Period'),
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
            onPressed: _isLoading ? null : _fetchSummary,
            child: const Text('Load Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final students = _summary!.students;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Total',
                _summary!.totalStudents.toString(),
                const Color(0xFF3B82F6),
              ),
              _buildStatCard(
                'Present',
                _summary!.totalPresent.toString(),
                const Color(0xFF22C55E),
              ),
              _buildStatCard(
                'Absent',
                _summary!.totalAbsent.toString(),
                const Color(0xFFEF4444),
              ),
              _buildStatCard(
                'Attendance',
                '${_summary!.attendancePercentage.toStringAsFixed(1)}%',
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
        // Period Matrix Table
        Expanded(
          child: students.isEmpty
              ? const Center(
                  child: Text(
                    'No students found for the selected filters.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF1E293B),
                        ),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
