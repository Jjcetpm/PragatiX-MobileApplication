import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/student/models/student_deletion_request.dart';
import 'package:pragatix/features/student/widgets/delete_student_confirmation_dialog.dart';
import 'package:pragatix/features/student/widgets/student_deletion_status_banner.dart';

class CcStudentProfilePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const CcStudentProfilePage({super.key, required this.student});

  @override
  State<CcStudentProfilePage> createState() => _CcStudentProfilePageState();
}

class _CcStudentProfilePageState extends State<CcStudentProfilePage> {
  final AdminRepository _adminRepository = getIt<AdminRepository>();
  StudentDeletionRequest? _deletionRequest;

  @override
  void initState() {
    super.initState();
    _fetchDeletionStatus();
  }

  int get studentId {
    final raw = widget.student['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  Future<void> _fetchDeletionStatus() async {
    if (studentId <= 0) return;
    try {
      final req = await _adminRepository.getStudentDeletionRequest(studentId);
      if (mounted) {
        setState(() {
          _deletionRequest = req;
        });
      }
    } catch (_) {}
  }

  Future<void> _openDeleteDialog() async {
    if (studentId <= 0) return;

    if (_deletionRequest != null && _deletionRequest!.isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A deletion request is already pending Super Admin approval.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    final String name = widget.student['fullName'] ?? widget.student['name'] ?? 'N/A';
    final String regNo = widget.student['regNo'] ?? widget.student['studentId'] ?? 'N/A';
    final String deptName = widget.student['departmentName'] ?? widget.student['department'] ?? 'N/A';
    final String section = widget.student['section']?.toString() ?? 'N/A';
    final String year = widget.student['year']?.toString() ?? 'N/A';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteStudentConfirmationDialog(
        studentId: studentId,
        studentName: name,
        registerNumber: regNo,
        departmentName: deptName,
        sectionName: section,
        year: year,
        onConfirm: (reason) async {
          await _adminRepository.submitStudentDeletionRequest(
            studentId: studentId,
            reason: reason,
          );
        },
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion request submitted to Super Admin for approval.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        _fetchDeletionStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.student['fullName'] ?? widget.student['name'] ?? 'N/A';
    final String regNo = widget.student['regNo'] ?? widget.student['studentId'] ?? 'N/A';
    final String sprNo = widget.student['sprNo'] ?? 'N/A';
    final String deptName = widget.student['departmentName'] ?? widget.student['department'] ?? 'N/A';
    final String academicYear = widget.student['academicYear'] ?? 'N/A';
    final String year = widget.student['year']?.toString() ?? 'N/A';
    final String semester = widget.student['semester']?.toString() ?? 'N/A';
    final String section = widget.student['section']?.toString() ?? 'N/A';
    final String email = widget.student['email'] ?? 'N/A';
    final String phone = widget.student['phone'] ?? 'N/A';
    final String dob = widget.student['dateOfBirth'] ?? 'N/A';
    final String gender = widget.student['gender'] ?? 'N/A';

    final guardian = widget.student['guardian'] as Map<String, dynamic>?;
    final String gName = guardian?['guardianName'] ?? 'N/A';
    final String gRel = guardian?['relationship'] ?? 'N/A';
    final String gPhone = guardian?['phoneNo'] ?? 'N/A';
    final String gEmail = guardian?['email'] ?? 'N/A';

    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser ?? {};
    final dynamic rawRoles = currentUser['roles'];
    final List<dynamic> roles = rawRoles is List ? rawRoles : [];
    final bool isSuperAdmin = roles.any((r) {
      if (r == null) return false;
      final n = r is String ? r : (r is Map ? (r['name'] ?? r['authority'] ?? '').toString() : '');
      return n == 'ROLE_SUPER_ADMIN' || n == 'SUPER_ADMIN';
    });

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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFCA5A5)),
            tooltip: 'Delete Student',
            onPressed: _openDeleteDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Banner if deletion request exists
            if (_deletionRequest != null)
              StudentDeletionStatusBanner(
                request: _deletionRequest!,
                isSuperAdmin: isSuperAdmin,
                onApprove: isSuperAdmin && _deletionRequest!.isPending
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        try {
                          await _adminRepository.approveStudentDeletionRequest(_deletionRequest!.id);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Student deletion approved.'),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                          nav.pop(true);
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      }
                    : null,
                onReject: isSuperAdmin && _deletionRequest!.isPending
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await _adminRepository.rejectStudentDeletionRequest(_deletionRequest!.id);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Student deletion rejected. Profile retained.'),
                              backgroundColor: Color(0xFF2563EB),
                            ),
                          );
                          _fetchDeletionStatus();
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      }
                    : null,
              ),

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
            const SizedBox(height: 20),

            // Delete Student Button Card
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFFECACA), width: 1),
              ),
              color: const Color(0xFFFFF5F5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Student Profile',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Submits deletion request for Super Admin authorization',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openDeleteDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
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
