import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/features/teacher/pages/students_tab.dart';
import 'package:pragatix/features/activity/pages/group_activity_year_page.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/badge/pages/cc_badge_requests_page.dart';
import 'package:pragatix/features/penalty/pages/penalty_requests_page.dart'
    as spdms_penalty;
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';

class PerformanceActivitiesTab extends StatefulWidget {
  final List<String> subRoles;
  const PerformanceActivitiesTab({super.key, required this.subRoles});

  @override
  State<PerformanceActivitiesTab> createState() =>
      _PerformanceActivitiesTabState();
}

class _PerformanceActivitiesTabState extends State<PerformanceActivitiesTab> {
  // Navigation Flow State
  // 0: Category Grid Selection
  // 1: Event List (filtered by category)
  // 2: Year Selection
  // 3: Department Selection
  // 4: Section Selection
  // 5: Student Selection List & Award Screen
  int _currentFlowStep = 0;

  String? _selectedCategory;
  List<dynamic> _myActivities = [];
  int _pendingBadgeRequests = 0;
  int _pendingPenaltyRequests = 0;
  bool _isLoadingActivities = false;

  dynamic _selectedEvent; // Activity representation
  final List<dynamic> _rawEligibleStudents = [];
  List<dynamic> _eligibleStudents = [];
  bool _isLoadingStudents = false;
  int? _assignmentId;

  // Selection State
  final Set<int> _selectedStudentIds = {};
  bool _selectAll = false;
  final TextEditingController _remarksController = TextEditingController();
  bool _isAwarding = false;

  // Drill-down selection state
  dynamic _selectedYear;
  dynamic _selectedDept;
  String? _selectedSection;

  List<dynamic> _availableYearsList = [];
  List<dynamic> _availableDeptsList = [];
  List<dynamic> _availableSectionsList = [];
  bool _hasSections = false;

  // Search queries
  String _eventSearchQuery = '';
  String _deptSearchQuery = '';
  String _studentSearchQuery = '';

  final List<Map<String, dynamic>> _fixedYears = [
    {'yearName': '1st Year', 'yearNo': 1},
    {'yearName': '2nd Year', 'yearNo': 2},
    {'yearName': '3rd Year', 'yearNo': 3},
    {'yearName': '4th Year', 'yearNo': 4},
  ];

