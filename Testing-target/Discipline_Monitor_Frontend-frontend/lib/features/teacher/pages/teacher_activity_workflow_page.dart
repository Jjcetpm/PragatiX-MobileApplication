import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';

class TeacherActivityWorkflowPage extends StatefulWidget {
  final ActivityModel activity;
  final int? stageId;
  final String? stageName;

  const TeacherActivityWorkflowPage({
    super.key,
    required this.activity,
    this.stageId,
    this.stageName,
  });

  @override
  State<TeacherActivityWorkflowPage> createState() =>
      _TeacherActivityWorkflowPageState();
}

class _TeacherActivityWorkflowPageState
    extends State<TeacherActivityWorkflowPage> {
  // Flow steps:
  // 1: Year selection
  // 2: Dept selection
  // 3: Section selection
  // 4: Student selection & Award
  int _currentFlowStep = 1;

  bool _isLoading = false;
  bool _isAwarding = false;

  // Selected state
  dynamic _selectedYear;
  dynamic _selectedDept;
  int? _assignmentId;

  List<dynamic> _availableYearsList = [];
  List<dynamic> _availableDeptsList = [];
  List<dynamic> _availableSectionsList = [];
  bool _hasSections = false;
  List<dynamic> _eligibleStudents = [];
  final Set<int> _selectedStudentIds = {};
  bool _selectAll = false;

  // Search controllers / queries
  String _deptSearchQuery = '';
  String _studentSearchQuery = '';
  final TextEditingController _remarksController = TextEditingController();

  final List<Map<String, dynamic>> _fixedYears = [
    {'yearName': '1st Year', 'yearNo': 1},
    {'yearName': '2nd Year', 'yearNo': 2},
    {'yearName': '3rd Year', 'yearNo': 3},
    {'yearName': '4th Year', 'yearNo': 4},
  ];

  @override
  void initState() {
    super.initState();
    _fetchYearsForActivity();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  List<String> _getYearAliases(Map<String, dynamic> fy) {
    final no = fy['yearNo'];
    final aliases = <String>[];
    if (no == 1) {
      aliases.addAll(['1', '1st', 'first', 'i', '1st year', 'year 1', 'first year']);
    } else if (no == 2) {
      aliases.addAll(['2', '2nd', 'second', 'ii', '2nd year', 'year 2', 'second year']);
    } else if (no == 3) {
      aliases.addAll(['3', '3rd', 'third', 'iii', '3rd year', 'year 3', 'third year']);
    } else if (no == 4) {
      aliases.addAll(['4', '4th', 'fourth', 'iv', '4th year', 'year 4', 'fourth year']);
    }
    return aliases;
  }

  String _getYearParam(dynamic year) {
    final yearNo = year['yearNo'];
    if (yearNo == 2) return 'II';
    if (yearNo == 3) return 'III';
    if (yearNo == 4) return 'IV';
    return 'I';
  }

  Future<void> _fetchYearsForActivity() async {
    setState(() {
      _isLoading = true;
      _availableYearsList = [];
    });
    try {
      final stageParam = widget.stageId != null ? '?stageId=${widget.stageId}' : '';
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activity.id}/years$stageParam',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> yrs = data['data'] ?? [];
          setState(() {
            _availableYearsList = _fixedYears.where((fy) {
              final aliases = _getYearAliases(fy);
              return yrs.any(
                (y) => aliases.contains(y.toString().toLowerCase().trim()),
              );
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching years: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDeptsForYear(dynamic year) async {
    setState(() {
      _isLoading = true;
      _availableDeptsList = [];
    });
    try {
      final yearParam = _getYearParam(year);
      final stageParam = widget.stageId != null ? '&stageId=${widget.stageId}' : '';
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activity.id}/departments?year=$yearParam$stageParam',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _availableDeptsList = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSectionsForDept(dynamic dept) async {
    setState(() {
      _isLoading = true;
      _availableSectionsList = [];
    });
    try {
      final yearParam = _getYearParam(_selectedYear);
      final deptId = dept['id'];
      final stageParam = widget.stageId != null ? '&stageId=${widget.stageId}' : '';

      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activity.id}/sections?year=$yearParam&departmentId=$deptId$stageParam',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          setState(() {
            _availableSectionsList = list;
            _hasSections = list.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchStudentsFinal(dynamic section) async {
    setState(() {
      _isLoading = true;
      _eligibleStudents = [];
      _selectedStudentIds.clear();
      _selectAll = false;
      _assignmentId = null;
    });
    try {
      final yearParam = _getYearParam(_selectedYear);
      final deptId = _selectedDept['id'];
      final stageParam = widget.stageId != null ? '&stageId=${widget.stageId}' : '';

      String url =
          '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activity.id}/students?year=$yearParam&departmentId=$deptId$stageParam';
      if (section != null) {
        final secId = section['id'];
        url += '&sectionId=$secId';
      }

      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            final List<dynamic> list = List.from(data['data']['students'] ?? []);
            list.sort((a, b) {
              final nameA = (a['fullName'] as String? ?? '').trim().toLowerCase();
              final nameB = (b['fullName'] as String? ?? '').trim().toLowerCase();
              final comp = nameA.compareTo(nameB);
              if (comp != 0) return comp;
              final regA = (a['regNo'] as String? ?? '').trim().toLowerCase();
              final regB = (b['regNo'] as String? ?? '').trim().toLowerCase();
              return regA.compareTo(regB);
            });
            _eligibleStudents = list;
            final assignData = data['data']['assignment'];
            _assignmentId = assignData != null
                ? (assignData['id'] as num?)?.toInt()
                : null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAward() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one student'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isAwarding = true);

    try {
      final body = {
        'studentIds': _selectedStudentIds.toList(),
        'activityId': widget.activity.id,
        'assignmentId': _assignmentId ?? widget.activity.id,
        'remarks': _remarksController.text.trim(),
      };

      final response = await getIt<TeacherProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/student-xp/award/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'XP Awarded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _remarksController.clear();
          Navigator.pop(context, true);
          return;
        }
      }

      if (!mounted) return;
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorData['message'] ?? 'Failed to award XP'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAwarding = false);
      }
    }
  }

  void _onYearSelected(dynamic year) {
    setState(() {
      _selectedYear = year;
      _deptSearchQuery = '';
      _currentFlowStep = 2;
    });
    _fetchDeptsForYear(year);
  }

  void _onDeptSelected(dynamic dept) async {
    setState(() {
      _selectedDept = dept;
    });
    await _fetchSectionsForDept(dept);
    if (_hasSections) {
      setState(() => _currentFlowStep = 3);
    } else {
      setState(() => _currentFlowStep = 4);
      _fetchStudentsFinal(null);
    }
  }

  void _onSectionSelected(dynamic sec) {
    setState(() {
      _currentFlowStep = 4;
    });
    _fetchStudentsFinal(sec);
  }

  List<dynamic> get _filteredDepts {
    if (_deptSearchQuery.trim().isEmpty) return _availableDeptsList;
    final query = _deptSearchQuery.toLowerCase();
    return _availableDeptsList
        .where((d) => d['name'].toString().toLowerCase().contains(query))
        .toList();
  }

  List<dynamic> get _filteredStudentsList {
    List<dynamic> list;
    if (_studentSearchQuery.trim().isEmpty) {
      list = List.from(_eligibleStudents);
    } else {
      final query = _studentSearchQuery.toLowerCase();
      list = _eligibleStudents.where((s) {
        final name = (s['fullName'] as String? ?? '').toLowerCase();
        final regNo = (s['regNo'] as String? ?? '').toLowerCase();
        return name.contains(query) || regNo.contains(query);
      }).toList();
    }
    list.sort((a, b) {
      final nameA = (a['fullName'] as String? ?? '').trim().toLowerCase();
      final nameB = (b['fullName'] as String? ?? '').trim().toLowerCase();
      final comp = nameA.compareTo(nameB);
      if (comp != 0) return comp;
      final regA = (a['regNo'] as String? ?? '').trim().toLowerCase();
      final regB = (b['regNo'] as String? ?? '').trim().toLowerCase();
      return regA.compareTo(regB);
    });
    return list;
  }

  void _handleBackNavigation() {
    if (_currentFlowStep > 1) {
      setState(() {
        if (_currentFlowStep == 4) {
          if (_hasSections) {
            _currentFlowStep = 3;
          } else {
            _currentFlowStep = 2;
          }
        } else {
          _currentFlowStep--;
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  String _getAppBarTitle() {
    switch (_currentFlowStep) {
      case 1:
        return 'Select Academic Year';
      case 2:
        return 'Select Department';
      case 3:
        return 'Select Section';
      case 4:
        return widget.activity.name;
      default:
        return widget.activity.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentFlowStep == 1,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF11998E)),
              )
            : _buildFlowBody(),
      ),
    );
  }

  Widget _buildFlowBody() {
    switch (_currentFlowStep) {
      case 1:
        return _buildYearSelection();
      case 2:
        return _buildDeptSelection();
      case 3:
        return _buildSectionSelection();
      case 4:
        return _buildStudentListAndAward();
      default:
        return _buildYearSelection();
    }
  }

  Widget _buildYearSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Academic Year',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _availableYearsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No available years found for this activity',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _availableYearsList.length,
                    itemBuilder: (ctx, idx) {
                      final year = _availableYearsList[idx];
                      final yearName = year['yearName'] ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _onYearSelected(year),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.blue.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    yearName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptSelection() {
    final depts = _filteredDepts;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Department',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search Department…',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _deptSearchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: depts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.domain_disabled_rounded,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No departments found',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: depts.length,
                    itemBuilder: (ctx, idx) {
                      final dept = depts[idx];
                      final name = dept['name'] ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _onDeptSelected(dept),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.indigo.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelection() {
    final uniqueSections = _availableSectionsList;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Section',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: uniqueSections.length,
              itemBuilder: (ctx, idx) {
                final sec = uniqueSections[idx];
                final secName = sec['sectionName'] ?? sec['name'] ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onSectionSelected(sec),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            child: const Icon(
                              Icons.class_rounded,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Section $secName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListAndAward() {
    final bool isPenalty = widget.activity.penaltyEnabled && !widget.activity.awardEnabled;
    final int xpAmount = isPenalty ? widget.activity.penaltyXp : widget.activity.awardXp;
    final String xpLabel = isPenalty ? 'Penalty' : 'Award';
    final Color themeColor = isPenalty ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final showStudents = _filteredStudentsList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Students',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$xpLabel: $xpAmount XP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search Student by Name/ID…',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _studentSearchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Select All Students',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                value: _selectAll,
                activeColor: themeColor,
                onChanged: (val) {
                  setState(() {
                    _selectAll = val ?? false;
                    if (_selectAll) {
                      _selectedStudentIds.addAll(
                        showStudents.map((s) => (s['id'] as num).toInt()),
                      );
                    } else {
                      _selectedStudentIds.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: showStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off_rounded,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No students match search criteria',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: showStudents.length,
                  itemBuilder: (context, index) {
                    final student = showStudents[index];
                    final int studentId = (student['id'] as num).toInt();
                    final String name = student['fullName'] ?? '';
                    final String studentIdStr = student['regNo'] ?? '';
                    final isChecked = _selectedStudentIds.contains(studentId);

                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: themeColor,
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: Text(
                        studentIdStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedStudentIds.add(studentId);
                          } else {
                            _selectedStudentIds.remove(studentId);
                            _selectAll = false;
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _remarksController,
                decoration: InputDecoration(
                  hintText: 'Add optional description/remarks…',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isAwarding ? null : _submitAward,
                  child: _isAwarding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "${isPenalty ? 'Deduct XP from' : 'Award XP to'} ${_selectedStudentIds.length} Students",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
