import 'package:flutter/material.dart';

class DeleteStudentDialog extends StatelessWidget {
  final String studentName;
  final VoidCallback onConfirmDelete;

  const DeleteStudentDialog({
    super.key,
    required this.studentName,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Student'),
      content: Text('Are you sure you want to delete student $studentName?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirmDelete();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
