import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/admin/pages/students_tab.dart';
import 'package:pragatix/features/admin/pages/teachers_tab.dart';
import 'package:pragatix/features/admin/pages/departments_tab.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

import '../../leaderboard/pages/shared_leaderboard_page.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  // ── Dashboard stats ──────────────────────────────────────────────────────────
  int totalStudents = 0;
  int totalTeachers = 0;
  int totalDepartments = 0;
  int totalAlerts = 0;
  int pendingBadgeRequests = 0;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  // ── Stats ────────────────────────────────────────────────────────────────────

  Future<void> _fetchStats() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final stats = await getIt<AdminRepository>().getStats();
      if (!mounted) return;
      setState(() {
        totalStudents = stats['totalStudents'] ?? 0;
        totalTeachers = stats['teachersCount'] ?? 0;
        totalDepartments = stats['totalDepartments'] ?? 0;
        totalAlerts = stats['totalAlerts'] ?? 0;
        pendingBadgeRequests = stats['pendingBadgeRequests'] ?? 0;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching dashboard stats: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser ?? {};
    final List<dynamic> roles = currentUser['roles'] ?? [];
    final String? assignedYear = currentUser['academicYear'];

    final bool isSuperAdmin = roles.any((r) {
      final name = r is String ? r : (r as Map)['name']?.toString() ?? '';
      return name == 'ROLE_SUPER_ADMIN' || name == 'SUPER_ADMIN';
    });

    String titlePrefix = 'Admin';
    String welcomeText = 'System Admin';
    if (isSuperAdmin) {
      titlePrefix = 'Super Admin';
      welcomeText = 'Super Admin';
    } else if (assignedYear != null) {
      String cleanYear = assignedYear.replaceAll('_', ' ').toLowerCase();
      cleanYear = cleanYear
          .split(' ')
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join(' ');
      titlePrefix = '$cleanYear Admin';
      welcomeText = '$cleanYear Admin';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '$titlePrefix Overview',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                        Text(
                          'Welcome back, $welcomeText',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Here is a summary of the discipline system metrics.',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 20),

                        // ── Stat Cards Grid ───────────────────────────────────
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildStatCard(
                              title: 'Students',
                              count: totalStudents.toString(),
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFF4A90E2),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const StudentsTab())),
                            ),
                            _buildStatCard(
                              title: 'Teachers',
                              count: totalTeachers.toString(),
                              icon: Icons.school_rounded,
                              color: const Color(0xFF34A853),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const TeachersTab())),
                            ),
                            _buildStatCard(
                              title: 'Departments',
                              count: totalDepartments.toString(),
                              icon: Icons.account_balance_rounded,
                              color: const Color(0xFFFBBC05),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const DepartmentsTab())),
                            ),
                            _buildStatCard(
                              title: 'Leaderboard',
                              count: 'Top',
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFFE91E63),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SharedLeaderboardPage(
                                    title: 'Global Leaderboard',
                                    showFilters: true,
                                    showCurrentUserRank: false,
                                  ),
                                ),
                              ),
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

  // ── Stat Card ────────────────────────────────────────────────────────────────

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
                      color: color.withValues(alpha: 0.1),
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
