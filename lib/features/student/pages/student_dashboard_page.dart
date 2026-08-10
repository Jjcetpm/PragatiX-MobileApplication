import 'package:flutter/material.dart';
import 'package:pragatix/features/student/pages/dashboard_tab.dart';
import 'package:pragatix/features/student/pages/point_review_tab.dart';
import 'package:pragatix/features/student/pages/leaderboard_tab.dart';
import 'package:pragatix/features/student/pages/activities_tab.dart';
import 'package:pragatix/features/student/pages/levels_badges_tab.dart';
import 'package:pragatix/features/profile/pages/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/attendance/pages/student_attendance_tab.dart';


class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardTab(),
      const PointReviewTab(),
      const LeaderboardTab(),
      const ActivitiesTab(),
      const StudentAttendanceTab(),
      const LevelsBadgesTab(),
      const ProfilePage(),
    ];

    // Fetch attendance summary on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF4F46E5); // Student portal brand color: Indigo

    final List<BottomNavigationBarItem> barItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history_edu_rounded),
        label: 'Point Review',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.leaderboard_rounded),
        label: 'Leaderboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_activity_rounded),
        label: 'Activities',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.co_present_rounded),
        label: 'Attendance',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.military_tech_rounded),
        label: 'Levels & Badges',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: activeColor,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        items: barItems,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
