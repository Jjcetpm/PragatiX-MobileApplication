import 'package:flutter/material.dart';
import 'package:pragatix/features/student/pages/dashboard_tab.dart';
import 'package:pragatix/features/student/pages/activities_tab.dart';
import 'package:pragatix/features/student/pages/point_review_tab.dart';
import 'package:pragatix/features/student/pages/levels_badges_tab.dart';
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

  void _goToHome() {
    if (mounted) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch attendance summary on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0284C7); // Sky Blue brand color
    const inactiveColor = Color(0xFF64748B);

    final List<Widget> screens = [
      const DashboardTab(),
      ActivitiesTab(onBack: _goToHome),
      PointReviewTab(onBack: _goToHome),
      StudentAttendanceTab(onBack: _goToHome),
      LevelsBadgesTab(onBack: _goToHome),
    ];

    return Scaffold(
      body: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentIndex != 0) {
            _goToHome();
          }
        },
        child: IndexedStack(
          index: _currentIndex.clamp(0, screens.length - 1),
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Home',
                  activeIcon: Icons.grid_view_rounded,
                  inactiveIcon: Icons.grid_view_outlined,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Activities',
                  activeIcon: Icons.checklist_rounded,
                  inactiveIcon: Icons.checklist_rounded,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Point Review',
                  activeIcon: Icons.insights_rounded,
                  inactiveIcon: Icons.insights_outlined,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Attendance',
                  activeIcon: Icons.calendar_month_rounded,
                  inactiveIcon: Icons.calendar_month_outlined,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  index: 4,
                  label: 'Rewards',
                  activeIcon: Icons.emoji_events_rounded,
                  inactiveIcon: Icons.emoji_events_outlined,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      splashColor: activeColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill container for active tab
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE0F2FE) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                size: 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