  final Map<String, Map<String, dynamic>> _categoryStyles = {
    'ACADEMIC': {
      'color': Colors.blue,
      'icon': Icons.school_rounded,
      'label': 'Academic',
    },
    'COMMUNICATION': {
      'color': Colors.indigo,
      'icon': Icons.chat_bubble_rounded,
      'label': 'Communication',
    },
    'LEADERSHIP': {
      'color': Colors.amber,
      'icon': Icons.emoji_events_rounded,
      'label': 'Leadership',
    },
    'INNOVATION': {
      'color': Colors.orange,
      'icon': Icons.lightbulb_rounded,
      'label': 'Innovation',
    },
    'PLACEMENT': {
      'color': Colors.green,
      'icon': Icons.work_rounded,
      'label': 'Placement',
    },
    'DISCIPLINE': {
      'color': Colors.red,
      'icon': Icons.verified_user_rounded,
      'label': 'Discipline',
    },
    'SPORTS': {
      'color': Colors.pink,
      'icon': Icons.sports_soccer_rounded,
      'label': 'Sports',
    },
    'COMMUNITY': {
      'color': Colors.teal,
      'icon': Icons.people_rounded,
      'label': 'Community',
    },
    'SKILL': {
      'color': Colors.purple,
      'icon': Icons.psychology_rounded,
      'label': 'Skill',
    },
    'CULTURAL': {
      'color': Colors.cyan,
      'icon': Icons.music_note_rounded,
      'label': 'Cultural',
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchMyActivities();
    if (widget.subRoles.any(
      (r) =>
          r.toUpperCase() == 'CC' ||
          r.toUpperCase() == 'CLASS_COORDINATOR' ||
          r.toUpperCase() == 'ROLE_CC',
    )) {
      _fetchPendingBadges();
    }
  }

  Future<void> _fetchPendingBadges() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/cc/dashboard/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          final pBadges = data['data']['pendingBadgeRequests'] ?? 0;
          final pPenalties = data['data']['pendingPenaltyRequests'] ?? 0;
          setState(() {
            _pendingBadgeRequests = pBadges;
            _pendingPenaltyRequests = pPenalties;
          });
          context.read<PenaltyProvider>().setPendingCount(pPenalties);
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  List<String> _getYearAliases(dynamic selectedYear) {
    if (selectedYear == null) return [];
    final yearName =
        selectedYear['yearName']?.toString().trim().toLowerCase() ?? '';
    final yearNo = (selectedYear['yearNo'] as num?)?.toInt() ?? -1;

    final List<String> aliases = [];
    if (yearName.isNotEmpty) {
      aliases.add(yearName);
    }
    if (yearNo != -1) {
      aliases.add(yearNo.toString());
      if (yearNo == 1) {
        aliases.addAll(['i', 'first', '1st', '1']);
      } else if (yearNo == 2) {
        aliases.addAll(['ii', 'second', '2nd', '2']);
      } else if (yearNo == 3) {
        aliases.addAll(['iii', 'third', '3rd', '3']);
      } else if (yearNo == 4) {
        aliases.addAll(['iv', 'fourth', '4th', '4']);
      }
    }
    return aliases;
  }

  List<Map<String, dynamic>> get _availableYears {
    final studentYears = _rawEligibleStudents
        .map((s) => s['year']?.toString().trim().toLowerCase() ?? '')
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList();

    final List<Map<String, dynamic>> list = [];
    for (final yr in _fixedYears) {
      final aliases = _getYearAliases(yr);
      final hasStudents = studentYears.any((sy) => aliases.contains(sy));
      if (hasStudents) {
        list.add(yr);
      }
    }
    return list.isNotEmpty ? list : _fixedYears;
  }

  List<Map<String, dynamic>> get _availableDepartments {
    if (_selectedYear == null) return [];
    final yearAliases = _getYearAliases(_selectedYear);

    final deptNames = _rawEligibleStudents
        .where((s) {
          final sYear = s['year']?.toString().trim().toLowerCase() ?? '';
          return yearAliases.contains(sYear);
        })
        .map((s) => s['departmentName']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final list = deptNames.map((name) => {'name': name}).toList();
    if (_deptSearchQuery.trim().isEmpty) return list;
    final query = _deptSearchQuery.toLowerCase();
    return list
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

  Future<void> _fetchMyActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });
    const url = '${ApiConfig.baseUrl}/api/v1/admin/my-activities';
    debugPrint('Requested URL: $url');
    debugPrint('Request parameters: None');
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          debugPrint('Parsed activities count: ${list.length}');
          setState(() {
            _myActivities = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching my activities: $e');
    }
    setState(() {
      _isLoadingActivities = false;
    });
  }

  Future<void> _fetchYearsForEvent(dynamic event) async {
    setState(() {
      _isLoadingStudents = true;
      _availableYearsList = [];
    });
    try {
      final activityId = event['activityId'];
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/$activityId/years',
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
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _fetchDeptsForYear(dynamic year) async {
    setState(() {
      _isLoadingStudents = true;
      _availableDeptsList = [];
    });
    try {
      final activityId = _selectedEvent['activityId'];
      final yearNo = year['yearNo'];
      String yearParam = 'I';
      if (yearNo == 2) yearParam = 'II';
      if (yearNo == 3) yearParam = 'III';
      if (yearNo == 4) yearParam = 'IV';

      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/$activityId/departments?year=$yearParam',
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
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _fetchSectionsForDept(dynamic dept) async {
    setState(() {
      _isLoadingStudents = true;
      _availableSectionsList = [];
    });
    try {
      final activityId = _selectedEvent['activityId'];
      final yearNo = _selectedYear['yearNo'];
      String yearParam = 'I';
      if (yearNo == 2) yearParam = 'II';
      if (yearNo == 3) yearParam = 'III';
      if (yearNo == 4) yearParam = 'IV';
      final deptId = dept['id'];

      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/$activityId/sections?year=$yearParam&departmentId=$deptId',
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
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _fetchStudentsFinal(dynamic section) async {
    setState(() {
      _isLoadingStudents = true;
      _eligibleStudents = [];
      _selectedStudentIds.clear();
      _selectAll = false;
      _assignmentId = null;
    });
    try {
      final activityId = _selectedEvent['activityId'];
      final yearNo = _selectedYear['yearNo'];
      String yearParam = 'I';
      if (yearNo == 2) yearParam = 'II';
      if (yearNo == 3) yearParam = 'III';
      if (yearNo == 4) yearParam = 'IV';
      final deptId = _selectedDept['id'];

      String url =
          '${ApiConfig.baseUrl}/api/v1/my-activities/$activityId/students?year=$yearParam&departmentId=$deptId';
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
      setState(() {
        _isLoadingStudents = false;
      });
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

    setState(() {
      _isAwarding = true;
    });

    try {
      final body = {
        'studentIds': _selectedStudentIds.toList(),
        'activityId': _selectedEvent['activityId'],
        'assignmentId': _assignmentId ?? _selectedEvent['activityId'],
        'remarks': _remarksController.text.trim(),
      };

      debugPrint(
        'FLUTTER DEBUG: Selected studentId: ${_selectedStudentIds.toList()}',
      );

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
          setState(() {
            _currentFlowStep = 1;
            _selectedStudentIds.clear();
          });
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
      setState(() {
        _isAwarding = false;
      });
    }
  }

  void _onCategorySelected(String categoryKey) {
    setState(() {
      _selectedCategory = categoryKey;
      _eventSearchQuery = '';
      _currentFlowStep = 1;
    });
  }

  void _onEventSelected(dynamic event) {
    final type = event['type']?.toString().toLowerCase() ?? 'individual';
    if (type.contains('group')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupActivityYearPage(activityId: event['activityId']),
        ),
      );
      return;
    }

    setState(() {
      _selectedEvent = event;
      _selectedYear = null;
      _selectedDept = null;
      _selectedSection = null;
      _currentFlowStep = 2;
    });
    _fetchYearsForEvent(event);
  }

  List<dynamic> get _filteredEvents {
    if (_selectedCategory == null) return [];
    final list = _myActivities.where((a) {
      final cat = a['xpCategory']?.toString().toUpperCase() ?? '';
      return cat == _selectedCategory;
    }).toList();
    if (_eventSearchQuery.trim().isEmpty) return list;
    final query = _eventSearchQuery.toLowerCase();
    return list.where((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      final desc = (a['description'] as String? ?? '').toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  void _onYearSelected(dynamic year) {
    setState(() {
      _selectedYear = year;
      _deptSearchQuery = '';
      _currentFlowStep = 3;
    });
    _fetchDeptsForYear(year);
  }

  void _onDeptSelected(dynamic dept) async {
    setState(() {
      _selectedDept = dept;
      _selectedSection = null;
    });
    await _fetchSectionsForDept(dept);
    if (_hasSections) {
      setState(() {
        _currentFlowStep = 4;
      });
    } else {
      setState(() {
        _currentFlowStep = 5;
      });
      _fetchStudentsFinal(null);
    }
  }

  void _onSectionSelected(dynamic sec) {
    setState(() {
      _selectedSection = sec['sectionName'] ?? sec['name'];
      _currentFlowStep = 5;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentFlowStep == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_currentFlowStep > 0) {
          setState(() {
            if (_currentFlowStep == 5) {
              if (_hasSections) {
                _currentFlowStep = 4;
              } else {
                _currentFlowStep = 3;
              }
            } else {
              _currentFlowStep--;
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentFlowStep == 0
                ? 'Performance Activities'
                : (_currentFlowStep == 1
                      ? "${_categoryStyles[_selectedCategory]?['label']} Events"
                      : (_currentFlowStep == 2
                            ? 'Select Year'
                            : (_currentFlowStep == 3
                                  ? 'Select Department'
                                  : (_currentFlowStep == 4
                                        ? 'Select Section'
                                        : "${_selectedEvent?['name']}")))),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: _currentFlowStep > 0
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_currentFlowStep == 5) {
                        if (_hasSections) {
                          _currentFlowStep = 4;
                        } else {
                          _currentFlowStep = 3;
                        }
                      } else {
                        _currentFlowStep--;
                      }
                    });
                  },
                )
              : null,
          actions: [
            if (widget.subRoles.any(
                  (r) =>
                      r.toUpperCase() == 'CC' ||
                      r.toUpperCase() == 'CLASS_COORDINATOR' ||
                      r.toUpperCase() == 'ROLE_CC',
                ) &&
                _currentFlowStep == 0)
              Row(
                children: [
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _pendingBadgeRequests > 0,
                      label: Text(
                        _pendingBadgeRequests.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    tooltip: 'Badge Requests',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CCBadgeRequestsPage(),
                        ),
                      ).then((_) => _fetchPendingBadges());
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Students Directory',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentsTab(subRoles: widget.subRoles),
                        ),
                      );
                    },
                  ),
                ],
              ),
            Consumer<PenaltyProvider>(
              builder: (context, penaltyProvider, _) {
                final count = penaltyProvider.pendingCount > 0
                    ? penaltyProvider.pendingCount
                    : _pendingPenaltyRequests;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text(
                      count.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.gavel_rounded, color: Colors.white),
                  ),
                  tooltip: 'Penalty Requests',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => spdms_penalty.PenaltyRequestsPage(
                          isCC: widget.subRoles.any(
                            (r) =>
                                r.toUpperCase() == 'CC' ||
                                r.toUpperCase() == 'CLASS_COORDINATOR' ||
                                r.toUpperCase() == 'ROLE_CC',
                          ),
                        ),
                      ),
                    ).then((_) => _fetchPendingBadges());
                  },
                );
              },
            ),
          ],
        ),
        body: _buildAwardXpTabBody(),
      ),
    );
  }

  Widget _buildAwardXpTabBody() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentFlowStep) {
      case 0:
        return _buildCategoryGrid();
      case 1:
        return _buildEventList();
      case 2:
        return _buildYearSelection();
      case 3:
        return _buildDeptSelection();
      case 4:
        return _buildSectionSelection();
      case 5:
        return _buildStudentListAndAward();
      default:
        return _buildCategoryGrid();
    }
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select XP Category to view predefined Events',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _categoryStyles.keys.length,
              itemBuilder: (context, index) {
                final key = _categoryStyles.keys.elementAt(index);
                final style = _categoryStyles[key]!;
                final color = style['color'] as Color;
                final icon = style['icon'] as IconData;
                final label = style['label'] as String;

                final count = _myActivities
                    .where(
                      (a) =>
                          (a['xpCategory']?.toString().toUpperCase() ?? '') ==
                          key,
                    )
                    .length;

                return InkWell(
                  onTap: () => _onCategorySelected(key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count configured events',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
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

  Widget _buildEventList() {
    final list = _filteredEvents;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Predefined Event (${list.length} available)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _eventSearchQuery,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search Event…',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _eventSearchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Events found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final String name = item['name'] ?? '';
                      final String desc =
                          item['description'] ?? 'No description';
                      final String xp = item['xp'] ?? '0';
                      final String xpType = item['xpType'] ?? 'Reward';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              desc,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (xpType == 'Penalty'
                                          ? Colors.red
                                          : const Color(0xFF11998e))
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$xp XP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: xpType == 'Penalty'
                                    ? Colors.red
                                    : const Color(0xFF11998e),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: () => _onEventSelected(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelection() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    final years = _availableYearsList;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Year',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: years.isEmpty
                ? const Center(child: Text('No years found'))
                : ListView.builder(
                    itemCount: years.length,
                    itemBuilder: (ctx, idx) {
                      final year = years[idx];
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
                                  backgroundColor: Colors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
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
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _deptSearchQuery,
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
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
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
                ? const Center(child: Text('No departments found'))
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
                                  backgroundColor: Colors.indigo.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.business,
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
                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
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
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    final String xpValue = _selectedEvent?['xp'] ?? '0';
    final String xpType = _selectedEvent?['xpType'] ?? 'Reward';
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
                      color: (xpType == 'Penalty' ? Colors.red : Colors.orange)
                          .shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (xpType == 'Penalty' ? Colors.red : Colors.orange)
                                .shade200,
                      ),
                    ),
                    child: Text(
                      "${xpType == 'Penalty' ? 'Penalty' : 'Award'}: $xpValue XP",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            (xpType == 'Penalty' ? Colors.red : Colors.orange)
                                .shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _studentSearchQuery,
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
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
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
                activeColor: xpType == 'Penalty'
                    ? Colors.red
                    : const Color(0xFF11998e),
                onChanged: (val) {
                  setState(() {
                    _selectAll = val ?? false;
                    if (_selectAll) {
                      _selectedStudentIds.addAll(
                        showStudents.map((s) => s['id'] as int),
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
        const Divider(height: 1),
        Expanded(
          child: showStudents.isEmpty
              ? const Center(child: Text('No students match search criteria'))
              : ListView.builder(
                  itemCount: showStudents.length,
                  itemBuilder: (context, index) {
                    final student = showStudents[index];
                    final int regNo = student['id'] as int;
                    final String name = student['fullName'] ?? '';
                    final String studentIdStr = student['regNo'] ?? '';
                    final isChecked = _selectedStudentIds.contains(regNo);

                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: xpType == 'Penalty'
                          ? Colors.red
                          : const Color(0xFF11998e),
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
                            _selectedStudentIds.add(regNo);
                          } else {
                            _selectedStudentIds.remove(regNo);
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
                color: Colors.black.withValues(alpha: 0.05),
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
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: xpType == 'Penalty'
                        ? Colors.red
                        : const Color(0xFF11998e),
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
                          "${xpType == 'Penalty' ? 'Deduct XP from' : 'Award XP to'} ${_selectedStudentIds.length} Students",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
