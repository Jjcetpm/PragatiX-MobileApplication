import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/core/services/loading_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import '../models/student_attendance_list_item.dart';
import '../services/attendance_service.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';

class TeacherAttendanceTab extends StatefulWidget {
  final bool hideAppBar;
  const TeacherAttendanceTab({Key? key, this.hideAppBar = false}) : super(key: key);

  @override
  State<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<TeacherAttendanceTab> {
  final AttendanceService _service = AttendanceService();

  DateTime _selectedDate = DateTime.now();
  int _selectedPeriod = 1;
  int _nextPeriod = 1;
  List<Map<String, dynamic>> _markedPeriods = [];
  int? _academicYearId;
  int? _yearId;
  int? _departmentId;
  int? _sectionId;

  List<dynamic> _academicYears = [];
  List<dynamic> _years = [];
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];

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
      final repo = getIt<AdminRepository>();
      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/academic-years'),
          headers: headers,
        ),
        repo.getAssignedYears(),
        repo.getDepartments(all: true),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections'),
          headers: headers,
        ),
      ]);

      if (!mounted) return;

      final mainDepts = (results[2] as List<dynamic>).where((d) {
        final type = (d['departmentType'] ?? d['type'] ?? '').toString().toUpperCase();
        final name = (d['name'] ?? d['deptName'] ?? '').toString();
        if (type == 'SUB') return false;
        if (name.toLowerCase().startsWith('department of')) return false;
        return true;
      }).toList();

      setState(() {
        _academicYears = jsonDecode((results[0] as http.Response).body)['data'] ?? [];
        _years = results[1] as List<dynamic>;
        _departments = mainDepts;
        _sections = jsonDecode((results[3] as http.Response).body)['data'] ?? [];

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
      ErrorHandler.showSnackBar(context, e);
    } finally {
      LoadingService.hide();
      if (mounted) {
        setState(() => _isLoadingLookups = false);
      }
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
      final marked = await _service.getMarkedPeriods(
        dateStr,
        _departmentId!,
        yearId: _yearId,
        sectionId: _sectionId,
      );

      if (mounted) {
        setState(() {
          _nextPeriod = nextPeriod;
          _markedPeriods = marked;

          final markedThisPeriod = _markedPeriods.firstWhere(
            (m) => m['period'] == _selectedPeriod,
            orElse: () => {},
          );
          final bool canViewThisPeriod = markedThisPeriod['canViewHistory'] == true;

          // If current selected period is locked or unviewable marked period, adjust selection
          if (markedThisPeriod.isEmpty && _selectedPeriod != _nextPeriod) {
            _selectedPeriod = _nextPeriod;
          } else if (markedThisPeriod.isNotEmpty && !canViewThisPeriod && _selectedPeriod != _nextPeriod) {
            _selectedPeriod = _nextPeriod;
          }
        });
      }
    } catch (e) {
      print("Failed to fetch next period: $e");
    }
  }

  Future<void> _loadStudents({bool isViewHistory = false}) async {
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
      });
      
      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students found for this class.')),
        );
      } else {
        if (isViewHistory) {
          _showAttendanceHistoryPopup(students);
        } else {
          _showAttendancePopup(students);
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('Holiday')) {
        setState(() {
          _isHoliday = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance cannot be marked. Today is configured as a Holiday.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (e.toString().contains('not configured') || e.toString().contains('Sunday') || e.toString().contains('Academic Calendar')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        if (mounted) {
          ErrorHandler.showSnackBar(context, e);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAttendanceHistoryPopup(List<StudentAttendanceListItem> students) {
    // Resolve Year Name
    String yearName = '';
    final foundYear = _years.firstWhere((y) => y['id'] == _yearId, orElse: () => null);
    if (foundYear != null) {
      yearName = foundYear['yearName']?.toString() ?? foundYear['yearNo']?.toString() ?? 'Year $_yearId';
    } else if (isYearAdmin) {
      yearName = 'Year Admin';
    } else if (_yearId != null) {
      yearName = 'Year $_yearId';
    }

    // Resolve Department Name
    String departmentName = '';
    final foundDept = _departments.firstWhere((d) => d['id'] == _departmentId, orElse: () => null);
    if (foundDept != null) {
      departmentName = foundDept['deptCode']?.toString() ?? foundDept['code']?.toString() ?? foundDept['deptName']?.toString() ?? foundDept['name']?.toString() ?? 'Dept';
    }

    // Resolve Section Name
    String sectionName = '';
    if (_sectionId != null) {
      final foundSec = _sections.firstWhere((s) => s['id'] == _sectionId, orElse: () => null);
      if (foundSec != null) {
        sectionName = foundSec['sectionName']?.toString() ?? 'Sec $_sectionId';
      }
    }

    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);

    // Resolve Faculty who marked it
    final markedInfo = _markedPeriods.firstWhere(
      (m) => m['period'] == _selectedPeriod,
      orElse: () => {},
    );
    String? facultyName = markedInfo['markedByFacultyName'] as String?;
    String? facultyDept = markedInfo['markedByFacultyDepartment'] as String?;
    String? markedAt = markedInfo['markedAt'] as String?;

    if ((facultyName == null || facultyName.isEmpty) && students.isNotEmpty) {
      facultyName = students.first.markedByFacultyName;
      facultyDept = students.first.markedByFacultyDepartment;
      markedAt = students.first.markedAt;
    }

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: AttendanceHistoryPopupContent(
            students: students,
            yearName: yearName,
            departmentName: departmentName,
            sectionName: sectionName,
            period: _selectedPeriod,
            dateStr: dateStr,
            facultyName: facultyName,
            facultyDepartment: facultyDept,
            markedAt: markedAt,
          ),
        );
      },
    );
  }

  void _showAttendancePopup(List<StudentAttendanceListItem> initialStudents) {
    // Resolve Year Name
    String yearName = '';
    final foundYear = _years.firstWhere((y) => y['id'] == _yearId, orElse: () => null);
    if (foundYear != null) {
      yearName = foundYear['yearName']?.toString() ?? foundYear['yearNo']?.toString() ?? 'Year $_yearId';
    } else if (isYearAdmin) {
      yearName = 'Year Admin';
    } else if (_yearId != null) {
      yearName = 'Year $_yearId';
    }

    // Resolve Department Name
    String departmentName = '';
    final foundDept = _departments.firstWhere((d) => d['id'] == _departmentId, orElse: () => null);
    if (foundDept != null) {
      departmentName = foundDept['deptCode']?.toString() ?? foundDept['code']?.toString() ?? foundDept['deptName']?.toString() ?? foundDept['name']?.toString() ?? 'Dept';
    }

    // Resolve Section Name
    String sectionName = '';
    if (_sectionId != null) {
      final foundSec = _sections.firstWhere((s) => s['id'] == _sectionId, orElse: () => null);
      if (foundSec != null) {
        sectionName = foundSec['sectionName']?.toString() ?? 'Sec $_sectionId';
      }
    }

    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: AttendancePopupContent(
            initialStudents: initialStudents,
            yearName: yearName,
            departmentName: departmentName,
            sectionName: sectionName,
            period: _selectedPeriod,
            dateStr: dateStr,
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
      ErrorHandler.showSnackBar(context, e);
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
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text(
                'Mark Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF1E293B),
              elevation: 0,
            ),
      body: Stack(
        fit: StackFit.expand,
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
            const Positioned.fill(
              child: PragatiXLoader(
                message: 'Loading attendance...',
                fullScreen: false,
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
                      final markedInfo = _markedPeriods.firstWhere(
                        (m) => m['period'] == periodNo,
                        orElse: () => {},
                      );
                      final bool isMarked = markedInfo.isNotEmpty;
                      final bool canViewHistory = markedInfo['canViewHistory'] == true;
                      final bool isMarkedByMe = markedInfo['isMarkedByMe'] == true;
                      final String? facultyName = markedInfo['markedByFacultyName'] as String?;
                      final bool isNext = periodNo == _nextPeriod && !isMarked;
                      final bool isEnabled = (isMarked && canViewHistory) || isNext;

                      String label = 'Period $periodNo';
                      if (isMarked) {
                        if (canViewHistory) {
                          if (isMarkedByMe) {
                            label += ' (Marked by you • View History)';
                          } else {
                            label += ' (Marked${facultyName != null ? " by $facultyName" : ""} • View History)';
                          }
                        } else {
                          label += ' (Marked${facultyName != null ? " by $facultyName" : ""} • Locked)';
                        }
                      } else if (isNext) {
                        label += ' (Active to Mark)';
                      } else {
                        label += ' (Locked)';
                      }

                      return DropdownMenuItem<int>(
                        value: periodNo,
                        enabled: isEnabled,
                        child: Row(
                          children: [
                            if (isMarked) ...[
                              Icon(
                                canViewHistory ? Icons.check_circle : Icons.lock_outline,
                                color: canViewHistory ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                            ] else if (isNext) ...[
                              const Icon(Icons.play_circle_fill, color: Color(0xFF2563EB), size: 16),
                              const SizedBox(width: 6),
                            ] else ...[
                              const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 16),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isMarked
                                      ? (canViewHistory ? const Color(0xFF16A34A) : const Color(0xFF94A3B8))
                                      : (isNext ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                                  fontWeight: (isMarked && canViewHistory) || isNext ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
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
          Builder(builder: (context) {
            final markedInfo = _markedPeriods.firstWhere(
              (m) => m['period'] == _selectedPeriod,
              orElse: () => {},
            );
            final bool isSelectedPeriodMarked = markedInfo.isNotEmpty;
            final bool canViewHistory = markedInfo['canViewHistory'] == true;
            final String? facultyName = markedInfo['markedByFacultyName'] as String?;

            final bool isButtonDisabled = _isLoading ||
                _isLoadingLookups ||
                (isSelectedPeriodMarked && !canViewHistory);

            String buttonLabel;
            if (_isLoadingLookups) {
              buttonLabel = 'Preparing Filters...';
            } else if (isSelectedPeriodMarked) {
              if (canViewHistory) {
                buttonLabel = 'View History (Period $_selectedPeriod)';
              } else {
                buttonLabel = 'Marked${facultyName != null ? " by $facultyName" : ""} • No Access';
              }
            } else {
              buttonLabel = 'Mark Attendance (Period $_selectedPeriod)';
            }

            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isButtonDisabled
                    ? null
                    : () => _loadStudents(isViewHistory: isSelectedPeriodMarked),
                icon: Icon(
                  isSelectedPeriodMarked
                      ? (canViewHistory ? Icons.history_edu_rounded : Icons.lock_outline)
                      : Icons.checklist_rounded,
                  size: 20,
                ),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelectedPeriodMarked
                      ? (canViewHistory ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8))
                      : const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AttendanceHistoryPopupContent extends StatefulWidget {
  final List<StudentAttendanceListItem> students;
  final String? yearName;
  final String? departmentName;
  final String? sectionName;
  final int? period;
  final String? dateStr;
  final String? facultyName;
  final String? facultyDepartment;
  final String? markedAt;

  const AttendanceHistoryPopupContent({
    Key? key,
    required this.students,
    this.yearName,
    this.departmentName,
    this.sectionName,
    this.period,
    this.dateStr,
    this.facultyName,
    this.facultyDepartment,
    this.markedAt,
  }) : super(key: key);

  @override
  State<AttendanceHistoryPopupContent> createState() => _AttendanceHistoryPopupContentState();
}

class _AttendanceHistoryPopupContentState extends State<AttendanceHistoryPopupContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentAttendanceListItem> get _filteredStudents {
    List<StudentAttendanceListItem> list = widget.students;
    if (_activeTab == 'PRESENT') {
      list = list.where((s) => s.status == 'PRESENT').toList();
    } else if (_activeTab == 'ABSENT') {
      list = list.where((s) => s.status == 'ABSENT').toList();
    }

    if (_searchQuery.trim().isEmpty) {
      return list;
    }
    final q = _searchQuery.trim().toLowerCase();
    return list.where((s) {
      final nameMatches = s.studentName.toLowerCase().contains(q);
      final regMatches = s.registerNumber.toLowerCase().contains(q);
      return nameMatches || regMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.students.length;
    final presentCount = widget.students.where((s) => s.status == 'PRESENT').length;
    final absentCount = widget.students.where((s) => s.status == 'ABSENT').length;
    final presentPct = totalCount > 0 ? (presentCount / totalCount * 100).toStringAsFixed(1) : '0';
    final absentPct = totalCount > 0 ? (absentCount / totalCount * 100).toStringAsFixed(1) : '0';
    final filtered = _filteredStudents;

    String facultyDisplay = '';
    if (widget.facultyName != null && widget.facultyName!.isNotEmpty) {
      facultyDisplay = widget.facultyName!;
      if (widget.facultyDepartment != null && widget.facultyDepartment!.isNotEmpty) {
        facultyDisplay += ' (${widget.facultyDepartment})';
      }
    } else {
      for (final s in widget.students) {
        if (s.markedByFacultyName != null && s.markedByFacultyName!.isNotEmpty) {
          facultyDisplay = s.markedByFacultyName!;
          if (s.markedByFacultyDepartment != null && s.markedByFacultyDepartment!.isNotEmpty) {
            facultyDisplay += ' (${s.markedByFacultyDepartment})';
          }
          break;
        }
      }
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Period ${widget.period ?? 1} • ${widget.dateStr ?? ""}${facultyDisplay.isNotEmpty ? " • By $facultyDisplay" : ""}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // ── Class Info Badges ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (widget.yearName != null && widget.yearName!.isNotEmpty)
                  _buildClassInfoChip(Icons.calendar_month_outlined, widget.yearName!, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                if (widget.departmentName != null && widget.departmentName!.isNotEmpty)
                  _buildClassInfoChip(Icons.domain_outlined, widget.departmentName!, const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
                if (widget.sectionName != null && widget.sectionName!.isNotEmpty)
                  _buildClassInfoChip(Icons.group_outlined, widget.sectionName!, const Color(0xFF0D9488), const Color(0xFFCCFBF1)),
                if (facultyDisplay.isNotEmpty)
                  _buildClassInfoChip(Icons.person_pin_rounded, 'Marked by: $facultyDisplay', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
              ],
            ),
          ),

          // ── Metrics Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total',
                    value: '$totalCount',
                    color: const Color(0xFF475569),
                    bgColor: const Color(0xFFF1F5F9),
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Present',
                    value: '$presentCount ($presentPct%)',
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Absent',
                    value: '$absentCount ($absentPct%)',
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEE2E2),
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
          ),

          // ── Filter Tabs & Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                // Filter Tabs
                Row(
                  children: [
                    _buildTabChip('ALL', 'All ($totalCount)', const Color(0xFF1E293B), const Color(0xFFF1F5F9)),
                    const SizedBox(width: 8),
                    _buildTabChip('PRESENT', 'Present ($presentCount)', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
                    const SizedBox(width: 8),
                    _buildTabChip('ABSENT', 'Absent ($absentCount)', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Box
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search student name or reg no...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Student List (Read-Only) ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No students match filter',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      final isPresent = s.status == 'PRESENT';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isPresent ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : 'S',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Student Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.registerNumber,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (s.remarks != null && s.remarks!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Remark: ${s.remarks}',
                                      style: const TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Status Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isPresent ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPresent ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    size: 14,
                                    color: isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPresent ? 'PRESENT' : 'ABSENT',
                                    style: TextStyle(
                                      color: isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ── Bottom Close Bar ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close History', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoChip(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String tabKey, String label, Color activeColor, Color activeBg) {
    final isSelected = _activeTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = tabKey),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}

class AttendancePopupContent extends StatefulWidget {
  final List<StudentAttendanceListItem> initialStudents;
  final String? yearName;
  final String? departmentName;
  final String? sectionName;
  final int? period;
  final String? dateStr;
  final Function(List<StudentAttendanceListItem>) onSave;

  const AttendancePopupContent({
    Key? key,
    required this.initialStudents,
    this.yearName,
    this.departmentName,
    this.sectionName,
    this.period,
    this.dateStr,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AttendancePopupContent> createState() => _AttendancePopupContentState();
}

class _AttendancePopupContentState extends State<AttendancePopupContent> {
  late List<StudentAttendanceListItem> _students;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _students = List.from(widget.initialStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentAttendanceListItem> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) {
      return _students;
    }
    final q = _searchQuery.trim().toLowerCase();
    return _students.where((s) {
      final nameMatches = s.studentName.toLowerCase().contains(q);
      final regMatches = s.registerNumber.toLowerCase().contains(q);
      return nameMatches || regMatches;
    }).toList();
  }

  void _markAll(String status) {
    setState(() {
      if (_searchQuery.trim().isEmpty) {
        _students = _students.map((s) => s.copyWith(status: status)).toList();
      } else {
        final filteredIds = _filteredStudents.map((s) => s.studentId).toSet();
        _students = _students.map((s) {
          if (filteredIds.contains(s.studentId)) {
            return s.copyWith(status: status);
          }
          return s;
        }).toList();
      }
    });
  }

  void _updateStudentStatus(int studentId, String newStatus) {
    setState(() {
      final index = _students.indexWhere((s) => s.studentId == studentId);
      if (index != -1) {
        _students[index] = _students[index].copyWith(status: newStatus);
      }
    });
  }

  void _openSummaryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AttendanceSummaryPage(
          students: _students,
          yearName: widget.yearName,
          departmentName: widget.departmentName,
          sectionName: widget.sectionName,
          period: widget.period,
          dateStr: widget.dateStr,
          onConfirm: (finalStudents) {
            Navigator.pop(context);
            widget.onSave(finalStudents);
          },
        ),
      ),
    );
  }

  Widget _buildClassInfoChip(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(StudentAttendanceListItem s) {
    final isPresent = s.status == 'PRESENT';
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Present (P) Button - Green
          InkWell(
            onTap: () => _updateStudentStatus(s.studentId, 'PRESENT'),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isPresent ? const Color(0xFF16A34A) : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPresent) ...[
                    const Icon(Icons.check, size: 14, color: Colors.white),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    'P',
                    style: TextStyle(
                      color: isPresent ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Absent (A) Button - Red
          InkWell(
            onTap: () => _updateStudentStatus(s.studentId, 'ABSENT'),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: !isPresent ? const Color(0xFFDC2626) : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPresent) ...[
                    const Icon(Icons.close, size: 14, color: Colors.white),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    'A',
                    style: TextStyle(
                      color: !isPresent ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mark Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by student name or roll number...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4F46E5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Class Info Header Strip (Year, Department, Section, Period, Date)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (widget.yearName != null && widget.yearName!.isNotEmpty) ...[
                      _buildClassInfoChip(
                        Icons.school_rounded,
                        widget.yearName!,
                        const Color(0xFF4338CA),
                        const Color(0xFFEEF2FF),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.departmentName != null && widget.departmentName!.isNotEmpty) ...[
                      _buildClassInfoChip(
                        Icons.domain_rounded,
                        widget.departmentName!,
                        const Color(0xFF0369A1),
                        const Color(0xFFE0F2FE),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.sectionName != null && widget.sectionName!.isNotEmpty) ...[
                      _buildClassInfoChip(
                        Icons.group_work_rounded,
                        'Sec: ${widget.sectionName}',
                        const Color(0xFF0F766E),
                        const Color(0xFFCCFBF1),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.period != null) ...[
                      _buildClassInfoChip(
                        Icons.access_time_filled_rounded,
                        'Period ${widget.period}',
                        const Color(0xFFB45309),
                        const Color(0xFFFEF3C7),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.dateStr != null && widget.dateStr!.isNotEmpty) ...[
                      _buildClassInfoChip(
                        Icons.calendar_today_rounded,
                        widget.dateStr!,
                        const Color(0xFF475569),
                        const Color(0xFFF1F5F9),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Action Buttons & Count Indicator (Overflow Protected)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? '${filtered.length} / ${_students.length} Students'
                          : '${_students.length} Students',
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _markAll('PRESENT'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 15,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Present Filtered'
                                : 'Mark All Present',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _markAll('ABSENT'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.highlight_off_rounded,
                            size: 15,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Absent Filtered'
                                : 'Mark All Absent',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Student List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No students found matching "$_searchQuery"'
                                : 'No students available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 100.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      final isPresent = s.status == 'PRESENT';
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isPresent
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                            width: 1.0,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            s.studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            s.registerNumber,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: _buildStatusToggle(s),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSummaryScreen,
        label: const Text(
          'Save Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.save, color: Colors.white),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }
}

class AttendanceSummaryPage extends StatefulWidget {
  final List<StudentAttendanceListItem> students;
  final String? yearName;
  final String? departmentName;
  final String? sectionName;
  final int? period;
  final String? dateStr;
  final Function(List<StudentAttendanceListItem>) onConfirm;

  const AttendanceSummaryPage({
    Key? key,
    required this.students,
    this.yearName,
    this.departmentName,
    this.sectionName,
    this.period,
    this.dateStr,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  String _activeTab = 'ABSENT';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final hasAbsent = widget.students.any((s) => s.status == 'ABSENT');
    _activeTab = hasAbsent ? 'ABSENT' : 'ALL';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentAttendanceListItem> get _displayedStudents {
    List<StudentAttendanceListItem> list = widget.students;
    if (_activeTab == 'ABSENT') {
      list = list.where((s) => s.status == 'ABSENT').toList();
    } else if (_activeTab == 'PRESENT') {
      list = list.where((s) => s.status == 'PRESENT').toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) =>
        s.studentName.toLowerCase().contains(q) ||
        s.registerNumber.toLowerCase().contains(q)
      ).toList();
    }

    return list;
  }

  Widget _buildClassInfoChip(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.students.length;
    final presentCount = widget.students.where((s) => s.status == 'PRESENT').length;
    final absentCount = widget.students.where((s) => s.status == 'ABSENT').toList().length;
    final percent = total > 0 ? ((presentCount / total) * 100).toStringAsFixed(1) : '0';
    final displayed = _displayedStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Class Context Banner in Summary Screen
          if ((widget.yearName != null && widget.yearName!.isNotEmpty) ||
              (widget.departmentName != null && widget.departmentName!.isNotEmpty))
            Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (widget.yearName != null && widget.yearName!.isNotEmpty) ...[
                      _buildClassInfoChip(Icons.school_rounded, widget.yearName!, Colors.white, Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(width: 6),
                    ],
                    if (widget.departmentName != null && widget.departmentName!.isNotEmpty) ...[
                      _buildClassInfoChip(Icons.domain_rounded, widget.departmentName!, Colors.white, Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(width: 6),
                    ],
                    if (widget.sectionName != null && widget.sectionName!.isNotEmpty) ...[
                      _buildClassInfoChip(Icons.group_work_rounded, 'Sec: ${widget.sectionName}', Colors.white, Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(width: 6),
                    ],
                    if (widget.period != null) ...[
                      _buildClassInfoChip(Icons.access_time_filled_rounded, 'Period ${widget.period}', const Color(0xFFFDE68A), Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(width: 6),
                    ],
                    if (widget.dateStr != null && widget.dateStr!.isNotEmpty) ...[
                      _buildClassInfoChip(Icons.calendar_today_rounded, widget.dateStr!, Colors.white70, Colors.white.withValues(alpha: 0.1)),
                    ],
                  ],
                ),
              ),
            ),
          // Top Stats Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Total
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 0.8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$total',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '100%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Present
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'PRESENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$presentCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Absent
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ABSENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$absentCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            Text(
                              total > 0 ? '${((absentCount / total) * 100).toStringAsFixed(1)}%' : '0%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter Tabs (Absent, Present, All)
                Row(
                  children: [
                    _buildTabChip('ABSENT', 'Absent ($absentCount)', const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
                    const SizedBox(width: 8),
                    _buildTabChip('PRESENT', 'Present ($presentCount)', const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
                    const SizedBox(width: 8),
                    _buildTabChip('ALL', 'All ($total)', const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
                  ],
                ),
              ],
            ),
          ),
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search student in summary...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Students List
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _activeTab == 'ABSENT' ? Icons.celebration_rounded : Icons.person_search_rounded,
                            size: 56,
                            color: _activeTab == 'ABSENT' ? const Color(0xFF16A34A) : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _activeTab == 'ABSENT' && _searchQuery.isEmpty
                                ? 'No Absent Students!\nAll students are marked as Present.'
                                : 'No students found matching current filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: _activeTab == 'ABSENT' && _searchQuery.isEmpty ? const Color(0xFF16A34A) : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: displayed.length,
                    itemBuilder: (context, index) {
                      final s = displayed[index];
                      final isPresent = s.status == 'PRESENT';
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isPresent ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPresent ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.registerNumber,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPresent ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isPresent ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPresent ? Icons.check_circle : Icons.cancel,
                                    size: 14,
                                    color: isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPresent ? 'PRESENT' : 'ABSENT',
                                    style: TextStyle(
                                      color: isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Bottom Sticky Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF475569)),
                    label: const Text(
                      'Edit Attendance',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onConfirm(widget.students);
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Confirm & Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String tabKey, String label, Color activeColor, Color activeBg) {
    final isSelected = _activeTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = tabKey),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
