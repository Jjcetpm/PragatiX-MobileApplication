import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/attendance/widgets/fire_streak_icon.dart';
import 'package:pragatix/core/di/service_locator.dart';

class LevelsBadgesTab extends StatefulWidget {
  const LevelsBadgesTab({super.key});

  @override
  State<LevelsBadgesTab> createState() => _LevelsBadgesTabState();
}

class _LevelsBadgesTabState extends State<LevelsBadgesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _studentName = '';
  int _studentXp = 95; // Default fallback score
  String _selectedPathway = 'None';

  // Theme Colors
  final Color primaryColor = const Color(0xFF4F46E5); // Indigo
  final Color appBarColor = const Color(0xFF1E293B); // Dark Slate
  final Color bgColor = const Color(0xFFF8FAFC); // Light Grey
  final Color textColor = const Color(0xFF1E293B); // Dark Text
  final Color subtitleColor = const Color(0xFF64748B); // Slate Grey Subtitle

  // 8 Levels Data (as per JJCET Guidelines)
  // Levels data removed; handled by backend API now.

  // Skill Pathways Data (Available from Level 3 onwards)
  final List<Map<String, String>> _pathways = [
    {
      'name': 'Core Engineering',
      'domain': 'Domain-specific (Mech/Civil/Aero/EEE/ECE)',
      'categories': 'Academic XP, Skill XP',
      'alignment': 'Faculty Mentor (dept. HoD)',
    },
    {
      'name': 'Cybersecurity',
      'domain': 'Security, ethical hacking',
      'categories': 'Skill XP, Certification XP',
      'alignment': 'Technical Coordinator',
    },
    {
      'name': 'Data Science',
      'domain': 'Analytics, visualization',
      'categories': 'Skill XP, Research XP',
      'alignment': 'Technical Coordinator',
    },
    {
      'name': 'Entrepreneurship',
      'domain': 'Startup, product thinking',
      'categories': 'Innovation XP, Leadership XP',
      'alignment': 'Senior Mentor (Stage 3)',
    },
    {
      'name': 'Research',
      'domain': 'Academic research, patents',
      'categories': 'Research XP, Innovation XP',
      'alignment': 'Research Committee',
    },
  ];

  IconData _getIconForBadge(String? iconName) {
    if (iconName == null || iconName.isEmpty)
      return Icons.military_tech_rounded;
    switch (iconName) {
      case 'event_available_rounded':
        return Icons.event_available_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      case 'access_time_filled_rounded':
        return Icons.access_time_filled_rounded;
      case 'code_rounded':
        return Icons.code_rounded;
      case 'school_rounded':
        return Icons.school_rounded;
      case 'offline_bolt_rounded':
        return Icons.offline_bolt_rounded;
      case 'emoji_events_rounded':
        return Icons.emoji_events_rounded;
      case 'layers_rounded':
        return Icons.layers_rounded;
      case 'question_answer_rounded':
        return Icons.question_answer_rounded;
      case 'work_history_rounded':
        return Icons.work_history_rounded;
      case 'campaign_rounded':
        return Icons.campaign_rounded;
      case 'verified_user_rounded':
        return Icons.verified_user_rounded;
      case 'handshake_rounded':
        return Icons.handshake_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'lightbulb_rounded':
        return Icons.lightbulb_rounded;
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'star_border_purple500_rounded':
        return Icons.star_border_purple500_rounded;
      case 'military_tech_rounded':
        return Icons.military_tech_rounded;
      case 'connect_without_contact_rounded':
        return Icons.connect_without_contact_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Fetch user profile to get discipline points (score)
    try {
      // Fetch user profile to get discipline points (score)
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
            _studentXp = resData['totalXp'] ?? 0;
            _studentName = resData['fullName'] ?? 'Sharugesh';
          });
        }
      }
    } catch (e) {
      // Ignore
    }

    if (mounted) {
      final bp = Provider.of<BadgeProvider>(context, listen: false);
      final xp = Provider.of<XpProvider>(context, listen: false);
      await bp.fetchMyBadges(context.read<AuthProvider>().token!);
      if (!mounted) return;
      await bp.fetchMyBadgeRequests(context.read<AuthProvider>().token!);
      if (!mounted) return;
      await bp.fetchAllBadges(context.read<AuthProvider>().token!);
      if (!mounted) return;
      await xp.fetchProgression(context.read<AuthProvider>().token!);
    }

    setState(() => _isLoading = false);
  }

  // Submit Badge Claim
  @override
  Widget build(BuildContext context) {
    final badgeProvider = Provider.of<BadgeProvider>(context);
    final xpProvider = Provider.of<XpProvider>(context);

    if (_isLoading || badgeProvider.isLoading || xpProvider.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    final progression = xpProvider.progression;
    if (progression == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(child: Text('Progression data unavailable')),
      );
    }

    final int currentLevelNum = progression['currentLevel'] ?? 1;

    return Scaffold(
      backgroundColor: Colors.transparent, // Light background matching dashboard
      appBar: AppBar(
        title: const Text(
          'Levels & Badges',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: appBarColor, // Dark slate AppBar matching dashboard
        elevation: 0,
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: FireStreakIcon(streakCount: provider.currentStreak),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.show_chart_rounded), text: 'Level & Pathway'),
            Tab(
              icon: Icon(Icons.military_tech_rounded),
              text: 'Badge Collection',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLevelsTab(progression),
          _buildBadgesTab(currentLevelNum),
        ],
      ),
    );
  }

  // ── LEVELS AND PATHWAY TAB (LIGHT THEME) ──────────────────────────
  Widget _buildLevelsTab(Map<String, dynamic> progression) {
    final int currentLevelNum = progression['currentLevel'] ?? 0;
    final String currentLevelTitle = progression['currentLevelName'] ?? 'Level';
    final int totalXp = progression['totalXp'] ?? 0;
    final int xpMax = progression['currentLevelMaxXp'] ?? 100;
    final double levelProgress =
        (progression['progressPercentage'] ?? 0.0) / 100.0;
    final bool isMaxLevel = progression['isMaxLevel'] ?? false;
    final int remainingXp = progression['remainingXp'] ?? 0;
    final List<dynamic> unlockedLevels = progression['unlockedLevels'] ?? [];
    final List<dynamic> lockedLevels = progression['lockedLevels'] ?? [];
    final List<dynamic> allLevels = [...unlockedLevels, ...lockedLevels];

    final bool isEligibleForPathway = currentLevelNum >= 3;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Card (Matching Dashboard Gradient style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  const Color(0xFF6366F1),
                ], // Indigo-violet gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
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
                      children: [
                        const Text(
                          'CURRENT LEVEL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lvl $currentLevelNum: $currentLevelTitle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalXp XP Points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isMaxLevel
                          ? 'Maximum Level Achieved'
                          : 'Target: $xpMax XP (Remaining: $remainingXp)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: levelProgress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Skill Pathway Section
          Text(
            'Skill Pathways',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your focus domain starting from Level 3 (Innovator).',
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (!isEligibleForPathway)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unlocks at Level 3 (Innovator) — 501+ XP',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildPathwaySelector(),

          const SizedBox(height: 28),

          // 8-Level Stepper Map
          Text(
            'Level Progression Map',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allLevels.length,
            itemBuilder: (context, index) {
              final lvl = allLevels[index];
              final int lvlNum = lvl['levelNumber'];
              final String lvlTitle = lvl['title'];
              final String range =
                  "${lvl['xpMin']} - ${lvl['xpMax'] == 99999 ? '10000+' : lvl['xpMax']}";
              final String objective =
                  lvl['primaryObjective'] ?? 'No objective';
              final String unlocks = lvl['keyUnlocks'] ?? 'No unlocks';
              final String stageName = "Stage ${lvl['stage'] ?? 1}";

              final bool isCurrent = lvlNum == currentLevelNum;
              final bool isCompleted = lvlNum < currentLevelNum;
              final bool isLocked = lvlNum > currentLevelNum;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node Graphic
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF10B981) // Green for complete
                              : isCurrent
                              ? primaryColor // Indigo for current
                              : Colors.grey.shade300,
                          border: Border.all(
                            color: isCurrent
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : isCurrent
                                ? Icons.bolt_rounded
                                : Icons.lock_outline_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (index != allLevels.length - 1)
                        Container(
                          width: 2.5,
                          height: 110,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Level Card
                  Expanded(
                    child: Opacity(
                      opacity: isLocked ? 0.6 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? primaryColor.withValues(alpha: 0.4)
                                : Colors.grey.shade200,
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
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
                                Text(
                                  'Lvl $lvlNum: $lvlTitle',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? primaryColor.withValues(alpha: 0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    stageName.toUpperCase(),
                                    style: TextStyle(
                                      color: isCurrent
                                          ? primaryColor
                                          : subtitleColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'XP Range: $range',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: Color(0xFFF1F5F9), height: 16),
                            Text(
                              'Objective: $objective',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.vpn_key_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Unlocks: $unlocks',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPathwaySelector() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_alt_rounded, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Choose Your Active Pathway',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              value: _selectedPathway == 'None' ? null : _selectedPathway,
              hint: Text(
                'Select a Skill Pathway',
                style: TextStyle(color: subtitleColor),
              ),
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              items: _pathways.map((pathway) {
                final name = pathway['name']!;
                return DropdownMenuItem<String>(value: name, child: Text(name));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPathway = val;
                  });
                }
              },
            ),
            if (_selectedPathway != 'None') ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              ..._pathways
                  .where((p) => p['name'] == _selectedPathway)
                  .map(
                    (p) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPathwayDetailRow('Focus Domain', p['domain']!),
                        _buildPathwayDetailRow(
                          'XP Categories',
                          p['categories']!,
                        ),
                        _buildPathwayDetailRow(
                          'Team Alignment',
                          p['alignment']!,
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPathwayDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: subtitleColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(val, style: TextStyle(color: textColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── BADGES COLLECTION TAB (LIGHT THEME) ───────────────────────────
  Widget _buildBadgesTab(int currentLevelNum) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: subtitleColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Foundation'),
                Tab(text: 'Achievement'),
                Tab(text: 'Excellence'),
                Tab(text: 'Elite'),
                Tab(text: 'Legacy'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBadgeGrid('Foundation', currentLevelNum),
                _buildBadgeGrid('Achievement', currentLevelNum),
                _buildBadgeGrid('Excellence', currentLevelNum),
                _buildBadgeGrid('Elite', currentLevelNum),
                _buildBadgeGrid('Legacy', currentLevelNum),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(String tier, int currentLevelNum) {
    final badgeProvider = Provider.of<BadgeProvider>(context);
    final list = badgeProvider.availableBadges
        .where((b) => b['tier'] == tier)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final badge = list[index];
        final int badgeId = badge['id'];
        final String name = badge['name'] ?? 'Unknown';
        final IconData icon = _getIconForBadge(badge['iconUrl']);

        final bool isEarned = badgeProvider.earnedBadges.any(
          (b) => (b['badgeId'] ?? b['badge']?['id']) == badgeId,
        );
        final bool isPending = badgeProvider.myBadgeRequests.any(
          (r) => r['badgeId'] == badgeId && r['status'] == 'PENDING',
        );
        final bool isRejected = badgeProvider.myBadgeRequests.any(
          (r) => r['badgeId'] == badgeId && r['status'] == 'REJECTED',
        );

        return GestureDetector(
          onTap: () =>
              _showBadgeDetailModal(badge, isEarned, isPending, isRejected),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isEarned
                    ? primaryColor.withValues(alpha: 0.5)
                    : isPending
                    ? Colors.amber.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: isEarned || isPending ? 1.5 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: isEarned
                        ? primaryColor
                        : isPending
                        ? Colors.amber
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: TextStyle(
                      color: isEarned
                          ? textColor
                          : textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isEarned
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : isPending
                          ? Colors.amber.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEarned
                          ? 'EARNED'
                          : isPending
                          ? 'PENDING'
                          : 'LOCKED',
                      style: TextStyle(
                        color: isEarned
                            ? const Color(0xFF059669)
                            : isPending
                            ? Colors.amber.shade800
                            : Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── BADGE MODAL (LIGHT THEME) ─────────────────────────────────────
  void _showBadgeDetailModal(
    Map<String, dynamic> badge,
    bool isEarned,
    bool isPending,
    bool isRejected,
  ) {
    final int badgeId = badge['id'];
    final String name = badge['name'] ?? 'Unknown';
    final String desc = badge['description'] ?? 'No description';
    final String authority = badge['approvalAuthority'] ?? 'Program Management';
    final String rarity = badge['rarity'] ?? 'Common';
    final IconData icon = _getIconForBadge(badge['iconUrl']);
    final TextEditingController proofLinkController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Row(
                      children: [
                        Icon(icon, size: 44, color: primaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      rarity.toUpperCase(),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Authority: $authority',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      desc,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Badge Approval Workflow (6 Steps)
                    Text(
                      'Badge Approval Workflow (6 Steps)',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildApprovalStep(
                      1,
                      'Claim Submitted',
                      'Student requests badge via portal',
                      true,
                    ),
                    _buildApprovalStep(
                      2,
                      'Evaluator Review',
                      'Verifies eligibility (1-3 days)',
                      isEarned || isPending,
                    ),
                    _buildApprovalStep(
                      3,
                      'Faculty Check',
                      'Quality committee check (2-5 days)',
                      isEarned,
                    ),
                    _buildApprovalStep(
                      4,
                      'Maker-Checker Sign-off',
                      'Approval authority sign-off (1-2 days)',
                      isEarned,
                    ),
                    _buildApprovalStep(
                      5,
                      'Badge Issued',
                      'Awarded to student profile',
                      isEarned,
                    ),
                    _buildApprovalStep(
                      6,
                      'Audit Logging',
                      'Permanent record logged',
                      isEarned,
                    ),

                    const SizedBox(height: 20),

                    // Claim / Status Button Actions
                    if (isEarned)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Badge Earned',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else if (isPending)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Pending Approval',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (isRejected)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your previous request was rejected. You can submit a new claim below.',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: proofLinkController,
                            decoration: InputDecoration(
                              labelText: 'Proof Link (Required)',
                              hintText: 'e.g., https://github.com/my-repo',
                              prefixIcon: const Icon(Icons.link),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                final link = proofLinkController.text.trim();
                                if (link.isEmpty ||
                                    Uri.tryParse(link)?.hasAbsolutePath !=
                                        true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid URL for the Proof Link',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                final provider = context.read<BadgeProvider>();
                                provider
                                    .requestBadgeWorkflow(
                                      context.read<AuthProvider>().token!,
                                      badgeId,
                                      link,
                                    )
                                    .then((response) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              response['message'] ??
                                                  (response['success']
                                                      ? 'Badge requested'
                                                      : 'Failed to request'),
                                            ),
                                            backgroundColor: response['success']
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        );
                                      }
                                    });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Submit Claim',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApprovalStep(
    int num,
    String title,
    String subtitle,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : Colors.grey.shade200,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    )
                  : Text(
                      '$num',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                        : const Color(0xFF64748B).withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
