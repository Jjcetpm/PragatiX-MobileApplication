import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
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
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments?type=MAIN'),
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

        _fetchNextAvailablePeriod();

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
  Future<void> _fetchNextAvailablePeriod() async {
    if (_departmentId == null) return;
    
    // Only Year Admin doesn't strictly need a Year ID, but it's passed if available.
    if (!isYearAdmin && _yearId == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final nextPeriod = await _service.getNextAvailablePeriod(
        dateStr,
        _departmentId!,
        yearId: _yearId,
        sectionId: _sectionId,
      );
      if (mounted) {
        setState(() {
          _selectedPeriod = nextPeriod;
        });
      }
    } catch (e) {
      // Ignore errors silently, it will fallback to Period 1
      print("Failed to fetch next period: $e");
    }
  }

  Future<void> _loadStudents() async {
    if ((!isYearAdmin && _yearId == null) || _departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Year and Department')),
      );
      return;
    }

    final filteredSections = _sections.where(
      (s) => s['departmentId'] == _departmentId || s['department']?['id'] == _departmentId,
    ).toList();

    if (filteredSections.isNotEmpty && _sectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Section')),
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
      
      if (!mounted) return;
      setState(() {
        _isHoliday = false;
        _isLoading = false;
      });
      
      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students found for this class.')),
        );
      } else {
        _showAttendancePopup(students);
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('Holiday')) {
        setState(() {
          _isHoliday = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance cannot be marked. Today is configured as a Holiday.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  void _showAttendancePopup(List<StudentAttendanceListItem> initialStudents) {
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: _AttendancePopupContent(
            initialStudents: initialStudents,
            onSave: (updatedStudents) {
              _saveAttendance(updatedStudents);
            },
          ),
        );
      },
    );
  }

  Future<void> _saveAttendance(List<StudentAttendanceListItem> updatedStudents) async {
    if ((!isYearAdmin && _yearId == null) ||
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
        updatedStudents,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance Saved Successfully')),
      );
      // Automatically unlock the next period after saving
      _fetchNextAvailablePeriod();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving attendance: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          ? const Center(child: PragatiXLoader())
          : Stack(
              children: [
                Column(
                  children: [
                    _buildFilters(),
                    const Divider(),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Select filters and click "Load Students" to mark attendance.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: PragatiXLoader()),
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
          Row(
            children: [
              if (!isYearAdmin) ...[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (v) {
                      setState(() => _yearId = v);
                      _fetchNextAvailablePeriod();
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
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
                            d['deptCode']?.toString() ??
                                d['code']?.toString() ??
                                d['deptName']?.toString() ??
                                d['name']?.toString() ??
                                'Unknown',
                            overflow: TextOverflow.ellipsis,
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
                    _fetchNextAvailablePeriod();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredSections.isNotEmpty)
            DropdownButtonFormField<int?>(
              isExpanded: true,
              value:
                  (_sectionId != null &&
                      filteredSections.any((s) => s['id'] == _sectionId))
                  ? _sectionId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Section',
              ),
              hint: const Text('Select Section'),
              items: filteredSections
                  .where((s) => s['id'] != null)
                  .map<DropdownMenuItem<int>>((s) {
                    return DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text(
                        s['sectionName']?.toString() ?? 'Unknown',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .toList(),
              onChanged: (v) {
                setState(() => _sectionId = v);
                _fetchNextAvailablePeriod();
              },
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
                    if (d != null) {
                      setState(() => _selectedDate = d);
                      _fetchNextAvailablePeriod();
                    }
                  },
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _selectedPeriod,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: List.generate(
                    8,
                    (i) {
                      final periodNo = i + 1;
                      final isEnabled = periodNo == _selectedPeriod;
                      return DropdownMenuItem<int>(
                        value: periodNo,
                        enabled: isEnabled,
                        child: Text(
                          'Period $periodNo' + (isEnabled ? '' : ' (Locked)'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isEnabled ? Colors.black : Colors.grey,
                          ),
                        ),
                      );
                    },
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
}

class _AttendancePopupContent extends StatefulWidget {
  final List<StudentAttendanceListItem> initialStudents;
  final Function(List<StudentAttendanceListItem>) onSave;

  const _AttendancePopupContent({
    Key? key,
    required this.initialStudents,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_AttendancePopupContent> createState() => _AttendancePopupContentState();
}

class _AttendancePopupContentState extends State<_AttendancePopupContent> {
  late List<StudentAttendanceListItem> _students;

  @override
  void initState() {
    super.initState();
    _students = List.from(widget.initialStudents);
  }

  void _markAll(String status) {
    setState(() {
      _students = _students.map((s) => s.copyWith(status: status)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              padding: const EdgeInsets.only(bottom: 100.0),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final s = _students[index];
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
                          _students[index] = s.copyWith(
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
          widget.onSave(_students);
        },
        label: const Text('Save Attendance'),
        icon: const Icon(Icons.save),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }
}
