import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pragatix/core/utils/string_utils.dart';

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
  final List<dynamic> years;
  final List<dynamic> semesters;
  final List<dynamic> genders;
  final List<dynamic> groups;
  final Future<List<dynamic>> Function(int?) fetchSectionsForDept;
  final Future<void> Function({
    required int? departmentId,
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

    final uniqueDepartments = _deduplicate(widget.departments);
    final uniqueYears = _deduplicate(widget.years);
    final uniqueGenders = _deduplicate(widget.genders);

    if (uniqueDepartments.isNotEmpty) {
      selectedDeptId = uniqueDepartments.first['id'];
    }
    if (uniqueYears.isNotEmpty) {
      selectedYearId = uniqueYears.first['id'];
    }
    final allowedSems = _getAllowedSemestersForYear(selectedYearId);
    if (allowedSems.isNotEmpty) {
      selectedSemesterId = allowedSems.first['id'];
    } else {
      selectedSemesterId = null;
    }
    if (uniqueGenders.isNotEmpty) {
      selectedGenderId = uniqueGenders.first['id'];
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final regNo = widget.regNoController.text.trim();
    final name = widget.nameController.text.trim();
    final email = widget.emailController.text.trim();
    final phone = widget.phoneController.text.trim();
    final guardianName = widget.guardianNameController.text.trim();
    final guardianRel = selectedGuardianRel ?? widget.guardianRelController.text.trim();
    final guardianPhone = widget.guardianPhoneController.text.trim();
    final guardianEmail = widget.guardianEmailController.text.trim();

    final now = DateTime.now();
    final maxAllowedDob = DateTime(now.year - 16, now.month, now.day);

    final sprNo = widget.sprNoController.text.trim();

    if (regNo.isEmpty) {
      _showError('Register Number is required');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(regNo)) {
      _showError('Register Number must contain digits only.');
      return;
    }
    if (!regNo.startsWith('8113')) {
      _showError('Register Number must start with 8113.');
      return;
    }
    if (sprNo.isNotEmpty && !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(sprNo)) {
      _showError('SPR Number must contain letters and numbers only (no symbols).');
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
    if (selectedGenderId == null) {
      _showError('Select Gender');
      return;
    }
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
    if (selectedDob == null) {
      _showError('Select Date of Birth');
      return;
    }
    if (selectedDob!.isAfter(maxAllowedDob)) {
      _showError('Student must be at least 16 years old.');
      return;
    }
    if (selectedDeptId == null) {
      _showError('Select Department');
      return;
    }
    if (selectedYearId == null) {
      _showError('Select Year');
      return;
    }
    if (selectedSemesterId == null) {
      _showError('Select Semester');
      return;
    }
    final allowedSems = _getAllowedSemestersForYear(selectedYearId);
    if (!allowedSems.any((s) => s['id'] == selectedSemesterId)) {
      _showError('Selected semester does not belong to the selected year.');
      return;
    }

    widget.onAddStudent(
      departmentId: selectedDeptId,
      yearId: selectedYearId,
      semesterId: selectedSemesterId,
      genderId: selectedGenderId,
      sectionId: selectedSectionId,
      groupId: null,
      address: addressController.text.trim(),
      dob: selectedDob,
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
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register New Student',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Personal Details'),
            TextField(
              controller: widget.regNoController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(labelText: 'Register Number *'),
            ),
            TextField(
              controller: widget.nameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                UpperCaseTextFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Full Name *'),
            ),
            TextField(
              controller: widget.emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
            ),
            TextField(
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone',
                counterText: '',
              ),
            ),
            TextField(
              controller: widget.sprNoController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                UpperCaseTextFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'SPR No'),
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
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
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
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pick'),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildSectionTitle('Guardian Details'),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
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
            const Divider(height: 32),
            _buildSectionTitle('Academic Details'),
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
              value: selectedYearId,
              decoration: const InputDecoration(labelText: 'Year *'),
              items: uniqueYears.map((y) {
                final yLabel = y['yearNo'] != null ? "Year ${y['yearNo']}" : (y['name'] ?? y['yearName'] ?? '');
                return DropdownMenuItem<int>(
                  value: y['id'],
                  child: Text(yLabel),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYearId = value;
                  final allowedSems = _getAllowedSemestersForYear(selectedYearId);
                  if (allowedSems.isNotEmpty) {
                    if (selectedSemesterId == null || !allowedSems.any((s) => s['id'] == selectedSemesterId)) {
                      selectedSemesterId = allowedSems.first['id'];
                    }
                  } else {
                    selectedSemesterId = null;
                  }
                });
              },
            ),
            DropdownButtonFormField<int>(
              value: selectedSemesterId,
              decoration: const InputDecoration(labelText: 'Semester *'),
              hint: Text(selectedYearId == null ? 'Select Year first' : 'Select Semester'),
              items: _getAllowedSemestersForYear(selectedYearId).map((sem) {
                return DropdownMenuItem<int>(
                  value: sem['id'],
                  child: Text(
                    sem['semesterNo'] != null
                        ? "Semester ${sem['semesterNo']}"
                        : (sem['semesterName'] ?? sem['name'] ?? ''),
                  ),
                );
              }).toList(),
              onChanged: selectedYearId == null ? null : (value) {
                setState(() {
                  selectedSemesterId = value;
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _validateAndSubmit,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
