import 'package:flutter/material.dart';

class StudentFab extends StatelessWidget {
  final VoidCallback onPressed;

  const StudentFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF2563EB),
      elevation: 4,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }
}
