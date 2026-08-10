import 'package:flutter/material.dart';

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
  final List<dynamic> academicYears;
  final List<dynamic> years;
  final List<dynamic> semesters;
  final List<dynamic> genders;
  final List<dynamic> groups;
  final Future<List<dynamic>> Function(int?) fetchSectionsForDept;
  final Future<void> Function({
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
    required this.academicYears,
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
  int? selectedAcademicYearId;
  int? selectedYearId;
  int? selectedSemesterId;
  int? selectedGenderId;
  int? selectedSectionId;
  int? selectedGroupId;
  DateTime? selectedDob;
  final TextEditingController addressController = TextEditingController();
  List<dynamic> dialogSections = [];
  bool isActive = true;
  final TextEditingController passwordController = TextEditingController();
  final List<String> guardianRelations = [
    'Father',
    'Mother',
    'Guardian',
    'Parent',
  ];
  String? selectedGuardianRel;
  bool isFetchingSections = false;

  String _normalizeSectionName(String name) {
    String cleaned = name.trim().toLowerCase();
    if (cleaned.startsWith('section ')) {
      cleaned = cleaned.substring(8).trim();
    }
    return cleaned;
  }

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

  @override
  void initState() {
    super.initState();
    widget.clearControllers();

    final s = widget.student;
    widget.regNoController.text = s['regNo'] ?? '';
    widget.nameController.text = s['fullName'] ?? '';
    widget.emailController.text = s['email'] ?? '';
    widget.phoneController.text = s['phone'] ?? '';
    widget.sprNoController.text = s['sprNo'] ?? '';
    addressController.text = s['address'] ?? '';
    isActive = s['active'] ?? true;
    passwordController.text = '';

    final g = s['guardian'];
    if (g != null) {
      widget.guardianNameController.text = g['guardianName'] ?? '';

      String relStr = g['relationship'] ?? '';
      // Map 'FATHER' to 'Father'
      if (relStr.isNotEmpty) {
        relStr = relStr[0].toUpperCase() + relStr.substring(1).toLowerCase();
        if (guardianRelations.contains(relStr)) {
          selectedGuardianRel = relStr;
        } else if (relStr.toUpperCase() == 'LOCAL_GUARDIAN') {
          selectedGuardianRel = 'Parent';
        }
      }
      widget.guardianRelController.text = selectedGuardianRel ?? '';

      widget.guardianPhoneController.text = g['phoneNo'] ?? '';
      widget.guardianEmailController.text = g['email'] ?? '';
    } else {
      widget.guardianNameController.text = '';
      widget.guardianRelController.text = '';
      widget.guardianPhoneController.text = '';
      widget.guardianEmailController.text = '';
      selectedGuardianRel = null;
    }

    if (s['dob'] != null) {
      try {
        selectedDob = DateTime.parse(s['dob']);
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

    final uniqueAcademicYears = _deduplicate(widget.academicYears);
    selectedAcademicYearId = s['academicYearId'];
    if (selectedAcademicYearId != null &&
        !uniqueAcademicYears.any((ay) => ay['id'] == selectedAcademicYearId)) {
      selectedAcademicYearId = null;
    }

    final uniqueYears = _deduplicate(widget.years);
    selectedYearId = s['yearId'];
    if (selectedYearId != null &&
        !uniqueYears.any((y) => y['id'] == selectedYearId)) {
      selectedYearId = null;
    }

    final uniqueSemesters = _deduplicate(widget.semesters);
    selectedSemesterId = s['semesterId'];
    if (selectedSemesterId != null &&
        !uniqueSemesters.any((sem) => sem['id'] == selectedSemesterId)) {
      selectedSemesterId = null;
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
    // We will trigger section fetch in build if needed, and validate it in build
  }

  @override
  void dispose() {
    addressController.dispose();
    passwordController.dispose();
    super.dispose();
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
    if (lastFetchedDeptId != selectedDeptId) {
      isFetchingSections = true;
      Future.microtask(() async {
        final list = await widget.fetchSectionsForDept(selectedDeptId);
        if (mounted) {
          setState(() {
            dialogSections = list;
            isFetchingSections = false;
            // Also validate selected section immediately
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
    final uniqueAcademicYears = _deduplicate(widget.academicYears);
    final uniqueYears = _deduplicate(widget.years);
    final uniqueSemesters = _deduplicate(widget.semesters);
    final uniqueGenders = _deduplicate(widget.genders);
    final uniqueGroups = _deduplicate(widget.groups);
    final uniqueSections = _deduplicate(dialogSections);

    if (selectedDeptId != null &&
        !uniqueDepartments.any((d) => d['id'] == selectedDeptId))
      selectedDeptId = null;
    if (selectedAcademicYearId != null &&
        !uniqueAcademicYears.any((ay) => ay['id'] == selectedAcademicYearId))
      selectedAcademicYearId = null;
    if (selectedYearId != null &&
        !uniqueYears.any((y) => y['id'] == selectedYearId))
      selectedYearId = null;
    if (selectedSemesterId != null &&
        !uniqueSemesters.any((sem) => sem['id'] == selectedSemesterId))
      selectedSemesterId = null;
    if (selectedGenderId != null &&
        !uniqueGenders.any((g) => g['id'] == selectedGenderId))
      selectedGenderId = null;
    if (selectedGroupId != null &&
        !uniqueGroups.any((g) => g['id'] == selectedGroupId))
      selectedGroupId = null;
    if (!isFetchingSections &&
        selectedSectionId != null &&
        !uniqueSections.any((sec) => sec['id'] == selectedSectionId))
      selectedSectionId = null;
    if (selectedGuardianRel != null &&
        !guardianRelations.contains(selectedGuardianRel))
      selectedGuardianRel = null;

    final inputDecoration = (String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Edit Student',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
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
                              decoration: inputDecoration('Student ID *'),
                              readOnly: true,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: widget.nameController,
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
                              maxLength: 10,
                              decoration: inputDecoration(
                                'Phone',
                              ).copyWith(counterText: ''),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: widget.sprNoController,
                              decoration: inputDecoration('SPR No'),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: addressController,
                              decoration: inputDecoration('Address'),
                              maxLines: 2,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedDob == null
                                      ? 'Select Date of Birth'
                                      : "DOB: ${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          selectedDob ?? DateTime(2004),
                                      firstDate: DateTime(1995),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDob = picked;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_month),
                                  label: const Text('Pick'),
                                ),
                              ],
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
                              value: selectedAcademicYearId,
                              decoration: inputDecoration('Academic Year'),
                              items: uniqueAcademicYears
                                  .map(
                                    (ay) => DropdownMenuItem<int>(
                                      value: ay['id'],
                                      child: Text(ay['academicYear'] ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedAcademicYearId = val),
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
                                            : '',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedYearId = val),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: selectedSemesterId,
                              decoration: inputDecoration('Semester'),
                              items: uniqueSemesters
                                  .map(
                                    (sem) => DropdownMenuItem<int>(
                                      value: sem['id'],
                                      child: Text(
                                        sem['semesterNo'] != null
                                            ? "Semester ${sem['semesterNo']}"
                                            : '',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedSemesterId = val),
                            ),
                            const SizedBox(height: 16),
                            isFetchingSections
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
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
                            _buildSectionTitle('Account & Security'),
                            DropdownButtonFormField<int>(
                              value: selectedGroupId,
                              decoration: inputDecoration('Group'),
                              items: uniqueGroups
                                  .map(
                                    (grp) => DropdownMenuItem<int>(
                                      value: grp['id'],
                                      child: Text(grp['groupName'] ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedGroupId = val),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration:
                                  inputDecoration(
                                    'New Password (Optional)',
                                  ).copyWith(
                                    helperText:
                                        'Leave blank to keep current password',
                                  ),
                            ),
                            const SizedBox(height: 16),
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
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
                    onPressed: () {
                      widget.onEditStudent(
                        id: widget.student['id'],
                        fullName: widget.nameController.text.trim(),
                        email: widget.emailController.text.trim(),
                        phone: widget.phoneController.text.trim(),
                        genderId: selectedGenderId,
                        departmentId: selectedDeptId,
                        academicYearId: selectedAcademicYearId,
                        yearId: selectedYearId,
                        semesterId: selectedSemesterId,
                        sectionId: selectedSectionId,
                        groupId: selectedGroupId,
                        sprNo: widget.sprNoController.text.trim(),
                        dob: selectedDob,
                        address: addressController.text.trim(),
                        active: isActive,
                        password: passwordController.text.trim(),
                      );
                    },
                    child: const Text('Update Student'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
