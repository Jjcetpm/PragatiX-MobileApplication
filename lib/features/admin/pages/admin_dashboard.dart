import 'package:flutter/material.dart';
import 'package:pragatix/features/admin/pages/overview_tab.dart';
import 'package:pragatix/features/admin/pages/activity_tab.dart';
import 'package:pragatix/features/profile/pages/profile_page.dart';
import 'package:pragatix/features/team/pages/team_group_management_tab.dart';
import 'package:pragatix/features/attendance/pages/admin_attendance_tab.dart';
import 'package:pragatix/features/badge/pages/admin_badge_requests_page.dart';
import 'package:pragatix/features/analytics/pages/analytics_tab.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';


import 'package:pragatix/features/badge/providers/badge_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const OverviewTab(),
      const AdminActivityManagementPage(),
      const AdminAttendanceTab(),
      const TeamGroupManagementTab(),
      const AdminBadgeRequestsPage(),
      const ProfilePage(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      final role = context.read<AuthProvider>().role ?? 'ADMIN';
      if (token != null && token.isNotEmpty) {
        context.read<BadgeProvider>().fetchAdminCCBadgeRequests(token, role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFEA4335),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_rounded),
            label: 'Activity',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.co_present_rounded),
            label: 'Attendance',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Consumer<BadgeProvider>(
              builder: (context, badgeProvider, _) => Badge(
                isLabelVisible: badgeProvider.pendingAdminCCRequestsCount > 0,
                label: Text(
                  badgeProvider.pendingAdminCCRequestsCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFFEA4335),
                child: const Icon(Icons.workspace_premium),
              ),
            ),
            label: 'Requests',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
