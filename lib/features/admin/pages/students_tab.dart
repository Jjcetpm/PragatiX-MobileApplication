import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';

import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';

import '../dialogs/add_student_dialog.dart';
import '../dialogs/edit_student_dialog.dart';
import '../widgets/student_filter_panel.dart';
import '../widgets/student_list.dart';
import '../widgets/student_fab.dart';
import 'package:pragatix/features/badge/pages/admin_badge_requests_page.dart';

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
      setState(() {
        departments = results[0];
        academicYears = results[1];
        years = results[2];
        semesters = results[3];
        genders = results[4];
        sections = results[5];
        groups = results[6];
        isLoadingLookups = false;

        if (departments.isNotEmpty) selectedDeptId = departments.first['id'];
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
        'regNo': regNoController.text.trim(),
        'fullName': nameController.text.trim(),
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
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'sprNo': sprNo,
        if (formattedDob != null) 'dateOfBirth': formattedDob,
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
    showDialog(
      context: context,
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
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
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
              required password,
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
                password: password,
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchStudents(isRefresh: true),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    StudentFilterPanel(
                      searchController: _searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StudentList(
                        studentsList: studentsList,
                        searchQuery: searchQuery,
                        scrollController: _scrollController,
                        isLoadingMore: _isLoadingMore,
                        hasMore: _hasMore,
                        onEdit: _showEditStudentDialog,
                        onDelete: _deleteStudent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: StudentFab(onPressed: _showAddStudentDialog),
    );
  }
}
