import 'package:flutter/material.dart';

class StudentFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;

  const StudentFilterPanel({
    super.key,
    required this.searchController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search by student ID or name...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
    );
  }
}
