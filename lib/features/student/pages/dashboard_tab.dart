import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/student/pages/activity_streaks_page.dart';
import 'package:pragatix/features/student/pages/leaderboard_tab.dart';
import 'package:pragatix/features/profile/pages/profile_page.dart';
import 'package:pragatix/features/student/pages/level_progression_page.dart';
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
    if (context.read<AuthProvider>().token! == 'debug_token') {
      setState(() => isLoading = false);
      return;
    }

    try {
      await _fetchProfileData();

      if (regNo.isNotEmpty) {
        debugPrint('Student ID loaded: $regNo');
        debugPrint('Register Number: $regNo');
        debugPrint('Department: $department');
        debugPrint('Year: $year');
        debugPrint('Section: $section');
        debugPrint('Calling XP Summary with: $regNo');
        debugPrint('Calling Team API with: $regNo');
        debugPrint('Calling Rank API with: $regNo');

        if (!mounted) return;
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

                // ── Discipline Score Card with Dynamic Stage Dots ────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDisciplineScoreCard(
                    score: totalXp > 0 ? totalXp : (score >= 100 ? score - 100 : score),
                    levelProgress: levelProgress,
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
                    stageNum: currentStage,
                    stageName: activeStageDetails?['stageName'] ?? 'Stage $currentStage',
                    maxXp: maxXp,
                    levelNum: levelNum,
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
    final bool isFemale = gender.trim().toLowerCase().startsWith('f');
    final String avatarAsset = isFemale
        ? 'assets/images/avatar_female.png'
        : 'assets/images/avatar_male.png';

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
              // Streak Pill
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
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivityStreaksPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
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
                            '$maxStreak',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE0E7FF),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          avatarAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            isFemale ? Icons.face_3_rounded : Icons.face_rounded,
                            size: 32,
                            color: roleBadgeColor,
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

  // ── Discipline Score Card with Dynamic Stage Dots ────────────────────────────

  Widget _buildDisciplineScoreCard({
    required int score,
    required double levelProgress,
  }) {
    final bool isFemale = gender.trim().toLowerCase().startsWith('f');
    final String mountainAsset = isFemale
        ? 'assets/images/card_mountain_hiker_female.png'
        : 'assets/images/card_mountain_hiker_male.png';

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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1A4E).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image: Full Mountain Landscape with Hiker on summit
            Positioned.fill(
              child: Image.asset(
                mountainAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF232766), Color(0xFF161942)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // Left-to-Right Multi-stop Gradient Overlay for high text readability
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xF51C1948), // Solid deep purple on left
                      Color(0xE21C1948),
                      Color(0x751C1948),
                      Color(0x051C1948), // Transparent on right so hiker shines through
                    ],
                    stops: [0.0, 0.44, 0.72, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Text(
                        'Discipline Score',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ],
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
                  const SizedBox(height: 18),

                  // Dynamic Stage Dots Progress Bar
                  _buildDynamicStageDots(
                    totalStages: allStages.isNotEmpty ? allStages.length : 3,
                    currentStage: currentStage,
                    levelProgress: levelProgress,
                  ),
                  const SizedBox(height: 18),

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

  // ── Dynamic Stage Dots Progress Bar with "You are here" marker ──────────────

  Widget _buildDynamicStageDots({
    required int totalStages,
    required int currentStage,
    required double levelProgress,
  }) {
    // Stage count + 1 so progress towards future/highest stage has a milestone ahead
    final int baseCount = totalStages < 2 ? 3 : totalStages;
    final int stageCount = baseCount + 1;
    final int activeIdx = (currentStage - 1).clamp(0, stageCount - 1);

    double currentProgressRatio = 0.0;
    if (stageCount > 1) {
      final double baseRatio = activeIdx / (stageCount - 1);
      final double step = 1.0 / (stageCount - 1);
      // Smooth intermediate position along the line between current stage and next
      final double fractional = (activeIdx < stageCount - 1)
          ? (levelProgress.clamp(0.0, 1.0) * step * 0.45)
          : 0.0;
      currentProgressRatio = (baseRatio + fractional).clamp(0.0, 1.0);
    }

    final bool isFemale = gender.trim().toUpperCase() == 'FEMALE';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        const double dotRadius = 11.0;
        final double trackWidth = totalWidth - (dotRadius * 2);
        final double targetCenterX = dotRadius + (trackWidth * currentProgressRatio);
        const double tagWidth = 96.0;
        final double tagLeft = (targetCenterX - (tagWidth / 2)).clamp(0.0, totalWidth - tagWidth);

        return SizedBox(
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // "You are here" Floating Marker Badge with Avatar
              Positioned(
                top: 0,
                left: tagLeft,
                child: SizedBox(
                  width: tagWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF818CF8).withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Gender Avatar Circle
                            ClipOval(
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  isFemale
                                      ? 'assets/images/avatar_female.png'
                                      : 'assets/images/avatar_male.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person_rounded,
                                    size: 10,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'You are here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const CustomPaint(
                        size: Size(8, 4),
                        painter: _StageTrianglePainter(color: Color(0xFF818CF8)),
                      ),
                    ],
                  ),
                ),
              ),

              // Inactive track line
              Positioned(
                top: 32,
                left: dotRadius,
                right: dotRadius,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Active filled progress line
              Positioned(
                top: 32,
                left: dotRadius,
                child: Container(
                  width: trackWidth * currentProgressRatio,
                  height: 3.5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF38BDF8),
                        Color(0xFF818CF8),
                        Color(0xFFA855F7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.6),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Stage Dots Row
              Positioned(
                top: 22,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(stageCount, (index) {
                    final int stageNum = index + 1;
                    final bool isFinalMilestone = index == stageCount - 1;
                    final bool isPast = stageNum < currentStage;
                    final bool isCurrent = stageNum == currentStage;

                    Color dotColor;
                    Color borderColor;
                    double dotSize = 22;

                    if (isFinalMilestone) {
                      dotSize = 26;
                      dotColor = isCurrent
                          ? const Color(0xFF818CF8)
                          : (isPast
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF1E2258).withValues(alpha: 0.85));
                      borderColor = isCurrent || isPast
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.7);
                    } else if (isCurrent) {
                      dotColor = const Color(0xFF818CF8);
                      borderColor = Colors.white;
                      dotSize = 24;
                    } else if (isPast) {
                      dotColor = const Color(0xFF38BDF8);
                      borderColor = Colors.white.withValues(alpha: 0.9);
                    } else {
                      dotColor = const Color(0xFF1E2258).withValues(alpha: 0.7);
                      borderColor = Colors.white.withValues(alpha: 0.25);
                    }

                    return Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        border: Border.all(
                          color: borderColor,
                          width: isCurrent || isFinalMilestone ? 2.0 : 1.5,
                        ),
                        boxShadow: isFinalMilestone
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : (isCurrent
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF818CF8).withValues(alpha: 0.7),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : (isPast
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null)),
                      ),
                      child: Center(
                        child: isFinalMilestone
                            ? Padding(
                                padding: const EdgeInsets.all(2.5),
                                child: Image.asset(
                                  'assets/images/treasure_chest.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.inventory_2_rounded,
                                    size: 13,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              )
                            : (isPast
                                ? const Icon(
                                    Icons.check,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '$stageNum',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isCurrent
                                          ? Colors.white
                                          : (isPast
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.45)),
                                    ),
                                  )),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
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
                // Top Row: Hexagon Compass Icon + Level Texts + Chevron button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Purple Rounded Hexagon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
                      ),
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

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

                // Bottom Section: Progress Bar & Info on Left, 3D Treasure Chest on Right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Progress bar + 0 / 100 XP + 0%
                    Expanded(
                      child: Column(
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
                    ),

                    const SizedBox(width: 14),

                    // Right: 3D Treasure Chest Image
                    SizedBox(
                      width: 92,
                      height: 80,
                      child: Image.asset(
                        'assets/images/treasure_chest.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.inventory_2_rounded,
                          size: 55,
                          color: Color(0xFFF59E0B),
                        ),
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

  // ── Leaderboard Hero Card with 3D Golden Trophy ──────────────────────────────

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
                    // 3D Golden Trophy Image
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: Image.asset(
                        'assets/images/leaderboard_trophy.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.emoji_events_rounded,
                          size: 55,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

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
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '#$rank',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 13,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      rank == 1 ? '1' : '2',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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



  // ── XP Summary Radial Connected Hub ─────────────────────────────────────────

  Widget _buildXpSummaryHub({
    required Map<String, int> categories,
    required int totalXp,
    required int stageNum,
    required String stageName,
    required int maxXp,
    required int levelNum,
  }) {
    final int mustXp = categories['mustXp'] ?? 0;
    final int individualXp = categories['individualXp'] ?? 0;
    final int groupXp = categories['groupXp'] ?? 0;

    final double mustRatio =
        totalXp > 0 ? (mustXp / totalXp).clamp(0.0, 1.0) : 0.0;
    final double indRatio =
        totalXp > 0 ? (individualXp / totalXp).clamp(0.0, 1.0) : 0.0;
    final double grpRatio =
        totalXp > 0 ? (groupXp / totalXp).clamp(0.0, 1.0) : 0.0;

    final int mustPercent = (mustRatio * 100).toInt();
    final int indPercent = (indRatio * 100).toInt();
    final int grpPercent = (grpRatio * 100).toInt();

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

            // Connected Radial Layout
            _buildRadialConnectedHub(
              mustXp: mustXp,
              mustPercent: mustPercent,
              mustRatio: mustRatio,
              individualXp: individualXp,
              indPercent: indPercent,
              indRatio: indRatio,
              groupXp: groupXp,
              grpPercent: grpPercent,
              grpRatio: grpRatio,
              totalXp: totalXp,
              stageNum: stageNum,
              stageName: stageName,
              maxXp: maxXp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialConnectedHub({
    required int mustXp,
    required int mustPercent,
    required double mustRatio,
    required int individualXp,
    required int indPercent,
    required double indRatio,
    required int groupXp,
    required int grpPercent,
    required double grpRatio,
    required int totalXp,
    required int stageNum,
    required String stageName,
    required int maxXp,
  }) {
    final int totalPercent =
        maxXp > 0 ? ((totalXp / maxXp) * 100).toInt().clamp(0, 100) : 0;

    return Column(
      children: [
        // Top Row: MUST XP Card (Left) ── Center Stage Hub (Middle) ── INDIVIDUAL XP Card (Right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Card: MUST XP
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
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
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: const Color(0xFFFDE68A).withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Horizontal Title & Value
                    const Text(
                      'MUST XP',
                      style: TextStyle(
                        fontSize: 11,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Progress Bar
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
                        const SizedBox(width: 6),
                        Text(
                          '$mustPercent%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mandatory XP from\nrequired activities.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center: Central Stage Hub
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildCentralStageHub(
                stageNum: stageNum,
                stageName: stageName,
                totalXp: totalXp,
                maxXp: maxXp,
                totalPercent: totalPercent,
              ),
            ),

            // Right Card: INDIVIDUAL XP
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
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
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: const Color(0xFFDDD6FE).withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Horizontal Title & Value
                    const Text(
                      'INDIVIDUAL XP',
                      style: TextStyle(
                        fontSize: 11,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Progress Bar
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
                        const SizedBox(width: 6),
                        Text(
                          '$indPercent%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'XP earned from\npersonal activities.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bottom Full-Width Card: GROUP XP
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      size: 18,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GROUP XP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$groupXp XP',
                          style: const TextStyle(
                            fontSize: 16,
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
              const SizedBox(height: 10),
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
                      fontSize: 10,
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
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCentralStageHub({
    required int stageNum,
    required String stageName,
    required int totalXp,
    required int maxXp,
    required int totalPercent,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Concentric Arc Rings with Center Winged Shield
        SizedBox(
          width: 115,
          height: 115,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom Arc Ring Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConcentricHubArcsPainter(),
                ),
              ),

              // Top Star Jewel
              Positioned(
                top: 1,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.6),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),

              // Center Hub Content (Winged Shield + Ribbon + Subtitle)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  // Winged 3D Shield
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left Wing
                      Transform.rotate(
                        angle: 0.35,
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 10,
                          color: Color(0xFFC7D2FE),
                        ),
                      ),
                      const SizedBox(width: 2),

                      // Shield Body
                      Container(
                        width: 36,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                            bottom: Radius.circular(18),
                          ),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5)
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$stageNum',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 2),
                      // Right Wing
                      Transform.rotate(
                        angle: -0.35,
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFFC7D2FE),
                        ),
                      ),
                    ],
                  ),

                  // Stage Ribbon below Shield
                  Transform.translate(
                    offset: const Offset(0, -4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'STAGE $stageNum',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Subtitle (EXPLORER / Stage Name)
                  Text(
                    stageName.toUpperCase().contains('STAGE')
                        ? 'EXPLORER'
                        : stageName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),

        // Total XP & Subtext
        Text(
          '$totalXp XP',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'Total Progress',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        // 3D Pedestal Platform Base with Decorative Leaves
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 3),
            const Text('🌿', style: TextStyle(fontSize: 11)),
          ],
        ),

        const SizedBox(height: 2),

        // Percentage text below pedestal
        Text(
          '$totalPercent%',
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }



  // ── Group Card ───────────────────────────────────────────────────────────────

  Widget _buildGroupCard() {
    if (teamDetailsData == null) {
      return Container(
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
    final String captainAvatar = isCaptainFemale
        ? 'assets/images/avatar_female.png'
        : 'assets/images/avatar_male.png';

    final bool isVcMale = vcGender == 'male' || vcGender == 'm';
    final String viceCaptainAvatar = isVcMale
        ? 'assets/images/avatar_male.png'
        : 'assets/images/avatar_female.png';

    return Container(
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
                  value: '#$teamRank',
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
                            ? ClipOval(
                                child: Image.asset(
                                  captainAvatar,
                                  fit: BoxFit.cover,
                                  width: 38,
                                  height: 38,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    isCaptainFemale
                                        ? Icons.person_2_rounded
                                        : Icons.person_rounded,
                                    size: 22,
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
                            ? ClipOval(
                                child: Image.asset(
                                  viceCaptainAvatar,
                                  fit: BoxFit.cover,
                                  width: 38,
                                  height: 38,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    isVcMale
                                        ? Icons.person_rounded
                                        : Icons.person_2_rounded,
                                    size: 22,
                                    color: isVcMale
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDB2777),
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

class _ConcentricHubArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background track ring
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, bgPaint);

    // Left Arc (MUST XP - Orange/Amber)
    final orangePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14 * 0.75, // from top-left
      3.14 * 0.45, // sweeping down-left
      false,
      orangePaint,
    );

    // Right Arc (Individual XP - Purple)
    final purplePaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 * 0.20, // from top-right
      3.14 * 0.45, // sweeping down-right
      false,
      purplePaint,
    );

    // Bottom Arc (Group XP - Green)
    final greenPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14 * 0.35,
      3.14 * 0.30,
      false,
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StageTrianglePainter extends CustomPainter {
  final Color color;
  const _StageTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
