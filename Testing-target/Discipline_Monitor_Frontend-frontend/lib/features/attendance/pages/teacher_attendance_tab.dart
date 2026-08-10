import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import '../models/student_attendance_list_item.dart';
import '../services/attendance_service.dart';

class TeacherAttendanceTab extends StatefulWidget {
  const TeacherAttendanceTab({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<TeacherAttendanceTab> {
  final AttendanceService _service = AttendanceService();

  DateTime _selectedDate = DateTime.now();
  int _selectedPeriod = 1;
  int? _academicYearId;
  int? _yearId;
  int? _departmentId;
  int? _sectionId;

  List<dynamic> _academicYears = [];
  List<dynamic> _years = [];
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];

  List<StudentAttendanceListItem>? _students;
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
      
      if (roleName == 'ROLE_ADMIN') hasAdmin = true;
      if (roleName == 'ROLE_SUPER_ADMIN' || roleName == 'ROLE_SUPERADMIN') hasSuperAdmin = true;
    }
    
    return hasAdmin && !hasSuperAdmin;
  }

  Future<void> _loadLookups() async {
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/academic-years'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections'),
          headers: headers,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _academicYears = jsonDecode(results[0].body)['data'] ?? [];
        _years = jsonDecode(results[1].body)['data'] ?? [];
        _departments = jsonDecode(results[2].body)['data'] ?? [];
        _sections = jsonDecode(results[3].body)['data'] ?? [];

        if (_academicYears.isNotEmpty)
          _academicYearId = _academicYears.first['id'];

        final currentUser = getIt<AuthProvider>().currentUser;
        if (currentUser != null) {
          final assignedSectionId = currentUser['sectionId'] as int?;
          final assignedDepartment = currentUser['department']?.toString();
          final assignedYear = currentUser['year']?.toString();

          if (assignedYear != null && _years.isNotEmpty) {
            final match = _years.firstWhere((y) {
              final yName = y['yearName']?.toString();
              final yNo = y['yearNo']?.toString();
              return yName == assignedYear || yNo == assignedYear;
            }, orElse: () => null);
            if (match != null) _yearId = match['id'];
          }
          if (assignedDepartment != null && _departments.isNotEmpty) {
            final match = _departments.firstWhere((d) {
              final dName = d['name']?.toString();
              final dDeptName = d['deptName']?.toString();
              final dCode = d['code']?.toString();
              return dName == assignedDepartment ||
                  dDeptName == assignedDepartment ||
                  dCode == assignedDepartment;
            }, orElse: () => null);
            if (match != null) _departmentId = match['id'];
          }
          if (assignedSectionId != null && _sections.isNotEmpty) {
            final match = _sections.firstWhere(
              (s) => s['id'] == assignedSectionId,
              orElse: () => null,
            );
            if (match != null) _sectionId = match['id'];
          }
        }

        // Fallback for missing matches
        if (_yearId == null && _years.isNotEmpty) _yearId = _years.first['id'];
        if (_departmentId == null && _departments.isNotEmpty)
          _departmentId = _departments.first['id'];

        // Auto select section if only 1 exists for the department
        if (_sectionId == null && _departmentId != null) {
          final deptSections = _sections
              .where(
                (s) =>
                    s['departmentId'] == _departmentId ||
                    s['department']?['id'] == _departmentId,
              )
              .toList();
          if (deptSections.length == 1) {
            _sectionId = deptSections.first['id'];
          }
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

  Future<void> _loadStudents() async {
    if ((!isYearAdmin && _yearId == null) || _departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Year and Department')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final students = await _service.getStudentsWithAttendance(
        dateStr,
        _selectedPeriod,
        _yearId!,
        _departmentId!,
        sectionId: _sectionId,
      );
      setState(() {
        _students = students;
        _isHoliday = false;
      });
    } catch (e) {
      if (e.toString().contains('Holiday')) {
        setState(() {
          _students = [];
          _isHoliday = true;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_students == null ||
        (!isYearAdmin && _yearId == null) ||
        _departmentId == null ||
        _academicYearId == null)
      return;

    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await _service.saveAttendance(
        dateStr,
        _selectedPeriod,
        _academicYearId!,
        isYearAdmin ? -1 : _yearId!,
        _departmentId!,
        _sectionId,
        _students!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance Saved Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving attendance: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _markAll(String status) {
    if (_students == null) return;
    setState(() {
      _students = _students!.map((s) => s.copyWith(status: status)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mark Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                const Divider(),
                Expanded(child: _buildStudentList()),
              ],
            ),
      floatingActionButton: _students != null && _students!.isNotEmpty && !_isHoliday
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveAttendance,
              label: const Text('Save Attendance'),
              icon: const Icon(Icons.save),
              backgroundColor: const Color(0xFF4F46E5),
            )
          : null,
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
          Row(
            children: [
              if (!isYearAdmin) ...[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value:
                        (_yearId != null && _years.any((y) => y['id'] == _yearId))
                        ? _yearId
                        : null,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: _years
                        .where((y) => y['id'] != null)
                        .map<DropdownMenuItem<int>>((y) {
                          return DropdownMenuItem<int>(
                            value: y['id'] as int,
                            child: Text(
                              y['yearName']?.toString() ??
                                  y['yearNo']?.toString() ??
                                  'Unknown',
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (v) => setState(() => _yearId = v),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: DropdownButtonFormField<int>(
                  value:
                      (_departmentId != null &&
                          _departments.any((d) => d['id'] == _departmentId))
                      ? _departmentId
                      : null,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: _departments
                      .where((d) => d['id'] != null)
                      .map<DropdownMenuItem<int>>((d) {
                        return DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(
                            d['name']?.toString() ??
                                d['deptName']?.toString() ??
                                d['code']?.toString() ??
                                'Unknown',
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _departmentId = v;
                      final deptSections = _sections
                          .where(
                            (s) =>
                                s['departmentId'] == _departmentId ||
                                s['department']?['id'] == _departmentId,
                          )
                          .toList();
                      if (deptSections.length == 1) {
                        _sectionId = deptSections.first['id'];
                      } else {
                        _sectionId = null;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredSections.isNotEmpty)
            DropdownButtonFormField<int?>(
              value:
                  (_sectionId != null &&
                      filteredSections.any((s) => s['id'] == _sectionId))
                  ? _sectionId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Section (Optional)',
              ),
              items: [
                if (filteredSections.length > 1)
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
                    })
                    .toList(),
              ],
              onChanged: (v) => setState(() => _sectionId = v),
            )
          else if (_departmentId != null)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All Students',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
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
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: List.generate(
                    8,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Period ${i + 1}'),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPeriod = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _loadStudents,
            child: const Text('Load Students'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isHoliday) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                'Attendance cannot be marked.\nToday is configured as a Holiday.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_students == null) {
      return const Center(child: Text('Select filters and load students'));
    }

    if (_students!.isEmpty) {
      return const Center(child: Text('No students found for this class.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _markAll('PRESENT'),
                child: const Text('Mark All Present'),
              ),
              TextButton(
                onPressed: () => _markAll('ABSENT'),
                child: const Text('Mark All Absent'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _students!.length,
            itemBuilder: (context, index) {
              final s = _students![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    s.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(s.registerNumber),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'PRESENT', label: Text('P')),
                      ButtonSegment(value: 'ABSENT', label: Text('A')),
                    ],
                    selected: {s.status},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _students![index] = s.copyWith(
                          status: newSelection.first,
                        );
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
