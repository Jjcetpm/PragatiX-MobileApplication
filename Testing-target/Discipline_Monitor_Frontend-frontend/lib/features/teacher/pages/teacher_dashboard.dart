import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/features/teacher/pages/teacher_stage_list_page.dart';
import 'package:pragatix/features/teacher/pages/leaderboard_tab.dart';
import 'package:pragatix/features/profile/pages/profile_page.dart';
import 'package:pragatix/features/teacher/pages/hod_performance_tab.dart';
import 'package:pragatix/features/attendance/pages/teacher_attendance_tab.dart';
import 'package:pragatix/features/teacher/pages/teacher_activity_requests_tab.dart';

import 'package:pragatix/features/team/pages/team_group_management_tab.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';
import 'package:pragatix/features/activity/providers/activity_completion_provider.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  List<Widget> _screens = [];
  List<String> subRoles = [];
  bool isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  bool get _isCc => subRoles.any((r) {
        final clean = r.trim().toUpperCase();
        return clean == 'CC' || clean == 'CLASS_COORDINATOR' || clean == 'ROLE_CLASS_COORDINATOR';
      });

  bool get _isHod => subRoles.any((r) {
        final clean = r.trim().toUpperCase();
        return clean == 'HOD' || clean == 'ROLE_HOD';
      });

  bool get _canManageGroups => _isCc || _isHod;

  Future<void> _fetchProfile() async {
    if (context.read<AuthProvider>().token! == 'debug_token') {
      setState(() {
        subRoles = ['CC', 'HOD', 'PET', 'Discipline Commitee'];
        isProfileLoading = false;
        _initializeScreens();
      });
      return;
    }
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> subs = data['data']['subRoles'] ?? [];
          final List<dynamic> mainRoles = data['data']['roles'] ?? [];
          if (!mounted) return;
          setState(() {
            subRoles = [
              ...subs.map((e) => e.toString()),
              ...mainRoles.map((e) => e.toString()),
            ].toList();
            isProfileLoading = false;
            _initializeScreens();
          });
          if (_isCc) {
            context.read<PenaltyProvider>().fetchPendingCount();
          }
          context.read<ActivityCompletionProvider>().fetchPendingCount();
          return;
        }
      }
    } catch (e) {
      // Catch
    }
    if (!mounted) return;
    setState(() {
      isProfileLoading = false;
      _initializeScreens();
    });
  }

  void _initializeScreens() {
    setState(() {
      _screens = [
        TeacherStageListPage(subRoles: subRoles),
        const TeacherAttendanceTab(),
        const LeaderboardTab(),
        const TeacherActivityRequestsTab(),
        if (_canManageGroups) const TeamGroupManagementTab(),
        if (_isHod) const HodPerformanceTab(),
        const ProfilePage(),
      ];
      if (_currentIndex >= _screens.length) {
        _currentIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isProfileLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<BottomNavigationBarItem> barItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment_turned_in_rounded),
        label: 'Activities',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.co_present_rounded),
        label: 'Attendance',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.leaderboard_rounded),
        label: 'Leaderboard',
      ),
      BottomNavigationBarItem(
        icon: Consumer<ActivityCompletionProvider>(
          builder: (context, actCompletion, _) => Badge(
            isLabelVisible: actCompletion.pendingCount > 0,
            label: Text(
              actCompletion.pendingCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            backgroundColor: Colors.red,
            child: const Icon(Icons.mark_email_unread_rounded),
          ),
        ),
        label: 'Requests',
      ),
      if (_canManageGroups)
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups_rounded),
          label: 'Groups',
        ),
      if (_isHod)
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'HOD Report',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: _screens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < barItems.length ? _currentIndex : 0,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF11998e),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: barItems,
      ),
    );
  }
}
