import 'package:flutter/material.dart';

class StudentFab extends StatelessWidget {
  final VoidCallback onPressed;

  const StudentFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFFEA4335),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
