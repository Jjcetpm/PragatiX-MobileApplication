import 'package:flutter/material.dart';

class CcStudentProfilePage extends StatelessWidget {
  final Map<String, dynamic> student;

  const CcStudentProfilePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final String name = student['fullName'] ?? 'N/A';
    final String regNo = student['regNo'] ?? 'N/A';
    final String sprNo = student['sprNo'] ?? 'N/A';
    final String deptName = student['departmentName'] ?? student['department'] ?? 'N/A';
    final String academicYear = student['academicYear'] ?? 'N/A';
    final String year = student['year']?.toString() ?? 'N/A';
    final String semester = student['semester']?.toString() ?? 'N/A';
    final String section = student['section']?.toString() ?? 'N/A';
    final String email = student['email'] ?? 'N/A';
    final String phone = student['phone'] ?? 'N/A';
    final String dob = student['dateOfBirth'] ?? 'N/A';
    final String gender = student['gender'] ?? 'N/A';

    final guardian = student['guardian'] as Map<String, dynamic>?;
    final String gName = guardian?['guardianName'] ?? 'N/A';
    final String gRel = guardian?['relationship'] ?? 'N/A';
    final String gPhone = guardian?['phoneNo'] ?? 'N/A';
    final String gEmail = guardian?['email'] ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Student Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF11998e).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF11998e),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        regNo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Academic Details
            _buildSection(
              title: 'Academic Information',
              icon: Icons.school,
              children: [
                _buildDetailRow('Department', deptName),
                _buildDetailRow('SPR No', sprNo),
                _buildDetailRow('Academic Year', academicYear),
                _buildDetailRow('Year', year),
                _buildDetailRow('Semester', semester),
                _buildDetailRow('Section', section),
              ],
            ),
            const SizedBox(height: 16),
            
            // Personal Details
            _buildSection(
              title: 'Personal Information',
              icon: Icons.person_outline,
              children: [
                _buildDetailRow('Email', email),
                _buildDetailRow('Phone', phone),
                _buildDetailRow('Date of Birth', dob),
                _buildDetailRow('Gender', gender),
              ],
            ),
            const SizedBox(height: 16),
            
            // Guardian Details
            _buildSection(
              title: 'Guardian Information',
              icon: Icons.family_restroom,
              children: [
                _buildDetailRow('Guardian Name', gName),
                _buildDetailRow('Relationship', gRel),
                _buildDetailRow('Phone', gPhone),
                _buildDetailRow('Email', gEmail),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF11998e), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
