import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/shared/widgets/shared_student_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pragatix/features/teacher/pages/teacher_student_detail.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/string_utils.dart';

part 'students_tab_dialogs.dart';

class StudentsTab extends StatefulWidget {
  final List<String> subRoles;
  const StudentsTab({super.key, required this.subRoles});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  bool get isCc => widget.subRoles.any(
    (r) =>
        r.toUpperCase() == 'CC' ||
        r.toUpperCase() == 'CLASS_COORDINATOR' ||
        r.toUpperCase() == 'ROLE_CC',
  );
  List<dynamic> studentsList = [];
  List<dynamic> departments = [];
  List<dynamic> academicYears = [];
  List<dynamic> years = [];
  List<dynamic> semesters = [];
  List<dynamic> genders = [];
  List<dynamic> sections = [];
  List<dynamic> groups = [];
  bool isLoadingLookups = true;
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? filterYear;
  final TextEditingController filterSectionController = TextEditingController();

  // Single Student controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController sprNoController = TextEditingController();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController guardianNameCtrl = TextEditingController();
  final TextEditingController guardianRelCtrl = TextEditingController();
  final TextEditingController guardianPhoneCtrl = TextEditingController();
  final TextEditingController guardianEmailCtrl = TextEditingController();
  String? selectedGuardianRel;

  DateTime? selectedDob;
  int? selectedDeptId;

  // Student Edit controllers
  final TextEditingController editNameController = TextEditingController();
  final TextEditingController editEmailController = TextEditingController();
  final TextEditingController editPhoneController = TextEditingController();
  final TextEditingController editSprNoController = TextEditingController();
  final TextEditingController editGenderController = TextEditingController();
  final TextEditingController editSemesterController = TextEditingController();
  final TextEditingController editYearController = TextEditingController();
  int? editSelectedDeptId;
  DateTime? editSelectedDob;

  @override
  void dispose() {
    _searchController.dispose();
    filterSectionController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    sprNoController.dispose();
    regNoController.dispose();
    guardianNameCtrl.dispose();
    guardianRelCtrl.dispose();
    guardianPhoneCtrl.dispose();
    guardianEmailCtrl.dispose();
    editNameController.dispose();
    editEmailController.dispose();
    editPhoneController.dispose();
    editSprNoController.dispose();
    editGenderController.dispose();
    editSemesterController.dispose();
    editYearController.dispose();
    super.dispose();
  }

  String? ccYear;
  int? ccDeptId;
  String? ccDeptName;
  String? ccSection;
  int? ccSectionId;
  String? ccAcademicYear;

