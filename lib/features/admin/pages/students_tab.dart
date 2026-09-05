import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pragatix/core/config/api_config.dart';

import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/core/utils/export_utils.dart';

import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

import '../dialogs/add_student_dialog.dart';
import '../dialogs/edit_student_dialog.dart';
import '../widgets/student_filter_panel.dart';
import '../widgets/student_list.dart';
import '../widgets/student_fab.dart';
import 'package:pragatix/features/badge/pages/admin_badge_requests_page.dart';
import 'package:pragatix/features/teacher/pages/teacher_student_detail.dart';

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  List<dynamic> studentsList = [];

  List<dynamic> departments = [];

  List<dynamic> academicYears = [];

  List<dynamic> years = [];

  List<dynamic> semesters = [];

  List<dynamic> genders = [];

  List<dynamic> sections = [];

  List<dynamic> groups = [];

  List<dynamic> dialogSections = [];

  bool isLoadingSections = false;

  int? lastFetchedDeptId;

  Future<List<dynamic>> _fetchSectionsForDept(int? deptId) async {
    if (deptId == null) {
      return [];
    }
    try {
      return await getIt<AdminRepository>().getDepartmentSections(deptId);
    } catch (e) {
      debugPrint('Error fetching dialog sections: $e');
      return [];
    }
  }

  bool isLoading = true;
  bool isLoadingLookups = true;

  // Pagination & Infinite Scroll State
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 1000;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _totalStudentsCount = 0;

  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController sprNoController = TextEditingController();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController guardianNameController = TextEditingController();
  final TextEditingController guardianRelController = TextEditingController();
  final TextEditingController guardianPhoneController = TextEditingController();
  final TextEditingController guardianEmailController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedSection;

  String? filterYear;
  int? filterDeptId;
  int? filterSectionId;
  List<dynamic> filterDepartments = [];
  List<dynamic> filterSections = [];
  List<dynamic> filterYears = [];

  int _pendingBadgeRequests = 0;

  DateTime? selectedDob;
  int? selectedDeptId;

  // Batch Selection Mode State (Super Admin)
  bool _isSelectionMode = false;
  final Set<int> _selectedStudentIds = {};

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    _fetchStudents();
    _fetchPendingBadges();
    _loadAllLookups();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !isLoading) {
        _fetchNextPage();
      }
    }
  }

  Future<void> _fetchPendingBadges() async {
    try {
      final stats = await getIt<AdminRepository>().getStats();
      if (mounted) {
        setState(() {
          _pendingBadgeRequests = stats['pendingBadgeRequests'] ?? 0;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    sprNoController.dispose();
    regNoController.dispose();
    guardianNameController.dispose();
    guardianRelController.dispose();
    guardianPhoneController.dispose();
    guardianEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLookups() async {
    try {
      final repo = getIt<AdminRepository>();
      final results = await Future.wait([
        repo.getDepartments(),
        repo.getAcademicYears(),
        repo.getYears(),
        repo.getSemesters(),
        repo.getGenders(),
        repo.getSections(),
        repo.getTeams(),
        repo.getAssignedYears(),
      ]);
      if (!mounted) return;
      final mainDepartments = (results[0] as List).where((d) {
        final type = (d['departmentType'] ?? d['type'] ?? '').toString().toUpperCase();
        final name = (d['name'] ?? d['deptName'] ?? '').toString();
        if (type == 'SUB') return false;
        if (name.toLowerCase().startsWith('department of')) return false;
        return true;
      }).toList();

      setState(() {
        departments = mainDepartments;
        academicYears = results[1];
        years = results[2];
        semesters = results[3];
        genders = results[4];
        sections = results[5];
        groups = results[6];
        filterYears = results[7];
        isLoadingLookups = false;

        if (departments.isNotEmpty) selectedDeptId = departments.first['id'];
        
        filterDepartments = List.from(departments); // Default for Admin
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingLookups = false);
    }
  }

  Future<void> _fetchStudents({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() => isLoading = true);
    }
    _currentPage = 0;
    try {
      final pageResult = await getIt<AdminRepository>().getStudentsPaginated(
        page: 0,
        size: _pageSize,
        sortBy: 'fullName',
        keyword: searchQuery,
        year: filterYear,
        departmentId: filterDeptId,
        sectionId: filterSectionId,
      );
      final List<dynamic> fetchedStudents = pageResult['content'] ?? [];
      final int totalPages = pageResult['totalPages'] ?? 1;
      final int totalElements = pageResult['totalElements'] ?? fetchedStudents.length;
      final bool last = pageResult['last'] ?? true;

      debugPrint(
        'Students Directory: Loaded ${fetchedStudents.length} of total $totalElements students',
      );

      if (!mounted) return;
      setState(() {
        studentsList = fetchedStudents;
        _currentPage = 0;
        _hasMore = !last && (_currentPage + 1 < totalPages);
        _totalStudentsCount = totalElements;
        isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (!mounted) return;
      setState(() {
        studentsList = [];
        isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
        _totalStudentsCount = 0;
      });
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final pageResult = await getIt<AdminRepository>().getStudentsPaginated(
        page: nextPage,
        size: _pageSize,
        sortBy: 'fullName',
        keyword: searchQuery,
        year: filterYear,
        departmentId: filterDeptId,
        sectionId: filterSectionId,
      );
      final List<dynamic> newStudents = pageResult['content'] ?? [];
      final int totalPages = pageResult['totalPages'] ?? 1;
      final bool last = pageResult['last'] ?? true;

      if (!mounted) return;
      setState(() {
        final existingIds = studentsList.map((s) => s['id']).toSet();
        for (final s in newStudents) {
          if (!existingIds.contains(s['id'])) {
            studentsList.add(s);
            existingIds.add(s['id']);
          }
        }
        _currentPage = nextPage;
        _hasMore = !last && (_currentPage + 1 < totalPages);
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading next page of students: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  String _normalizeSectionName(String name) {
    String cleaned = name.trim().toLowerCase();

    if (cleaned.startsWith('section ')) {
      cleaned = cleaned.substring(8).trim();
    }

    return cleaned;
  }

  Future<void> _addStudent({
    required int? departmentId,
    required int? yearId,
    required int? semesterId,
    required int? genderId,
    required int? sectionId,
    required int? groupId,
    required String address,
  }) async {
    if (regNoController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Required fields cannot be empty.')),
      );

      return;
    }

    final formattedDob =
        "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}";

    final passwordDob =
        "${selectedDob!.day.toString().padLeft(2, '0')}${selectedDob!.month.toString().padLeft(2, '0')}${selectedDob!.year}";

    try {
      await getIt<AdminRepository>().addStudent({
        'regNo': regNoController.text.trim().toUpperCase(),
        'fullName': nameController.text.trim().toUpperCase(),
        'email': emailController.text.trim(),
        'password': passwordDob,
        'phone': phoneController.text.trim(),
        'sprNo': sprNoController.text.trim(),
        'dateOfBirth': formattedDob,
        'address': address,
        'departmentId': departmentId,
        'yearId': yearId,
        'semesterId': semesterId,
        'genderId': genderId,
        'sectionId': sectionId,
        'teamId': groupId,
        'active': true,
        if (guardianNameController.text.trim().isNotEmpty)
          'guardian': {
            'guardianName': guardianNameController.text.trim(),
            'relationship': guardianRelController.text.trim().isEmpty
                ? 'Guardian'
                : guardianRelController.text.trim(),
            'phoneNo': guardianPhoneController.text.trim(),
            'email': guardianEmailController.text.trim(),
          },
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearControllers();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchStudents();
    } catch (e) {
      if (!mounted) return;

      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _editStudent({
    required int id,
    required String regNo,
    required String fullName,
    required String email,
    required String phone,
    required int? genderId,
    required int? departmentId,
    required int? yearId,
    required int? semesterId,
    required int? sectionId,
    required int? groupId,
    required String sprNo,
    required DateTime? dob,
    required String address,
    required bool active,
    required String password,
  }) async {
    final studentObj = studentsList.firstWhere((s) => s['id'] == id, orElse: () => null);
    final effectiveEmail = email.isNotEmpty ? email : (studentObj?['email'] ?? '').toString().trim();
    if (fullName.isEmpty || effectiveEmail.isEmpty || regNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Required fields cannot be empty.')),
      );

      return;
    }

    try {
      final formattedDob = dob != null
          ? "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}"
          : null;
      await getIt<AdminRepository>().updateStudent(id, {
        'regNo': regNo.trim().toUpperCase(),
        'fullName': fullName.trim().toUpperCase(),
        'email': effectiveEmail,
        'phone': phone,
        'sprNo': sprNo,
        if (formattedDob != null) 'dateOfBirth': formattedDob,
        if (formattedDob != null) 'dob': formattedDob,
        'address': address,
        'departmentId': departmentId,
        'yearId': yearId,
        'semesterId': semesterId,
        'genderId': genderId,
        'sectionId': sectionId,
        'teamId': groupId,
        'active': active,
        if (password.isNotEmpty) 'password': password,
        if (guardianNameController.text.trim().isNotEmpty)
          'guardian': {
            'guardianName': guardianNameController.text.trim(),
            'relationship': guardianRelController.text.trim().isEmpty
                ? 'Guardian'
                : guardianRelController.text.trim(),
            'phoneNo': guardianPhoneController.text.trim(),
            'email': guardianEmailController.text.trim(),
          },
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearControllers();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchStudents();
    } catch (e) {
      if (!mounted) return;

      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _deleteStudent(int id) async {
    try {
      await getIt<AdminRepository>().deleteStudent(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => isLoading = true);
      _fetchStudents();
    } catch (e) {
      if (!mounted) return;

      ErrorHandler.showSnackBar(context, e);
    }
  }

  void _clearControllers() {
    regNoController.clear();

    nameController.clear();

    emailController.clear();

    phoneController.clear();
    sprNoController.clear();
    guardianNameController.clear();
    guardianRelController.clear();
    guardianPhoneController.clear();
    guardianEmailController.clear();
    selectedDob = null;
  }

  void _showAddStudentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentDialog(
        regNoController: regNoController,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        sprNoController: sprNoController,
        guardianNameController: guardianNameController,
        guardianRelController: guardianRelController,
        guardianPhoneController: guardianPhoneController,
        guardianEmailController: guardianEmailController,
        departments: departments,
        years: years,
        semesters: semesters,
        genders: genders,
        groups: groups,
        fetchSectionsForDept: (deptId) => _fetchSectionsForDept(deptId),
        clearControllers: _clearControllers,
        onAddStudent:
            ({
              required departmentId,
              required yearId,
              required semesterId,
              required genderId,
              required sectionId,
              required groupId,
              required address,
              required dob,
            }) async {
              selectedDob = dob;
              await _addStudent(
                departmentId: departmentId,
                yearId: yearId,
                semesterId: semesterId,
                genderId: genderId,
                sectionId: sectionId,
                groupId: groupId,
                address: address,
              );
            },
      ),
      ),
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudentDialog(
        student: student,
        regNoController: regNoController,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        sprNoController: sprNoController,
        guardianNameController: guardianNameController,
        guardianRelController: guardianRelController,
        guardianPhoneController: guardianPhoneController,
        guardianEmailController: guardianEmailController,
        departments: departments,
        years: years,
        semesters: semesters,
        genders: genders,
        groups: groups,
        fetchSectionsForDept: (deptId) => _fetchSectionsForDept(deptId),
        clearControllers: _clearControllers,
        onEditStudent:
            ({
              required id,
              required regNo,
              required fullName,
              required email,
              required phone,
              required genderId,
              required departmentId,
              required yearId,
              required semesterId,
              required sectionId,
              required groupId,
              required sprNo,
              required dob,
              required address,
              required active,
            }) async {
              await _editStudent(
                id: id,
                regNo: regNo,
                fullName: fullName,
                email: email,
                phone: phone,
                genderId: genderId,
                departmentId: departmentId,
                yearId: yearId,
                semesterId: semesterId,
                sectionId: sectionId,
                groupId: groupId,
                sprNo: sprNo,
                dob: dob,
                address: address,
                active: active,
                password: '',
              );
            },
      ),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedStudentIds.clear();
      }
    });
  }

  void _toggleSelectStudent(int id) {
    setState(() {
      if (_selectedStudentIds.contains(id)) {
        _selectedStudentIds.remove(id);
      } else {
        _selectedStudentIds.add(id);
      }
    });
  }

  void _selectAllFiltered() {
    final currentFilteredIds = studentsList
        .map((s) => s['id'] is int ? s['id'] as int : int.tryParse(s['id'].toString()))
        .whereType<int>()
        .toSet();

    setState(() {
      final allCurrentlySelected = currentFilteredIds.isNotEmpty &&
          currentFilteredIds.every((id) => _selectedStudentIds.contains(id));
      if (allCurrentlySelected) {
        _selectedStudentIds.removeAll(currentFilteredIds);
      } else {
        _selectedStudentIds.addAll(currentFilteredIds);
      }
    });
  }

  void _showBulkUpdateDialog() {
    if (_selectedStudentIds.isEmpty) return;

    int? targetYearId;
    String? targetYearName;
    int? targetSemesterId;
    String? targetSemesterName;
    int? targetDepartmentId;
    int? targetSectionId;
    List<dynamic> targetSections = [];
    bool isSubmittingBulk = false;
    bool isLoadingTargetSections = false;

    // Available years: only assigned years if configured, else all years
    final availableYears = filterYears.isNotEmpty ? filterYears : years;

    // Available departments: strictly standard main 9 departments
    final availableDepartments = departments.where((d) {
      final type = (d['departmentType'] ?? d['type'] ?? '').toString().toUpperCase();
      final name = (d['name'] ?? d['deptName'] ?? '').toString();
      if (type == 'SUB') return false;
      if (name.toLowerCase().startsWith('department of')) return false;
      return true;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Helper to get strictly valid 2 semesters based on targetYear
            // Year 1 -> Semesters 1, 2
            // Year 2 -> Semesters 3, 4
            // Year 3 -> Semesters 5, 6
            // Year 4 -> Semesters 7, 8
            List<dynamic> getFilteredSemesters() {
              int yNo = 0;
              if (targetYearName != null) {
                final lower = targetYearName!.toLowerCase();
                if (lower.contains('1') || lower.contains('first') || lower.contains('i')) {
                  yNo = 1;
                } else if (lower.contains('2') || lower.contains('second') || lower.contains('ii')) {
                  yNo = 2;
                } else if (lower.contains('3') || lower.contains('third') || lower.contains('iii')) {
                  yNo = 3;
                } else if (lower.contains('4') || lower.contains('fourth') || lower.contains('iv')) {
                  yNo = 4;
                }
              }
              if (yNo == 0 && targetYearId != null) {
                final matched = years.firstWhere((y) => y['id'] == targetYearId, orElse: () => null);
                if (matched != null) {
                  yNo = (matched['yearNo'] ?? 0) is int ? matched['yearNo'] : int.tryParse(matched['yearNo'].toString()) ?? 0;
                }
              }

              if (yNo == 1) {
                return semesters.where((s) => s['semesterNo'] == 1 || s['semesterNo'] == 2 || (s['semesterName'] ?? '').toString().contains('1') || (s['semesterName'] ?? '').toString().contains('2')).toList();
              } else if (yNo == 2) {
                return semesters.where((s) => s['semesterNo'] == 3 || s['semesterNo'] == 4 || (s['semesterName'] ?? '').toString().contains('3') || (s['semesterName'] ?? '').toString().contains('4')).toList();
              } else if (yNo == 3) {
                return semesters.where((s) => s['semesterNo'] == 5 || s['semesterNo'] == 6 || (s['semesterName'] ?? '').toString().contains('5') || (s['semesterName'] ?? '').toString().contains('6')).toList();
              } else if (yNo == 4) {
                return semesters.where((s) => s['semesterNo'] == 7 || s['semesterNo'] == 8 || (s['semesterName'] ?? '').toString().contains('7') || (s['semesterName'] ?? '').toString().contains('8')).toList();
              }
              return [];
            }

            final allowedSemesters = getFilteredSemesters();

            Future<void> onDepartmentOrYearChanged() async {
              if (targetDepartmentId != null) {
                setModalState(() {
                  isLoadingTargetSections = true;
                  targetSectionId = null;
                  targetSections = [];
                });
                try {
                  final secs = await getIt<AdminRepository>().getFilterSections(
                    year: targetYearName,
                    departmentId: targetDepartmentId,
                  );
                  if (modalCtx.mounted) {
                    setModalState(() {
                      targetSections = secs;
                      isLoadingTargetSections = false;
                    });
                  }
                } catch (_) {
                  if (modalCtx.mounted) {
                    setModalState(() {
                      targetSections = [];
                      isLoadingTargetSections = false;
                    });
                  }
                }
              } else {
                setModalState(() {
                  targetSectionId = null;
                  targetSections = [];
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bulk Update Students',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                '${_selectedStudentIds.length} students selected for batch update',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Target Year Dropdown
                    const Text('Target Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: targetYearId,
                          hint: const Text('Select Year (1st, 2nd, 3rd, 4th)', style: TextStyle(fontSize: 13)),
                          items: availableYears.map((y) {
                            final yId = y['id'];
                            final yName = y['yearName'] ?? y['name'] ?? 'Year ${y['yearNo'] ?? ''}';
                            return DropdownMenuItem<dynamic>(
                              value: yId,
                              child: Text(yName.toString(), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final matched = availableYears.firstWhere((y) => y['id'] == val, orElse: () => null);
                            setModalState(() {
                              targetYearId = val as int?;
                              targetYearName = matched != null ? (matched['yearName'] ?? matched['name'] ?? '').toString() : null;
                              targetSemesterId = null;
                              targetSemesterName = null;
                            });
                            onDepartmentOrYearChanged();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Semester Field (Strictly dependent on Year: Year 1->Sem 1,2; Year 2->Sem 3,4; Year 3->Sem 5,6; Year 4->Sem 7,8)
                    Row(
                      children: [
                        const Text('Target Semester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                        if (targetYearName != null) ...[
                          const SizedBox(width: 6),
                          Text('(For $targetYearName)', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: targetYearId == null ? const Color(0xFFF8FAFC) : Colors.white,
                        border: Border.all(color: targetYearId == null ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: targetSemesterId,
                          hint: Text(
                            targetYearId == null ? 'Select Year first to choose Semester' : 'Select Semester (${allowedSemesters.map((s) => s['semesterNo'] ?? s['name']).join(', ')})',
                            style: TextStyle(fontSize: 13, color: targetYearId == null ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          items: allowedSemesters.map((s) {
                            final sId = s['id'];
                            final sName = s['semesterName'] ?? s['name'] ?? 'Semester ${s['semesterNo'] ?? ''}';
                            return DropdownMenuItem<dynamic>(
                              value: sId,
                              child: Text(sName.toString(), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: targetYearId == null ? null : (val) {
                            final matched = allowedSemesters.firstWhere((s) => s['id'] == val, orElse: () => null);
                            setModalState(() {
                              targetSemesterId = val as int?;
                              targetSemesterName = matched != null ? (matched['semesterName'] ?? matched['name'] ?? '').toString() : null;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target Department Field (9 Main Departments)
                    const Text('Target Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: targetDepartmentId,
                          hint: const Text('Select Department (9 Main Departments)', style: TextStyle(fontSize: 13)),
                          items: availableDepartments.map((d) {
                            final dId = d['id'];
                            final dName = d['deptCode'] != null ? '${d['deptCode']} - ${d['name']}' : (d['name'] ?? 'Department');
                            return DropdownMenuItem<dynamic>(
                              value: dId,
                              child: Text(dName.toString(), style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              targetDepartmentId = val as int?;
                            });
                            onDepartmentOrYearChanged();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target Section Field (Cascaded from Department & Year)
                    const Text('Target Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: targetDepartmentId == null ? const Color(0xFFF8FAFC) : Colors.white,
                        border: Border.all(color: targetDepartmentId == null ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: targetSectionId,
                          hint: isLoadingTargetSections
                              ? const Row(
                                  children: [
                                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                    SizedBox(width: 8),
                                    Text('Loading sections...', style: TextStyle(fontSize: 13)),
                                  ],
                                )
                              : Text(
                                  targetDepartmentId == null
                                      ? 'Select Department first'
                                      : (targetSections.isEmpty ? 'No sections found for this department' : 'Select Section'),
                                  style: TextStyle(fontSize: 13, color: targetDepartmentId == null ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                          items: targetSections.map((sec) {
                            final secId = sec['id'];
                            final secName = sec['sectionName'] ?? sec['name'] ?? 'Section';
                            return DropdownMenuItem<dynamic>(
                              value: secId,
                              child: Text(secName.toString(), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (targetDepartmentId == null || targetSections.isEmpty) ? null : (val) {
                            setModalState(() {
                              targetSectionId = val as int?;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSubmittingBulk ? null : () => Navigator.pop(modalCtx),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSubmittingBulk || (targetYearId == null && targetSemesterId == null && targetDepartmentId == null && targetSectionId == null)
                                ? null
                                : () async {
                                    setModalState(() => isSubmittingBulk = true);
                                    try {
                                      await getIt<AdminRepository>().batchUpdateStudents(
                                        studentIds: _selectedStudentIds.toList(),
                                        yearId: targetYearId,
                                        year: targetYearName,
                                        semesterId: targetSemesterId,
                                        semester: targetSemesterName,
                                        departmentId: targetDepartmentId,
                                        sectionId: targetSectionId,
                                      );
                                      if (modalCtx.mounted) {
                                        Navigator.pop(modalCtx);
                                      }
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Successfully updated ${_selectedStudentIds.length} students!'),
                                          backgroundColor: const Color(0xFF16A34A),
                                        ),
                                      );
                                      setState(() {
                                        _selectedStudentIds.clear();
                                        _isSelectionMode = false;
                                      });
                                      _fetchStudents(isRefresh: true);
                                    } catch (e) {
                                      if (modalCtx.mounted) {
                                        setModalState(() => isSubmittingBulk = false);
                                      }
                                      if (mounted) {
                                        ErrorHandler.showSnackBar(context, e);
                                      }
                                    }
                                  },
                            child: isSubmittingBulk
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  )
                                : Text(
                                    'Apply to ${_selectedStudentIds.length} Students',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color iconColor = const Color(0xFF334155),
    Widget? badgeChild,
  }) {
    final button = Container(
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
        icon: Icon(icon, color: iconColor, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );

    if (badgeChild != null) {
      return badgeChild;
    }
    return button;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
      final roles = (user?['roles'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final subRoles = (user?['subRoles'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final canAddStudent = roles.contains('ROLE_SUPER_ADMIN') || 
                            roles.contains('ROLE_ADMIN') || 
                            roles.contains('ROLE_HOD') ||
                            subRoles.contains('HOD') ||
                            subRoles.contains('CC') ||
                            roles.contains('ROLE_CLASS_COORDINATOR');

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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        _buildHeaderActionButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Students Directory',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              !isLoading && studentsList.isNotEmpty
                                  ? 'Showing ${studentsList.length}${_totalStudentsCount > studentsList.length ? ' of $_totalStudentsCount' : ''} students'
                                  : 'Manage enrolled student records',
                              style: const TextStyle(
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
                          if (context.read<AuthProvider>().currentUser?['roles']?.contains('ROLE_SUPER_ADMIN') ?? false) ...[
                            _buildHeaderActionButton(
                              icon: _isSelectionMode ? Icons.checklist_rtl_rounded : Icons.checklist_rounded,
                              tooltip: _isSelectionMode ? 'Exit Selection Mode' : 'Batch Update Mode',
                              iconColor: _isSelectionMode ? const Color(0xFF2563EB) : const Color(0xFF475569),
                              onPressed: _toggleSelectionMode,
                            ),
                            const SizedBox(width: 6),
                            _buildHeaderActionButton(
                              icon: Icons.file_download_rounded,
                              tooltip: 'Export Excel',
                              onPressed: _exportStudentsExcel,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Badge(
                            isLabelVisible: _pendingBadgeRequests > 0,
                            label: Text(
                              _pendingBadgeRequests.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            backgroundColor: Colors.red,
                            child: _buildHeaderActionButton(
                              icon: Icons.notifications_rounded,
                              tooltip: 'Badge Requests',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminBadgeRequestsPage(),
                                  ),
                                ).then((_) => _fetchPendingBadges());
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildHeaderActionButton(
                            icon: Icons.refresh_rounded,
                            tooltip: 'Refresh',
                            onPressed: () {
                              _fetchStudents(isRefresh: true);
                              _fetchPendingBadges();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(child: PragatiXLoader())
                      : RefreshIndicator(
                          onRefresh: () => _fetchStudents(isRefresh: true),
                          color: const Color(0xFF2563EB),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Column(
                              children: [
                                StudentFilterPanel(
                                  searchController: _searchController,
                                  onSearchChanged: (value) {
                                    setState(() {
                                      searchQuery = value;
                                    });
                      },
                      onSearchSubmitted: (value) {
                        _fetchStudents();
                      },
                      isSuperAdmin: context.read<AuthProvider>().currentUser?['roles']?.contains('ROLE_SUPER_ADMIN') ?? false,
                      years: filterYears.isNotEmpty ? filterYears : years,
                      departments: filterDepartments,
                      sections: filterSections,
                      selectedYear: filterYear,
                      selectedDepartmentId: filterDeptId,
                      selectedSectionId: filterSectionId,
                      onYearChanged: (year) async {
                        setState(() {
                          filterYear = year;
                          filterSectionId = null;
                          filterSections = [];
                          filterDepartments = List.from(departments);
                        });
                        if (filterDeptId != null) {
                          try {
                            final secs = await getIt<AdminRepository>().getFilterSections(
                              year: filterYear, 
                              departmentId: filterDeptId
                            );
                            if (mounted) setState(() => filterSections = secs);
                          } catch (_) {
                            if (mounted) setState(() => filterSections = []);
                          }
                        }
                        _fetchStudents();
                      },
                      onDepartmentChanged: (deptId) async {
                        setState(() {
                          filterDeptId = deptId;
                          filterSectionId = null;
                        });
                        if (deptId != null) {
                          try {
                            final secs = await getIt<AdminRepository>().getFilterSections(
                              year: filterYear, 
                              departmentId: deptId
                            );
                            setState(() => filterSections = secs);
                          } catch (_) {
                            setState(() => filterSections = []);
                          }
                        } else {
                          setState(() => filterSections = []);
                        }
                        _fetchStudents();
                      },
                      onSectionChanged: (secId) {
                        setState(() => filterSectionId = secId);
                        _fetchStudents();
                      },
                      onReset: () {
                        setState(() {
                          filterYear = null;
                          filterDeptId = null;
                          filterSectionId = null;
                          filterDepartments = List.from(departments);
                          filterSections = [];
                          _searchController.clear();
                          searchQuery = '';
                        });
                        _fetchStudents();
                      },
                    ),
                    if (_isSelectionMode) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: studentsList.isNotEmpty &&
                                  studentsList
                                      .map((s) => s['id'] is int ? s['id'] as int : int.tryParse(s['id'].toString()))
                                      .whereType<int>()
                                      .every((id) => _selectedStudentIds.contains(id)),
                              activeColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) => _selectAllFiltered(),
                            ),
                            Expanded(
                              child: Text(
                                'Select All (${studentsList.length} Filtered)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E40AF),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedStudentIds.length} Selected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedStudentIds.isEmpty ? Colors.grey.shade400 : const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: _selectedStudentIds.isEmpty ? null : _showBulkUpdateDialog,
                              icon: const Icon(Icons.edit_note_rounded, size: 16),
                              label: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Expanded(
                      child: StudentList(
                        studentsList: studentsList,
                        searchQuery: '', // Pass empty since search is server-side now
                        scrollController: _scrollController,
                        isLoadingMore: _isLoadingMore,
                        hasMore: _hasMore,
                        genders: genders,
                        isSelectionMode: _isSelectionMode,
                        selectedIds: _selectedStudentIds,
                        onToggleSelect: _toggleSelectStudent,
                        onTap: (student) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherStudentDetail(student: student),
                            ),
                          ).then((_) => _fetchStudents(isRefresh: true));
                        },
                        onEdit: _showEditStudentDialog,
                        onDelete: _deleteStudent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
      floatingActionButton: canAddStudent ? StudentFab(onPressed: _showAddStudentSelection) : null,
    );
  }

  void _showAddStudentSelection() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Single Student'),
                subtitle: const Text('Add a student manually.'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddStudentDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Bulk Upload'),
                subtitle: const Text('Upload an Excel file with multiple students.'),
                onTap: () {
                  Navigator.pop(context);
                  _showBulkUploadDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showBulkUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bulk Upload Students'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('First, download the Excel template.'),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final response = await http.get(
                        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/bulk-upload/template'),
                        headers: {
                          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
                        },
                      );

                      if (response.statusCode == 200) {
                        await ExportUtils.saveBytesAndOpen(
                          context,
                          response.bodyBytes,
                          'SPDMS_Student_Bulk_Upload_Template.xlsx',
                          successMessage: 'Template downloaded successfully!',
                        );
                      } else {
                        if (context.mounted) {
                          String errorMsg = 'Unable to download student upload template.';
                          switch (response.statusCode) {
                            case 400:
                              errorMsg = 'Unable to generate the student upload template.';
                              break;
                            case 401:
                              errorMsg = 'Your session has expired. Please login again.';
                              break;
                            case 403:
                              errorMsg = 'You do not have permission to download this template.';
                              break;
                            case 404:
                              errorMsg = 'Student upload template endpoint was not found.';
                              break;
                            case 408:
                              errorMsg = 'Request timed out. Please try again.';
                              break;
                            case 500:
                              errorMsg = 'Server error. Please try again later.';
                              break;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error downloading template: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text('Download Excel Template', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11998e),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Fill the template and upload it.'),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _uploadBulkExcel();
                  },
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text('Upload Filled Excel', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38ef7d),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadBulkExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        setState(() => isLoading = true);
        
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/v1/students/bulk-parse'),
        );
        
        request.headers.addAll({
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        });
        
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
        
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        var parsedResponse = jsonDecode(responseBody);
        
        if (response.statusCode == 200 && parsedResponse['success'] == true) {
          List<dynamic> parsedData = parsedResponse['data'] ?? [];
          
          if (parsedData.isEmpty) {
            throw Exception('No valid student data found in the Excel file');
          }
          
          if (!mounted) return;
          _showPreviewDialog(parsedData, file.path);
        } else {
          throw Exception(parsedResponse['message'] ?? 'Failed to parse Excel file');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _showPreviewDialog(List<dynamic> parsedData, String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Preview - ${parsedData.length} Students found'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: parsedData.length,
              itemBuilder: (context, index) {
                var student = parsedData[index];
                return ListTile(
                  title: Text(student['fullName'] ?? 'Unknown'),
                  subtitle: Text('${student['regNo']} | ${student['email']}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => isLoading = false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmBulkUpload(parsedData);
              },
              child: const Text('Confirm Import'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmBulkUpload(List<dynamic> parsedData) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/bulk-import'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(parsedData),
      );

      var parsedResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && parsedResponse['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(parsedResponse['data'] ?? 'Students imported successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchStudents();
        }
      } else {
        throw Exception(parsedResponse['message'] ?? 'Failed to import students');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  Future<void> _exportStudentsExcel() async {
    setState(() => isLoading = true);
    try {
      String url = '${ApiConfig.baseUrl}/api/v1/students/export?';
      if (searchQuery.isNotEmpty) url += 'keyword=$searchQuery&';
      if (filterYear != null) url += 'year=$filterYear&';
      if (filterDeptId != null) url += 'departmentId=$filterDeptId&';
      if (filterSectionId != null) url += 'sectionId=$filterSectionId&';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      if (response.statusCode == 200) {
        await ExportUtils.saveBytesAndOpen(
          context,
          response.bodyBytes,
          'Students_Export.xlsx',
          successMessage: 'Student list exported successfully.',
        );
      } else {
        throw Exception('Export failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

}
