import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';

import 'package:pragatix/features/profile/models/profile_response.dart';
import 'package:pragatix/features/profile/repository/profile_repository.dart';
import 'package:pragatix/shared/widgets/profile_header.dart';
import 'package:pragatix/shared/widgets/shared_profile_card.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/shared/widgets/shared_logout_button.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/student/models/student_deletion_request.dart';
import 'package:pragatix/features/student/widgets/delete_student_confirmation_dialog.dart';
import 'package:pragatix/features/student/widgets/student_deletion_status_banner.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileRepository _repository;
  AdminRepository get _adminRepository => getIt<AdminRepository>();
  ProfileResponse? _profile;
  StudentDeletionRequest? _deletionRequest;
  Timer? _statusPollTimer;
  bool _isLoading = true;
  String? _error;
  dynamic _rawError;

  @override
  void initState() {
    super.initState();
    _repository = ProfileRepository();
    // Use addPostFrameCallback to ensure context is ready for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _loadDeletionRequest();
      }
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _rawError = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        throw Exception('User is not authenticated');
      }
      final profile = await _repository.getMyProfile(token);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
        if (profile.studentDetails != null) {
          _loadDeletionRequest();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rawError = e;
          _error = ErrorHandler.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDeletionRequest() async {
    try {
      final req = await _adminRepository.getMyStudentDeletionRequest();
      if (!mounted) return;

      if (req != null && req.isApproved) {
        _statusPollTimer?.cancel();
        // Super Admin approved the deletion! Force automatic logout immediately.
        final auth = getIt<AuthProvider>();
        await auth.logout();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account deletion request has been approved. The account has been deactivated.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _deletionRequest = req;
      });

      if (req != null && req.isPending) {
        if (_statusPollTimer == null || !_statusPollTimer!.isActive) {
          _startStatusPolling();
        }
      } else {
        _statusPollTimer?.cancel();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _statusPollTimer?.cancel();
        final auth = getIt<AuthProvider>();
        await auth.logout();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: const Color(0xFFF1F5F9),
              height: 1,
            ),
          ),
        ),
        body: const Center(
          child: PragatiXLoader(fullScreen: false, message: 'Loading Profile...'),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        body: SafeArea(
          child: ErrorHandler.buildErrorWidget(
            _rawError ?? _error,
            onRetry: _loadProfile,
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        body: const Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: const Color(0xFF4F46E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SharedProfileHeader(
                title: _profile!.fullName,
                subtitle: _profile!.role,
                icon: Icons.person_outline_rounded,
                isCaptain: _profile!.studentDetails?.isCaptain ?? false,
                isViceCaptain: _profile!.studentDetails?.isViceCaptain ?? false,
              ),
              const SizedBox(height: 24),
              
              _buildCommonInfoCard(),
              const SizedBox(height: 16),
              
              if (_profile!.superAdminDetails != null) ...[
                _buildSuperAdminCard(),
                const SizedBox(height: 16),
              ],
              if (_profile!.teacherDetails != null &&
                  _profile!.ccDetails == null &&
                  _profile!.hodDetails == null) ...[
                _buildTeacherCard(),
                const SizedBox(height: 16),
              ],
              if (_profile!.studentDetails != null) ...[
                _buildStudentCard(),
                const SizedBox(height: 16),
              ],
              if (_profile!.ccDetails != null) ...[
                _buildCcCard(),
                const SizedBox(height: 16),
              ],
              if (_profile!.hodDetails != null) ...[
                _buildHodCard(),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
              _buildQuickActions(),
              if (_profile!.studentDetails != null) ...[
                _buildStudentDeletionSection(),
                const SizedBox(height: 16),
              ],
              const SharedLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshDbCache() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final auth = context.read<AuthProvider>();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/superadmin/cache/refresh'),
        headers: {
          'Authorization': 'Bearer ${auth.token!}',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Database cache refreshed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to refresh cache: ${response.statusCode}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  Widget _buildCommonInfoCard() {
    final isAdmin = _profile!.adminDetails != null;
    final isSuperAdmin = _profile!.superAdminDetails != null;
    
    return SharedProfileCard(
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 10),
        if (_profile!.username.isNotEmpty && _profile!.username != _profile!.email && !_profile!.username.contains('@')) ...[
          SharedProfileRow(label: 'Username', value: _profile!.username),
          const SizedBox(height: 4),
        ],
        SharedProfileRow(label: 'Email', value: _profile!.email ?? (_profile!.username.contains('@') ? _profile!.username : 'Not Available')),
        const SizedBox(height: 4),
        if (isAdmin) ...[
          SharedProfileRow(label: 'Assigned Year', value: _profile!.adminDetails!.academicYear ?? 'Not Available'),
          const SizedBox(height: 4),
        ] else if (!isSuperAdmin) ...[
          SharedProfileRow(label: 'Department', value: _profile!.department ?? 'Not Available'),
          const SizedBox(height: 4),
        ],
        SharedProfileRow(label: 'Status', value: _profile!.accountStatus ?? 'Not Available'),
      ],
    );
  }

  Widget _buildSuperAdminCard() {
    final stats = _profile!.superAdminDetails!;
    return SharedProfileCard(
      children: [
        const Text(
          'System Statistics',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 10),
        SharedProfileRow(label: 'Total Departments', value: stats.totalDepartments.toString()),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Total Students', value: stats.totalStudents.toString()),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Total Teachers', value: stats.totalTeachers.toString()),
      ],
    );
  }

  Widget _buildTeacherCard() {
    final stats = _profile!.teacherDetails!;
    return SharedProfileCard(
      children: [
        const Text(
          'Teacher Information',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 10),
        SharedProfileRow(label: 'Employee ID', value: stats.employeeId ?? 'Not Available'),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Total Students', value: stats.totalStudents.toString()),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Attendance Taken', value: stats.attendanceTakenCount.toString()),
      ],
    );
  }

  Widget _buildStudentCard() {
    final stats = _profile!.studentDetails!;
    
    String leadershipRole = 'Student';
    if (stats.isCaptain) {
      leadershipRole = 'Captain';
    } else if (stats.isViceCaptain) {
      leadershipRole = 'Vice Captain';
    }

    String attendanceDisplay = '${stats.attendancePercentage}%';
    try {
      final attendanceProv = context.read<AttendanceProvider>();
      if (attendanceProv.summary != null) {
        attendanceDisplay = '${attendanceProv.summary!.attendancePercentage}%';
      }
    } catch (_) {}

    return SharedProfileCard(
      children: [
        const Text(
          'Academic Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 10),
        SharedProfileRow(label: 'Register Number', value: stats.registerNumber ?? 'Not Available'),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Academic Year', value: stats.academicYear ?? 'Not Available'),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Section', value: stats.section ?? 'Not Available'),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Leadership Role', value: leadershipRole),
        const SizedBox(height: 16),
        const Text(
          'Performance',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 10),
        SharedProfileRow(label: 'Current XP', value: stats.currentXp.toString()),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Attendance', value: attendanceDisplay),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Rank', value: stats.rank.toString()),
      ],
    );
  }

  Widget _buildCcCard() {
    final stats = _profile!.ccDetails!;
    return SharedProfileCard(
      children: [
        const Text(
          'Class Coordinator Info',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 10),
        SharedProfileRow(label: 'Section', value: stats.section ?? 'Not Available'),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Assigned Year', value: stats.academicYear ?? 'Not Available'),
      ],
    );
  }

  Widget _buildHodCard() {
    final stats = _profile!.hodDetails!;
    return SharedProfileCard(
      children: [
        const Text(
          'HOD Statistics',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 10),
        SharedProfileRow(label: 'Total Faculty', value: stats.totalFaculty.toString()),
        const SizedBox(height: 4),
        SharedProfileRow(label: 'Total Students', value: stats.totalStudents.toString()),
      ],
    );
  }

  Widget _buildQuickActions() {
    final isSuperAdmin = _profile!.superAdminDetails != null;

    if (!isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _refreshDbCache,
          icon: const Icon(Icons.cached_rounded),
          label: const Text('Refresh DB Cache'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Future<void> _openDeleteDialog() async {
    if (_profile == null || _profile!.studentDetails == null) return;

    final studentDetails = _profile!.studentDetails!;
    final studentId = studentDetails.id ?? 0;

    final result = await DeleteStudentConfirmationDialog.show(
      context: context,
      studentName: _profile!.fullName,
      registerNumber: studentDetails.registerNumber ?? _profile!.username,
      departmentName: _profile!.department,
      sectionName: studentDetails.section,
      year: studentDetails.academicYear,
      onConfirm: (reason) async {
        await _adminRepository.submitStudentDeletionRequest(
          studentId: studentId,
          reason: reason,
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion request submitted for Super Admin approval.'),
          backgroundColor: Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadDeletionRequest();
    }
  }

  Widget _buildStudentDeletionSection() {
    if (_profile!.studentDetails == null) return const SizedBox.shrink();

    final isPending = _deletionRequest?.isPending ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_deletionRequest != null) ...[
          StudentDeletionStatusBanner(
            request: _deletionRequest!,
            onRefresh: _loadDeletionRequest,
            onReRequest: _openDeleteDialog,
          ),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPending ? const Color(0xFFE2E8F0) : const Color(0xFFFEE2E2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPending ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: isPending ? const Color(0xFF64748B) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete My Account & Data',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isPending ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPending
                              ? 'Your deletion request is currently awaiting Super Admin review.'
                              : 'Submit an account deletion request for Super Admin approval.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isPending ? null : _openDeleteDialog,
                  icon: Icon(
                    isPending ? Icons.hourglass_top_rounded : Icons.delete_forever_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isPending ? 'Deletion Request Pending Approval' : 'Request Account Deletion',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    side: BorderSide(
                      color: isPending ? const Color(0xFFCBD5E1) : const Color(0xFFFCA5A5),
                      width: 1.2,
                    ),
                    backgroundColor: isPending ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
