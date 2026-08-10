import 'package:flutter/material.dart';
import 'package:pragatix/shared/widgets/student_search/student_search_dialog.dart';

class StudentSearchField extends StatelessWidget {
  final Map<String, dynamic>? selectedStudent;
  final ValueChanged<Map<String, dynamic>> onStudentSelected;
  final String labelText;

  const StudentSearchField({
    Key? key,
    required this.selectedStudent,
    required this.onStudentSelected,
    this.labelText = 'Search Captain',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayString = selectedStudent != null
        ? '${selectedStudent!['fullName']} (${selectedStudent!['regNo']})'
        : '';

    return TextField(
      readOnly: true,
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => const StudentSearchDialog(),
        );

        if (result != null) {
          onStudentSelected(result);
        }
      },
      controller: TextEditingController(text: displayString),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: '🔍 Search Student...',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }
}
