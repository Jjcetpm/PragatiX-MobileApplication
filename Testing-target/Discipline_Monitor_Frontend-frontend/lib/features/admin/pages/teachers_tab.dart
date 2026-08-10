import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';

Future<List<dynamic>> _apiGetDepartments(String token) async {
  try {
    return await getIt<AdminRepository>().getDepartments();
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

  // Add/Edit Dialog controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
    final depts = await getIt<AdminRepository>().getDepartments();
    if (!mounted) return;
    final roles = await getIt<AdminRepository>().getRoles();
    if (!mounted) return;
    final subjects = await getIt<AdminRepository>().getSubjects();
    if (!mounted) return;
    final secs = await getIt<AdminRepository>().getSections();
    setState(() {
      departments = depts;
      availableRoles = roles;
      subjectsList = subjects;
      sections = secs;
      if (departments.isNotEmpty) {
        selectedDeptId = departments.first['id'];
      }
    });
  }

  Future<void> _fetchTeachers() async {
    try {
      final allUsers = await getIt<AdminRepository>().getUsers();
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
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
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
        'username': usernameController.text.trim(),
        'password': passwordController.text,
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
    usernameController.clear();
    passwordController.clear();
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

  void _showAddTeacherDialog() {
    _clearControllers();
    lastFetchedDeptId = null;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (lastFetchedDeptId != selectedDeptId) {
              Future.microtask(
                () => _fetchSectionsForDept(selectedDeptId, setDialogState),
              );
            }
            return AlertDialog(
              title: const Text(
                'Add New Staff / User',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                      ),
                    ),
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
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                      ),
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
                      items: departments.where((d) => d['id'] != null).map((d) {
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
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDeptId = value;
                          selectedSectionId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMainRole,
                      decoration: const InputDecoration(
                        labelText: 'System Role *',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ROLE_TEACHER',
                          child: Text('Teacher'),
                        ),
                        DropdownMenuItem(
                          value: 'ROLE_TRANSPORT',
                          child: Text('Transport'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMainRole = value ?? 'ROLE_TEACHER';
                        });
                      },
                    ),
                    if (selectedMainRole == 'ROLE_TEACHER') ...[
                      const SizedBox(height: 15),
                      const Text(
                        'Teacher Sub-Roles:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'HOD',
                        'CC',
                        'Discipline Commitee',
                        'Lab instructor',
                        'PET',
                      ].map((subRole) {
                        return CheckboxListTile(
                          title: Text(subRole),
                          value: selectedSubRoles.contains(subRole),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedSubRoles.add(subRole);
                              } else {
                                selectedSubRoles.remove(subRole);
                                if (subRole == 'CC') {
                                  selectedYear = null;
                                  selectedSectionId = null;
                                }
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

                            return DropdownButtonFormField<int?>(
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
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        'Subject Specialization:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      if (subjectsList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            "No subjects configured. Add subjects under 'Manage Subjects'.",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...subjectsList.map((subject) {
                          final String subjName = subject['name'];
                          final String subjSubrole = 'Subject: $subjName';
                          return CheckboxListTile(
                            title: Text(subjName),
                            value: selectedSubRoles.contains(subjSubrole),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedSubRoles.add(subjSubrole);
                                } else {
                                  selectedSubRoles.remove(subjSubrole);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _addTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA4335),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (lastFetchedDeptId != selectedDeptId) {
              Future.microtask(
                () => _fetchSectionsForDept(selectedDeptId, setDialogState),
              );
            }
            return AlertDialog(
              title: Text(
                "Edit User: ${teacher["username"]}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
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
                      items: departments.where((d) => d['id'] != null).map((d) {
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
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDeptId = value;
                          selectedSectionId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMainRole,
                      decoration: const InputDecoration(
                        labelText: 'System Role *',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ROLE_TEACHER',
                          child: Text('Teacher'),
                        ),
                        DropdownMenuItem(
                          value: 'ROLE_TRANSPORT',
                          child: Text('Transport'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMainRole = value ?? 'ROLE_TEACHER';
                        });
                      },
                    ),
                    if (selectedMainRole == 'ROLE_TEACHER') ...[
                      const SizedBox(height: 15),
                      const Text(
                        'Teacher Sub-Roles:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'HOD',
                        'CC',
                        'Discipline Commitee',
                        'Lab instructor',
                        'PET',
                      ].map((subRole) {
                        return CheckboxListTile(
                          title: Text(subRole),
                          value: selectedSubRoles.contains(subRole),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedSubRoles.add(subRole);
                              } else {
                                selectedSubRoles.remove(subRole);
                                if (subRole == 'CC') {
                                  selectedYear = null;
                                  selectedSectionId = null;
                                }
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

                            return DropdownButtonFormField<int?>(
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
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        'Subject Specialization:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      if (subjectsList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            "No subjects configured. Add subjects under 'Manage Subjects'.",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...subjectsList.map((subject) {
                          final String subjName = subject['name'];
                          final String subjSubrole = 'Subject: $subjName';
                          return CheckboxListTile(
                            title: Text(subjName),
                            value: selectedSubRoles.contains(subjSubrole),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedSubRoles.add(subjSubrole);
                                } else {
                                  selectedSubRoles.remove(subjSubrole);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _editTeacher(teacher['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA4335),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showManageSubjectsDialog,
                        icon: const Icon(
                          Icons.book_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Manage Subjects',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTeacherDialog,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Add Teacher',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA4335),
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
                        final String username = t['username'] ?? '';
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
                              'Username: $username\nEmail: $email\nDept: $deptName\nRole: $rolesStr$subRolesStr',
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
                                          'Are you sure you want to delete teacher $name?',
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
