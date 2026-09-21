import 'package:flutter/material.dart';
import 'package:pragatix/features/attendance/pages/teacher_attendance_tab.dart';
import 'package:pragatix/features/attendance/pages/admin_attendance_tab.dart';

class TeacherAttendanceHubPage extends StatefulWidget {
  final List<String>? subRoles;
  const TeacherAttendanceHubPage({Key? key, this.subRoles}) : super(key: key);

  @override
  State<TeacherAttendanceHubPage> createState() => _TeacherAttendanceHubPageState();
}

class _TeacherAttendanceHubPageState extends State<TeacherAttendanceHubPage> {
  // 0: Mark Attendance, 1: History Matrix
  int _activeMode = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header & Mode Switcher ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Attendance Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mark student attendance & check daily history matrix',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Segmented Mode Switcher (Web Dual-Mode Matching) ─────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Option 1: Mark Attendance
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_activeMode != 0) {
                                setState(() => _activeMode = 0);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeMode == 0
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB)
                                              .withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 16,
                                    color: _activeMode == 0
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mark Attendance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _activeMode == 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: _activeMode == 0
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // Option 2: History Matrix
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_activeMode != 1) {
                                setState(() => _activeMode = 1);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeMode == 1
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB)
                                              .withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                    color: _activeMode == 1
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'History Matrix',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _activeMode == 1
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: _activeMode == 1
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Mode View Container ─────────────────────────────────────────────
            Expanded(
              child: _activeMode == 0
                  ? const TeacherAttendanceTab(hideAppBar: true)
                  : AdminAttendanceTab(
                      hideHeader: true,
                      subRoles: widget.subRoles,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
