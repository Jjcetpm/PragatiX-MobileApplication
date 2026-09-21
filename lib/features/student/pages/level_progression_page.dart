import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';

class LevelProgressionPage extends StatefulWidget {
  const LevelProgressionPage({super.key});

  @override
  State<LevelProgressionPage> createState() => _LevelProgressionPageState();
}

class _LevelProgressionPageState extends State<LevelProgressionPage> {
  bool _isLoading = true;

  final Color primaryIndigo = const Color(0xFF4F46E5);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color textColor = const Color(0xFF0F172A);
  final Color subtitleColor = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null && token.isNotEmpty && token != 'debug_token') {
        final xp = Provider.of<XpProvider>(context, listen: false);
        await xp.fetchProgression(token);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);

    if (_isLoading || xpProvider.isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(),
        body: const Center(
          child: PragatiXLoader(fullScreen: false, message: 'Loading Progression...'),
        ),
      );
    }

    final progression = xpProvider.progression;

    // Fallback standard 5 levels if backend returns empty
    final List<Map<String, dynamic>> fallbackLevels = [
      {
        'levelNumber': 1,
        'title': 'Explorer',
        'xpMin': 0,
        'xpMax': 100,
        'primaryObjective': 'Build participation habits',
      },
      {
        'levelNumber': 2,
        'title': 'Builder',
        'xpMin': 101,
        'xpMax': 500,
        'primaryObjective': 'Develop consistency & discipline',
      },
      {
        'levelNumber': 3,
        'title': 'Innovator',
        'xpMin': 501,
        'xpMax': 1500,
        'primaryObjective': 'Build technical & collaborative skills',
      },
      {
        'levelNumber': 4,
        'title': 'Leader',
        'xpMin': 1501,
        'xpMax': 3000,
        'primaryObjective': 'Lead projects and inspire peers',
      },
      {
        'levelNumber': 5,
        'title': 'Visionary',
        'xpMin': 3001,
        'xpMax': 5000,
        'primaryObjective': 'Create impact and drive innovation',
      },
    ];

    final int currentLevelNum = progression?['currentLevel'] ?? 3;
    final String currentLevelTitle = progression?['currentLevelName'] ?? 'Innovator';
    final int totalXp = progression?['totalXp'] ?? 540;
    final int xpMax = progression?['currentLevelMaxXp'] ?? 1500;
    final double levelProgress = progression != null
        ? ((progression['progressPercentage'] ?? 36.0) as num).toDouble() / 100.0
        : (totalXp / xpMax).clamp(0.0, 1.0);
    final int remainingXp = progression?['remainingXp'] ?? (xpMax - totalXp > 0 ? xpMax - totalXp : 0);

    final List<dynamic> rawUnlocked = progression?['unlockedLevels'] ?? [];
    final List<dynamic> rawLocked = progression?['lockedLevels'] ?? [];
    final List<dynamic> allLevels = (rawUnlocked.isNotEmpty || rawLocked.isNotEmpty)
        ? [...rawUnlocked, ...rawLocked]
        : fallbackLevels;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryIndigo,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Current Level Hero Card with Circular Ring
              _buildHeroLevelCard(
                currentLevelNum: currentLevelNum,
                title: currentLevelTitle,
                totalXp: totalXp,
                targetXp: xpMax,
                remainingXp: remainingXp,
                progress: levelProgress,
              ),
              const SizedBox(height: 14),

              // 2. 4-Column Dark Summary Metrics
              _buildDarkSummaryBox(
                totalXp: totalXp,
                targetXp: xpMax,
                remainingXp: remainingXp,
                completedLevels: currentLevelNum, // In screenshot shows current lvl ratio e.g. 3 / 8
                totalLevels: allLevels.length,
              ),
              const SizedBox(height: 24),

              // 3. Section Header
              Text(
                'Your Progress Journey',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete levels and earn XP to reach new heights!',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // 4. Vertical Stepper Level Cards
              _buildLevelTimeline(
                allLevels: allLevels,
                currentLevelNum: currentLevelNum,
                totalXp: totalXp,
                levelProgress: levelProgress,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Gradient App Bar ───────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Level Progression',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 19,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ── 1. Hero Current Level Card ─────────────────────────────────────────────
  Widget _buildHeroLevelCard({
    required int currentLevelNum,
    required String title,
    required int totalXp,
    required int targetXp,
    required int remainingXp,
    required double progress,
  }) {
    final int percentInt = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Info & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT LEVEL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6366F1),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lvl $currentLevelNum: $title',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),

                // XP Points & Target Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalXp XP Points',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: primaryIndigo,
                      ),
                    ),
                    Text(
                      'Target: $targetXp XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEDE9FE),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryIndigo),
                  ),
                ),
                const SizedBox(height: 8),

                // Remaining XP
                Text(
                  'Remaining: $remainingXp XP',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right: Circular Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFFEDE9FE),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryIndigo),
                ),
              ),
              Text(
                '$percentInt%',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. 4-Column Dark Summary Box ───────────────────────────────────────────
  Widget _buildDarkSummaryBox({
    required int totalXp,
    required int targetXp,
    required int remainingXp,
    required int completedLevels,
    required int totalLevels,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMetricColumn('$totalXp', 'Current XP'),
          _buildDivider(),
          _buildMetricColumn('$targetXp', 'Target XP'),
          _buildDivider(),
          _buildMetricColumn('$remainingXp', 'XP to next level'),
          _buildDivider(),
          _buildMetricColumn('$completedLevels / $totalLevels', 'Levels Completed'),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
              height: 1.15,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 26,
      width: 1,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  // ── 3. Level Progression Timeline List ─────────────────────────────────────
  Widget _buildLevelTimeline({
    required List<dynamic> allLevels,
    required int currentLevelNum,
    required int totalXp,
    required double levelProgress,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allLevels.length,
      itemBuilder: (context, index) {
        final lvl = allLevels[index];
        final int lvlNum = lvl['levelNumber'] ?? (index + 1);
        final String lvlTitle = lvl['title'] ?? 'Level $lvlNum';
        final int xpMin = lvl['xpMin'] ?? 0;
        final int xpMax = lvl['xpMax'] ?? 100;
        final String range = xpMax >= 99999 ? '$xpMin+' : '$xpMin - $xpMax';
        final String objective = lvl['primaryObjective'] ?? 'Complete stage activities';

        final bool isCurrent = lvlNum == currentLevelNum;
        final bool isCompleted = lvlNum < currentLevelNum;
        final bool isLocked = lvlNum > currentLevelNum;
        final bool isLast = index == allLevels.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Timeline Node & Connecting Line
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    // Node Icon Circle
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF4F46E5)
                            : isCurrent
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFE2E8F0),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : isCurrent
                            ? Text(
                                '$lvlNum',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right: Level Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCurrent ? const Color(0xFF818CF8) : const Color(0xFFF1F5F9),
                      width: isCurrent ? 1.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: isCurrent ? 0.05 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level Title & Status Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level $lvlNum: $lvlTitle',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isLocked ? const Color(0xFF475569) : textColor,
                            ),
                          ),
                          _buildStatusPill(isCompleted, isCurrent, isLocked),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // XP Range
                      Text(
                        'XP Range: $range',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Objective
                      Text(
                        'Objective: $objective',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                          height: 1.25,
                        ),
                      ),

                      // Bottom Progress Info for Completed / Current
                      if (isCompleted) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$xpMax / $xpMax XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: primaryIndigo,
                            ),
                          ),
                        ),
                      ] else if (isCurrent) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$totalXp / $xpMax XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: primaryIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: levelProgress.clamp(0.0, 1.0),
                            minHeight: 4.5,
                            backgroundColor: const Color(0xFFEDE9FE),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryIndigo),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(bool isCompleted, bool isCurrent, bool isLocked) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Completed',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Current Level',
          style: TextStyle(
            color: Color(0xFF6366F1),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Locked',
        style: TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
