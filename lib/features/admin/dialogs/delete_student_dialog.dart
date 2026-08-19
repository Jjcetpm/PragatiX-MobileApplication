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
      title: const Text('Confirm Deletion'),
      content: Text('Are you sure you want to move student $studentName to the Recycle Bin?'),
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
