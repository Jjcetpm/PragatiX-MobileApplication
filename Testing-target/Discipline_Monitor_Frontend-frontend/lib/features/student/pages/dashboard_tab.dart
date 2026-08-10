import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/attendance/widgets/fire_streak_icon.dart';
import 'package:pragatix/features/student/pages/activity_streaks_page.dart';
import 'package:pragatix/features/captain/pages/student_group_tab.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool isLoading = true;
  String studentName = '';
  String regNo = '';
  String department = '';
  String section = '';
  String year = '';
  int score = 95; // Discipline points
  int rank = 1;
  int currentStage = 1;
  bool isCaptain = false;
  bool isViceCaptain = false;
  bool isMember = false;
  String teamName = '';
  Map<String, dynamic>? activeStageDetails;
  Map<String, dynamic>? teamDetailsData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (context.read<AuthProvider>().token! == 'debug_token') {
      setState(() => isLoading = false);
      return;
    }

    try {
      await _fetchProfileData(); // This populates regNo

      if (regNo.isNotEmpty) {
        debugPrint('Student ID loaded: $regNo');
        debugPrint('Register Number: $regNo');
        debugPrint('Department: $department');
        debugPrint('Year: $year');
        debugPrint('Section: $section');
        debugPrint('Calling XP Summary with: $regNo');
        debugPrint('Calling Team API with: $regNo');
        debugPrint('Calling Rank API with: $regNo');

        final token = context.read<AuthProvider>().token!;
        final xpProv = Provider.of<XpProvider>(context, listen: false);

        await Future.wait([
          _fetchTeamDetails(),
          _fetchStages(),
          xpProv.fetchSummary(regNo, token),
          xpProv.fetchHistory(regNo, token),
          xpProv.fetchStreaks(regNo, token),
          xpProv.fetchActivityStreaks(token),
          xpProv.fetchProgression(token),
        ]);
      } else {
        debugPrint('Error: regNo is empty after _fetchProfileData');
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStages() async {
    if (context.read<AuthProvider>().token! == 'debug_token') return;
    try {
      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/stages'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> stagesList = data['data'] ?? [];
          final active = stagesList.firstWhere(
            (s) => s['isActive'] == true || s['active'] == true,
            orElse: () => null,
          );
          if (active != null) {
            setState(() {
              activeStageDetails = active;
              currentStage = active['displayOrder'] ?? 1;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTeamDetails() async {
    if (context.read<AuthProvider>().token! == 'debug_token') return;
    try {
      final response = await getIt<TeamProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/my-team/details'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (mounted) {
            setState(() {
              teamDetailsData = data['data'];
            });
          }
        } else {
          if (mounted) setState(() => teamDetailsData = null);
        }
      } else {
        if (mounted) setState(() => teamDetailsData = null);
      }
    } catch (_) {
      if (mounted) setState(() => teamDetailsData = null);
    }
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final resData = data['data'];
          setState(() {
            studentName = resData['fullName'] ?? '';
            regNo = resData['username'] ?? '';
            section = resData['section'] ?? '';
            year = resData['year'] ?? '';
            department = resData['department'] ?? '';
            score = resData['score'] ?? 0;
            rank = resData['rank'] != null && resData['rank'] > 0
                ? resData['rank']
                : 1;
            isCaptain = resData['isCaptain'] == true;
            isViceCaptain = resData['isViceCaptain'] == true;
            isMember = resData['isMember'] == true;
            teamName = resData['teamName'] ?? '';
            if (resData['stage'] != null && activeStageDetails == null) {
              currentStage = resData['stage'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);

    if (isLoading || xpProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: PragatiXLoader(fullScreen: false, message: 'Loading Dashboard...'),
        ),
      );
    }

    final totalXp = xpProvider.totalXp;
    final progression = xpProvider.progression;
    final int levelNum = progression != null
        ? (progression['currentLevel'] ?? 1)
        : 1;
    final String levelTitle = progression != null
        ? (progression['currentLevelName'] ?? 'Explorer')
        : 'Explorer';
    final int minXp = progression != null
        ? (progression['currentLevelMinXp'] ?? 0)
        : 0;
    final int maxXp = progression != null
        ? (progression['currentLevelMaxXp'] ?? 100)
        : 100;
    final double levelProgress = progression != null
        ? ((progression['progressPercentage'] ?? 0.0) / 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Student Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          Consumer<XpProvider>(
            builder: (context, provider, child) {
              int maxStreak = 0;
              for (var streak in provider.streaks) {
                final int current = streak['currentStreak'] ?? 0;
                final bool isBroken = streak['isBroken'] ?? false;
                if (!isBroken && current > maxStreak) {
                  maxStreak = current;
                }
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivityStreaksPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: FireStreakIcon(streakCount: maxStreak),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.groups_rounded, color: Colors.white),
            tooltip: 'My Group',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentGroupTab(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchProfileData();
          await _fetchStages();
          await _fetchTeamDetails();
          if (!mounted) return;
          final xpProv = Provider.of<XpProvider>(context, listen: false);
          if (!mounted) return;
          await xpProv.fetchSummary(regNo, context.read<AuthProvider>().token!);
          if (!mounted) return;
          await xpProv.fetchHistory(regNo, context.read<AuthProvider>().token!);
          if (!mounted) return;
          await xpProv.fetchStreaks(regNo, context.read<AuthProvider>().token!);
          if (!mounted) return;
          await xpProv.fetchActivityStreaks(context.read<AuthProvider>().token!);
          if (!mounted) return;
          await xpProv.fetchProgression(context.read<AuthProvider>().token!);
        },
        color: const Color(0xFF4F46E5),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Text
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCaptain) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'CAPTAIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isViceCaptain) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'VICE CAPTAIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isMember) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'MEMBER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Discipline Score card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discipline Score',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$totalXp Points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Department',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  department,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Section & Year',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (year.isNotEmpty && section.isNotEmpty)
                                Text(
                                  '$year Year - Sec $section',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              else if (year.isNotEmpty)
                                Text(
                                  '$year Year',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Widget 3: Level Progress Card
                _buildLevelProgressCard(
                  levelNum,
                  levelTitle,
                  totalXp,
                  maxXp,
                  levelProgress,
                ),

                const SizedBox(height: 20),

                // Widget 4: Stage Progress Banner
                _buildStageProgressBanner(currentStage, totalXp),

                const SizedBox(height: 24),

                // Metric Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.emoji_events_rounded,
                        iconColor: Colors.amber.shade600,
                        bgColor: Colors.amber.shade50,
                        title: 'Leaderboard Rank',
                        value: '#$rank',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.shield_rounded,
                        iconColor: Colors.teal.shade600,
                        bgColor: Colors.teal.shade50,
                        title: 'Active Stage',
                        value: 'Stage $currentStage',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Widget 2: Streak Cards Row
                const Text(
                  'Active Streaks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStreaksRow(xpProvider.streaks),

                const SizedBox(height: 24),

                // Activity Streaks
                const Text(
                  'Activity Streaks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActivityStreaksRow(xpProvider.activityStreaks),

                const SizedBox(height: 24),
                _buildXpSummaryGrid(xpProvider.xpByCategory, totalXp),
                const SizedBox(height: 24),

                // Widget 1: XP Category Mini Bar Chart
                const Text(
                  'XP by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoryBarChart(xpProvider.xpByCategory),

                const SizedBox(height: 24),

                // Widget 6: Group Card
                _buildGroupCard(),

                const SizedBox(height: 28),

                // Widget 5: Recent Activity Feed
                const Text(
                  'Recent Point Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActivityFeed(xpProvider.history),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBarChart(Map<String, int> categories) {
    final double individualXp = (categories['individualXp'] ?? 0).toDouble();
    final double groupXp = (categories['groupXp'] ?? 0).toDouble();
    final double mustXp = (categories['mustXp'] ?? 0).toDouble();

    double maxVal = [
      individualXp,
      groupXp,
      mustXp,
    ].reduce((curr, next) => curr > next ? curr : next);
    if (maxVal < 10) maxVal = 100;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (event is FlTapUpEvent &&
                  barTouchResponse != null &&
                  barTouchResponse.spot != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecting to XP Tracker filtered view...'),
                  ),
                );
              }
            },
            enabled: true,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  );
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Individual', style: style);
                    case 1:
                      return const Text('Group', style: style);
                    case 2:
                      return const Text('MUST', style: style);
                    default:
                      return const Text('', style: style);
                  }
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeBarGroup(0, individualXp, Colors.purple),
            _makeBarGroup(1, groupXp, Colors.green),
            _makeBarGroup(2, mustXp, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildXpSummaryGrid(Map<String, int> categories, int totalXp) {
    final list = [
      {'label': 'Total XP', 'value': totalXp, 'color': Colors.blue},
      {
        'label': 'Individual XP',
        'value': categories['individualXp'] ?? 0,
        'color': Colors.purple,
      },
      {
        'label': 'Group XP',
        'value': categories['groupXp'] ?? 0,
        'color': Colors.green,
      },
      {
        'label': 'MUST XP',
        'value': categories['mustXp'] ?? 0,
        'color': Colors.amber,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'XP Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final label = item['label'] as String;
              final val = item['value'] as int;
              final color = item['color'] as Color;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$val XP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total XP',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '$totalXp XP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  // Widget 2: Horizontal Streaks List
  Widget _buildStreaksRow(List<dynamic> streaks) {
    if (streaks.isEmpty) {
      return const Text('No active streaks recorded.');
    }
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: streaks.length,
        itemBuilder: (context, index) {
          final streak = streaks[index];
          final String name = streak['streakType'].toString().replaceFirst(
            '_',
            ' ',
          );
          final int count = streak['currentStreak'] ?? 0;
          final bool isBroken = streak['isBroken'] ?? false;

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBroken ? Colors.red.shade200 : Colors.green.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isBroken ? '❄️' : '🔥',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isBroken ? 'Broken' : '$count Days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isBroken ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityStreaksRow(List<dynamic> streaks) {
    if (streaks.isEmpty) {
      return const Text('No active activity streaks recorded.');
    }
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: streaks.length,
        itemBuilder: (context, index) {
          final streak = streaks[index];
          final String name = streak['activityName']?.toString() ?? 'Activity';
          final int count = streak['currentStreak'] ?? 0;
          final int longest = streak['longestStreak'] ?? 0;
          final bool isBroken = count == 0;

          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBroken ? Colors.red.shade200 : Colors.orange.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isBroken ? '💤' : '⚡',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isBroken ? 'No Streak' : '$count Times',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isBroken ? Colors.red : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget 3: Level Progress Card
  Widget _buildLevelProgressCard(
    int levelNum,
    String levelTitle,
    int totalXp,
    int maxXp,
    double progress,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Level $levelNum — $levelTitle',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.stars_rounded, color: Colors.indigo, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalXp / $maxXp XP to next level',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget 4: Stage Progress Banner
  Widget _buildStageProgressBanner(int currentStage, int totalXp) {
    if (activeStageDetails == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Column(
          children: [
            Icon(Icons.lock_clock, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text(
              'No Active Stage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'No active stage is currently available. Activities are locked.',
              style: TextStyle(fontSize: 13, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final int expectedXp = activeStageDetails?['expectedXp'] ?? 1000;
    final String countdown = activeStageDetails?['countdown'] as String? ?? '';

    final double progress = expectedXp > 0
        ? (totalXp / expectedXp).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Stage $currentStage Progress',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (countdown.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        countdown,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : const Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalXp / $expectedXp XP',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: progress >= 1.0
                      ? Colors.green
                      : const Color(0xFF4F46E5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget 5: Recent Activity Feed
  Widget _buildActivityFeed(List<dynamic> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No recent activities recorded.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length > 5 ? 5 : history.length,
      itemBuilder: (context, index) {
        final log = history[index];
        final int points = log['xpPoints'] ?? 0;
        final bool isPositive = points > 0;
        final String status = log['status'] ?? 'APPROVED';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: isPositive
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Icon(
                isPositive
                    ? Icons.add_circle_outline_rounded
                    : Icons.remove_circle_outline_rounded,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              log['activityName'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontSize: 13,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  log['submittedAt'] != null
                      ? log['submittedAt'].toString().split('T')[0]
                      : '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: 'APPROVED'.equalsIgnoreCase(status)
                        ? Colors.green.withValues(alpha: 0.1)
                        : 'REJECTED'.equalsIgnoreCase(status)
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: 'APPROVED'.equalsIgnoreCase(status)
                          ? Colors.green
                          : 'REJECTED'.equalsIgnoreCase(status)
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Text(
              isPositive ? '+$points XP' : '$points XP',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget 6: Group Card
  Widget _buildGroupCard() {
    if (teamDetailsData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.group_off, color: Colors.grey, size: 40),
              SizedBox(height: 12),
              Text(
                'No Team Assigned',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String name = teamDetailsData!['teamName'] ?? 'Unnamed Team';
    final String captain = teamDetailsData!['captainName'] ?? 'Not Assigned';
    final String viceCaptain =
        teamDetailsData!['viceCaptainName'] ?? 'Not Assigned';
    final int teamXp = teamDetailsData!['totalTeamXp'] ?? 0;
    final String stage = teamDetailsData!['stage'] ?? 'Stage 1';
    final String dept = teamDetailsData!['department'] ?? 'N/A';
    final String sec = teamDetailsData!['section'] ?? 'N/A';
    final int memberCount =
        teamDetailsData!['currentMemberCount'] ??
        (teamDetailsData!['members'] as List?)?.length ??
        0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Group: $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stage.toUpperCase(),
                  style: TextStyle(
                    color: Colors.indigo.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallBadge(Icons.business, dept),
              _buildSmallBadge(Icons.class_, 'Sec: $sec'),
              _buildSmallBadge(Icons.people, '$memberCount Members'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Captain',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      captain,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vice Captain',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viceCaptain,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Group XP: $teamXp XP',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }
}
