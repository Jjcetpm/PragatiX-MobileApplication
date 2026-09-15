import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/string_utils.dart';
import 'package:pragatix/core/utils/export_utils.dart';
import 'admin_teacher_detail.dart';

Future<List<dynamic>> _apiGetDepartments(String token) async {
  try {
    final list = await getIt<AdminRepository>().getDepartments(all: true);
    return list;
  } catch (e) {
    return [];
  }
}

Future<List<dynamic>> _apiGetRoles(String token) async {
  try {
    return await getIt<AdminRepository>().getRoles();
  } catch (e) {
    return [];
  }
}

Future<List<dynamic>> _apiGetSections(String token) async {
  try {
    return await getIt<AdminRepository>().getSections();
  } catch (e) {
    return [];
  }
}

Future<List<dynamic>> _apiGetSubjects(String token) async {
  try {
    return await getIt<AdminRepository>().getSubjects();
  } catch (e) {
    return [];
  }
}

class TeachersTab extends StatefulWidget {
  const TeachersTab({super.key});

  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  List<dynamic> usersList = [];
  List<dynamic> departments = [];
  List<dynamic> availableRoles = [];
  List<dynamic> subjectsList = [];
  List<dynamic> sections = [];
  bool isLoading = true;


  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  int? selectedDeptId;
  int? selectedSectionId;
  String selectedMainRole = 'ROLE_TEACHER';
  Set<String> selectedSubRoles = {};
  String? selectedYear;

  List<dynamic> dialogSections = [];
  bool isLoadingSections = false;
  int? lastFetchedDeptId;

