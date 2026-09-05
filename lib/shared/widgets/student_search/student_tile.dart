import 'package:flutter/material.dart';

class StudentTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onTap;

  const StudentTile({super.key, required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String name = student['fullName'] ?? 'Unknown';
    final String regNo = student['regNo'] ?? 'N/A';
    final String sprNo = student['sprNo'] ?? 'N/A';
    final String email = student['email'] ?? 'N/A';
    final String dept =
        student['departmentName'] ?? student['department'] ?? 'Unknown Dept';
    final String year = student['year'] ?? 'Unknown Year';
    final dynamic rawSec = student['sectionName'] ?? student['section'];
    final String secStr = rawSec?.toString().trim() ?? '';
    final bool hasSection = secStr.isNotEmpty &&
        secStr.toLowerCase() != 'null' &&
        secStr.toLowerCase() != 'unknown section' &&
        secStr.toLowerCase() != 'n/a' &&
        secStr.toLowerCase() != 'none';
    final String section = hasSection ? secStr : 'No Section';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Reg No : $regNo'),
              Text('SPR No : $sprNo'),
              Text('Email : $email'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasSection ? '$year - $dept - $section' : '$year - $dept (No Section)',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
