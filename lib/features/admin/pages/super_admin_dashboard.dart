import 'package:flutter/material.dart';
import 'package:pragatix/features/admin/pages/overview_tab.dart';
import 'package:pragatix/features/admin/pages/activity_tab.dart';
import 'package:pragatix/features/activity/pages/year_selection_page.dart';
import 'package:pragatix/features/profile/pages/profile_page.dart';
import 'package:pragatix/features/team/pages/team_group_management_tab.dart';
import 'package:pragatix/features/attendance/pages/admin_attendance_tab.dart';
import 'package:pragatix/features/admin/pages/super_admin_management_tab.dart';
import 'package:pragatix/features/analytics/pages/analytics_tab.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';


import 'package:pragatix/features/banking/pages/admin_banking_dashboard_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const OverviewTab(),
      const YearSelectionPage(),
      const AdminAttendanceTab(),
      const TeamGroupManagementTab(),
      const SuperAdminManagementTab(),
      const AdminBankingDashboardPage(),
      const ProfilePage(),
    ];


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

          const BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_rounded),
            label: 'Admins',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_rounded),
            label: 'Banking',
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
