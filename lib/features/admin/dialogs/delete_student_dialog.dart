import 'package:flutter/material.dart';

class DeleteStudentDialog extends StatefulWidget {
  final String studentName;
  final Function(String reason)? onConfirmWithReason;
  final VoidCallback? onConfirmDelete;

  const DeleteStudentDialog({
    super.key,
    required this.studentName,
    this.onConfirmWithReason,
    this.onConfirmDelete,
  });

  @override
  State<DeleteStudentDialog> createState() => _DeleteStudentDialogState();
}

class _DeleteStudentDialogState extends State<DeleteStudentDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Request Deletion',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you really want to delete student ${widget.studentName}?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This will automatically send a deletion request to the Super Admin for approval. The student profile will remain active until approved.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Reason for Deletion *',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please provide a reason';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'e.g. Left college, course withdrawal, etc.',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final reason = _reasonController.text.trim();
            Navigator.pop(context);
            if (widget.onConfirmWithReason != null) {
              widget.onConfirmWithReason!(reason);
            } else if (widget.onConfirmDelete != null) {
              widget.onConfirmDelete!();
            }
          },
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}
