import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pragatix/core/config/api_config.dart';

import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/core/utils/error_handler.dart';

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

  int _pendingBadgeRequests = 0;

  DateTime? selectedDob;
  int? selectedDeptId;

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

    required int? academicYearId,

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
        'academicYearId': academicYearId,
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

    required String fullName,

    required String email,

    required String phone,

    required int? genderId,

    required int? departmentId,

    required int? academicYearId,

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
    if (fullName.isEmpty || email.isEmpty) {
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
        'fullName': fullName.trim().toUpperCase(),
        'email': email,
        'phone': phone,
        'sprNo': sprNo,
        if (formattedDob != null) 'dateOfBirth': formattedDob,
        if (formattedDob != null) 'dob': formattedDob,
        'address': address,
        'departmentId': departmentId,
        'academicYearId': academicYearId,
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
        academicYears: academicYears,
        years: years,
        semesters: semesters,
        genders: genders,
        groups: groups,
        fetchSectionsForDept: (deptId) => _fetchSectionsForDept(deptId),
        clearControllers: _clearControllers,
        onAddStudent:
            ({
              required departmentId,
              required academicYearId,
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
                academicYearId: academicYearId,
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
        academicYears: academicYears,
        years: years,
        semesters: semesters,
        genders: genders,
        groups: groups,
        fetchSectionsForDept: (deptId) => _fetchSectionsForDept(deptId),
        clearControllers: _clearControllers,
        onEditStudent:
            ({
              required id,
              required fullName,
              required email,
              required phone,
              required genderId,
              required departmentId,
              required academicYearId,
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
                fullName: fullName,
                email: email,
                phone: phone,
                genderId: genderId,
                departmentId: departmentId,
                academicYearId: academicYearId,
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

  @override
  Widget build(BuildContext context) {
      final roles = context.read<AuthProvider>().currentUser?['roles'] ?? [];
      final subRoles = context.read<AuthProvider>().currentUser?['subRoles'] ?? [];
      final canAddStudent = roles.contains('ROLE_SUPER_ADMIN') || 
                            roles.contains('ROLE_ADMIN') || 
                            subRoles.contains('CC') ||
                            roles.contains('ROLE_CLASS_COORDINATOR');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Students Directory',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            if (!isLoading && studentsList.isNotEmpty)
              Text(
                'Showing ${studentsList.length}${_totalStudentsCount > studentsList.length ? ' of $_totalStudentsCount' : ''} students',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        
          actions: [
            if (context.read<AuthProvider>().currentUser?['roles']?.contains('ROLE_SUPER_ADMIN') ?? false)
              IconButton(
                icon: const Icon(Icons.file_download, color: Colors.white),
                tooltip: 'Export Excel',
                onPressed: _exportStudentsExcel,
              ),

          IconButton(
            icon: Badge(
              isLabelVisible: _pendingBadgeRequests > 0,
              label: Text(
                _pendingBadgeRequests.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchStudents(isRefresh: true);
              _fetchPendingBadges();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: PragatiXLoader())
          : RefreshIndicator(
              onRefresh: () => _fetchStudents(isRefresh: true),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                      years: years,
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
                    const SizedBox(height: 16),
                    Expanded(
                      child: StudentList(
                        studentsList: studentsList,
                        searchQuery: '', // Pass empty since search is server-side now
                        scrollController: _scrollController,
                        isLoadingMore: _isLoadingMore,
                        hasMore: _hasMore,
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
                        bool hasPermission = true;
                        if (Platform.isAndroid && (await Permission.storage.request().isDenied)) {
                          if (await Permission.manageExternalStorage.request().isDenied) {
                            hasPermission = false;
                          }
                        }

                        Directory? dir;
                        if (Platform.isAndroid) {
                          dir = Directory('/storage/emulated/0/Download');
                          if (!await dir.exists()) {
                            try {
                              await dir.create(recursive: true);
                            } catch (_) {
                              dir = Directory('/storage/emulated/0/Downloads');
                              if (!await dir.exists()) {
                                try {
                                  await dir.create(recursive: true);
                                } catch (_) {
                                  dir = await getExternalStorageDirectory();
                                  dir ??= await getApplicationDocumentsDirectory();
                                }
                              }
                            }
                          }
                        } else if (Platform.isIOS) {
                          dir = await getApplicationDocumentsDirectory();
                        } else {
                          dir = await getDownloadsDirectory();
                        }
                        
                        if (dir != null) {
                          String filename = 'SPDMS_Student_Bulk_Upload_Template.xlsx';
                          String filePath = '${dir.path}/$filename';
                          File file = File(filePath);
                          
                          int counter = 1;
                          while (await file.exists()) {
                            filename = 'SPDMS_Student_Bulk_Upload_Template_($counter).xlsx';
                            filePath = '${dir.path}/$filename';
                            file = File(filePath);
                            counter++;
                          }

                          await file.writeAsBytes(response.bodyBytes);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Template downloaded to Downloads folder: $filename'),
                                backgroundColor: Colors.green,
                                action: SnackBarAction(
                                  label: 'Open',
                                  textColor: Colors.white,
                                  onPressed: () => OpenFilex.open(
                                    file.path,
                                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                  ),
                                ),
                              ),
                            );
                          }
                        }
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
        bool hasPermission = true;
        if (Platform.isAndroid && (await Permission.storage.request().isDenied)) {
          if (await Permission.manageExternalStorage.request().isDenied) {
            hasPermission = false;
          }
        }

        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            try {
              await dir.create(recursive: true);
            } catch (_) {
              dir = Directory('/storage/emulated/0/Downloads');
              if (!await dir.exists()) {
                try {
                  await dir.create(recursive: true);
                } catch (_) {
                  dir = await getExternalStorageDirectory();
                  dir ??= await getApplicationDocumentsDirectory();
                }
              }
            }
          }
        } else if (Platform.isIOS) {
          dir = await getApplicationDocumentsDirectory();
        } else {
          dir = await getDownloadsDirectory();
        }
        
        if (dir != null) {
          String filename = 'Students_Export.xlsx';
          String filePath = '${dir.path}/$filename';
          File file = File(filePath);
          
          int counter = 1;
          while (await file.exists()) {
            filename = 'Students_Export_($counter).xlsx';
            filePath = '${dir.path}/$filename';
            file = File(filePath);
            counter++;
          }

          await file.writeAsBytes(response.bodyBytes);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Student list exported successfully.'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () => OpenFilex.open(
                    file.path,
                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  ),
                ),
              ),
            );
          }
        }
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
