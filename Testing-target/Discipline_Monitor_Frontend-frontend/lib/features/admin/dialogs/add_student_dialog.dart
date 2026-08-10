import 'package:flutter/material.dart';

class AddStudentDialog extends StatefulWidget {
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
    required int? departmentId,
    required int? academicYearId,
    required int? yearId,
    required int? semesterId,
    required int? genderId,
    required int? sectionId,
    required int? groupId,
    required String address,
    required DateTime? dob,
  })
  onAddStudent;
  final VoidCallback clearControllers;

  const AddStudentDialog({
    super.key,
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
    required this.onAddStudent,
    required this.clearControllers,
  });

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
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
  final List<String> guardianRelations = [
    'Father',
    'Mother',
    'Guardian',
    'Parent',
  ];
  String? selectedGuardianRel;
  bool isFetchingSections = false;

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

    final uniqueDepartments = _deduplicate(widget.departments);
    final uniqueAcademicYears = _deduplicate(widget.academicYears);
    final uniqueYears = _deduplicate(widget.years);
    final uniqueSemesters = _deduplicate(widget.semesters);
    final uniqueGenders = _deduplicate(widget.genders);

    if (uniqueDepartments.isNotEmpty)
      selectedDeptId = uniqueDepartments.first['id'];
    if (uniqueAcademicYears.isNotEmpty)
      selectedAcademicYearId = uniqueAcademicYears.first['id'];
    if (uniqueYears.isNotEmpty) selectedYearId = uniqueYears.first['id'];
    if (uniqueSemesters.isNotEmpty)
      selectedSemesterId = uniqueSemesters.first['id'];
    if (uniqueGenders.isNotEmpty) selectedGenderId = uniqueGenders.first['id'];
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
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

    return AlertDialog(
      title: const Text(
        'Register New Student',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.regNoController,
              decoration: const InputDecoration(labelText: 'Student ID *'),
            ),
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
            ),
            TextField(
              controller: widget.emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
            ),
            TextField(
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone',
                counterText: '',
              ),
            ),
            TextField(
              controller: widget.sprNoController,
              decoration: const InputDecoration(labelText: 'SPR No'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Guardian Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            TextField(
              controller: widget.guardianNameController,
              decoration: const InputDecoration(labelText: 'Guardian Name *'),
            ),
            DropdownButtonFormField<String>(
              value: selectedGuardianRel,
              decoration: const InputDecoration(labelText: 'Relationship *'),
              items: guardianRelations.map((rel) {
                return DropdownMenuItem<String>(value: rel, child: Text(rel));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGuardianRel = value;
                  widget.guardianRelController.text = value ?? '';
                });
              },
            ),
            TextField(
              controller: widget.guardianPhoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Guardian Phone *',
                counterText: '',
              ),
            ),
            TextField(
              controller: widget.guardianEmailController,
              decoration: const InputDecoration(labelText: 'Guardian Email'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDob == null
                      ? 'Select Date of Birth *'
                      : "DOB: ${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectedDob == null
                        ? Colors.redAccent
                        : Colors.black87,
                  ),
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
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: selectedDeptId,
              decoration: const InputDecoration(labelText: 'Department *'),
              items: uniqueDepartments.map((d) {
                return DropdownMenuItem<int>(
                  value: d['id'],
                  child: Text(d['code'] ?? d['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDeptId = value;
                  selectedSectionId = null;
                });
              },
            ),
            DropdownButtonFormField<int>(
              value: selectedAcademicYearId,
              decoration: const InputDecoration(labelText: 'Academic Year *'),
              items: uniqueAcademicYears.map((ay) {
                return DropdownMenuItem<int>(
                  value: ay['id'],
                  child: Text(ay['academicYear'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAcademicYearId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              value: selectedYearId,
              decoration: const InputDecoration(labelText: 'Year *'),
              items: uniqueYears.map((y) {
                return DropdownMenuItem<int>(
                  value: y['id'],
                  child: Text(y['yearNo'] != null ? "Year ${y['yearNo']}" : ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYearId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              value: selectedSemesterId,
              decoration: const InputDecoration(labelText: 'Semester *'),
              items: uniqueSemesters.map((sem) {
                return DropdownMenuItem<int>(
                  value: sem['id'],
                  child: Text(
                    sem['semesterNo'] != null
                        ? "Semester ${sem['semesterNo']}"
                        : '',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSemesterId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              value: selectedGenderId,
              decoration: const InputDecoration(labelText: 'Gender *'),
              items: uniqueGenders.map((g) {
                return DropdownMenuItem<int>(
                  value: g['id'],
                  child: Text(g['genderName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGenderId = value;
                });
              },
            ),
            isFetchingSections
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                : DropdownButtonFormField<int>(
                    value: selectedSectionId,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: uniqueSections.map((sec) {
                      return DropdownMenuItem<int>(
                        value: sec['id'],
                        child: Text(sec['sectionName'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSectionId = value;
                      });
                    },
                  ),
            DropdownButtonFormField<int>(
              value: selectedGroupId,
              decoration: const InputDecoration(labelText: 'Group'),
              items: uniqueGroups.map((grp) {
                return DropdownMenuItem<int>(
                  value: grp['id'],
                  child: Text(grp['groupName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGroupId = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAddStudent(
              departmentId: selectedDeptId,
              academicYearId: selectedAcademicYearId,
              yearId: selectedYearId,
              semesterId: selectedSemesterId,
              genderId: selectedGenderId,
              sectionId: selectedSectionId,
              groupId: selectedGroupId,
              address: addressController.text,
              dob: selectedDob,
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