  Future<void> _fetchMeProfile() async {
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final profile = data['data'];
          setState(() {
            ccYear = profile['year']?.toString();
            ccDeptName = profile['department']?.toString();
            ccDeptId = profile['departmentId'] as int?;
            ccSection = profile['section']?.toString();
            ccSectionId = profile['sectionId'] as int?;
            ccAcademicYear = profile['academicYear']?.toString();
          });
        }
      }
    } catch (_) {}
  }
  @override
  void initState() {
    super.initState();
    final bool isHod = widget.subRoles.contains('HOD');
    if (isCc) {
      _fetchMeProfile().then((_) {
        _fetchStudents();
      });
    } else {
      isLoading = false;
    }
    _loadAllLookups();
  }

  Future<void> _loadAllLookups() async {
    try {
      final headers = {
        'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
      };
      final results = await Future.wait([
        getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments'),
          headers: headers,
        ),
        getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/academic-years'),
          headers: headers,
        ),
        getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'),
          headers: headers,
        ),
        getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/semesters'),
          headers: headers,
        ),
        getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/genders'),
          headers: headers,
        ),
        getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections'),
          headers: headers,
        ),
        getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
          headers: headers,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        departments = jsonDecode(results[0].body)['data'] ?? [];
        academicYears = jsonDecode(results[1].body)['data'] ?? [];
        years = jsonDecode(results[2].body)['data'] ?? [];
        semesters = jsonDecode(results[3].body)['data'] ?? [];
        genders = jsonDecode(results[4].body)['data'] ?? [];
        sections = jsonDecode(results[5].body)['data'] ?? [];
        groups = jsonDecode(results[6].body)['data'] ?? [];
        isLoadingLookups = false;


        if (departments.isNotEmpty) selectedDeptId = departments.first['id'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingLookups = false);
    }
  }

  int _getYearNumber(String yr) {
    final y = yr.toLowerCase();
    if (y.contains('1') || y == 'i' || y.contains('first')) return 1;
    if (y.contains('2') || y == 'ii' || y.contains('second')) return 2;
    if (y.contains('3') || y == 'iii' || y.contains('third')) return 3;
    if (y.contains('4') || y == 'iv' || y.contains('fourth')) return 4;
    return -1;
  }

  String _normalizeSectionName(String name) {
    String cleaned = name.trim().toLowerCase();
    if (cleaned.startsWith('section ')) {
      cleaned = cleaned.substring(8).trim();
    }
    return cleaned;
  }

  Future<void> _fetchStudents() async {
    final bool isHod = widget.subRoles.contains('HOD');

    if (!isHod && !isCc) {
      setState(() {
        studentsList = [];
        isLoading = false;
      });
      return;
    }

    if (isHod && (filterYear == null || filterYear!.isEmpty)) {
      setState(() {
        studentsList = [];
        isLoading = false;
      });
      return;
    }

    const String url =
        '${ApiConfig.baseUrl}/api/v1/students?page=0&size=1000&sortBy=fullName';
    debugPrint('Requested URL: $url');
    debugPrint('Request parameters: page=0, size=1000, sortBy=fullName');

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
          final rawList = data['data']['content'] as List? ?? [];
          debugPrint('Parsed students count: ${rawList.length}');
          setState(() {
            studentsList = rawList;
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }

    setState(() {
      studentsList = [];
      isLoading = false;
    });
  }

  Future<void> _searchStudents(String query) async {
    if (query.trim().isEmpty) {
      setState(() => isLoading = true);
      _fetchStudents();
      return;
    }
    setState(() => isLoading = true);
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/students/search?keyword=${Uri.encodeComponent(query.trim())}&page=0&size=1000',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final rawList = data['data']['content'] as List? ?? [];
          setState(() {
            if (isCc) {
              studentsList = rawList.where((s) {
                final sYear = s['year']?.toString().trim().toLowerCase() ?? '';
                final sDeptName =
                    s['departmentName']?.toString().trim().toLowerCase() ?? '';
                final sSection =
                    s['section']?.toString().trim().toLowerCase() ?? '';

                final targetYear = ccYear?.trim().toLowerCase() ?? '';
                final targetDeptName = ccDeptName?.trim().toLowerCase() ?? '';
                final targetSection = ccSection?.trim().toLowerCase() ?? '';

                bool yearMatches = false;
                if (targetYear.isEmpty) {
                  yearMatches = true;
                } else {
                  final targetNo = _getYearNumber(targetYear);
                  final sNo = _getYearNumber(sYear);
                  if (targetNo != -1 && sNo != -1) {
                    yearMatches = (targetNo == sNo);
                  } else {
                    yearMatches = (sYear == targetYear);
                  }
                }

                final bool deptMatches =
                    targetDeptName.isEmpty || sDeptName == targetDeptName;
                final bool sectionMatches =
                    targetSection.isEmpty || sSection == targetSection;

                return yearMatches && deptMatches && sectionMatches;
              }).toList();
            } else {
              studentsList = rawList;
            }
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback
    }
    setState(() {
      studentsList = [];
      isLoading = false;
    });
  }

  Future<void> _addSingleStudent({
    required int? departmentId,
    required int? academicYearId,
    required int? yearId,
    required int? semesterId,
    required int? genderId,
    required int? sectionId,
    required int? groupId,
    required String address,
  }) async {
    if (nameController.text.trim().isEmpty ||
        regNoController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, Reg No, Email and DOB are required.'),
        ),
      );
      return;
    }

    final formattedDob =
        "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}";

    // Generates DOB as ddMMyyyy (e.g. 15102004)
    final passwordDob =
        "${selectedDob!.day.toString().padLeft(2, '0')}${selectedDob!.month.toString().padLeft(2, '0')}${selectedDob!.year}";

    try {
      final response = await getIt<TeacherProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
        body: jsonEncode({
          'regNo': regNoController.text.trim(),
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordDob,
          'phone': phoneController.text.trim(),
          'dateOfBirth': formattedDob,
          'dob': formattedDob,
          'address': address,
          'departmentId': departmentId,
          'academicYearId': academicYearId,
          'yearId': yearId,
          'semesterId': semesterId,
          'genderId': genderId,
          'sectionId': sectionId,
          'groupId': groupId,
          'sprNo': sprNoController.text.trim(),
          'active': true,
          'guardian': {
            'guardianName': guardianNameCtrl.text.trim(),
            'relationship': selectedGuardianRel,
            'phoneNo': guardianPhoneCtrl.text.trim(),
            'email': guardianEmailCtrl.text.trim(),
          },
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 ||
          (response.statusCode == 200 && data['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearControllers();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Registration Failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _uploadBulkExcel() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) return;
      final filePath = result.files.single.path!;

      if (!mounted) return;

      setState(() => isLoading = true);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/bulk-parse'),
      );
      request.headers['Authorization'] =
          'Bearer ${context.read<AuthProvider>().token!}';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['success'] == true) {
        List<dynamic> allRows = data['data'] ?? [];
        List<dynamic> rejectedRows = allRows
            .where(
              (s) =>
                  s['errorReason'] != null &&
                  s['errorReason'].toString().isNotEmpty,
            )
            .toList();
        List<dynamic> parsedStudents = allRows
            .where(
              (s) =>
                  s['errorReason'] == null ||
                  s['errorReason'].toString().isEmpty,
            )
            .toList();

        if (rejectedRows.isNotEmpty && mounted) {
          String reasons = rejectedRows
              .map(
                (r) => '${r['fullName']} (${r['regNo']}): ${r['errorReason']}',
              )
              .join('\n\n');
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Some Rows Rejected'),
              content: SingleChildScrollView(child: Text(reasons)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        if (parsedStudents.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'No valid student records found in the Excel sheet.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // For CC: auto-inject department, year, and section into each student
        if (isCc) {
          // Resolve year ID
          int? ccYearId;
          if (ccYear != null) {
            final yMatch = years.firstWhere(
              (y) =>
                  y['yearNo']?.toString() == ccYear ||
                  "Year ${y["yearNo"]}" == ccYear,
              orElse: () => null,
            );
            if (yMatch != null) ccYearId = yMatch['id'];
          }

          // Resolve section ID
          int? ccSectionId;
          if (ccSection != null && ccSection!.isNotEmpty && ccDeptId != null) {
            final sMatch = sections.firstWhere((sec) {
              final depId = sec['department'] != null
                  ? sec['department']['id']
                  : sec['departmentId'];
              final sName = _normalizeSectionName(sec['sectionName'] ?? '');
              final targetSec = _normalizeSectionName(ccSection!);
              return depId == ccDeptId && sName == targetSec;
            }, orElse: () => null);
            if (sMatch != null) ccSectionId = sMatch['id'];
          }

          parsedStudents = parsedStudents.map((s) {
            final student = Map<String, dynamic>.from(s);
            if (ccDeptId != null) student['departmentId'] = ccDeptId;
            if (ccYearId != null) student['yearId'] = ccYearId;
            if (ccSectionId != null) student['sectionId'] = ccSectionId;
            if (ccSection != null && ccSection!.isNotEmpty)
              student['section'] = ccSection;
            return student;
          }).toList();
        }

        final bool? importCompleted = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (context) => BulkVerificationScreen(
              parsedStudents: parsedStudents,

              departments: departments,
            ),
          ),
        );

        if (importCompleted == true) {
          setState(() => isLoading = true);
          _fetchStudents();
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Failed to parse spreadsheet file.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error picking/parsing file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _clearControllers() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    sprNoController.clear();
    regNoController.clear();
    guardianNameCtrl.clear();
    guardianRelCtrl.clear();
    guardianPhoneCtrl.clear();
    guardianEmailCtrl.clear();
    selectedGuardianRel = null;
    setState(() {
      selectedDob = null;
      selectedDeptId = null;
    });
    if (departments.isNotEmpty) {
      selectedDeptId = departments.first['id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = studentsList.where((s) {
      if (searchQuery.isEmpty) return true;
      final String sId = (s['regNo'] ?? '').toString().toLowerCase();
      final String name = (s['fullName'] ?? '').toString().toLowerCase();
      final String spr = (s['sprNo'] ?? '').toString().toLowerCase();
      final String deptName = (s['departmentName'] ?? '').toString().toLowerCase();
      return sId.contains(searchQuery) ||
          name.contains(searchQuery) ||
          spr.contains(searchQuery) ||
          deptName.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Students Directory',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          if (isCc) ...[
            IconButton(
              icon: const Icon(Icons.group_add_outlined, color: Colors.white),
              tooltip: 'Manage Groups',
              onPressed: _showManageGroupsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.insights_outlined, color: Colors.white),
              tooltip: 'Report Monitor',
              onPressed: _showReportMonitorDialog,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchStudents();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF11998e)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (widget.subRoles.contains('HOD')) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter Students (HOD)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: filterYear,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Year *',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'I',
                                        child: Text('I Year'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'II',
                                        child: Text('II Year'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'III',
                                        child: Text('III Year'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'IV',
                                        child: Text('IV Year'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        filterYear = value;
                                        isLoading = true;
                                      });
                                      _fetchStudents();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: filterSectionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Section (Optional)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (value) {
                                      setState(() => isLoading = true);
                                      _fetchStudents();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by student name or reg no...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                                _fetchStudents();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF11998e), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim().toLowerCase();
                      });
                    },
                    onSubmitted: (value) {
                      _searchStudents(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? RefreshIndicator(
                            color: const Color(0xFF11998e),
                            backgroundColor: Colors.white,
                            onRefresh: () async {
                              await _fetchStudents();
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height: 350,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      searchQuery.isNotEmpty
                                          ? 'No students match "$searchQuery"'
                                          : 'No students found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF11998e),
                            backgroundColor: Colors.white,
                            onRefresh: () async {
                              await _fetchStudents();
                            },
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredStudents.length,
                              itemBuilder: (context, index) {
                                final s = filteredStudents[index];
                                final String sId = s['regNo'] ?? '';
                                final String name = s['fullName'] ?? '';
                                final String deptName =
                                    s['departmentName'] ?? 'No Department';
                                final String spr = s['sprNo'] ?? 'N/A';
                                final int score = s['score'] ?? 0;

                                final String yearStr =
                                    s['year'] != null &&
                                            s['year'].toString().isNotEmpty
                                        ? " • Year: ${s["year"]}"
                                        : '';
                                final String sectionStr =
                                    s['section'] != null &&
                                            s['section'].toString().isNotEmpty
                                        ? " • Section: ${s["section"]}"
                                        : '';

                                return SharedStudentCard(
                                  name: name,
                                  themeColor: const Color(0xFF11998e),
                                  subtitle:
                                      'Reg No: $sId • SPR: $spr$yearStr$sectionStr\nDept: $deptName',
                                  score: score,
                                  trailingContent: isCc
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _showEditStudentDialog(s),
                                              tooltip: 'Edit student',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Delete Student'),
                                                    content: Text(
                                                      'Are you sure you want to delete student $name?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(context),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                          _deleteStudent(s['id']);
                                                        },
                                                        child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              tooltip: 'Delete student',
                                            ),
                                          ],
                                        )
                                      : null,
                                  onTap: () {
                                    final mappedStudent = {
                                      'id': s['id'],
                                      'name': name,
                                      'regNo': sId,
                                      'dept': deptName,
                                      'score': score,
                                      'teamRole': s['teamRole'] ?? 'MEMBER',
                                    };
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TeacherStudentDetail(
                                          student: mappedStudent,
                                        ),
                                      ),
                                    ).then((_) {
                                      if (_searchController.text.trim().isNotEmpty) {
                                        _searchStudents(_searchController.text.trim());
                                      } else {
                                        _fetchStudents();
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: isCc
          ? FloatingActionButton.extended(
              onPressed: _showAddStudentOptions,
              backgroundColor: const Color(0xFF11998e),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Students',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

class BulkVerificationScreen extends StatefulWidget {
  final List<dynamic> parsedStudents;
  final List<dynamic> departments;

  const BulkVerificationScreen({
    super.key,
    required this.parsedStudents,

    required this.departments,
  });

  @override
  State<BulkVerificationScreen> createState() => _BulkVerificationScreenState();
}

class _BulkVerificationScreenState extends State<BulkVerificationScreen> {
  late List<Map<String, dynamic>> _students;
  late List<bool> _checkedStates;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _students = List<Map<String, dynamic>>.from(
      widget.parsedStudents.map((item) => Map<String, dynamic>.from(item)),
    );
    _checkedStates = List<bool>.filled(_students.length, true);
  }

  void _toggleCheckAll(bool val) {
    setState(() {
      for (int i = 0; i < _checkedStates.length; i++) {
        _checkedStates[i] = val;
      }
    });
  }

  Future<void> _editStudent(int index) async {
    final updatedStudent = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditStudentDialog(student: _students[index]),
    );

    if (updatedStudent != null) {
      setState(() {
        _students[index] = updatedStudent;
      });
    }
  }

  void _removeStudent(int index) {
    setState(() {
      _students.removeAt(index);
      _checkedStates.removeAt(index);
    });
  }

  Future<void> _proceedImport() async {
    final selectedStudents = <Map<String, dynamic>>[];
    for (int i = 0; i < _students.length; i++) {
      if (_checkedStates[i]) {
        selectedStudents.add(_students[i]);
      }
    }

    if (selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check at least one student to import.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isImporting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final response = await getIt<TeacherProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/bulk-import'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
        body: jsonEncode(selectedStudents),
      );

      final data = jsonDecode(response.body);

      setState(() => _isImporting = false);

      if (response.statusCode == 200 && data['success'] == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Import complete!'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to save students list.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isImporting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Network/Server error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allChecked =
        _checkedStates.isNotEmpty && _checkedStates.every((e) => e);
    final anyChecked = _checkedStates.any((e) => e);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Verify Spreadsheet Data',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
      body: _isImporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF11998e)),
                  SizedBox(height: 16),
                  Text(
                    'Saving selected students into database...',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11998e).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: allChecked,
                          tristate: anyChecked && !allChecked,
                          onChanged: (val) => _toggleCheckAll(val ?? true),
                          activeColor: const Color(0xFF11998e),
                        ),
                        Text(
                          allChecked ? 'Uncheck All' : 'Check All',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_checkedStates.where((c) => c).length} selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF11998e),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final s = _students[index];
                        final name = s['fullName'] ?? '';
                        final regNo = s['regNo'] ?? '';
                        final sprNo = s['sprNo'] ?? '';
                        final email = s['email'] ?? '';
                        final dob = s['dateOfBirth'] ?? 'N/A';
                        final dept = s['departmentName'] ?? '';
                        final academicYear = s['academicYear'] ?? '';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: _checkedStates[index]
                                  ? const Color(
                                      0xFF11998e,
                                    ).withValues(alpha: 0.4)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          elevation: _checkedStates[index] ? 3 : 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _checkedStates[index],
                                  onChanged: (val) {
                                    setState(() {
                                      _checkedStates[index] = val ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF11998e),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _checkedStates[index]
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Reg: $regNo • SPR: $sprNo'),
                                      Text(
                                        'Dept: $dept • Acad Year: $academicYear • DOB: $dob',
                                      ),
                                      Text('Email: $email'),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () => _editStudent(index),
                                      tooltip: 'Edit details',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => _removeStudent(index),
                                      tooltip: 'Delete record',
                                    ),
                                  ],
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
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isImporting
                    ? null
                    : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isImporting ? null : _proceedImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11998e),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed Import',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditStudentDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  const EditStudentDialog({super.key, required this.student});

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController regCtrl;
  late final TextEditingController sprCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController deptCtrl;
  late final TextEditingController academicYearCtrl;
  DateTime? dob;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.student['fullName'] ?? '');
    regCtrl = TextEditingController(text: widget.student['regNo'] ?? '');
    sprCtrl = TextEditingController(text: widget.student['sprNo'] ?? '');
    emailCtrl = TextEditingController(text: widget.student['email'] ?? '');
    phoneCtrl = TextEditingController(text: widget.student['phone'] ?? '');
    deptCtrl = TextEditingController(
      text: widget.student['departmentName'] ?? '',
    );
    academicYearCtrl = TextEditingController(
      text: widget.student['academicYear'] ?? '',
    );
    if (widget.student['dateOfBirth'] != null) {
      try {
        dob = DateTime.parse(widget.student['dateOfBirth']);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    regCtrl.dispose();
    sprCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    deptCtrl.dispose();
    academicYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit Student Details',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: regCtrl,
              decoration: const InputDecoration(
                labelText: 'Register No (reg_no)',
              ),
            ),
            TextField(
              controller: sprCtrl,
              decoration: const InputDecoration(labelText: 'SPR No (spr_no)'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone',
                counterText: '',
              ),
            ),
            TextField(
              controller: deptCtrl,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            TextField(
              controller: academicYearCtrl,
              decoration: const InputDecoration(
                labelText: 'Academic Year (e.g. 2024-2025)',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dob == null
                      ? 'No DOB Selected'
                      : "DOB: ${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dob ?? DateTime(2004),
                      firstDate: DateTime(1995),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        dob = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedStudent = Map<String, dynamic>.from(widget.student);
            updatedStudent['fullName'] = nameCtrl.text.trim();
            updatedStudent['regNo'] = regCtrl.text.trim();
            updatedStudent['sprNo'] = sprCtrl.text.trim();
            updatedStudent['email'] = emailCtrl.text.trim();
            updatedStudent['phone'] = phoneCtrl.text.trim();
            updatedStudent['departmentName'] = deptCtrl.text.trim();
            updatedStudent['academicYear'] = academicYearCtrl.text.trim();
            if (dob != null) {
              updatedStudent['dateOfBirth'] =
                  "${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}";
            }
            Navigator.pop(context, updatedStudent);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF11998e),
          ),
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
