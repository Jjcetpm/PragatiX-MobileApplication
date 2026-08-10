import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/utils/export_utils.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/attendance/models/admin_attendance_summary.dart';
import 'package:pragatix/features/attendance/services/attendance_service.dart';
import 'package:pragatix/features/teacher/pages/department_students_page.dart';
import 'package:pragatix/features/teacher/pages/department_teachers_page.dart';
import 'package:pragatix/features/teacher/services/hod_analytics_service.dart';

class HodPerformanceTab extends StatefulWidget {
  const HodPerformanceTab({super.key});

  @override
  State<HodPerformanceTab> createState() => _HodPerformanceTabState();
}

class _HodPerformanceTabState extends State<HodPerformanceTab> with SingleTickerProviderStateMixin {
  final HodAnalyticsService _service = HodAnalyticsService();
  final AttendanceService _attendanceService = AttendanceService();

  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedYear = 'All Years';
  List<String> _availableYears = [
    'All Years',
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  late TabController _tabController;

  // Attendance Matrix State
  DateTime _matrixSelectedDate = DateTime.now();
  int? _matrixYearId;
  int? _matrixSectionId;
  List<dynamic> _lookupYears = [];
  List<dynamic> _lookupSections = [];
  AdminAttendanceSummary? _attendanceSummary;
  bool _isLoadingMatrix = false;
  bool _isMatrixHoliday = false;
  String _matrixSearchQuery = '';
  final TextEditingController _matrixSearchController = TextEditingController();

  // Discipline Filter State
  String _penaltySearchQuery = '';
  final TextEditingController _penaltySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchDashboard();
    _loadMatrixLookups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matrixSearchController.dispose();
    _penaltySearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        throw Exception('User is not authenticated.');
      }

      final data = await _service.getHodDashboard(
        year: _selectedYear == 'All Years' ? null : _selectedYear,
        token: token,
      );

      if (mounted) {
        setState(() {
          _dashboardData = data;
          if (data['availableYears'] != null) {
            _availableYears = List<String>.from(data['availableYears']);
          }
          if (data['selectedYear'] != null) {
            _selectedYear = data['selectedYear'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMatrixLookups() async {
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final headers = {'Authorization': 'Bearer $token'};
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _lookupYears = list;
            if (_lookupYears.isNotEmpty && _matrixYearId == null) {
              _matrixYearId = _lookupYears.first['id'];
            }
          });
          _loadDepartmentSections();
        }
      }
    } catch (e) {
      debugPrint('Error loading lookup years: $e');
    }
  }

