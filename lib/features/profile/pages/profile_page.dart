import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';

import 'package:pragatix/features/profile/models/profile_response.dart';
import 'package:pragatix/features/profile/repository/profile_repository.dart';
import 'package:pragatix/shared/widgets/profile_header.dart';
import 'package:pragatix/shared/widgets/shared_profile_card.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';

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

    final String resolvedGender = _profile!.gender ?? _profile!.studentDetails?.gender ?? '';
    final bool isFemale = resolvedGender.trim().toLowerCase().startsWith('f');
    final String? avatarAsset = _profile!.studentDetails != null
        ? (isFemale ? 'assets/images/avatar_female.png' : 'assets/images/avatar_male.png')
        : null;

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
                icon: Icons.person,
                imageAsset: avatarAsset,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
        SharedProfileRow(label: 'Phone', value: _profile!.phone ?? 'Not Available'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSuperAdmin) ...[
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
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(
            'Logout',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