  Future<void> _fetchSectionsForDept(
    int? deptId,
    void Function(void Function()) setDialogState,
  ) async {
    if (deptId == null) {
      setDialogState(() {
        dialogSections = [];
        lastFetchedDeptId = null;
      });
      return;
    }
    setDialogState(() {
      isLoadingSections = true;
      lastFetchedDeptId = deptId;
    });
    try {
      final list = await getIt<AdminRepository>().getDepartmentSections(deptId);
      setDialogState(() {
        dialogSections = list;
      });
    } catch (e) {
      debugPrint('Error fetching dialog sections: $e');
    } finally {
      setDialogState(() {
        isLoadingSections = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final depts = await getIt<AdminRepository>().getDepartments(all: true);
    if (!mounted) return;
    final roles = await getIt<AdminRepository>().getRoles();
    if (!mounted) return;
    final subjects = await getIt<AdminRepository>().getSubjects();
    if (!mounted) return;
    final secs = await getIt<AdminRepository>().getSections();
    setState(() {
      departments = List<dynamic>.from(depts);
      departments.sort((a, b) {
        String nameA = (a['name'] ?? a['deptName'] ?? a['code'] ?? '').toString().toLowerCase();
        String nameB = (b['name'] ?? b['deptName'] ?? b['code'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      availableRoles = roles;
      subjectsList = subjects;
      sections = secs;
      if (departments.isNotEmpty) {
        selectedDeptId = departments.first['id'];
      }
    });
  }
  int? filterDeptId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  Future<void> _fetchTeachers() async {
    try {
      final allUsers = await getIt<AdminRepository>().getTeachers(departmentId: filterDeptId, keyword: _searchQuery);
      setState(() {
        usersList = allUsers.where((u) {
          final List<dynamic> roles = (u['roles'] as List<dynamic>?) ?? [];
          final List<dynamic> subRoles = (u['subRoles'] as List<dynamic>?) ?? [];
          final roleStrings = roles.map((r) => r.toString().toUpperCase()).toList();
          final subRoleStrings = subRoles.map((s) => s.toString().toUpperCase()).toList();

          if (roleStrings.contains('ROLE_STUDENT') || roleStrings.contains('STUDENT')) return false;
          if (roleStrings.contains('ROLE_SUPER_ADMIN') || roleStrings.contains('SUPER_ADMIN')) return false;

          return roleStrings.contains('ROLE_TEACHER') ||
              roleStrings.contains('TEACHER') ||
              roleStrings.contains('ROLE_TRANSPORT') ||
              roleStrings.contains('TRANSPORT') ||
              roleStrings.contains('ROLE_HOD') ||
              roleStrings.contains('HOD') ||
              subRoleStrings.contains('HOD') ||
              subRoleStrings.contains('CC');
        }).toList();
        isLoading = false;
      });
      return;
    } catch (e) {
      debugPrint('ERROR FETCHING TEACHERS: ' + e.toString());
      if (mounted) {
        setState(() {
          usersList = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addTeacher() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Required fields cannot be empty.')),
      );
      return;
    }

    if (selectedSubRoles.contains('HOD') && selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Department for HOD.'),
        ),
      );
      return;
    }

    if (selectedSubRoles.contains('CC')) {
      if (selectedDeptId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a Department for Class Coordinator (CC).'),
          ),
        );
        return;
      }
      if (selectedYear == null || selectedYear!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a Year for Class Coordinator (CC).'),
          ),
        );
        return;
      }
    }

    try {
      await getIt<AdminRepository>().addUser({
        'password': StringUtils.generateSecurePassword(),
        'fullName': nameController.text.trim().toUpperCase(),
        'email': emailController.text.trim(),
        'departmentId': selectedDeptId,
        'roles': [selectedMainRole],
        'subRoles': selectedSubRoles.toList(),
        'sectionId': selectedSubRoles.contains('CC') ? selectedSectionId : null,
        'year': selectedSubRoles.contains('CC') ? selectedYear : null,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearControllers();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchTeachers();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _editTeacher(int id) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Required fields cannot be empty.')),
      );
      return;
    }
    if (selectedSubRoles.contains('HOD') && selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Department for HOD.'),
        ),
      );
      return;
    }
    if (selectedSubRoles.contains('CC')) {
      if (selectedDeptId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a Department for Class Coordinator (CC).'),
          ),
        );
        return;
      }
      if (selectedYear == null || selectedYear!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a Year for Class Coordinator (CC).'),
          ),
        );
        return;
      }
    }
    try {
      final roleToSend = selectedMainRole.startsWith('ROLE_') ? selectedMainRole : 'ROLE_$selectedMainRole';
      await getIt<AdminRepository>().updateUser(id, {
        'fullName': nameController.text.trim().toUpperCase(),
        'email': emailController.text.trim(),
        'departmentId': selectedDeptId,
        'roles': [roleToSend],
        'subRoles': selectedSubRoles.toList(),
        'sectionId': selectedSubRoles.contains('CC') ? selectedSectionId : null,
        'year': selectedSubRoles.contains('CC') ? selectedYear : null,
        'active': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearControllers();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchTeachers();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _deleteTeacher(int id) async {
    try {
      await getIt<AdminRepository>().deleteUser(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => isLoading = true);
      _fetchTeachers();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _addSubject(String name) async {
    if (name.trim().isEmpty) return;
    try {
      await getIt<AdminRepository>().addSubject(name.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMetadata();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _deleteSubject(int id) async {
    try {
      await getIt<AdminRepository>().deleteSubject(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMetadata();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  String _computeNextSectionLetter(List<dynamic> sections) {
    final existing = sections
        .map((s) => (s['sectionName'] ?? s['name'] ?? '').toString().trim().toUpperCase())
        .toSet();
    for (int i = 0; i < 26; i++) {
      final letter = String.fromCharCode(65 + i);
      if (!existing.contains(letter)) {
        return letter;
      }
    }
    return '';
  }

  void _showAddSectionToDeptDialog(int? deptId, void Function(void Function()) setDialogState) {
    if (deptId == null) return;
    final nextExpected = _computeNextSectionLetter(dialogSections);
    final TextEditingController sectionController = TextEditingController(text: nextExpected);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Section'),
          content: TextField(
            controller: sectionController,
            maxLength: 1,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
            ],
            decoration: InputDecoration(
              labelText: 'Section Letter',
              hintText: 'e.g. A, B',
              counterText: '',
              helperText: dialogSections.isEmpty
                  ? "First section starts from 'A'"
                  : (nextExpected.isNotEmpty
                      ? "Next in sequence: $nextExpected"
                      : "All sections (A-Z) created"),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = sectionController.text.trim().toUpperCase();
                if (val.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a section letter'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!RegExp(r'^[A-Z]$').hasMatch(val)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Section must be a single letter (e.g. A, B, C)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final existingLetters = dialogSections
                    .map((s) => (s['sectionName'] ?? s['name'] ?? '').toString().trim().toUpperCase())
                    .toSet();
                if (existingLetters.contains(val)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Section '$val' already exists in this department"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final expected = _computeNextSectionLetter(dialogSections);
                if (expected.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maximum section limit reached (A-Z)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (val != expected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        dialogSections.isEmpty
                            ? "First section must start from 'A'"
                            : "Sections must be sequential. Next section must be '$expected'",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  await getIt<AdminRepository>().addDepartmentSection(deptId, val);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Section added successfully!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                  await _fetchSectionsForDept(deptId, setDialogState);
                } catch (e) {
                  if (!mounted) return;
                  ErrorHandler.showSnackBar(context, e);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showManageSubjectsDialog() {
    final TextEditingController subjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Manage Subjects',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subjectController,
                            decoration: const InputDecoration(
                              labelText: 'New Subject Name',
                              hintText: 'e.g. Mathematics',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (subjectController.text.trim().isEmpty) return;
                            await _addSubject(subjectController.text.trim());
                            subjectController.clear();
                            if (!mounted) return;
                            final freshSubjects = await getIt<AdminRepository>()
                                .getSubjects();
                            setDialogState(() {
                              subjectsList = freshSubjects;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA4335),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Configured Subjects:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: subjectsList.isEmpty
                          ? const Center(
                              child: Text(
                                'No subjects created yet.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              itemCount: subjectsList.length,
                              itemBuilder: (context, index) {
                                final s = subjectsList[index];
                                return ListTile(
                                  title: Text(s['name'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await _deleteSubject(s['id']);
                                      if (!mounted) return;
                                      final freshSubjects =
                                          await getIt<AdminRepository>()
                                              .getSubjects();
                                      setDialogState(() {
                                        subjectsList = freshSubjects;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearControllers() {
    nameController.clear();
    emailController.clear();
    sectionController.clear();
    selectedMainRole = 'ROLE_TEACHER';
    selectedSubRoles = {};
    selectedYear = null;
    if (departments.isNotEmpty) {
      selectedDeptId = departments.first['id'];
    }
  }

  void _showAddTeacherSelection() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Teacher'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Single Teacher'),
                subtitle: const Text('Add a teacher manually.'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTeacherDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Bulk Upload'),
                subtitle: const Text('Upload an Excel file with multiple teachers.'),
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
          title: const Text('Bulk Upload Teachers'),
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
                        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/users/bulk-upload/template'),
                        headers: {
                          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
                        },
                      );
                      if (response.statusCode == 200) {
                        await ExportUtils.saveBytesAndOpen(
                          context,
                          response.bodyBytes,
                          'SPDMS_Teacher_Bulk_Upload_Template.xlsx',
                          successMessage: 'Template downloaded successfully!',
                        );
                      } else {
                        if (context.mounted) {
                          String errorMsg = 'Unable to download teacher upload template.';
                          switch (response.statusCode) {
                            case 400:
                              errorMsg = 'Unable to generate the teacher upload template.';
                              break;
                            case 401:
                              errorMsg = 'Your session has expired. Please login again.';
                              break;
                            case 403:
                              errorMsg = 'You do not have permission to download this template.';
                              break;
                            case 404:
                              errorMsg = 'Teacher upload template is not available.';
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
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ErrorHandler.showSnackBar(context, e);
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
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                  label: const Text('Choose Excel File', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

      if (result == null || result.files.single.path == null) return;
      File file = File(result.files.single.path!);

      final parseResult = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _TeacherBulkProgressDialog(
          title: 'Uploading & Validating File',
          action: (updateProgress) async {
            updateProgress(0.15, 'Reading Excel file...');
            await Future.delayed(const Duration(milliseconds: 150));
            updateProgress(0.40, 'Sending file to server for parsing...');

            var request = http.MultipartRequest(
              'POST',
              Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/users/bulk-parse'),
            );
            request.headers.addAll({
              'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
            });
            request.files.add(await http.MultipartFile.fromPath('file', file.path));

            updateProgress(0.70, 'Validating teachers and sub-roles...');
            var response = await request.send();
            var responseBody = await response.stream.bytesToString();
            var parsedResponse = jsonDecode(responseBody);
            if (http.TransitCrypto.containsEncryptedData(responseBody)) {
              parsedResponse = await http.TransitCrypto.decryptPayload(parsedResponse);
            }

            updateProgress(0.95, 'Preparing preview...');
            return parsedResponse;
          },
        ),
      );

      if (parseResult is Exception) {
        throw parseResult;
      }

      if (parseResult is Map<String, dynamic> && parseResult['success'] == true) {
        List<dynamic> parsedData = parseResult['data'] ?? [];
        String errorMsg = parseResult['error'] ?? '';

        if (parsedData.isEmpty && errorMsg.isEmpty) {
          throw Exception('No valid teacher data found in the Excel file');
        }

        if (!mounted) return;
        _showPreviewDialog(parsedData, errorMsg);
      } else if (parseResult is Map<String, dynamic>) {
        throw Exception(parseResult['message'] ?? 'Failed to parse Excel file');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _showPreviewDialog(List<dynamic> parsedData, String errorMsg) {
    List<String> rawErrors = errorMsg.isNotEmpty ? errorMsg.split(';') : [];
    List<String> errors = rawErrors
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    int validCount = parsedData.length;
    int skippedCount = errors.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA4335).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined, color: Color(0xFFEA4335), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Upload Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Metric Cards Row
                Row(
                  children: [
                    // Total Valid / Imported
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.green.shade900.withValues(alpha: 0.25) : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '$validCount',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Valid to Import',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.green.shade200 : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Skipped Count
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: skippedCount > 0
                              ? (isDark ? Colors.red.shade900.withValues(alpha: 0.25) : Colors.red.shade50)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: skippedCount > 0
                                ? Colors.red.withValues(alpha: 0.3)
                                : (isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  skippedCount > 0 ? Icons.warning_amber_rounded : Icons.remove_circle_outline,
                                  color: skippedCount > 0 ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$skippedCount',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: skippedCount > 0 ? Colors.red : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Skipped Records',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: skippedCount > 0
                                    ? (isDark ? Colors.red.shade200 : Colors.red.shade800)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Skipped Details Section
                if (skippedCount > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        'Skipped Details ($skippedCount):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: errors.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (context, index) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errors[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All $validCount records are valid and ready to be imported.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.green.shade200 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (validCount > 0)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _confirmBulkUpload(parsedData);
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                label: Text('Import $validCount Teachers', style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA4335),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmBulkUpload(List<dynamic> parsedData) async {
    try {
      final importResult = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _TeacherBulkProgressDialog(
          title: 'Importing Teachers',
          action: (updateProgress) async {
            updateProgress(0.15, 'Submitting ${parsedData.length} teachers...');
            await Future.delayed(const Duration(milliseconds: 150));
            updateProgress(0.45, 'Creating teacher accounts & assigning roles...');

            final response = await http.post(
              Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/users/bulk-import'),
              headers: {
                'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(parsedData),
            );

            updateProgress(0.85, 'Finalizing import...');
            var parsedResponse = jsonDecode(response.body);
            return parsedResponse;
          },
        ),
      );

      if (importResult is Exception) {
        throw importResult;
      }

      if (importResult is Map<String, dynamic> && importResult['success'] == true) {
        String finalMsg = importResult['message'] ?? 'Teachers imported successfully';
        String errorMsg = importResult['error'] ?? '';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$finalMsg ${errorMsg.isNotEmpty ? 'with some errors.' : ''}'),
              backgroundColor: errorMsg.isNotEmpty ? Colors.orange : Colors.green,
            ),
          );
          _fetchTeachers();
        }
      } else if (importResult is Map<String, dynamic>) {
        throw Exception(importResult['message'] ?? 'Failed to import teachers');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _showAddTeacherDialog() {
    _clearControllers();
    lastFetchedDeptId = null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              if (lastFetchedDeptId != selectedDeptId) {
                Future.microtask(
                  () => _fetchSectionsForDept(selectedDeptId, setDialogState),
                );
              }
              return Scaffold(
                appBar: AppBar(
                  title: const Text(
                    'Add New Staff / User',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email *'),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        initialValue: departments.any(
                                  (d) =>
                                      (d['id'] != null
                                          ? int.tryParse(d['id'].toString())
                                          : null) ==
                                      selectedDeptId,
                                )
                            ? selectedDeptId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No Department (Optional)', overflow: TextOverflow.ellipsis),
                          ),
                          ...departments.where((d) => d['id'] != null).map((d) {
                            final dId = int.tryParse(d['id'].toString());
                            return DropdownMenuItem<int?>(
                              value: dId,
                              child: Text(
                                (d['name'] ??
                                        d['deptName'] ??
                                        d['code'] ??
                                        d['deptCode'] ??
                                        '')
                                    .toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDeptId = value;
                            selectedSectionId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Teacher Sub-Roles:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...['Other', 'HOD', 'CC'].map((subRole) {
                        String? groupValue = 'Other';
                        if (selectedSubRoles.contains('HOD')) groupValue = 'HOD';
                        else if (selectedSubRoles.contains('CC')) groupValue = 'CC';

                        return RadioListTile<String>(
                          title: Text(subRole),
                          value: subRole,
                          groupValue: groupValue,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (String? value) {
                            setDialogState(() {
                              selectedSubRoles.remove('HOD');
                              selectedSubRoles.remove('CC');
                              if (value != 'Other' && value != null) {
                                selectedSubRoles.add(value);
                              }
                              if (value != 'CC') {
                                selectedYear = null;
                                selectedSectionId = null;
                              }
                            });
                          },
                        );
                      }),
                      if (selectedSubRoles.contains('CC')) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue:
                              ['I', 'II', 'III', 'IV'].contains(selectedYear)
                              ? selectedYear
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Coordinator Year *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'I', child: Text('I Year')),
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
                            setDialogState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setSectionState) {
                            final filteredSections = dialogSections;
                            final hasSecs = filteredSections.isNotEmpty;

                            final currentDept = departments.firstWhere((d) => d['id'] == selectedDeptId, orElse: () => {});
                            final deptName = (currentDept['name'] ?? currentDept['deptName'] ?? '').toString();
                            final deptSupportsSections = currentDept['supportsSections'] == true;

                            if (!deptSupportsSections) {
                              // Clear section since dept doesn't support it
                              if (selectedSectionId != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setDialogState(() => selectedSectionId = null);
                                });
                              }
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No sections needed — this department does not use sections.',
                                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    isExpanded: true,
                                    initialValue:
                                        filteredSections.any(
                                          (sec) => sec['id'] == selectedSectionId,
                                        )
                                        ? selectedSectionId
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Coordinator Section *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(
                                          hasSecs
                                              ? 'Select Section'
                                              : 'No Sections Available',
                                        ),
                                      ),
                                      ...filteredSections.map((sec) {
                                        return DropdownMenuItem<int?>(
                                          value: sec['id'],
                                          child: Text(
                                            "Section ${sec["sectionName"] ?? ""}",
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedSectionId = value;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                                  onPressed: () {
                                    _showAddSectionToDeptDialog(selectedDeptId, setDialogState);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _addTeacher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA4335),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Create',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ));
  }

  void _showEditTeacherDialog(Map<String, dynamic> teacher) {
    nameController.text = teacher['fullName'] ?? '';
    emailController.text = teacher['email'] ?? '';
    selectedDeptId = teacher['departmentId'] != null
        ? int.tryParse(teacher['departmentId'].toString())
        : null;

    final List<dynamic> rolesList = teacher['roles'] ?? [];
    if (rolesList.isNotEmpty) {
      final firstRole = rolesList.first.toString();
      selectedMainRole = firstRole.startsWith('ROLE_') ? firstRole : 'ROLE_$firstRole';
    } else {
      selectedMainRole = 'ROLE_TEACHER';
    }

    final List<dynamic> subRolesList = teacher['subRoles'] ?? [];
    selectedSubRoles = subRolesList.map((e) => e.toString()).toSet();
    selectedSectionId = teacher['sectionId'] != null
        ? int.tryParse(teacher['sectionId'].toString())
        : null;
    if (selectedSectionId == null &&
        teacher['section'] != null &&
        selectedDeptId != null) {
      final match = sections.firstWhere((sec) {
        final depId = sec['department'] != null
            ? sec['department']['id']
            : sec['departmentId'];
        return depId == selectedDeptId &&
            sec['sectionName']?.toString().trim().toLowerCase() ==
                teacher['section'].toString().trim().toLowerCase();
      }, orElse: () => null);
      if (match != null) {
        selectedSectionId = match['id'];
      }
    }
    final String? rawYear = teacher['year']?.toString();
    if (rawYear == '1' || rawYear == 'I') {
      selectedYear = 'I';
    } else if (rawYear == '2' || rawYear == 'II') {
      selectedYear = 'II';
    } else if (rawYear == '3' || rawYear == 'III') {
      selectedYear = 'III';
    } else if (rawYear == '4' || rawYear == 'IV') {
      selectedYear = 'IV';
    } else {
      selectedYear = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              if (lastFetchedDeptId != selectedDeptId) {
                Future.microtask(
                  () => _fetchSectionsForDept(selectedDeptId, setDialogState),
                );
              }
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    "Edit User: ${teacher["username"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email *'),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        initialValue:
                            departments.any(
                              (d) =>
                                  (d['id'] != null
                                      ? int.tryParse(d['id'].toString())
                                      : null) ==
                                  selectedDeptId,
                            )
                            ? selectedDeptId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No Department (Optional)', overflow: TextOverflow.ellipsis),
                          ),
                          ...departments.where((d) => d['id'] != null).map((d) {
                            final dId = int.tryParse(d['id'].toString());
                            return DropdownMenuItem<int?>(
                              value: dId,
                              child: Text(
                                (d['name'] ??
                                        d['deptName'] ??
                                        d['code'] ??
                                        d['deptCode'] ??
                                        '')
                                    .toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDeptId = value;
                            selectedSectionId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Teacher Sub-Roles:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...['Other', 'HOD', 'CC'].map((subRole) {
                        String? groupValue = 'Other';
                        if (selectedSubRoles.contains('HOD')) groupValue = 'HOD';
                        else if (selectedSubRoles.contains('CC')) groupValue = 'CC';

                        return RadioListTile<String>(
                          title: Text(subRole),
                          value: subRole,
                          groupValue: groupValue,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (String? value) {
                            setDialogState(() {
                              selectedSubRoles.remove('HOD');
                              selectedSubRoles.remove('CC');
                              if (value != 'Other' && value != null) {
                                selectedSubRoles.add(value);
                              }
                              if (value != 'CC') {
                                selectedYear = null;
                                selectedSectionId = null;
                              }
                            });
                          },
                        );
                      }),
                      if (selectedSubRoles.contains('CC')) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue:
                              ['I', 'II', 'III', 'IV'].contains(selectedYear)
                              ? selectedYear
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Coordinator Year *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'I', child: Text('I Year')),
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
                            setDialogState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setSectionState) {
                            final filteredSections = dialogSections;
                            final hasSecs = filteredSections.isNotEmpty;

                            final currentDept = departments.firstWhere((d) => d['id'] == selectedDeptId, orElse: () => {});
                            final deptName = (currentDept['name'] ?? currentDept['deptName'] ?? '').toString();
                            final deptSupportsSections = currentDept['supportsSections'] == true;

                            if (!deptSupportsSections) {
                              // Clear section since dept doesn't support it
                              if (selectedSectionId != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setDialogState(() => selectedSectionId = null);
                                });
                              }
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No sections needed — this department does not use sections.',
                                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    isExpanded: true,
                                    initialValue:
                                        filteredSections.any(
                                          (sec) => sec['id'] == selectedSectionId,
                                        )
                                        ? selectedSectionId
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Coordinator Section *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(
                                          hasSecs
                                              ? 'Select Section'
                                              : 'No Sections Available',
                                        ),
                                      ),
                                      ...filteredSections.map((sec) {
                                        return DropdownMenuItem<int?>(
                                          value: sec['id'],
                                          child: Text(
                                            "Section ${sec["sectionName"] ?? ""}",
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedSectionId = value;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                                  onPressed: () {
                                    _showAddSectionToDeptDialog(selectedDeptId, setDialogState);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _editTeacher(teacher['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA4335),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ));
  }


  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color iconColor = const Color(0xFF334155),
  }) {
    return Container(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherSelection,
        backgroundColor: const Color(0xFF2563EB),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
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
                          iconColor: const Color(0xFF4B5563),
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
                              'Teacher Directory',
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
                              !isLoading && usersList.isNotEmpty
                                  ? 'Showing ${usersList.length} faculty profiles'
                                  : 'Faculty profiles & department assignments',
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
                      _buildHeaderActionButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh',
                        onPressed: () {
                          setState(() => isLoading = true);
                          _fetchTeachers();
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  style: const TextStyle(color: Color(0xFF0F172A)),
                                  decoration: InputDecoration(
                                    labelText: 'Search Teacher (Name, Email, Username)',
                                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C5CE7)),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                                            tooltip: 'Clear',
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                                isLoading = true;
                                              });
                                              _fetchTeachers();
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    // Update suffix icon visibility without triggering search
                                    setState(() {});
                                  },
                                  onSubmitted: (value) {
                                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                                    setState(() {
                                      _searchQuery = value.trim();
                                      isLoading = true;
                                    });
                                    _fetchTeachers();
                                  },
                                ),
                              ),
                              if (departments.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: DropdownButtonFormField<int?>(
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Filter by Department',
                                      prefixIcon: const Icon(Icons.filter_list_rounded, color: Color(0xFF4B5563)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    value: filterDeptId,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('All Departments', overflow: TextOverflow.ellipsis),
                                      ),
                                      ...departments.where((d) => d['id'] != null).map((d) {
                                        final dId = int.tryParse(d['id'].toString());
                                        return DropdownMenuItem<int?>(
                                          value: dId,
                                          child: Text(
                                            (d['name'] ?? d['deptName'] ?? d['code'] ?? d['deptCode'] ?? '').toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        filterDeptId = value;
                                        isLoading = true;
                                      });
                                      _fetchTeachers();
                                    },
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _showAddTeacherSelection,
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        '+ Add Teacher',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        padding: const EdgeInsets.symmetric(vertical: 13),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: usersList.length,
                                  itemBuilder: (context, index) {
                                    final t = usersList[index];
                                    final String name = t['fullName'] ?? '';
                                    final String email = t['email'] ?? '';
                                    final String deptName =
                                        t['departmentName'] ?? 'No Department';
                                    final List<dynamic> rolesList = t['roles'] ?? [];
                                    final rolesStr = rolesList
                                        .map((e) => e.toString().replaceAll('ROLE_', ''))
                                        .join(', ');
                                    final List<dynamic> subRolesList = t['subRoles'] ?? [];
                                    String subRolesStr = '';
                                    if (subRolesList.isNotEmpty) {
                                      final List<String> mappedSubs = [];
                                      for (var r in subRolesList) {
                                        if (r.toString() == 'CC') {
                                          String ccDetails = 'CC';
                                          final List<String> ccParts = [];
                                          if (t['year'] != null &&
                                              t['year'].toString().isNotEmpty) {
                                            ccParts.add("Year: ${t["year"]}");
                                          }
                                          if (t['section'] != null &&
                                              t['section'].toString().isNotEmpty) {
                                            ccParts.add("Section: ${t["section"]}");
                                          }
                                          if (ccParts.isNotEmpty) {
                                            ccDetails += " (${ccParts.join(" | ")})";
                                          }
                                          mappedSubs.add(ccDetails);
                                        } else {
                                          mappedSubs.add(r.toString());
                                        }
                                      }
                                      subRolesStr =
                                          " | Sub-roles: ${mappedSubs.join(", ")}";
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF64748B).withValues(alpha: 0.06),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AdminTeacherDetail(teacher: t),
                                            ),
                                          );
                                        },
                                        leading: Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.assignment_ind_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        title: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Email: $email\nDept: $deptName\nRole: $rolesStr$subRolesStr',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Color(0xFF2563EB),
                                                size: 20,
                                              ),
                                              onPressed: () => _showEditTeacherDialog(t),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Color(0xFFEF4444),
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Delete Teacher'),
                                                    content: Text(
                                                      'Are you sure you want to move teacher $name to the Recycle Bin?',
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
                                                          _deleteTeacher(t['id']);
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherBulkProgressDialog extends StatefulWidget {
  final String title;
  final Future<dynamic> Function(void Function(double progress, String status) updateProgress) action;

  const _TeacherBulkProgressDialog({
    required this.title,
    required this.action,
  });

  @override
  State<_TeacherBulkProgressDialog> createState() => _TeacherBulkProgressDialogState();
}

class _TeacherBulkProgressDialogState extends State<_TeacherBulkProgressDialog> {
  double _progress = 0.05;
  String _status = 'Initializing...';
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startProgressAnimation();
    _executeAction();
  }

  void _startProgressAnimation() {
    _ticker = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return;
      if (_progress < 0.90) {
        setState(() {
          _progress = (_progress + 0.03).clamp(0.0, 0.92);
        });
      }
    });
  }

  Future<void> _executeAction() async {
    try {
      final result = await widget.action((progress, status) {
        if (!mounted) return;
        setState(() {
          _progress = progress.clamp(0.0, 1.0);
          _status = status;
        });
      });
      _ticker?.cancel();
      if (!mounted) return;
      setState(() {
        _progress = 1.0;
        _status = 'Completed!';
      });
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      _ticker?.cancel();
      if (!mounted) return;
      Navigator.of(context).pop(e);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFEA4335);

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Please do not close this window.',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

