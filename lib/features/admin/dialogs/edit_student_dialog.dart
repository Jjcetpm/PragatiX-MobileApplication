import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pragatix/core/utils/string_utils.dart';

class EditStudentDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final TextEditingController regNoController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController sprNoController;
  final TextEditingController guardianNameController;
  final TextEditingController guardianRelController;
  final TextEditingController guardianPhoneController;
  final TextEditingController guardianEmailController;
  final List<dynamic> departments;
  final List<dynamic> years;
  final List<dynamic> semesters;
  final List<dynamic> genders;
  final List<dynamic> groups;
  final Future<List<dynamic>> Function(int?) fetchSectionsForDept;
  final Future<void> Function({
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
  })
  onEditStudent;
  final VoidCallback clearControllers;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.regNoController,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.sprNoController,
    required this.guardianNameController,
    required this.guardianRelController,
    required this.guardianPhoneController,
    required this.guardianEmailController,
    required this.departments,
    required this.years,
    required this.semesters,
    required this.genders,
    required this.groups,
    required this.fetchSectionsForDept,
    required this.onEditStudent,
    required this.clearControllers,
  });

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  int? lastFetchedDeptId;
  int? selectedDeptId;
  int? selectedYearId;
  int? selectedSemesterId;
  int? selectedGenderId;
  int? selectedSectionId;
  int? selectedGroupId;
  DateTime? selectedDob;
  final TextEditingController addressController = TextEditingController();
  List<dynamic> dialogSections = [];
  bool isActive = true;
  final List<String> guardianRelations = [
    'Father',
    'Mother',
    'Guardian',
  ];
  String? selectedGuardianRel;
  bool isFetchingSections = false;

  final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final RegExp _phoneRegex = RegExp(r'^\d{10}$');

  List<dynamic> _deduplicate(List<dynamic> list) {
    final seenIds = <int>{};
    return list.where((item) {
      if (item == null || item['id'] == null) return false;
      final id = item['id'] as int;
      if (seenIds.contains(id)) return false;
      seenIds.add(id);
      return true;
    }).toList();
  }

  List<dynamic> _getAllowedSemestersForYear(int? yearId) {
    if (yearId == null) return [];
    final matchedYear = widget.years.firstWhere(
      (y) => y['id'] == yearId,
      orElse: () => null,
    );
    if (matchedYear == null) return [];

    int yNo = 0;
    if (matchedYear['yearNo'] != null) {
      yNo = matchedYear['yearNo'] is int
          ? matchedYear['yearNo']
          : int.tryParse(matchedYear['yearNo'].toString()) ?? 0;
    }
    if (yNo == 0) {
      final name = (matchedYear['yearName'] ?? matchedYear['name'] ?? '').toString().toLowerCase();
      if (name.contains('1') || name.contains('first') || name.contains('i')) {
        yNo = 1;
      } else if (name.contains('2') || name.contains('second') || name.contains('ii')) {
        yNo = 2;
      } else if (name.contains('3') || name.contains('third') || name.contains('iii')) {
        yNo = 3;
      } else if (name.contains('4') || name.contains('fourth') || name.contains('iv')) {
        yNo = 4;
      }
    }

    final uniqueSemesters = _deduplicate(widget.semesters);
    return uniqueSemesters.where((sem) {
      int sNo = 0;
      if (sem['semesterNo'] != null) {
        sNo = sem['semesterNo'] is int
            ? sem['semesterNo']
            : int.tryParse(sem['semesterNo'].toString()) ?? 0;
      }
      if (sNo == 0) {
        final semName = (sem['semesterName'] ?? sem['name'] ?? '').toString().toLowerCase();
        final match = RegExp(r'\d+').firstMatch(semName);
        if (match != null) {
          sNo = int.tryParse(match.group(0)!) ?? 0;
        }
      }
      if (yNo == 1) return sNo == 1 || sNo == 2;
      if (yNo == 2) return sNo == 3 || sNo == 4;
      if (yNo == 3) return sNo == 5 || sNo == 6;
      if (yNo == 4) return sNo == 7 || sNo == 8;
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    widget.clearControllers();

    final s = widget.student;
    widget.regNoController.text = s['regNo'] ?? '';
    widget.nameController.text = s['fullName'] ?? '';
    widget.emailController.text = s['email'] ?? '';
    widget.phoneController.text = s['phone'] != null ? s['phone'].toString() : '';
    widget.sprNoController.text = s['sprNo'] ?? '';
    addressController.text = s['address'] ?? '';
    isActive = s['active'] ?? true;

    final g = s['guardian'];
    if (g != null) {
      widget.guardianNameController.text = g['guardianName'] ?? '';

      String relStr = g['relationship'] ?? '';
      if (relStr.isNotEmpty) {
        relStr = relStr[0].toUpperCase() + relStr.substring(1).toLowerCase();
        if (guardianRelations.contains(relStr)) {
          selectedGuardianRel = relStr;
        } else {
          selectedGuardianRel = 'Guardian';
        }
      }
      widget.guardianRelController.text = selectedGuardianRel ?? '';

      widget.guardianPhoneController.text = g['phoneNo'] != null ? g['phoneNo'].toString() : '';
      widget.guardianEmailController.text = g['email'] ?? '';
    } else {
      widget.guardianNameController.text = '';
      widget.guardianRelController.text = '';
      widget.guardianPhoneController.text = '';
      widget.guardianEmailController.text = '';
      selectedGuardianRel = null;
    }

    final rawDob = s['dob'] ?? s['dateOfBirth'];
    if (rawDob != null) {
      try {
        if (rawDob is DateTime) {
          selectedDob = rawDob;
        } else {
          selectedDob = DateTime.parse(rawDob.toString().split('T')[0]);
        }
      } catch (e) {
        selectedDob = null;
      }
    }

    final uniqueDepartments = _deduplicate(widget.departments);
    selectedDeptId = s['departmentId'];
    if (selectedDeptId != null &&
        !uniqueDepartments.any((d) => d['id'] == selectedDeptId)) {
      selectedDeptId = null;
    }

    final uniqueYears = _deduplicate(widget.years);
    selectedYearId = s['yearId'];
    if (selectedYearId != null &&
        !uniqueYears.any((y) => y['id'] == selectedYearId)) {
      selectedYearId = null;
    }

    final allowedSems = _getAllowedSemestersForYear(selectedYearId);
    selectedSemesterId = s['semesterId'];
    if (selectedSemesterId != null &&
        !allowedSems.any((sem) => sem['id'] == selectedSemesterId)) {
      selectedSemesterId = allowedSems.isNotEmpty ? allowedSems.first['id'] : null;
    }

    final uniqueGenders = _deduplicate(widget.genders);
    selectedGenderId = s['genderId'];
    if (selectedGenderId == null && s['gender'] != null) {
      final match = uniqueGenders.firstWhere(
        (g) => g['genderName'] == s['gender'],
        orElse: () => null,
      );
      if (match != null) selectedGenderId = match['id'];
    }
    if (selectedGenderId != null &&
        !uniqueGenders.any((g) => g['id'] == selectedGenderId)) {
      selectedGenderId = null;
    }

    final uniqueGroups = _deduplicate(widget.groups);
    selectedGroupId = s['teamId'];
    if (selectedGroupId != null &&
        !uniqueGroups.any((g) => g['id'] == selectedGroupId)) {
      selectedGroupId = null;
    }

    selectedSectionId = s['sectionId'];
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final regNo = widget.regNoController.text.trim();
    final name = widget.nameController.text.trim();
    final rawEmail = widget.emailController.text.trim();
    final existingEmail = (widget.student['email'] ?? '').toString().trim();
    final email = rawEmail.isNotEmpty ? rawEmail : existingEmail;
    final phone = widget.phoneController.text.trim();
    final guardianName = widget.guardianNameController.text.trim();
    final guardianRel = selectedGuardianRel ?? widget.guardianRelController.text.trim();
    final guardianPhone = widget.guardianPhoneController.text.trim();
    final guardianEmail = widget.guardianEmailController.text.trim();

    final now = DateTime.now();
    final maxAllowedDob = DateTime(now.year - 16, now.month, now.day);

    if (regNo.isEmpty) {
      _showError('Register Number is required');
      return;
    }
    if (name.isEmpty) {
      _showError('Full Name is required');
      return;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      _showError('Full Name must contain letters and spaces only.');
      return;
    }
    if (email.isEmpty) {
      _showError('Email is required');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showError('Enter a valid email address.');
      return;
    }
    if (phone.isNotEmpty && !_phoneRegex.hasMatch(phone)) {
      _showError('Phone number must contain digits only.');
      return;
    }
    final sprNo = widget.sprNoController.text.trim();
    if (sprNo.isNotEmpty && !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(sprNo)) {
      _showError('SPR Number must contain letters and numbers only (no symbols).');
      return;
    }
    if (guardianName.isNotEmpty || guardianPhone.isNotEmpty || guardianEmail.isNotEmpty) {
      if (guardianName.isEmpty) {
        _showError('Guardian Name is required');
        return;
      }
      if (guardianRel.isEmpty) {
        _showError('Guardian Relationship is required');
        return;
      }
      if (guardianPhone.isEmpty) {
        _showError('Guardian Phone is required');
        return;
      }
      if (!_phoneRegex.hasMatch(guardianPhone)) {
        _showError('Phone number must contain digits only.');
        return;
      }
      if (guardianEmail.isNotEmpty && !_emailRegex.hasMatch(guardianEmail)) {
        _showError('Enter a valid email address.');
        return;
      }
    }
    if (selectedDob != null && selectedDob!.isAfter(maxAllowedDob)) {
      _showError('Student must be at least 16 years old.');
      return;
    }

    if (selectedYearId != null && selectedSemesterId != null) {
      final allowedSems = _getAllowedSemestersForYear(selectedYearId);
      if (!allowedSems.any((s) => s['id'] == selectedSemesterId)) {
        _showError('Selected semester does not belong to the selected year.');
        return;
      }
    }

    widget.onEditStudent(
      id: widget.student['id'],
      regNo: regNo.toUpperCase(),
      fullName: name.toUpperCase(),
      email: email,
      phone: phone,
      genderId: selectedGenderId,
      departmentId: selectedDeptId,
      yearId: selectedYearId,
      semesterId: selectedSemesterId,
      sectionId: selectedSectionId,
      groupId: null,
      sprNo: widget.sprNoController.text.trim(),
      dob: selectedDob,
      address: addressController.text.trim(),
      active: isActive,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final maxAllowedDob = DateTime(now.year - 16, now.month, now.day);
    final minAllowedDob = DateTime(1970, 1, 1);

    if (lastFetchedDeptId != selectedDeptId) {
      isFetchingSections = true;
      Future.microtask(() async {
        final list = await widget.fetchSectionsForDept(selectedDeptId);
        if (mounted) {
          setState(() {
            dialogSections = list;
            isFetchingSections = false;
            if (selectedSectionId != null &&
                !list.any((sec) => sec['id'] == selectedSectionId)) {
              selectedSectionId = null;
            }
          });
        }
      });
      lastFetchedDeptId = selectedDeptId;
    }

    final uniqueDepartments = _deduplicate(widget.departments);
    final uniqueYears = _deduplicate(widget.years);
    final uniqueSemesters = _deduplicate(widget.semesters);
    final uniqueGenders = _deduplicate(widget.genders);
    final uniqueGroups = _deduplicate(widget.groups);
    final uniqueSections = _deduplicate(dialogSections);

    if (selectedDeptId != null &&
        !uniqueDepartments.any((d) => d['id'] == selectedDeptId)) {
      selectedDeptId = null;
    }
    if (selectedYearId != null &&
        !uniqueYears.any((y) => y['id'] == selectedYearId)) {
      selectedYearId = null;
    }
    if (selectedSemesterId != null &&
        !uniqueSemesters.any((sem) => sem['id'] == selectedSemesterId)) {
      selectedSemesterId = null;
    }
    if (selectedGenderId != null &&
        !uniqueGenders.any((g) => g['id'] == selectedGenderId)) {
      selectedGenderId = null;
    }
    if (selectedGroupId != null &&
        !uniqueGroups.any((g) => g['id'] == selectedGroupId)) {
      selectedGroupId = null;
    }
    if (!isFetchingSections &&
        selectedSectionId != null &&
        !uniqueSections.any((sec) => sec['id'] == selectedSectionId)) {
      selectedSectionId = null;
    }
    if (selectedGuardianRel != null &&
        !guardianRelations.contains(selectedGuardianRel)) {
      selectedGuardianRel = null;
    }

    final inputDecoration = (String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Student',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Personal Information'),
                    TextField(
                      controller: widget.regNoController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                      ],
                      decoration: inputDecoration('Register Number *'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.nameController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        UpperCaseTextFormatter(),
                      ],
                      decoration: inputDecoration('Full Name *'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.emailController,
                      decoration: inputDecoration('Email *'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 10,
                      decoration: inputDecoration(
                        'Phone',
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.sprNoController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        UpperCaseTextFormatter(),
                      ],
                      decoration: inputDecoration('SPR No'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedGenderId,
                      decoration: inputDecoration('Gender'),
                      items: uniqueGenders
                          .map(
                            (g) => DropdownMenuItem<int>(
                              value: g['id'],
                              child: Text(g['genderName'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedGenderId = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: inputDecoration('Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                color: selectedDob != null ? const Color(0xFF1E293B) : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedDob == null
                                    ? 'Select Date of Birth'
                                    : 'DOB: ${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontWeight: selectedDob != null ? FontWeight.bold : FontWeight.normal,
                                  color: selectedDob != null ? Colors.black87 : Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: (selectedDob != null && !selectedDob!.isAfter(maxAllowedDob))
                                    ? selectedDob!
                                    : DateTime(now.year - 18, 1, 1),
                                firstDate: minAllowedDob,
                                lastDate: maxAllowedDob,
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDob = picked;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: Text(selectedDob == null ? 'Pick' : 'Change'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Guardian Information'),
                    TextField(
                      controller: widget.guardianNameController,
                      decoration: inputDecoration('Guardian Name *'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGuardianRel,
                      decoration: inputDecoration(
                        'Relationship (e.g. Father, Mother) *',
                      ),
                      items: guardianRelations.map((rel) {
                        return DropdownMenuItem<String>(
                          value: rel,
                          child: Text(rel),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGuardianRel = value;
                          widget.guardianRelController.text =
                              value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.guardianPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 10,
                      decoration: inputDecoration(
                        'Guardian Phone *',
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.guardianEmailController,
                      decoration: inputDecoration('Guardian Email'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Academic Information'),
                    DropdownButtonFormField<int>(
                      value: selectedDeptId,
                      decoration: inputDecoration('Department'),
                      items: uniqueDepartments
                          .map(
                            (d) => DropdownMenuItem<int>(
                              value: d['id'],
                              child: Text(d['code'] ?? d['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        selectedDeptId = val;
                        selectedSectionId = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedYearId,
                      decoration: inputDecoration('Year'),
                      items: uniqueYears
                          .map(
                            (y) => DropdownMenuItem<int>(
                              value: y['id'],
                              child: Text(
                                y['yearNo'] != null
                                    ? "Year ${y['yearNo']}"
                                    : (y['name'] ?? y['yearName'] ?? ''),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        selectedYearId = val;
                        final allowedSems = _getAllowedSemestersForYear(selectedYearId);
                        if (allowedSems.isNotEmpty) {
                          if (selectedSemesterId == null || !allowedSems.any((s) => s['id'] == selectedSemesterId)) {
                            selectedSemesterId = allowedSems.first['id'];
                          }
                        } else {
                          selectedSemesterId = null;
                        }
                      }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedSemesterId,
                      decoration: inputDecoration('Semester'),
                      hint: Text(selectedYearId == null ? 'Select Year first' : 'Select Semester'),
                      items: _getAllowedSemestersForYear(selectedYearId)
                          .map(
                            (sem) => DropdownMenuItem<int>(
                              value: sem['id'],
                              child: Text(
                                sem['semesterNo'] != null
                                    ? "Semester ${sem['semesterNo']}"
                                    : (sem['semesterName'] ?? sem['name'] ?? ''),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: selectedYearId == null ? null : (val) =>
                          setState(() => selectedSemesterId = val),
                    ),
                    const SizedBox(height: 16),
                    isFetchingSections
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: selectedSectionId,
                            decoration: inputDecoration('Section'),
                            items: uniqueSections
                                .map(
                                  (sec) => DropdownMenuItem<int>(
                                    value: sec['id'],
                                    child: Text(
                                      sec['sectionName'] ?? '',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedSectionId = val),
                          ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Account & Status'),
                    SwitchListTile(
                      title: const Text(
                        'Active Account',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      onChanged: (val) =>
                          setState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                ),
                onPressed: _validateAndSubmit,
                child: const Text('Update Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
