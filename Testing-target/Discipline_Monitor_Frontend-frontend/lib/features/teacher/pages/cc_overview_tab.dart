import 'package:flutter/material.dart';

// Import necessary dependencies

import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/badge/pages/cc_badge_requests_page.dart';
import 'package:pragatix/features/teacher/pages/performance_activities_tab.dart';
import 'package:pragatix/features/teacher/pages/students_tab.dart';
import 'package:pragatix/features/attendance/pages/teacher_attendance_tab.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';

class CCOverviewTab extends StatefulWidget {
  final List<String> subRoles;
  const CCOverviewTab({super.key, required this.subRoles});

  @override
  State<CCOverviewTab> createState() => _CCOverviewTabState();
}

class _CCOverviewTabState extends State<CCOverviewTab> {
  int totalActivities = 0;
  int totalStudents = 0;
  int totalAttendance = 0;
  int pendingBadgeRequests = 0;
  int pendingPenaltyRequests = 0;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final token = context.read<AuthProvider>().token;
      if (token == 'debug_token') {
        setState(() {
          totalActivities = 10;
          totalStudents = 120;
          totalAttendance = 95;
          pendingBadgeRequests = 5;
          pendingPenaltyRequests = 2;
          isLoading = false;
        });
        return;
      }

      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/cc/dashboard/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final stats = data['data'];
          setState(() {
            totalActivities = stats['totalActivities'] ?? 0;
            totalStudents = stats['totalStudents'] ?? 0;
            totalAttendance = stats['totalAttendance'] ?? 0;
            pendingBadgeRequests = stats['pendingBadgeRequests'] ?? 0;
            pendingPenaltyRequests = stats['pendingPenaltyRequests'] ?? 0;
            isLoading = false;
          });
          if (mounted) {
            context.read<PenaltyProvider>().setPendingCount(pendingPenaltyRequests);
          }
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'CC Overview',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchStats();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFFF1F5F9)],
            stops: [0.3, 0.3],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load dashboard data',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchStats,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to CC Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here is a summary of your class metrics.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 30),

                    // Stat Cards Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          title: 'Activities',
                          count: totalActivities.toString(),
                          icon: Icons.event_note_rounded,
                          color: const Color(0xFF4A90E2),
                          onTap: () {}, // Handled by bottom nav normally
                        ),
                        _buildStatCard(
                          title: 'Students',
                          count: totalStudents.toString(),
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF34A853),
                          onTap: () {},
                        ),
                        _buildStatCard(
                          title: 'Attendance',
                          count: '$totalAttendance%', // Mocked as %
                          icon: Icons.co_present_rounded,
                          color: const Color(0xFFFBBC05),
                          onTap: () {},
                        ),
                        _buildStatCard(
                          title: 'Badge Requests',
                          count: pendingBadgeRequests.toString(),
                          icon: Icons.badge_rounded,
                          color: const Color(0xFF9C27B0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CCBadgeRequestsPage(),
                            ),
                          ).then((_) => _fetchStats()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
