import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/features/profile/models/profile_response.dart';
import 'package:pragatix/features/profile/repository/profile_repository.dart';
import 'package:pragatix/shared/widgets/profile_header.dart';
import 'package:pragatix/shared/widgets/shared_profile_card.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileRepository _repository;
  ProfileResponse? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ProfileRepository();
    // Use addPostFrameCallback to ensure context is ready for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading profile: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SharedProfileHeader(
              title: _profile!.fullName,
              subtitle: _profile!.role,
              icon: Icons.person,
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
            if (_profile!.adminDetails != null) ...[
              _buildAdminCard(),
              const SizedBox(height: 16),
            ],
            if (_profile!.teacherDetails != null) ...[
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
          ],
        ),
      ),
    );
  }

  Widget _buildCommonInfoCard() {
    return SharedProfileCard(
      children: [
        const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Username', value: _profile!.username),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Email', value: _profile!.email ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Phone', value: _profile!.phone ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Department', value: _profile!.department ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Status', value: _profile!.accountStatus ?? 'Not Available'),
      ],
    );
  }

  Widget _buildSuperAdminCard() {
    final stats = _profile!.superAdminDetails!;
    return SharedProfileCard(
      children: [
        const Text('System Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Total Departments', value: stats.totalDepartments.toString()),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Total Students', value: stats.totalStudents.toString()),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Total Teachers', value: stats.totalTeachers.toString()),
      ],
    );
  }

  Widget _buildAdminCard() {
    final stats = _profile!.adminDetails!;
    return SharedProfileCard(
      children: [
        const Text('Academic Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Assigned Year', value: stats.academicYear ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Total Students', value: stats.totalStudentsInYear.toString()),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Total Groups', value: stats.totalGroups.toString()),
      ],
    );
  }

  Widget _buildTeacherCard() {
    final stats = _profile!.teacherDetails!;
    return SharedProfileCard(
      children: [
        const Text('Teacher Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Employee ID', value: stats.employeeId ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Total Students', value: stats.totalStudents.toString()),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Attendance Taken', value: stats.attendanceTakenCount.toString()),
      ],
    );
  }

  Widget _buildStudentCard() {
    final stats = _profile!.studentDetails!;
    
    String leadershipRole = 'Member';
    if (stats.isCaptain) leadershipRole = 'Captain';
    else if (stats.isViceCaptain) leadershipRole = 'Vice Captain';

    return SharedProfileCard(
      children: [
        const Text('Academic Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Register Number', value: stats.registerNumber ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Academic Year', value: stats.academicYear ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Section', value: stats.section ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Leadership Role', value: leadershipRole),
        const SizedBox(height: 16),
        const Text('Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Current XP', value: stats.currentXp.toString()),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Attendance', value: '${stats.attendancePercentage}%'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Rank', value: stats.rank.toString()),
      ],
    );
  }

  Widget _buildCcCard() {
    final stats = _profile!.ccDetails!;
    return SharedProfileCard(
      children: [
        const Text('Class Coordinator Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Section', value: stats.section ?? 'Not Available'),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Assigned Year', value: stats.academicYear ?? 'Not Available'),
      ],
    );
  }

  Widget _buildHodCard() {
    final stats = _profile!.hodDetails!;
    return SharedProfileCard(
      children: [
        const Text('HOD Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        SharedProfileRow(label: 'Total Faculty', value: stats.totalFaculty.toString()),
        const SizedBox(height: 8),
        SharedProfileRow(label: 'Total Students', value: stats.totalStudents.toString()),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
          },
          icon: const Icon(Icons.lock),
          label: const Text('Change Password'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.studentPrimary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
