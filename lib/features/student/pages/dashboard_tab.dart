import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/student/pages/leaderboard_tab.dart';
import 'package:pragatix/features/profile/pages/profile_page.dart';
import 'package:pragatix/features/student/pages/level_progression_page.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/features/team/pages/student_team_details_page.dart';


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
  String gender = '';
  int score = 0; // Discipline points
  int rank = 1;
  int currentStage = 1;
  bool isCaptain = false;
  bool isViceCaptain = false;
  bool isMember = false;
  String teamName = '';
  Map<String, dynamic>? activeStageDetails;
  Map<String, dynamic>? teamDetailsData;
  List<dynamic> allStages = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (context.read<AuthProvider>().token == 'debug_token') {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      await _fetchProfileData();

      if (regNo.isNotEmpty && mounted) {
        debugPrint('Student ID loaded: $regNo');
        debugPrint('Register Number: $regNo');
        debugPrint('Department: $department');
        debugPrint('Year: $year');
        debugPrint('Section: $section');
        debugPrint('Calling XP Summary with: $regNo');
        debugPrint('Calling Team API with: $regNo');
        debugPrint('Calling Rank API with: $regNo');

        final token = context.read<AuthProvider>().token ?? '';
        final xpProv = Provider.of<XpProvider>(context, listen: false);

        await Future.wait([
          _fetchTeamDetails().catchError((_) {}),
          _fetchStages().catchError((_) {}),
          xpProv.fetchSummary(regNo, token).catchError((_) {}),
          xpProv.fetchHistory(regNo, token).catchError((_) {}),
          xpProv.fetchStreaks(regNo, token).catchError((_) {}),
          xpProv.fetchActivityStreaks(token).catchError((_) {}),
          xpProv.fetchProgression(token).catchError((_) {}),
        ]).timeout(const Duration(seconds: 8), onTimeout: () => []);
      } else {
        debugPrint('Warning: regNo is empty after _fetchProfileData');
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
    if (!mounted) return;
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
          stagesList.sort((a, b) => ((a['displayOrder'] ?? 0) as int)
              .compareTo((b['displayOrder'] ?? 0) as int));
          final stageForStudent = stagesList.firstWhere(
            (s) => (s['displayOrder'] ?? s['order']) == currentStage,
            orElse: () => stagesList.firstWhere(
              (s) => s['isActive'] == true || s['active'] == true,
              orElse: () => null,
            ),
          );
          if (mounted) {
            setState(() {
              allStages = stagesList;
              if (stageForStudent != null) {
                activeStageDetails = stageForStudent;
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTeamDetails() async {
    if (!mounted) return;
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
    if (!mounted) return;
    try {
      final authToken = context.read<AuthProvider>().token ?? '';
      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final resData = data['data'];
          
          debugPrint('====== FORENSIC: FLUTTER ROLE RESOLUTION ======');
          debugPrint('Raw /auth/me data: $resData');
          debugPrint('isCaptain flag from backend: ${resData['isCaptain']}');
          debugPrint('isViceCaptain flag from backend: ${resData['isViceCaptain']}');
          debugPrint('isMember flag from backend: ${resData['isMember']}');
          debugPrint('gender from backend: ${resData['gender']}');
          debugPrint('teamRole from backend: ${resData['teamRole']}');
          debugPrint('userType from backend: ${resData['userType']}');
          String resolvedGender = resData['gender'] ?? '';
          if (resolvedGender.isEmpty) {
            try {
              final profResp = await getIt<StudentProxyService>().get(
                Uri.parse('${ApiConfig.baseUrl}/api/v1/profile/me'),
                headers: {
                  'Authorization': 'Bearer $authToken',
                },
              );
              if (profResp.statusCode == 200) {
                final profData = jsonDecode(profResp.body);
                if (profData['success'] == true && profData['data'] != null) {
                  resolvedGender = profData['data']['gender'] ?? profData['data']['studentDetails']?['gender'] ?? '';
                }
              }
            } catch (_) {}
          }

          if (mounted) {
            setState(() {
              studentName = resData['fullName'] ?? '';
              regNo = resData['username'] ?? resData['regNo'] ?? '';
              section = resData['section'] ?? '';
              year = resData['year'] ?? '';
              department = resData['department'] ?? '';
              gender = resolvedGender;
              final rawXp = resData['totalXp'] as int?;
              final rawScore = resData['score'] as int?;
              // Remove 100 extra offset so dashboard displays student's actual current XP
              score = rawXp ?? (rawScore != null && rawScore >= 100 ? rawScore - 100 : (rawScore ?? 0));
              rank = resData['rank'] != null && resData['rank'] > 0
                  ? resData['rank']
                  : 1;
              isCaptain = resData['isCaptain'] == true;
              isViceCaptain = resData['isViceCaptain'] == true;
              isMember = resData['isMember'] == true;
              teamName = resData['teamName'] ?? '';
              if (resData['stage'] != null && resData['stage'] > 0) {
                currentStage = resData['stage'];
              } else if (resData['currentStage'] != null && resData['currentStage'] > 0) {
                currentStage = resData['currentStage'];
              }
            });
          }
          debugPrint('Final resolved Flutter dashboard state: isCaptain=$isCaptain, isViceCaptain=$isViceCaptain, isMember=$isMember, gender=$gender');
          debugPrint('===============================================');
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);

    if (isLoading) {
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
    final int maxXp = progression != null
        ? (progression['currentLevelMaxXp'] ?? 100)
        : 100;
    final double levelProgress = progression != null
        ? ((progression['progressPercentage'] ?? 0.0) / 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final authProvider = context.read<AuthProvider>();
            final xpProv = Provider.of<XpProvider>(context, listen: false);
            await _fetchProfileData();
            await _fetchStages();
            await _fetchTeamDetails();
            final token = authProvider.token ?? '';
            await xpProv.fetchSummary(regNo, token);
            await xpProv.fetchHistory(regNo, token);
            await xpProv.fetchStreaks(regNo, token);
            await xpProv.fetchActivityStreaks(token);
            await xpProv.fetchProgression(token);
          },
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header with Avatar & Streaks ─────────────────────────
                _buildTopHeader(),
                const SizedBox(height: 12),

                // ── Welcome Text ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              studentName.isNotEmpty ? studentName : 'Student',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4F46E5),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Discipline Score Card ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDisciplineScoreCard(
                    score: totalXp > 0 ? totalXp : (score >= 100 ? score - 100 : score),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Current Level Card (Full Width) ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCurrentLevelCard(
                    levelNum: levelNum,
                    levelTitle: levelTitle,
                    totalXp: totalXp,
                    maxXp: maxXp,
                    levelProgress: levelProgress,
                  ),
                ),

                const SizedBox(height: 18),

                // ── Leaderboard Hero Card with 3D Golden Trophy ──────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildLeaderboardHeroCard(rank: rank),
                ),

                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildXpSummaryHub(
                    categories: xpProvider.xpByCategory,
                    totalXp: totalXp,
                    activeStageDetails: activeStageDetails,
                    stages: allStages.isNotEmpty ? allStages : xpProvider.stages,
                  ),
                ),
                const SizedBox(height: 22),

                // ── Group Card ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildGroupCard(),
                ),

                const SizedBox(height: 26),

                // ── Recent Activity Feed ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Header ───────────────────────────────────────────────────────────────

  Widget _buildTopHeader() {
    String? roleBadgeText;
    Color roleBadgeColor = const Color(0xFF6366F1);
    if (isCaptain) {
      roleBadgeText = '★ Captain';
      roleBadgeColor = const Color(0xFF8B5CF6);
    } else if (isViceCaptain) {
      roleBadgeText = '★ Vice Captain';
      roleBadgeColor = const Color(0xFF7C3AED);
    } else if (isMember) {
      roleBadgeText = 'Member';
      roleBadgeColor = const Color(0xFF3B82F6);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Student Dashboard',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streak Pill (Attendance Streak Display Only)
              Consumer<AttendanceProvider>(
                builder: (context, provider, child) {
                  final int streak = provider.currentStreak;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFDDD0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Profile Avatar Button (Navigates to ProfilePage)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFFE0E7FF),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (roleBadgeText != null)
                      Positioned(
                        bottom: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: roleBadgeColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: roleBadgeColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            roleBadgeText,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Discipline Score Card ───────────────────────────────────────────────────

  Widget _buildDisciplineScoreCard({
    required int score,
  }) {

    String formatYear(String y) {
      if (y.trim().isEmpty) return 'First Year';
      if (y.toLowerCase().contains('year')) return y.trim();
      return '${y.trim()} Year';
    }

    final String secYearText = section.isNotEmpty
        ? '${formatYear(year)} - Sec $section'
        : formatYear(year);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Card Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Text(
                    'Discipline Score',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Points
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Points',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Info Row: Department (Left) & Section & Year (Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Department',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              department.isNotEmpty
                                  ? department
                                  : 'Computer Science and Engineering',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                            Text(
                            'Section & Year',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            secYearText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Current Level Card with 3D Treasure Chest ────────────────────────────────

  Widget _buildCurrentLevelCard({
    required int levelNum,
    required String levelTitle,
    required int totalXp,
    required int maxXp,
    required double levelProgress,
  }) {
    final int remainingXp = (maxXp - totalXp) > 0 ? (maxXp - totalXp) : 0;
    final int nextLevelNum = levelNum + 1;
    final int progressPercent = (levelProgress * 100).toInt().clamp(0, 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LevelProgressionPage(),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Level Texts + Chevron button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Name & XP Helper
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Level',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level $levelNum — $levelTitle',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            remainingXp > 0
                                ? 'Earn $remainingXp XP to reach Level $nextLevelNum'
                                : 'Maximum level reached!',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron Button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bottom Section: Progress Bar & Info (0 / 100 XP + 0%)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pill Track Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: levelProgress.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$totalXp / $maxXp XP',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
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

  // ── Leaderboard Hero Card ───────────────────────────────────────────────────

  Widget _buildLeaderboardHeroCard({required int rank}) {
    String motivationalText;
    if (rank == 1) {
      motivationalText = "You're on top! Keep it up!";
    } else if (rank <= 3) {
      motivationalText = 'Top 3 contender! Keep climbing!';
    } else if (rank <= 10) {
      motivationalText = 'In the top 10! Keep earning XP!';
    } else {
      motivationalText = 'Keep earning XP to climb the ranks!';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeaderboardTab(),
            ),
          ).then((_) {
            if (mounted) _fetchProfileData();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    // Leaderboard Rank & Rank Value
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leaderboard Rank',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$rank',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Motivational Banner Pill
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Center(
                    child: Text(
                      motivationalText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // ── XP Summary Boxes Hub ───────────────────────────────────────────────────

  Widget _buildXpSummaryHub({
    required Map<String, int> categories,
    required int totalXp,
    Map<String, dynamic>? activeStageDetails,
    List<dynamic>? stages,
  }) {
    final int mustXp = categories['mustXp'] ?? 0;
    final int individualXp = categories['individualXp'] ?? 0;
    final int groupXp = categories['groupXp'] ?? 0;

    int mustThreshold = (activeStageDetails?['mustThreshold'] as num?)?.toInt() ?? 0;
    int individualThreshold = (activeStageDetails?['individualThreshold'] as num?)?.toInt() ?? 0;
    int groupThreshold = (activeStageDetails?['groupThreshold'] as num?)?.toInt() ?? 0;

    // Check subgroups in activeStageDetails if any threshold is not found
    if (activeStageDetails?['subgroups'] is List) {
      for (var sub in activeStageDetails!['subgroups']) {
        final subName = (sub['name'] ?? '').toString().toLowerCase();
        final subThresh = (sub['threshold'] as num?)?.toInt() ?? 0;
        if (subThresh > 0) {
          if ((subName.contains('must') || subName.contains('mandatory')) && mustThreshold == 0) {
            mustThreshold = subThresh;
          } else if ((subName.contains('individual') || subName.contains('personal')) && individualThreshold == 0) {
            individualThreshold = subThresh;
          } else if ((subName.contains('group') || subName.contains('team')) && groupThreshold == 0) {
            groupThreshold = subThresh;
          }
        }
      }
    }

    // Fallback to stages list if needed
    final stagesList = stages ?? allStages;
    if ((mustThreshold == 0 || individualThreshold == 0 || groupThreshold == 0) && stagesList.isNotEmpty) {
      final stageItem = stagesList.firstWhere(
        (s) => (s['displayOrder'] ?? s['order']) == currentStage,
        orElse: () => stagesList.firstWhere(
          (s) => s['isActive'] == true || s['active'] == true,
          orElse: () => stagesList.first,
        ),
      );
      if (stageItem != null) {
        if (mustThreshold == 0) mustThreshold = (stageItem['mustThreshold'] as num?)?.toInt() ?? 0;
        if (individualThreshold == 0) individualThreshold = (stageItem['individualThreshold'] as num?)?.toInt() ?? 0;
        if (groupThreshold == 0) groupThreshold = (stageItem['groupThreshold'] as num?)?.toInt() ?? 0;

        if (stageItem['subgroups'] is List) {
          for (var sub in stageItem['subgroups']) {
            final subName = (sub['name'] ?? '').toString().toLowerCase();
            final subThresh = (sub['threshold'] as num?)?.toInt() ?? 0;
            if (subThresh > 0) {
              if ((subName.contains('must') || subName.contains('mandatory')) && mustThreshold == 0) {
                mustThreshold = subThresh;
              } else if ((subName.contains('individual') || subName.contains('personal')) && individualThreshold == 0) {
                individualThreshold = subThresh;
              } else if ((subName.contains('group') || subName.contains('team')) && groupThreshold == 0) {
                groupThreshold = subThresh;
              }
            }
          }
        }
      }
    }

    final double mustRatio = mustThreshold > 0
        ? (mustXp / mustThreshold).clamp(0.0, 1.0)
        : (mustXp > 0 ? 1.0 : 0.0);
    final double indRatio = individualThreshold > 0
        ? (individualXp / individualThreshold).clamp(0.0, 1.0)
        : (individualXp > 0 ? 1.0 : 0.0);
    final double grpRatio = groupThreshold > 0
        ? (groupXp / groupThreshold).clamp(0.0, 1.0)
        : (groupXp > 0 ? 1.0 : 0.0);

    final int mustPercent = mustThreshold > 0
        ? ((mustXp / mustThreshold) * 100).clamp(0, 100).round()
        : (mustXp > 0 ? 100 : 0);
    final int indPercent = individualThreshold > 0
        ? ((individualXp / individualThreshold) * 100).clamp(0, 100).round()
        : (individualXp > 0 ? 100 : 0);
    final int grpPercent = groupThreshold > 0
        ? ((groupXp / groupThreshold) * 100).clamp(0, 100).round()
        : (groupXp > 0 ? 100 : 0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'XP Summary',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Track your progress and level up!',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total XP',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$totalXp XP',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Top Row: MUST XP Box (Left) & INDIVIDUAL XP Box (Right)
            Row(
              children: [
                // Left Box: MUST XP
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icons Header: Squircle Badge on Left, Watermark on Right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            Icon(
                              Icons.shield_outlined,
                              size: 22,
                              color: const Color(0xFFFDE68A).withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Title & Value
                        const Text(
                          'MUST XP',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$mustXp XP',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Progress Bar & Percentage
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 5,
                                  child: LinearProgressIndicator(
                                    value: mustRatio,
                                    backgroundColor: const Color(0xFFFEF3C7),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$mustPercent%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mandatory XP from required activities.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Right Box: INDIVIDUAL XP
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFDDD6FE),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icons Header: Squircle Badge on Left, Watermark on Right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            Icon(
                              Icons.person_outline_rounded,
                              size: 22,
                              color: const Color(0xFFDDD6FE).withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Title & Value
                        const Text(
                          'INDIVIDUAL XP',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$individualXp XP',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Progress Bar & Percentage
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 5,
                                  child: LinearProgressIndicator(
                                    value: indRatio,
                                    backgroundColor: const Color(0xFFF3E8FF),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$indPercent%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'XP earned from personal activities.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Full-Width Box: GROUP XP
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GROUP XP',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$groupXp XP',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.groups_outlined,
                        size: 26,
                        color: const Color(0xFFA7F3D0).withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 5,
                            child: LinearProgressIndicator(
                              value: grpRatio,
                              backgroundColor: const Color(0xFFD1FAE5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF059669),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$grpPercent%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'XP earned by your group as a team.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
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



  // ── Group Card ───────────────────────────────────────────────────────────────

  Widget _buildGroupCard() {
    if (teamDetailsData == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentTeamDetailsPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.group_off_rounded, color: Color(0xFF94A3B8), size: 40),
                  SizedBox(height: 12),
                  Text(
                    'No Team Assigned',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

    final String name = teamDetailsData!['teamName'] ?? 'Test Team';
    final String captain = teamDetailsData!['captainName'] ?? 'Test Captain';
    final String viceCaptain =
        teamDetailsData!['viceCaptainName'] ?? 'Test Vice Captain';
    final String stage = teamDetailsData!['stage'] ??
        (activeStageDetails?['stageName'] ?? 'Stage 1');
    final int memberCount = teamDetailsData!['currentMemberCount'] ??
        (teamDetailsData!['members'] as List?)?.length ??
        24;
    final int teamRank =
        teamDetailsData!['rank'] ?? teamDetailsData!['teamRank'] ?? 1;

    // Determine Captain & Vice Captain Genders
    String captainGender = (teamDetailsData!['captainGender'] ?? '').toString().toLowerCase();
    String vcGender = (teamDetailsData!['viceCaptainGender'] ?? '').toString().toLowerCase();

    // Fallback gender lookup from members list if available
    final List<dynamic>? membersList = teamDetailsData!['members'] as List<dynamic>?;
    if (membersList != null) {
      for (var m in membersList) {
        final String role = (m['teamRole'] ?? '').toString().toUpperCase();
        final String mGender = (m['gender'] ?? '').toString().toLowerCase();
        if (captainGender.isEmpty && (role == 'CAPTAIN' || m['studentName'] == captain)) {
          captainGender = mGender;
        }
        if (vcGender.isEmpty && (role == 'VICE_CAPTAIN' || m['studentName'] == viceCaptain)) {
          vcGender = mGender;
        }
      }
    }

    final bool hasCaptain = captain.trim().isNotEmpty &&
        captain.trim().toUpperCase() != 'N/A' &&
        captain.trim().toUpperCase() != 'NONE';
    final bool hasViceCaptain = viceCaptain.trim().isNotEmpty &&
        viceCaptain.trim().toUpperCase() != 'N/A' &&
        viceCaptain.trim().toUpperCase() != 'NONE';

    final bool isCaptainFemale = captainGender == 'female' || captainGender == 'f';
    final bool isVcMale = vcGender == 'male' || vcGender == 'm';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentTeamDetailsPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Team Name & Stage Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'My Group: $name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stage.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Metrics Row (Total Members & Group Rank)
              Row(
                children: [
                  Expanded(
                    child: _buildGroupMetricPill(
                      icon: Icons.groups_rounded,
                      iconBg: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF6366F1),
                      label: 'Total Members',
                      value: '$memberCount',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGroupMetricPill(
                      icon: Icons.bar_chart_rounded,
                      iconBg: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      label: 'Group Rank',
                      value: '$teamRank',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Leadership Box (Captain & Vice Captain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    // Captain
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: hasCaptain
                                ? (isCaptainFemale
                                    ? const Color(0xFFFCE7F3)
                                    : const Color(0xFFDCFCE7))
                                : const Color(0xFFF1F5F9),
                            child: hasCaptain
                                ? Center(
                                    child: Text(
                                      captain.isNotEmpty ? captain[0].toUpperCase() : 'C',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: isCaptainFemale
                                            ? const Color(0xFFDB2777)
                                            : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Captain',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasCaptain ? captain : 'Not Assigned',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: hasCaptain ? FontWeight.w800 : FontWeight.w600,
                                    color: hasCaptain ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 36,
                      width: 1.2,
                      color: const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),

                    // Vice Captain
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: hasViceCaptain
                                ? (isVcMale
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFCE7F3))
                                : const Color(0xFFF1F5F9),
                            child: hasViceCaptain
                                ? Center(
                                    child: Text(
                                      viceCaptain.isNotEmpty ? viceCaptain[0].toUpperCase() : 'V',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vice Captain',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasViceCaptain ? viceCaptain : 'Not Assigned',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: hasViceCaptain ? FontWeight.w800 : FontWeight.w600,
                                    color: hasViceCaptain ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupMetricPill({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5.5),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity Feed ────────────────────────────────────────────────────────────

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
}

extension StringExtension on String {
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }
}


