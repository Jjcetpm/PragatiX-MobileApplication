import 'package:flutter/material.dart';

import 'package:pragatix/features/activity/pages/group_activity_execution_page.dart';

class GroupActivitySecPage extends StatelessWidget {
  final int activityId;
  final dynamic selectedYear;
  final dynamic selectedDept;
  final List<dynamic> availableSections;
  final int? stageId;

  const GroupActivitySecPage({
    super.key,
    required this.activityId,
    required this.selectedYear,
    required this.selectedDept,
    required this.availableSections,
    this.stageId,
  });

  // Theme constants
  static const Color _primary = Color(0xFF1E3A8A); // Deep blue
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _dark = Color(0xFF0F172A);

  void _navigateToGroups(BuildContext context, dynamic section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupActivityExecutionPage(
          activityId: activityId,
          selectedYear: selectedYear,
          selectedDept: selectedDept,
          selectedSection: section,
          stageId: stageId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Select Section'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: availableSections.isEmpty
          ? const Center(child: Text('No sections available.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableSections.length,
              itemBuilder: (context, index) {
                final sec = availableSections[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    title: Text(
                      sec['sectionName'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () => _navigateToGroups(context, sec),
                  ),
                );
              },
            ),
    );
  }
}
