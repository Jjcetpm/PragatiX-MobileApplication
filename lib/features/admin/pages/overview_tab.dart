import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/admin/pages/students_tab.dart';
import 'package:pragatix/features/admin/pages/teachers_tab.dart';
import 'package:pragatix/features/admin/pages/departments_tab.dart';
import 'package:pragatix/features/enrollment/pages/enrollment_admin_page.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

import '../../leaderboard/pages/shared_leaderboard_page.dart';
import '../../recycle_bin/screens/recycle_bin_screen.dart';
import '../../recycle_bin/services/recycle_bin_service.dart';
import 'package:pragatix/features/admin/pages/admin_levels_page.dart';
import 'package:pragatix/core/utils/error_handler.dart';

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
  int recycleBinCount = 0;
  bool isLoading = true;
  bool hasError = false;
  dynamic errorObject;

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
      errorObject = null;
    });
    try {
      final stats = await getIt<AdminRepository>().getStats();
      int rCount = 0;
      try {
        final auth = context.read<AuthProvider>();
        final items = await RecycleBinService(auth).getDeletedItems();
        rCount = items.length;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        totalStudents = stats['totalStudents'] ?? 0;
        totalTeachers = stats['teachersCount'] ?? 0;
        totalDepartments = stats['totalDepartments'] ?? 0;
        totalAlerts = stats['totalAlerts'] ?? 0;
        pendingBadgeRequests = stats['pendingBadgeRequests'] ?? 0;
        recycleBinCount = rCount;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching dashboard stats: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        hasError = true;
        errorObject = e;
        isLoading = false;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser ?? {};
    final dynamic rawRoles = currentUser['roles'];
    final List<dynamic> roles = rawRoles is List ? rawRoles : [];
    final dynamic rawYear = currentUser['academicYear'];
    final String? assignedYear = rawYear?.toString();

    final bool isSuperAdmin = roles.any((r) {
      if (r == null) return false;
      final name = r is String ? r : (r is Map ? (r['name'] ?? r['authority'] ?? '').toString() : '');
      return name == 'ROLE_SUPER_ADMIN' || name == 'SUPER_ADMIN';
    });

    String titlePrefix = 'Admin';
    String welcomeText = 'Super Admin';
    if (isSuperAdmin) {
      titlePrefix = 'Super Admin';
      welcomeText = 'Super Admin';
    } else if (assignedYear != null && assignedYear.trim().isNotEmpty && assignedYear != 'null') {
      String cleanYear = assignedYear.replaceAll('_', ' ').toLowerCase();
      cleanYear = cleanYear
          .split(' ')
          .where((s) => s.isNotEmpty)
          .map((s) => s[0].toUpperCase() + (s.length > 1 ? s.substring(1) : ''))
          .join(' ');
      titlePrefix = '$cleanYear Admin';
      welcomeText = '$cleanYear Admin';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FB),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.28, 0.40, 1.0],
            colors: [
              Color(0xFFDCE8F6),
              Color(0xFFE8EFF9),
              Color(0xFFF4F7FB),
              Color(0xFFF4F7FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Header ───────────────────────────────────────────────
              _buildHeader(titlePrefix),

              // ── Body Content ─────────────────────────────────────────────
              Expanded(
                child: isLoading
                    ? const Center(child: PragatiXLoader(fullScreen: false))
                    : hasError
                        ? _buildErrorView()
                        : RefreshIndicator(
                            onRefresh: _fetchStats,
                            color: const Color(0xFF2563EB),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Welcome Hero Banner with College Image ──
                                  _buildWelcomeBanner(welcomeText),
                                  const SizedBox(height: 22),

                                  // ── Metrics Section Header ───────────────
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'System Overview',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // ── Stat Cards Grid (2x2) ────────────────
                                  _buildStatsGrid(),
                                  const SizedBox(height: 14),

                                  // ── Wide Featured Leaderboard Card ───────
                                  _buildLeaderboardCard(),
                                  const SizedBox(height: 14),

                                  // ── Wide Featured Level Progression Card ──
                                  _buildLevelsCard(),
                                  const SizedBox(height: 28),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(String titlePrefix) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$titlePrefix Overview',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recycle Bin (Dynamic 3D Empty vs Full)
              _buildHeaderActionButton(
                customIcon: Image.asset(
                  recycleBinCount > 0
                      ? 'assets/images/recycle_bin_full.png'
                      : 'assets/images/recycle_bin_empty.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFF1E293B),
                  ),
                ),
                tooltip: recycleBinCount > 0
                    ? 'Recycle Bin ($recycleBinCount items)'
                    : 'Recycle Bin (Empty)',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecycleBinScreen(),
                    ),
                  );
                  _fetchStats();
                },
              ),
              const SizedBox(width: 8),

              // Refresh Button
              _buildHeaderActionButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onPressed: () {
                  setState(() => isLoading = true);
                  _fetchStats();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    IconData? icon,
    Widget? customIcon,
    required String tooltip,
    required VoidCallback onPressed,
    Color iconColor = const Color(0xFF1E293B),
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: customIcon ?? Icon(icon, size: 20, color: iconColor),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  // ── Welcome Hero Banner with College Background ──────────────────────────────

  Widget _buildWelcomeBanner(String welcomeText) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Dark base background
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 165),
              color: const Color(0xFF0D1522),
            ),

            // College Image positioned on right side
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.58,
              child: Image.asset(
                'assets/images/college_banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/college_campus.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1E293B),
                    ),
                  );
                },
              ),
            ),

            // Horizontal gradient overlay from solid dark slate on left to soft fade over image
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.38, 0.65, 1.0],
                    colors: [
                      const Color(0xFF0D1522),
                      const Color(0xFF0D1522),
                      const Color(0xFF0D1522).withOpacity(0.60),
                      const Color(0xFF0D1522).withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),

            // Subtle top/bottom vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0D1522).withOpacity(0.25),
                      Colors.transparent,
                      const Color(0xFF0D1522).withOpacity(0.50),
                    ],
                  ),
                ),
              ),
            ),

            // Sleek card border
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            // Banner Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.72),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          welcomeText,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '👋',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.54,
                    ),
                    child: Text(
                      "Here's a quick overview of your institution's performance.",
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.white.withOpacity(0.70),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // College Tag Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF93C5FD),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'JJCET Campus',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.90),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat Cards Grid (2x2) ────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: [
        _buildStatCard(
          title: 'Students',
          count: totalStudents.toString(),
          icon: Icons.groups_rounded,
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentsTab()),
          ),
        ),
        _buildStatCard(
          title: 'Teachers',
          count: totalTeachers.toString(),
          icon: Icons.school_rounded,
          gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeachersTab()),
          ),
        ),
        _buildStatCard(
          title: 'Departments',
          count: totalDepartments.toString(),
          icon: Icons.account_balance_rounded,
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DepartmentsTab()),
          ),
        ),
        _buildStatCard(
          title: 'Enrollment',
          count: 'Manage',
          icon: Icons.how_to_reg_rounded,
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnrollmentAdminPage()),
          ),
        ),
      ],
    );
  }

  // ── Single Stat Card ─────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: gradientColors[0].withOpacity(0.08),
          highlightColor: gradientColors[0].withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wide Featured Leaderboard Card ───────────────────────────────────────────

  Widget _buildLeaderboardCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFEC4899).withOpacity(0.08),
          highlightColor: const Color(0xFFEC4899).withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Leaderboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View top ranking students and achievements',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wide Featured Level Progression Management Card ─────────────────────────

  Widget _buildLevelsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminLevelsPage(),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFF6366F1).withOpacity(0.08),
          highlightColor: const Color(0xFF6366F1).withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level Progression',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage year-wise levels, XP milestones & unlocks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error View ───────────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    final classification = ErrorHandler.classify(errorObject);
    final isMaintenance = classification.isMaintenance;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMaintenance ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMaintenance ? Icons.construction_rounded : Icons.wifi_off_rounded,
                color: isMaintenance ? const Color(0xFFD97706) : const Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              classification.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              classification.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchStats,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


