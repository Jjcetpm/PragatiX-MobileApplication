import 'package:flutter/material.dart';
import 'package:pragatix/shared/widgets/student_search/student_search_dialog.dart';

class StudentSearchField extends StatelessWidget {
  final Map<String, dynamic>? selectedStudent;
  final ValueChanged<Map<String, dynamic>> onStudentSelected;
  final String labelText;
  final bool unassignedOnly;
  final String? year;
  final dynamic departmentId;
  final String? departmentName;
  final dynamic sectionId;
  final String? sectionName;
  final bool enabled;
  final VoidCallback? onDisabledTap;

  const StudentSearchField({
    super.key,
    required this.selectedStudent,
    required this.onStudentSelected,
    this.labelText = 'Search Captain',
    this.unassignedOnly = false,
    this.year,
    this.departmentId,
    this.departmentName,
    this.sectionId,
    this.sectionName,
    this.enabled = true,
    this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayString = selectedStudent != null
        ? '${selectedStudent!['fullName']} (${selectedStudent!['regNo']})'
        : '';

    return TextField(
      readOnly: true,
      onTap: () async {
        if (!enabled) {
          if (onDisabledTap != null) {
            onDisabledTap!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select Year and Department first before selecting a Team Captain.'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
          return;
        }

        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => StudentSearchDialog(
            unassignedOnly: unassignedOnly,
            year: year,
            departmentId: departmentId,
            departmentName: departmentName,
            sectionId: sectionId,
            sectionName: sectionName,
          ),
        );

        if (result != null) {
          onStudentSelected(result);
        }
      },
      controller: TextEditingController(text: displayString),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: enabled ? '🔍 Search Student...' : 'Select Year & Department first',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        filled: !enabled,
        fillColor: !enabled ? const Color(0xFFF1F5F9) : null,
      ),
    );
  }
}
