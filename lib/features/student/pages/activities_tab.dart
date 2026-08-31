import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/student/screens/stage_details_screen.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  List<Map<String, dynamic>> stages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
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
          final List<dynamic> fetchedStages = data['data'] ?? [];

          final List<Map<String, dynamic>> mapped = fetchedStages
              .map((st) {
                return st as Map<String, dynamic>;
              })
              .toList();

          mapped.sort(
            (a, b) => ((a['displayOrder'] ?? a['id']) as num).compareTo(
              (b['displayOrder'] ?? b['id']) as num,
            ),
          );

          setState(() {
            stages = mapped;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _initializeData: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: PragatiXLoader(fullScreen: false, message: 'Loading Activities...'),
        ),
      );
    }

    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    // Compute dynamic overall progress across all loaded stages
    int totalSubgroups = 0;
    int completedSubgroups = 0;
    for (var st in stages) {
      final int cCount = (st['overallCompletedSubgroups'] as num?)?.toInt() ?? 0;
      final int tCount = (st['overallTotalSubgroups'] as num?)?.toInt() ??
          (st['subgroups'] as List?)?.length ??
          0;
      totalSubgroups += tCount;
      completedSubgroups += cCount;
    }
    final double overallProgress =
        totalSubgroups > 0 ? (completedSubgroups / totalSubgroups) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initializeData,
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section with Mountain Graphic & Streak
                _buildTopHeader(attendanceProvider.currentStreak),
                const SizedBox(height: 20),

                // Hero Progress Card ("Your Progress") with Trophy
                _buildHeroProgressCard(
                  completedSubgroups: completedSubgroups,
                  totalSubgroups: totalSubgroups,
                  overallProgress: overallProgress,
                ),
                const SizedBox(height: 20),

                // Dynamic Timeline Roadmap Stage List
                if (stages.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hiking_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No activities or stages found.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stages.length,
                    itemBuilder: (context, index) {
                      final stage = stages[index];
                      return _buildTimelineItem(
                        index: index + 1,
                        totalItems: stages.length,
                        stage: stage,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StageDetailsScreen(stage: stage),
                            ),
                          ).then((_) {
                            _initializeData();
                          });
                        },
                      );
                    },
                  ),

                const SizedBox(height: 12),

                // Motivation Banner ("Keep Going!") with Gift Box
                _buildMotivationBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ──────────────────────────────────────────────────────────
  Widget _buildTopHeader(int streakCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Mountain flag graphic on top-right background
        Positioned(
          right: 35,
          top: -10,
          child: Opacity(
            opacity: 0.95,
            child: Image.asset(
              'assets/images/activities_mountain_flag.png',
              height: 95,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Text & Streak row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activities & Stages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Complete subgroups to unlock\nthe next stages.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            // Streak pill badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$streakCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. Hero Progress Card ──────────────────────────────────────────────────
  Widget _buildHeroProgressCard({
    required int completedSubgroups,
    required int totalSubgroups,
    required double overallProgress,
  }) {
    final int percentInt = (overallProgress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular progress gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: overallProgress > 0 ? overallProgress : 0.0,
                      strokeWidth: 5.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  Text(
                    '$percentInt%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Subgroups completed description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedSubgroups / $totalSubgroups Subgroups Completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep going! Great things await you.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trophy asset illustration
              Image.asset(
                'assets/images/activities_trophy.png',
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFD700),
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Timeline Stage Roadmap Item (Centered Alignment) ───────────────────
  Widget _buildTimelineItem({
    required int index,
    required int totalItems,
    required Map<String, dynamic> stage,
    required VoidCallback onTap,
  }) {
    final int stageNumber = (stage['displayOrder'] as num?)?.toInt() ?? index;
    final bool isCompleted =
        stage['isCompleted'] == true || stage['stageStatus'] == 'COMPLETED';
    final bool isLocked = (stage['isLocked'] == true ||
            stage['locked'] == true ||
            stage['stageStatus'] == 'LOCKED') &&
        !isCompleted;
    final bool isActive = !isLocked && !isCompleted;
    final String name = stage['name'] ?? 'Stage $stageNumber';
    final int completedCount =
        (stage['overallCompletedSubgroups'] as num?)?.toInt() ?? 0;
    final int totalCount =
        (stage['overallTotalSubgroups'] as num?)?.toInt() ??
        (stage['subgroups'] as List?)?.length ??
        3;
    final int percentage = ((stage['overallPercentage'] as num?)?.toDouble() ??
            (totalCount > 0 ? (completedCount / totalCount * 100) : 0))
        .toInt();

    final Color nodeColor = isCompleted
        ? const Color(0xFF16A34A)
        : (isActive ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1));

    const Color lineColor = Color(0xFFE2E8F0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left timeline column: Top Line, Centered Circle Node, Bottom Line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                // Top line (connects to previous stage above)
                Expanded(
                  child: index > 1
                      ? Center(
                          child: Container(
                            width: 2,
                            color: lineColor,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Centered Circle node
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeColor,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4F46E5)
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : Text(
                            '$stageNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                  ),
                ),
                // Bottom line (connects to next stage below)
                Expanded(
                  child: index < totalItems
                      ? Center(
                          child: Container(
                            width: 2,
                            color: lineColor,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right Stage Card (vertically padded for clean card spacing)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFEDE9FE)
                        : const Color(0xFFF1F5F9),
                    width: isActive ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: !isLocked ? onTap : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Circular leading icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? const Color(0xFFDCFCE7)
                                  : (isActive
                                      ? const Color(0xFFEDE9FE)
                                      : const Color(0xFFF1F5F9)),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : (isActive
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_rounded),
                              color: isCompleted
                                  ? const Color(0xFF16A34A)
                                  : (isActive
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF94A3B8)),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Middle text column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isCompleted
                                      ? 'Stage Completed'
                                      : (isActive
                                          ? 'Complete $totalCount subgroups'
                                          : 'Complete previous stage'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isCompleted
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF64748B),
                                    fontWeight: isCompleted
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (isActive)
                                  Text(
                                    'Progress: $percentage% • $completedCount / $totalCount Subgroups',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  )
                                else if (isLocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Locked',
                                      style: TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if (isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Right Chevron
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isActive
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFCBD5E1),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Bottom Motivation Banner ────────────────────────────────────────────
  Widget _buildMotivationBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
      ),
      child: Row(
        children: [
          // Star Icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDE9FE),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Color(0xFF7C3AED),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Info Column
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep Going!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Complete subgroups, earn XP and\nunlock exciting rewards.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Gift Box asset illustration
          Image.asset(
            'assets/images/activities_gift_box.png',
            height: 52,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFF7C3AED),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
