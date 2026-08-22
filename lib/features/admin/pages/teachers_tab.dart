import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/string_utils.dart';

Future<List<dynamic>> _apiGetDepartments(String token) async {
  try {
    return await getIt<AdminRepository>().getDepartments(all: true);
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
      departments = depts;
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
          final List<dynamic> roles = u['roles'] ?? [];
          return roles.contains('ROLE_TEACHER') ||
              roles.contains('ROLE_TRANSPORT');
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

    if (selectedSubRoles.contains('CC') &&
        (selectedYear == null || selectedYear!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Year for Class Coordinator (CC).'),
        ),
      );
      return;
    }

    try {
      await getIt<AdminRepository>().addUser({
        'password': StringUtils.generateSecurePassword(),
        'fullName': nameController.text.trim(),
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
    if (selectedSubRoles.contains('CC') &&
        (selectedYear == null || selectedYear!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Year for Class Coordinator (CC).'),
        ),
      );
      return;
    }
    try {
      await getIt<AdminRepository>().updateUser(id, {
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'departmentId': selectedDeptId,
        'roles': [selectedMainRole],
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

  void _showAddSectionToDeptDialog(int? deptId, void Function(void Function()) setDialogState) {
    if (deptId == null) return;
    final TextEditingController sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Section'),
          content: TextField(
            controller: sectionController,
            decoration: const InputDecoration(
              labelText: 'Section Name',
              hintText: 'e.g. A, B, C',
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
                if (val.isEmpty) return;
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
                        if (Platform.isAndroid) {
                          int sdkVersion = 0;
                          try {
                            final numbers = RegExp(r'\d+')
                                .allMatches(Platform.operatingSystemVersion)
                                .map((m) => int.parse(m.group(0)!))
                                .toList();
                            if (numbers.isNotEmpty) {
                              sdkVersion = numbers.firstWhere(
                                (n) => n >= 19 && n <= 100,
                                orElse: () => numbers.first,
                              );
                            }
                          } catch (_) {}

                          PermissionStatus status;
                          if (sdkVersion >= 33) {
                            status = await Permission.manageExternalStorage.status;
                            if (!status.isGranted) {
                              status = await Permission.manageExternalStorage.request();
                            }
                          } else {
                            status = await Permission.storage.status;
                            if (!status.isGranted) {
                              status = await Permission.storage.request();
                            }
                          }

                          if (!status.isGranted) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Storage permission is required to save the template.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
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
                          String filename = 'SPDMS_Teacher_Bulk_Upload_Template.xlsx';
                          String filePath = '${dir.path}/$filename';
                          File file = File(filePath);
                          
                          int counter = 1;
                          while (await file.exists()) {
                            filename = 'SPDMS_Teacher_Bulk_Upload_Template_($counter).xlsx';
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No internet connection or something went wrong. Please check your network and try again.'),
                            backgroundColor: Colors.redAccent,
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
    final messenger = ScaffoldMessenger.of(context);
    
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
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/users/bulk-upload'),
      );
      request.headers['Authorization'] = 'Bearer ${context.read<AuthProvider>().token!}';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 400) {
        final data = jsonDecode(responseBody);
        
        List<dynamic> results = data['data'] ?? [];
        String message = data['message'] ?? (response.statusCode == 200 ? 'Upload processed' : 'Upload failed');
        
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(response.statusCode == 200 ? 'Upload Results' : 'Upload Failed'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 16),
                    if (results.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            String r = results[index].toString();
                            bool isError = !r.toLowerCase().contains("successfully");
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isError ? Icons.error : Icons.check_circle,
                                color: isError ? Colors.red : Colors.green,
                              ),
                              title: Text(r, style: TextStyle(fontSize: 12)),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchTeachers(); // Refresh list
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
                            child: Text('No Department (Optional)'),
                          ),
                          ...departments.where((d) => d['id'] != null).map((d) {
                            final dId = int.tryParse(d['id'].toString());
                            return DropdownMenuItem<int?>(
                              value: dId,
                              child: Text(
                                (d['code'] ??
                                        d['name'] ??
                                        d['deptCode'] ??
                                        d['deptName'] ??
                                        '')
                                    .toString(),
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
                      ...['None', 'HOD', 'CC'].map((subRole) {
                        String? groupValue = 'None';
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
                              if (value != 'None' && value != null) {
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
      selectedMainRole = rolesList.first.toString();
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
                            child: Text('No Department (Optional)'),
                          ),
                          ...departments.where((d) => d['id'] != null).map((d) {
                            final dId = int.tryParse(d['id'].toString());
                            return DropdownMenuItem<int?>(
                              value: dId,
                              child: Text(
                                (d['code'] ??
                                        d['name'] ??
                                        d['deptCode'] ??
                                        d['deptName'] ??
                                        '')
                                    .toString(),
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
                      ...['None', 'HOD', 'CC'].map((subRole) {
                        String? groupValue = 'None';
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
                              if (value != 'None' && value != null) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Directory',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchTeachers();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Teacher (Name, Email, Username)',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          setState(() {
                            _searchQuery = value;
                            isLoading = true;
                          });
                          _fetchTeachers();
                        });
                      },
                    ),
                  ),
                  if (departments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Filter by Department',
                          prefixIcon: const Icon(Icons.filter_list),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        value: filterDeptId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Departments'),
                          ),
                          ...departments.where((d) => d['id'] != null).map((d) {
                            final dId = int.tryParse(d['id'].toString());
                            return DropdownMenuItem<int?>(
                              value: dId,
                              child: Text(
                                (d['name'] ?? d['code'] ?? d['deptName'] ?? d['deptCode'] ?? '').toString(),
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
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Add Teacher',
                            style: TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA4335),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.assignment_ind,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Email: $email\nDept: $deptName\nRole: $rolesStr$subRolesStr',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showEditTeacherDialog(t),
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
    );
  }
}