  Future<void> _loadDepartmentSections() async {
    final deptId = _getDepartmentId();
    if (deptId == null) return;

    try {
      final token = getIt<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections?departmentId=$deptId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _lookupSections = decoded['data'] ?? [];
          _matrixSectionId = null;
        });
        _fetchMatrixAttendance();
      }
    } catch (e) {
      debugPrint('Error loading dept sections: $e');
    }
  }

  Future<void> _fetchMatrixAttendance() async {
    if (_matrixYearId == null) return;
    final deptId = _getDepartmentId();

    setState(() {
      _isLoadingMatrix = true;
      _isMatrixHoliday = false;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_matrixSelectedDate);
      final summary = await _attendanceService.getAdminSummary(
        dateStr,
        _matrixYearId!,
        deptId,
        sectionId: _matrixSectionId,
      );
      if (mounted) {
        setState(() {
          _attendanceSummary = summary;
          _isLoadingMatrix = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Holiday')) {
          setState(() {
            _attendanceSummary = null;
            _isMatrixHoliday = true;
            _isLoadingMatrix = false;
          });
        } else {
          setState(() {
            _isLoadingMatrix = false;
          });
        }
      }
    }
  }

  Future<void> _exportMatrixExcel() async {
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final deptId = _getDepartmentId();
      String yearNo = '';
      if (_lookupYears.isNotEmpty) {
        final yObj = _lookupYears.firstWhere((y) => y['id'] == _matrixYearId, orElse: () => null);
        if (yObj != null) {
          yearNo = yObj['yearNo']?.toString() ?? yObj['yearName']?.toString() ?? '';
        }
      }
      final dateStr = DateFormat('yyyy-MM-dd').format(_matrixSelectedDate);
      String url = '${ApiConfig.baseUrl}/api/v1/analytics/attendance/export?yearNo=$yearNo&startDate=$dateStr&endDate=$dateStr';
      if (deptId != null) url += '&departmentId=$deptId';
      if (_matrixSectionId != null) url += '&sectionId=$_matrixSectionId';

      await ExportUtils.downloadAndOpenExcel(context, url, token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting attendance: $e')),
        );
      }
    }
  }

  int? _getDepartmentId() {
    if (_dashboardData != null && _dashboardData!['department'] != null) {
      final dept = _dashboardData!['department'];
      if (dept is Map && dept['id'] != null) {
        return int.tryParse(dept['id'].toString());
      }
    }
    final user = getIt<AuthProvider>().currentUser;
    final dept = user?['department'];
    if (dept is Map && dept['id'] != null) {
      return int.tryParse(dept['id'].toString());
    }
    return null;
  }

  String _getDepartmentName() {
    if (_dashboardData != null && _dashboardData!['department'] != null) {
      final dept = _dashboardData!['department'];
      if (dept is Map && dept['name'] != null) {
        return dept['name'].toString();
      }
    }
    final user = getIt<AuthProvider>().currentUser;
    final dept = user?['department'];
    if (dept is Map && dept['name'] != null) {
      return dept['name'].toString();
    }
    return 'Department';
  }

  String _getDepartmentCode() {
    if (_dashboardData != null && _dashboardData!['department'] != null) {
      final dept = _dashboardData!['department'];
      if (dept is Map && dept['code'] != null) {
        return dept['code'].toString();
      }
    }
    return 'DEPT';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF38BDF8)),
              SizedBox(height: 16),
              Text(
                'Loading Department Analytics...',
                style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Unable to Load Analytics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchDashboard,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final overview = _dashboardData?['overview'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchDashboard();
            await _fetchMatrixAttendance();
          },
          color: const Color(0xFF38BDF8),
          backgroundColor: const Color(0xFF1E293B),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildOverviewCards(overview),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: const Color(0xFF38BDF8),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF38BDF8),
                      unselectedLabelColor: const Color(0xFF94A3B8),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Attendance', icon: Icon(Icons.calendar_today_outlined, size: 18)),
                        Tab(text: 'XP Analytics', icon: Icon(Icons.bolt_outlined, size: 18)),
                        Tab(text: 'Discipline', icon: Icon(Icons.shield_outlined, size: 18)),
                        Tab(text: 'Leaderboard', icon: Icon(Icons.emoji_events_outlined, size: 18)),
                        Tab(text: 'Sections', icon: Icon(Icons.domain_outlined, size: 18)),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceTab(),
                _buildXpTab(),
                _buildDisciplineTab(),
                _buildLeaderboardTab(),
                _buildSectionComparisonTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER CARD
  // ==========================================
  Widget _buildHeaderCard() {
    final deptName = _getDepartmentName();
    final deptCode = _getDepartmentCode();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$deptName Analytics',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'HOD Dashboard • Dept Code: $deptCode',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 12),

              // Study Year Filter Bar
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      const Text(
                        'Study Year:',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF38BDF8), size: 20),
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                        items: _availableYears.map((y) {
                          return DropdownMenuItem<String>(
                            value: y,
                            child: Text(y),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _selectedYear) {
                            setState(() => _selectedYear = val);
                            _fetchDashboard();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // OVERVIEW CARDS (WITH CLICK ACTIONS & SCORE CLAMP <= 100)
  // ==========================================
  Widget _buildOverviewCards(Map<String, dynamic> overview) {
    final totalStudents = (overview['totalStudents'] ?? 0) as int;
    final totalTeachers = (overview['totalTeachers'] ?? 0) as int;
    final totalSections = (overview['totalSections'] ?? 0) as int;
    final avgXp = (overview['avgXp'] ?? 0) as num;

    // Strict clamping to 100 max
    final rawScore = ((overview['avgDisciplineScore'] ?? 100) as num).toDouble();
    final avgDisciplineScore = rawScore.clamp(0.0, 100.0);

    final deptId = _getDepartmentId();
    final deptName = _getDepartmentName();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth > 600)
            ? (constraints.maxWidth - 24) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // 1. Total Students Card (Clickable)
            _buildInteractiveStatCard(
              width: cardWidth,
              title: 'Total Students',
              value: '$totalStudents',
              subtitle: 'Tap to view list →',
              icon: Icons.people_alt_outlined,
              iconColor: const Color(0xFF38BDF8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepartmentStudentListPage(
                      departmentId: deptId,
                      departmentName: deptName,
                      initialYear: _selectedYear,
                    ),
                  ),
                );
              },
            ),

            // 2. Total Teachers Card (Clickable)
            _buildInteractiveStatCard(
              width: cardWidth,
              title: 'Total Teachers',
              value: '$totalTeachers',
              subtitle: 'Tap to view list →',
              icon: Icons.person_pin_outlined,
              iconColor: const Color(0xFF818CF8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepartmentTeacherListPage(
                      departmentId: deptId,
                      departmentName: deptName,
                    ),
                  ),
                );
              },
            ),

            // 3. Discipline Score Card (Clamped <= 100)
            _buildDisciplineScoreCard(
              width: cardWidth,
              score: avgDisciplineScore,
            ),

            // 4. Avg XP Card
            _buildStandardStatCard(
              width: cardWidth,
              title: 'Avg Student XP',
              value: '${avgXp.round()} XP',
              subtitle: '$totalSections Sections',
              icon: Icons.bolt_outlined,
              iconColor: const Color(0xFFF59E0B),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInteractiveStatCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: iconColor.withOpacity(0.7), size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplineScoreCard({
    required double width,
    required double score,
  }) {
    Color scoreColor;
    if (score >= 85) {
      scoreColor = const Color(0xFF10B981);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B);
    } else {
      scoreColor = const Color(0xFFEF4444);
    }

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.verified_user_outlined, color: scoreColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Max 100',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scoreColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${score.toStringAsFixed(1)}/100',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: scoreColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const Text(
            'Avg Discipline Score',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardStatCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: ATTENDANCE TAB (OVERVIEW & MATRIX, NO HEATMAP)
  // ==========================================
  Widget _buildAttendanceTab() {
    final attData = _dashboardData?['attendanceAnalytics'] as Map<String, dynamic>? ?? {};
    final overallPercentage = ((attData['overallPercentage'] ?? 0.0) as num).toDouble();
    final totalRecords = (attData['totalRecords'] ?? 0) as int;
    final presentCount = (attData['presentCount'] ?? 0) as int;
    final partialAbsentCount = (attData['partialAbsentCount'] ?? 0) as int;
    final fullAbsentCount = (attData['fullAbsentCount'] ?? 0) as int;

    final sectionAtt = (attData['sectionAttendance'] as List<dynamic>?) ?? [];
    final dailyTrend = (attData['dailyTrend'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Metric Cards
          _buildAttendanceOverviewCards(
            overallPercentage,
            totalRecords,
            presentCount,
            partialAbsentCount,
            fullAbsentCount,
          ),
          const SizedBox(height: 20),

          // Daily Trend Chart
          if (dailyTrend.isNotEmpty) ...[
            _buildDailyAttendanceTrendCard(dailyTrend),
            const SizedBox(height: 20),
          ],

          // Section Breakdown
          if (sectionAtt.isNotEmpty) ...[
            _buildSectionAttendanceCards(sectionAtt),
            const SizedBox(height: 24),
          ],

          // ==========================================
          // DETAILED ATTENDANCE MATRIX SECTION
          // ==========================================
          _buildDetailedAttendanceMatrixSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAttendanceOverviewCards(
    double overallPercentage,
    int total,
    int present,
    int partialAbsent,
    int fullAbsent,
  ) {
    Color pctColor = overallPercentage >= 85
        ? const Color(0xFF10B981)
        : (overallPercentage >= 75 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final cardWidth = isNarrow ? (constraints.maxWidth - 10) / 2 : (constraints.maxWidth - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Overall %
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Attendance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${overallPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: pctColor),
                  ),
                  const SizedBox(height: 4),
                  Text('$total Records', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),

            // Present Count
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Full Present', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '$present',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Complete Day', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),

            // Absent / Partial Count
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Absences', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$fullAbsent',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                      const Text(' Full', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      const SizedBox(width: 6),
                      Text(
                        '$partialAbsent',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      ),
                      const Text(' Part', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Full / Partial', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyAttendanceTrendCard(List<dynamic> trend) {
    List<FlSpot> spots = [];
    List<String> labels = [];

    for (int i = 0; i < trend.length; i++) {
      final item = trend[i] as Map<String, dynamic>;
      final rate = ((item['attendanceRate'] ?? item['percentage'] ?? 0.0) as num).toDouble();
      spots.add(FlSpot(i.toDouble(), rate));
      labels.add((item['date'] ?? item['day'] ?? '').toString());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Attendance Trend (Recent Days)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF334155), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        if (val % 25 == 0) {
                          return Text(
                            '${val.toInt()}%',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        int idx = val.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          final l = labels[idx];
                          final short = l.length > 5 ? l.substring(5) : l;
                          return Text(short, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF38BDF8),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF38BDF8).withOpacity(0.15),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionAttendanceCards(List<dynamic> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Section-wise Attendance Rates',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth > 500) ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: list.map((item) {
                final map = item as Map<String, dynamic>;
                final secName = map['sectionName']?.toString() ?? 'Sec';
                final rate = ((map['attendanceRate'] ?? map['percentage'] ?? 0.0) as num).toDouble();
                final stuCount = (map['studentCount'] ?? 0) as int;

                Color color = rate >= 85
                    ? const Color(0xFF10B981)
                    : (rate >= 75 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Sec $secName',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$stuCount Students',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '${rate.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // DETAILED ATTENDANCE MATRIX (PERIOD-WISE)
  // ==========================================
  Widget _buildDetailedAttendanceMatrixSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Export
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Attendance History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Period-wise student attendance log',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportMatrixExcel,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 14),

          // Filters (Year, Section, Date)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Year Filter
              if (_lookupYears.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _matrixYearId,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 18),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      items: _lookupYears.map((y) {
                        return DropdownMenuItem<int>(
                          value: y['id'] as int,
                          child: Text(y['yearName']?.toString() ?? 'Year ${y['id']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _matrixYearId = val);
                          _fetchMatrixAttendance();
                        }
                      },
                    ),
                  ),
                ),

              // Section Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _matrixSectionId,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 18),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All Sections')),
                      ..._lookupSections.map((s) {
                        return DropdownMenuItem<int?>(
                          value: s['id'] as int,
                          child: Text('Section ${s['sectionName']}'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _matrixSectionId = val);
                      _fetchMatrixAttendance();
                    },
                  ),
                ),
              ),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _matrixSelectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _matrixSelectedDate = picked);
                    _fetchMatrixAttendance();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy').format(_matrixSelectedDate),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _matrixSearchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search student in daily matrix...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
            onChanged: (val) => setState(() => _matrixSearchQuery = val),
          ),
          const SizedBox(height: 12),

          // Attendance Matrix Table
          if (_isLoadingMatrix)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
            )
          else if (_isMatrixHoliday)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.beach_access_rounded, color: Color(0xFFF59E0B), size: 36),
                  SizedBox(height: 8),
                  Text('Selected date is marked as Holiday', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else if (_attendanceSummary == null || _attendanceSummary!.students.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('No attendance records found for this date/section', style: TextStyle(color: Color(0xFF94A3B8))),
            )
          else
            _buildMatrixTable(),
        ],
      ),
    );
  }

  Widget _buildMatrixTable() {
    final filtered = _attendanceSummary!.students.where((s) {
      if (_matrixSearchQuery.trim().isEmpty) return true;
      final q = _matrixSearchQuery.toLowerCase();
      return s.studentName.toLowerCase().contains(q) || s.registerNumber.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
        dataRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
        horizontalMargin: 12,
        columnSpacing: 16,
        headingTextStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12),
        dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Reg No')),
          DataColumn(label: Text('P1')),
          DataColumn(label: Text('P2')),
          DataColumn(label: Text('P3')),
          DataColumn(label: Text('P4')),
          DataColumn(label: Text('P5')),
          DataColumn(label: Text('P6')),
          DataColumn(label: Text('P7')),
          DataColumn(label: Text('P8')),
        ],
        rows: List.generate(filtered.length, (idx) {
          final s = filtered[idx];
          return DataRow(
            cells: [
              DataCell(Text('${idx + 1}', style: const TextStyle(color: Color(0xFF64748B)))),
              DataCell(Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(s.registerNumber, style: const TextStyle(color: Color(0xFF94A3B8)))),
              for (int p = 1; p <= 8; p++)
                DataCell(_buildPeriodBadge(s.periodStatuses[p] ?? '-')),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPeriodBadge(String status) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    if (label == 'P' || label == 'PRESENT') {
      bg = const Color(0xFF10B981).withOpacity(0.15);
      fg = const Color(0xFF10B981);
      label = 'P';
    } else if (label == 'A' || label == 'ABSENT') {
      bg = const Color(0xFFEF4444).withOpacity(0.15);
      fg = const Color(0xFFEF4444);
      label = 'A';
    } else if (label == 'OD' || label == 'ON DUTY') {
      bg = const Color(0xFF38BDF8).withOpacity(0.15);
      fg = const Color(0xFF38BDF8);
      label = 'OD';
    } else if (label == 'L' || label == 'LEAVE') {
      bg = const Color(0xFFF59E0B).withOpacity(0.15);
      fg = const Color(0xFFF59E0B);
      label = 'L';
    } else {
      bg = const Color(0xFF334155);
      fg = const Color(0xFF94A3B8);
      label = '-';
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: XP ANALYTICS TAB
  // ==========================================
  Widget _buildXpTab() {
    final xpData = _dashboardData?['xpAnalytics'] as Map<String, dynamic>? ?? {};
    final totalXp = (xpData['totalXp'] ?? 0) as num;
    final awardedXp = (xpData['awardedXp'] ?? 0) as num;
    final penaltyXp = (xpData['penaltyXp'] ?? 0) as num;
    final netXp = (xpData['netXp'] ?? (awardedXp - penaltyXp)) as num;

    final topGainers = (xpData['topGainers'] as List<dynamic>?) ?? [];
    final lowestStudents = (xpData['lowestStudents'] as List<dynamic>?) ?? [];
    final monthlyTrend = (xpData['monthlyTrend'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth > 500) ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Total XP',
                    value: '$totalXp XP',
                    subtitle: 'All Students',
                    icon: Icons.bolt,
                    iconColor: const Color(0xFF38BDF8),
                  ),
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Awarded XP',
                    value: '+$awardedXp XP',
                    subtitle: 'Positive rewards',
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF10B981),
                  ),
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Penalty XP',
                    value: '-$penaltyXp XP',
                    subtitle: 'Deductions',
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFEF4444),
                  ),
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Net XP Growth',
                    value: '$netXp XP',
                    subtitle: 'Awarded - Penalty',
                    icon: Icons.stacked_line_chart,
                    iconColor: const Color(0xFF818CF8),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Monthly XP Trend Chart
          if (monthlyTrend.isNotEmpty) ...[
            _buildMonthlyXpTrendCard(monthlyTrend),
            const SizedBox(height: 20),
          ],

          // Top Gainers & Lowest XP Lists
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStudentXpRankingList('Top 5 XP Achievers', topGainers, const Color(0xFF10B981), Icons.emoji_events)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStudentXpRankingList('Students Needing Focus', lowestStudents, const Color(0xFFF59E0B), Icons.warning_amber)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildStudentXpRankingList('Top 5 XP Achievers', topGainers, const Color(0xFF10B981), Icons.emoji_events),
                    const SizedBox(height: 16),
                    _buildStudentXpRankingList('Students Needing Focus', lowestStudents, const Color(0xFFF59E0B), Icons.warning_amber),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMonthlyXpTrendCard(List<dynamic> trend) {
    List<BarChartGroupData> barGroups = [];
    List<String> months = [];

    for (int i = 0; i < trend.length; i++) {
      final item = trend[i] as Map<String, dynamic>;
      final xp = ((item['totalXp'] ?? item['xp'] ?? 0) as num).toDouble();
      months.add((item['month'] ?? item['name'] ?? 'M$i').toString());
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: xp,
              color: const Color(0xFF38BDF8),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text('Monthly XP Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        int idx = val.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Text(months[idx], style: const TextStyle(color: Color(0xFF64748B), fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentXpRankingList(String title, List<dynamic> list, Color headerColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: headerColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No records available', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 12),
              itemBuilder: (context, idx) {
                final s = list[idx] as Map<String, dynamic>;
                final name = (s['fullName'] ?? s['name'] ?? 'Student').toString();
                final xp = (s['totalXp'] ?? s['xp'] ?? 0) as num;
                final sec = (s['section'] is Map ? s['section']['sectionName'] : s['section'])?.toString() ?? '-';

                return Row(
                  children: [
                    Text('#${idx + 1}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Sec $sec', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('$xp XP', style: TextStyle(color: headerColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: DISCIPLINE ANALYTICS TAB (NO YEAR COMPARISON, WITH RECENT PENALTIES)
  // ==========================================
  Widget _buildDisciplineTab() {
    final discData = _dashboardData?['disciplineAnalytics'] as Map<String, dynamic>? ?? {};
    final totalCases = (discData['totalCases'] ?? 0) as int;
    final positiveActivities = (discData['positiveActivities'] ?? 0) as int;
    final penalties = (discData['penalties'] ?? 0) as int;
    final warnings = (discData['warnings'] ?? 0) as int;

    final recentPenalties = (_dashboardData?['recentPenalties'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discipline Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth > 500) ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Total Logs',
                    value: '$totalCases',
                    subtitle: 'Recorded actions',
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF38BDF8),
                  ),
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Positive Activities',
                    value: '$positiveActivities',
                    subtitle: 'Rewards given',
                    icon: Icons.thumb_up_alt_outlined,
                    iconColor: const Color(0xFF10B981),
                  ),
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Penalties Issued',
                    value: '$penalties',
                    subtitle: 'Deductions',
                    icon: Icons.gavel_outlined,
                    iconColor: const Color(0xFFEF4444),
                  ),
                  _buildStandardStatCard(
                    width: cardWidth,
                    title: 'Warnings',
                    value: '$warnings',
                    subtitle: 'Advisories',
                    icon: Icons.warning_amber_outlined,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ==========================================
          // RECENT PENALTY HISTORY (NEWEST FIRST)
          // ==========================================
          _buildRecentPenaltiesSection(recentPenalties),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecentPenaltiesSection(List<dynamic> list) {
    final filtered = list.where((item) {
      if (item is! Map) return false;
      if (_penaltySearchQuery.trim().isEmpty) return true;
      final q = _penaltySearchQuery.toLowerCase();
      final name = (item['studentName'] ?? '').toString().toLowerCase();
      final reg = (item['registerNumber'] ?? '').toString().toLowerCase();
      final reason = (item['reason'] ?? '').toString().toLowerCase();
      return name.contains(q) || reg.contains(q) || reason.contains(q);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Penalty History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Latest disciplinary actions in this department',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${filtered.length} Penalties',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),

          // Search in Penalties
          TextField(
            controller: _penaltySearchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by student name, reg no or reason...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
            onChanged: (val) => setState(() => _penaltySearchQuery = val),
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    _penaltySearchQuery.isNotEmpty ? 'No penalties match your search' : 'No penalties recorded for this department',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filtered[index] as Map<String, dynamic>;
                return _buildPenaltyCard(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPenaltyCard(Map<String, dynamic> item) {
    final studentName = (item['studentName'] ?? 'Unknown Student').toString();
    final regNo = (item['registerNumber'] ?? '-').toString();
    final sec = (item['sectionName'] ?? '-').toString();
    final reason = (item['reason'] ?? 'Discipline violation').toString();
    final penaltyXp = (item['penaltyXp'] ?? 0) as num;
    final timestamp = (item['timestamp'] ?? '').toString();
    final addedBy = (item['addedBy'] ?? 'Admin / CC').toString();

    String formattedDate = timestamp;
    try {
      if (timestamp.isNotEmpty) {
        final parsed = DateTime.parse(timestamp);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('Reg: $regNo', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Sec $sec', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Penalty XP Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Text(
                  '-$penaltyXp XP',
                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Reason
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              reason,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),

          // Footer: Timestamp & Added By
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formattedDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              Text('By: $addedBy', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: LEADERBOARD TAB (CLAMPED SCORE <= 100)
  // ==========================================
  Widget _buildLeaderboardTab() {
    final topStudents = (_dashboardData?['topStudents'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department Leaderboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Top ranked students by XP & Discipline',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 16),
                    SizedBox(width: 4),
                    Text('Top 10', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (topStudents.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No students found in leaderboard', style: TextStyle(color: Color(0xFF64748B))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final s = topStudents[idx] as Map<String, dynamic>;
                return _buildLeaderboardCard(s, idx + 1);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> s, int rank) {
    final name = (s['fullName'] ?? s['name'] ?? 'Student').toString();
    final regNo = (s['regNo'] ?? s['registerNumber'] ?? '-').toString();
    final sec = (s['section'] is Map ? s['section']['sectionName'] : s['section'])?.toString() ?? '-';
    final xp = (s['totalXp'] ?? s['xp'] ?? 0) as num;

    // Strict clamping <= 100
    final rawScore = ((s['score'] ?? 100) as num).toDouble();
    final score = rawScore.clamp(0.0, 100.0);

    Color rankBg;
    Color rankFg;
    if (rank == 1) {
      rankBg = const Color(0xFFF59E0B); // Gold
      rankFg = Colors.black;
    } else if (rank == 2) {
      rankBg = const Color(0xFF94A3B8); // Silver
      rankFg = Colors.black;
    } else if (rank == 3) {
      rankBg = const Color(0xFFB45309); // Bronze
      rankFg = Colors.white;
    } else {
      rankBg = const Color(0xFF334155);
      rankFg = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(color: rankFg, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('Reg: $regNo • Sec $sec', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),

          // XP & Clamped Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xp XP',
                style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${score.toInt()}/100',
                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: SECTION COMPARISON TAB (SCORE CLAMP <= 100)
  // ==========================================
  Widget _buildSectionComparisonTab() {
    final secList = (_dashboardData?['sections'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Section Performance Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Comparative analysis of all sections in this department',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),

          if (secList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No sections found', style: TextStyle(color: Color(0xFF64748B))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: secList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final s = secList[idx] as Map<String, dynamic>;
                return _buildSectionCard(s);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> s) {
    final secName = (s['sectionName'] ?? s['name'] ?? 'Section').toString();
    final studentCount = (s['studentCount'] ?? 0) as int;
    final avgXp = ((s['avgXp'] ?? 0) as num).round();
    final attRate = ((s['attendanceRate'] ?? 0.0) as num).toDouble();

    // Strict clamping <= 100
    final rawScore = ((s['avgDisciplineScore'] ?? 100) as num).toDouble();
    final disciplineScore = rawScore.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Section $secName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$studentCount Students',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),

          // Stats in Section
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildSectionStatItem('Avg XP', '$avgXp XP', const Color(0xFFF59E0B)),
                  _buildSectionStatItem('Attendance', '${attRate.toStringAsFixed(1)}%', const Color(0xFF10B981)),
                  _buildSectionStatItem('Discipline Score', '${disciplineScore.toStringAsFixed(1)}/100', const Color(0xFF38BDF8)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// Sliver Persistent Header Delegate for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0F172A),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
