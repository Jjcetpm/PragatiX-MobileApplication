
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';



Future<List<dynamic>> _apiGetDepartments(String token) async {

  try {

    final response = await null;

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      if (data['success'] == true) {

        return data['data'] ?? [];

      }

    }

  } catch (e) {

    // Fallback

  }

  return [];

}



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



  Future<void> _fetchSectionsForDept(int? deptId, void Function(void Function()) setDialogState) async {

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

      final response = await null;

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data['success'] == true) {

          final List<dynamic> list = data['data'] ?? [];

          setDialogState(() {

            dialogSections = list;

          });

        }

      }

    } catch (e) {

      print('Error fetching dialog sections: $e');

    } finally {

      setDialogState(() {

        isLoadingSections = false;

      });

    }

  }



  bool isLoading = true;

  bool isLoadingLookups = true;

  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();



  // Controllers

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController sprNoController = TextEditingController();

  final TextEditingController regNoController = TextEditingController();

  DateTime? selectedDob;

  int? selectedDeptId;



  @override

  void initState() {

    super.initState();

    _fetchStudents();

    _loadAllLookups();

  }



  @override

  void dispose() {

    _searchController.dispose();

    nameController.dispose();

    emailController.dispose();

    phoneController.dispose();

    sprNoController.dispose();

    regNoController.dispose();

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



  Future<void> _fetchStudents() async {
    try {
      final fetchedStudents = await getIt<AdminRepository>().getStudents();
      if (!mounted) return;
      setState(() {
        studentsList = fetchedStudents;
        isLoading = false;
      });
    } catch (e) {
      // Fallback
      if (!mounted) return;
      setState(() {
        studentsList = [];
        isLoading = false;
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



    final formattedDob = "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}";

    final passwordDob = "${selectedDob!.day.toString().padLeft(2, '0')}${selectedDob!.month.toString().padLeft(2, '0')}${selectedDob!.year}";



    try {

      final response = await null;



      if (!mounted) return;

      final data = jsonDecode(response.body);



      if (response.statusCode == 201 || (response.statusCode == 200 && data['success'] == true)) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Student created successfully!'), backgroundColor: Colors.green),

        );

        _clearControllers();

        Navigator.pop(context);

        setState(() => isLoading = true);

        _fetchStudents();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(data['message'] ?? 'Failed to create student'), backgroundColor: Colors.redAccent),

        );

      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.redAccent),

      );

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

      final response = await null;



      if (!mounted) return;

      final data = jsonDecode(response.body);



      if (response.statusCode == 200 && data['success'] == true) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Student details updated successfully!'), backgroundColor: Colors.green),

        );

        _clearControllers();

        Navigator.pop(context);

        setState(() => isLoading = true);

        _fetchStudents();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(data['message'] ?? 'Failed to update student'), backgroundColor: Colors.redAccent),

        );

      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.redAccent),

      );

    }

  }



  Future<void> _deleteStudent(int id) async {

    try {

      final response = await null;



      if (!mounted) return;

      if (response.statusCode == 200) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Student deleted successfully'), backgroundColor: Colors.green),

        );

        setState(() => isLoading = true);

        _fetchStudents();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Delete failed on server'), backgroundColor: Colors.redAccent),

        );

      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.redAccent),

      );

    }

  }



  void _clearControllers() {

    regNoController.clear();

    nameController.clear();

    emailController.clear();

    phoneController.clear();

    sprNoController.clear();

    selectedDob = null;

  }



  void _showAddStudentDialog() {

    _clearControllers();

    lastFetchedDeptId = null;

    int? selectedDeptId = departments.isNotEmpty ? departments.first['id'] : null;

    int? selectedAcademicYearId = academicYears.isNotEmpty ? academicYears.first['id'] : null;

    int? selectedYearId = years.isNotEmpty ? years.first['id'] : null;

    int? selectedSemesterId = semesters.isNotEmpty ? semesters.first['id'] : null;

    int? selectedGenderId = genders.isNotEmpty ? genders.first['id'] : null;

    int? selectedSectionId;

    int? selectedGroupId;

    final TextEditingController addressController = TextEditingController();



    showDialog(

      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (context, setDialogState) {

            if (lastFetchedDeptId != selectedDeptId) {

              Future.microtask(() => _fetchSectionsForDept(selectedDeptId, setDialogState));

            }

            final filteredSections = dialogSections;

            if (selectedSectionId != null && !filteredSections.any((sec) => sec['id'] == selectedSectionId)) {

              selectedSectionId = null;

            }



            return AlertDialog(

              title: const Text('Register New Student', style: TextStyle(fontWeight: FontWeight.bold)),

              content: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    TextField(controller: regNoController, decoration: const InputDecoration(labelText: 'Student ID *')),

                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name *')),

                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email *')),

                    TextField(

                      controller: phoneController,

                      keyboardType: TextInputType.phone,

                      maxLength: 10,

                      decoration: const InputDecoration(

                        labelText: 'Phone',

                        counterText: '',

                      ),

                    ),

                    TextField(controller: sprNoController, decoration: const InputDecoration(labelText: 'SPR No')),

                    TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),

                    const SizedBox(height: 12),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [

                        Text(

                          selectedDob == null

                              ? 'Select Date of Birth *'

                              : "DOB: ${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}",

                          style: TextStyle(fontWeight: FontWeight.bold, color: selectedDob == null ? Colors.redAccent : Colors.black87),

                        ),

                        TextButton.icon(

                          onPressed: () async {

                            final picked = await showDatePicker(

                              context: context,

                              initialDate: DateTime(2004),

                              firstDate: DateTime(1995),

                              lastDate: DateTime.now(),

                            );

                            if (picked != null) {

                              setDialogState(() {

                                selectedDob = picked;

                              });

                            }

                          },

                          icon: const Icon(Icons.calendar_month),

                          label: const Text('Pick'),

                        )

                      ],

                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<int>(

                      initialValue: selectedDeptId,

                      decoration: const InputDecoration(labelText: 'Department *'),

                      items: departments.map((d) {

                        return DropdownMenuItem<int>(

                          value: d['id'],

                          child: Text(d['code'] ?? d['name']),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedDeptId = value;

                          selectedSectionId = null;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: selectedAcademicYearId,

                      decoration: const InputDecoration(labelText: 'Academic Year *'),

                      items: academicYears.map((ay) {

                        return DropdownMenuItem<int>(

                          value: ay['id'],

                          child: Text(ay['academicYear'] ?? ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedAcademicYearId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: selectedYearId,

                      decoration: const InputDecoration(labelText: 'Year *'),

                      items: years.map((y) {

                        return DropdownMenuItem<int>(

                          value: y['id'],

                          child: Text(y['yearNo'] != null ? "Year ${y["yearNo"]}" : ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedYearId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: selectedSemesterId,

                      decoration: const InputDecoration(labelText: 'Semester *'),

                      items: semesters.map((s) {

                        return DropdownMenuItem<int>(

                          value: s['id'],

                          child: Text(s['semesterNo'] != null ? "Semester ${s["semesterNo"]}" : ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedSemesterId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: selectedGenderId,

                      decoration: const InputDecoration(labelText: 'Gender *'),

                      items: genders.map((g) {

                        return DropdownMenuItem<int>(

                          value: g['id'],

                          child: Text(g['genderName'] ?? ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedGenderId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int?>(

                      initialValue: filteredSections.any((sec) => sec['id'] == selectedSectionId) ? selectedSectionId : null,

                      decoration: const InputDecoration(labelText: 'Section (Optional)'),

                      items: [

                        DropdownMenuItem<int?>(

                          value: null,

                          child: Text(filteredSections.isNotEmpty ? 'No Section Selected (Optional)' : 'No Sections Available'),

                        ),

                        ...filteredSections.map((sec) {

                          return DropdownMenuItem<int?>(

                            value: sec['id'],

                            child: Text(sec['sectionName'] ?? ''),

                          );

                        })

                      ],

                      onChanged: (value) {

                        setDialogState(() {

                          selectedSectionId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int?>(

                      initialValue: selectedGroupId,

                      decoration: const InputDecoration(labelText: 'Group (Optional)'),

                      items: [

                        const DropdownMenuItem<int?>(

                          value: null,

                          child: Text('No Group Selected (Optional)'),

                        ),

                        ...groups.map((grp) {

                          return DropdownMenuItem<int?>(

                            value: grp['teamId'],

                            child: Text(grp['teamName'] ?? ''),

                          );

                        })

                      ],

                      onChanged: (value) {

                        setDialogState(() {

                          selectedGroupId = value;

                        });

                      },

                    ),

                  ],

                ),

              ),

              actions: [

                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

                ElevatedButton(

                  onPressed: () {

                    _addStudent(

                      departmentId: selectedDeptId,

                      academicYearId: selectedAcademicYearId,

                      yearId: selectedYearId,

                      semesterId: selectedSemesterId,

                      genderId: selectedGenderId,

                      sectionId: selectedSectionId,

                      groupId: selectedGroupId,

                      address: addressController.text.trim(),

                    );

                  },

                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),

                  child: const Text('Add Student', style: TextStyle(color: Colors.white)),

                ),

              ],

            );

          },

        );

      },

    );

  }



  void _showEditStudentDialog(Map<String, dynamic> student) {

    lastFetchedDeptId = null;

    final TextEditingController nameCtrl = TextEditingController(text: student['fullName'] ?? '');

    final TextEditingController emailCtrl = TextEditingController(text: student['email'] ?? '');

    final TextEditingController phoneCtrl = TextEditingController(text: student['phone'] ?? '');

    final TextEditingController sprCtrl = TextEditingController(text: student['sprNo'] ?? '');

    final TextEditingController addressCtrl = TextEditingController(text: student['address'] ?? '');

    final TextEditingController passwordCtrl = TextEditingController();



    DateTime? editDob;

    if (student['dateOfBirth'] != null) {

      try {

        editDob = DateTime.parse(student['dateOfBirth']);

      } catch (_) {}

    }



    int? selectedDeptId = student['departmentId'];

    if (selectedDeptId == null && student['departmentName'] != null) {

      final match = departments.firstWhere((d) => d['name'] == student['departmentName'], orElse: () => null);

      if (match != null) selectedDeptId = match['id'];

    }

    if (selectedDeptId == null && departments.isNotEmpty) {

      selectedDeptId = departments.first['id'];

    }



    int? selectedAcademicYearId = student['academicYearId'];

    if (selectedAcademicYearId == null && student['academicYear'] != null) {

      final match = academicYears.firstWhere((ay) => ay['academicYear'] == student['academicYear'], orElse: () => null);

      if (match != null) selectedAcademicYearId = match['id'];

    }

    if (selectedAcademicYearId == null && academicYears.isNotEmpty) {

      selectedAcademicYearId = academicYears.first['id'];

    }



    int? selectedYearId = student['yearId'];

    if (selectedYearId == null && student['year'] != null) {

      final match = years.firstWhere((y) => y['yearNo']?.toString() == student['year'], orElse: () => null);

      if (match != null) selectedYearId = match['id'];

    }

    if (selectedYearId == null && years.isNotEmpty) {

      selectedYearId = years.first['id'];

    }



    int? selectedSemesterId = student['semesterId'];

    if (selectedSemesterId == null && student['semester'] != null) {

      final match = semesters.firstWhere((s) => s['semesterNo']?.toString() == student['semester'], orElse: () => null);

      if (match != null) selectedSemesterId = match['id'];

    }

    if (selectedSemesterId == null && semesters.isNotEmpty) {

      selectedSemesterId = semesters.first['id'];

    }



    int? selectedGenderId = student['genderId'];

    if (selectedGenderId == null && student['gender'] != null) {

      final match = genders.firstWhere((g) => g['genderName']?.toString().toUpperCase() == student['gender'].toString().toUpperCase(), orElse: () => null);

      if (match != null) selectedGenderId = match['id'];

    }

    if (selectedGenderId == null && genders.isNotEmpty) {

      selectedGenderId = genders.first['id'];

    }



    int? selectedSectionId = student['sectionId'];

    int? selectedGroupId = student['groupId'];

    bool active = student['active'] ?? true;



    showDialog(

      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (context, setDialogState) {

            if (lastFetchedDeptId != selectedDeptId) {

              Future.microtask(() => _fetchSectionsForDept(selectedDeptId, setDialogState));

            }

            final filteredSections = dialogSections;

            if (selectedSectionId != null && !filteredSections.any((sec) => sec['id'] == selectedSectionId)) {

              selectedSectionId = null;

            }



            return AlertDialog(

              title: Text("Edit Student: ${student["studentId"]}", style: const TextStyle(fontWeight: FontWeight.bold)),

              content: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),

                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *')),

                    TextField(

                      controller: phoneCtrl,

                      keyboardType: TextInputType.phone,

                      maxLength: 10,

                      decoration: const InputDecoration(

                        labelText: 'Phone',

                        counterText: '',

                      ),

                    ),

                    TextField(controller: sprCtrl, decoration: const InputDecoration(labelText: 'SPR No')),

                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),

                    TextField(

                      controller: passwordCtrl,

                      obscureText: true,

                      decoration: const InputDecoration(labelText: 'Change Password (leave empty to keep current)'),

                    ),

                    const SizedBox(height: 10),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [

                        Text(

                          editDob == null

                              ? 'Select Date of Birth *'

                              : "DOB: ${editDob!.year}-${editDob!.month.toString().padLeft(2, '0')}-${editDob!.day.toString().padLeft(2, '0')}",

                          style: const TextStyle(fontWeight: FontWeight.bold),

                        ),

                        TextButton.icon(

                          onPressed: () async {

                            final picked = await showDatePicker(

                              context: context,

                              initialDate: editDob ?? DateTime(2004),

                              firstDate: DateTime(1995),

                              lastDate: DateTime.now(),

                            );

                            if (picked != null) {

                              setDialogState(() {

                                editDob = picked;

                              });

                            }

                          },

                          icon: const Icon(Icons.calendar_month),

                          label: const Text('Select'),

                        )

                      ],

                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<int>(

                      initialValue: departments.any((d) => d['id'] == selectedDeptId) ? selectedDeptId : null,

                      decoration: const InputDecoration(labelText: 'Department *'),

                      items: departments.map((d) {

                        return DropdownMenuItem<int>(

                          value: d['id'],

                          child: Text(d['code'] ?? d['name']),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedDeptId = value;

                          selectedSectionId = null;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: academicYears.any((ay) => ay['id'] == selectedAcademicYearId) ? selectedAcademicYearId : null,

                      decoration: const InputDecoration(labelText: 'Academic Year *'),

                      items: academicYears.map((ay) {

                        return DropdownMenuItem<int>(

                          value: ay['id'],

                          child: Text(ay['academicYear'] ?? ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedAcademicYearId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: years.any((y) => y['id'] == selectedYearId) ? selectedYearId : null,

                      decoration: const InputDecoration(labelText: 'Year *'),

                      items: years.map((y) {

                        return DropdownMenuItem<int>(

                          value: y['id'],

                          child: Text(y['yearNo'] != null ? "Year ${y["yearNo"]}" : ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedYearId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: semesters.any((s) => s['id'] == selectedSemesterId) ? selectedSemesterId : null,

                      decoration: const InputDecoration(labelText: 'Semester *'),

                      items: semesters.map((s) {

                        return DropdownMenuItem<int>(

                          value: s['id'],

                          child: Text(s['semesterNo'] != null ? "Semester ${s["semesterNo"]}" : ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedSemesterId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int>(

                      initialValue: genders.any((g) => g['id'] == selectedGenderId) ? selectedGenderId : null,

                      decoration: const InputDecoration(labelText: 'Gender *'),

                      items: genders.map((g) {

                        return DropdownMenuItem<int>(

                          value: g['id'],

                          child: Text(g['genderName'] ?? ''),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedGenderId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int?>(

                      initialValue: filteredSections.any((sec) => sec['id'] == selectedSectionId) ? selectedSectionId : null,

                      decoration: const InputDecoration(labelText: 'Section (Optional)'),

                      items: [

                        DropdownMenuItem<int?>(

                          value: null,

                          child: Text(filteredSections.isNotEmpty ? 'No Section Selected (Optional)' : 'No Sections Available'),

                        ),

                        ...filteredSections.map((sec) {

                          return DropdownMenuItem<int?>(

                            value: sec['id'],

                            child: Text(sec['sectionName'] ?? ''),

                          );

                        })

                      ],

                      onChanged: (value) {

                        setDialogState(() {

                          selectedSectionId = value;

                        });

                      },

                    ),

                    DropdownButtonFormField<int?>(

                      initialValue: groups.any((grp) => grp['teamId'] == selectedGroupId) ? selectedGroupId : null,

                      decoration: const InputDecoration(labelText: 'Group (Optional)'),

                      items: [

                        const DropdownMenuItem<int?>(

                          value: null,

                          child: Text('No Group Selected (Optional)'),

                        ),

                        ...groups.map((grp) {

                          return DropdownMenuItem<int?>(

                            value: grp['teamId'],

                            child: Text(grp['teamName'] ?? ''),

                          );

                        })

                      ],

                      onChanged: (value) {

                        setDialogState(() {

                          selectedGroupId = value;

                        });

                      },

                    ),

                    SwitchListTile(

                      title: const Text('Active'),

                      value: active,

                      onChanged: (value) {

                        setDialogState(() {

                          active = value;

                        });

                      },

                    ),

                  ],

                ),

              ),

              actions: [

                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

                ElevatedButton(

                  onPressed: () {

                    _editStudent(

                      id: student['id'],

                      fullName: nameCtrl.text.trim(),

                      email: emailCtrl.text.trim(),

                      phone: phoneCtrl.text.trim(),

                      genderId: selectedGenderId,

                      departmentId: selectedDeptId,

                      academicYearId: selectedAcademicYearId,

                      yearId: selectedYearId,

                      semesterId: selectedSemesterId,

                      sectionId: selectedSectionId,

                      groupId: selectedGroupId,

                      sprNo: sprCtrl.text.trim(),

                      dob: editDob,

                      address: addressCtrl.text.trim(),

                      active: active,

                      password: passwordCtrl.text.trim(),

                    );

                  },

                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),

                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),

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

        title: const Text('Student Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),

        backgroundColor: const Color(0xFF1E293B),

        elevation: 0,

        actions: [

          IconButton(

            icon: const Icon(Icons.refresh, color: Colors.white),

            onPressed: () {

              setState(() => isLoading = true);

              _fetchStudents();

            },

          )

        ],

      ),

      body: isLoading

          ? const Center(child: CircularProgressIndicator())

          : Padding(

              padding: const EdgeInsets.all(16.0),

              child: Column(

                children: [

                  TextField(

                    controller: _searchController,

                    decoration: InputDecoration(

                      hintText: 'Search by student ID or name...',

                      prefixIcon: const Icon(Icons.search),

                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                    ),

                    onChanged: (value) {

                      setState(() {

                        searchQuery = value.toLowerCase();

                      });

                    },

                  ),

                  const SizedBox(height: 16),

                  Expanded(

                    child: ListView.builder(

                      itemCount: studentsList.length,

                      itemBuilder: (context, index) {

                        final s = studentsList[index];

                        final String sId = s['studentId'] ?? '';

                        final String name = s['fullName'] ?? '';

                        final String deptName = s['departmentName'] ?? 'No Department';



                        if (searchQuery.isNotEmpty &&

                            !sId.toLowerCase().contains(searchQuery) &&

                            !name.toLowerCase().contains(searchQuery)) {

                          return const SizedBox.shrink();

                        }



                        return Card(

                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                          margin: const EdgeInsets.only(bottom: 12),

                          elevation: 2,

                          child: ListTile(

                            leading: CircleAvatar(

                              backgroundColor: const Color(0xFFEA4335).withOpacity(0.1),

                              child: const Icon(Icons.person, color: Color(0xFFEA4335)),

                            ),

                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),

                            subtitle: Text("$sId • $deptName\nSem: ${s["semester"] ?? '1'}${s["year"] != null && s["year"].toString().isNotEmpty ? ' • Year: ${s["year"]}' : ''}${s["section"] != null && s["section"].toString().isNotEmpty ? ' • Section: ${s["section"]}' : ''}"),

                            trailing: Row(

                              mainAxisSize: MainAxisSize.min,

                              children: [

                                IconButton(

                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),

                                  onPressed: () => _showEditStudentDialog(s),

                                ),

                                IconButton(

                                  icon: const Icon(Icons.delete_outline, color: Colors.red),

                                  onPressed: () {

                                    showDialog(

                                      context: context,

                                      builder: (context) => AlertDialog(

                                        title: const Text('Delete Student'),

                                        content: Text('Are you sure you want to delete student $name?'),

                                        actions: [

                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

                                          TextButton(

                                            onPressed: () {

                                              Navigator.pop(context);

                                              _deleteStudent(s['id']);

                                            },

                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),

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

      floatingActionButton: FloatingActionButton(

        onPressed: _showAddStudentDialog,

        backgroundColor: const Color(0xFFEA4335),

        child: const Icon(Icons.add, color: Colors.white),

      ),

    );

  }

}

