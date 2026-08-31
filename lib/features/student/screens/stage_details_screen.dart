import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/student/screens/activity_details_screen.dart';
import 'package:pragatix/core/utils/string_utils.dart';

class StageDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> stage;

  const StageDetailsScreen({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final String name = stage['name'] ?? 'Stage Details';
    final int expectedXp = (stage['expectedXp'] as num?)?.toInt() ?? 0;
    final int currentXp = ((stage['studentMustXp'] as num?)?.toInt() ?? 0) +
        ((stage['studentIndividualXp'] as num?)?.toInt() ?? 0) +
        ((stage['studentGroupXp'] as num?)?.toInt() ?? 0);
    final double percentage = ((stage['overallPercentage'] as num?)?.toDouble() ??
            (expectedXp > 0 ? (currentXp / expectedXp * 100) : 0.0)) /
        100.0;

    final List subgroups = stage['subgroups'] ?? [];
    final String stageStatus = stage['stageStatus'] ?? 'ACTIVE';
    final bool isCompleted = stageStatus == 'COMPLETED';
    final bool isActive = stageStatus == 'ACTIVE';

    final validSubgroups = subgroups.where((sub) {
      final List acts = (sub['activities'] as List? ?? [])
          .where((act) => act['attendanceEngineEnabled'] != true)
          .toList();
      final int threshold = (sub['threshold'] as num?)?.toInt() ?? 0;
      return acts.isNotEmpty || threshold > 0;
    }).toList();

    int globalActivityCounter = 1;

    int streakCount = 0;
    try {
      streakCount = Provider.of<AttendanceProvider>(context, listen: false).currentStreak;
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Back button, Title, Streak & Mountain Trail Graphic
              _buildTopHeader(context, streakCount),
              const SizedBox(height: 18),

              // Stage Summary Hero Card
              _buildStageSummaryCard(
                currentXp: currentXp,
                expectedXp: expectedXp,
                percentage: percentage.clamp(0.0, 1.0),
                categoriesCount: validSubgroups.isNotEmpty ? validSubgroups.length : 3,
                stageStatus: stageStatus,
              ),
              const SizedBox(height: 22),

              // Subgroups & Activities List
              if (validSubgroups.isEmpty)
                _buildFallbackEmptyOrSampleActivities(context, isActive, isCompleted)
              else
                ...validSubgroups.map((subgroup) {
                  final String rawSubName = subgroup['name'] ?? 'Category';
                  final String subName = StringUtils.toTitleCase(rawSubName);
                  final List rawActivities = subgroup['activities'] ?? [];
                  final List activities = rawActivities
                      .where((act) => act['attendanceEngineEnabled'] != true)
                      .toList();

                  int categoryXp = 0;
                  final lowerName = rawSubName.toLowerCase();
                  if (lowerName.contains('must') || lowerName.contains('mandatory')) {
                    categoryXp = (stage['studentMustXp'] as num?)?.toInt() ?? 0;
                  } else if (lowerName.contains('individual')) {
                    categoryXp = (stage['studentIndividualXp'] as num?)?.toInt() ?? 0;
                  } else if (lowerName.contains('group') || lowerName.contains('team')) {
                    categoryXp = (stage['studentGroupXp'] as num?)?.toInt() ?? 0;
                  } else {
                    for (var act in activities) {
                      categoryXp += (act['awardedXp'] as num?)?.toInt() ?? 0;
                    }
                  }

                  final int threshold = (subgroup['threshold'] as num?)?.toInt() ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subgroup Header Row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  subName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$categoryXp / $threshold XP',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Activities inside this subgroup
                      if (activities.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.auto_awesome, size: 18, color: Color(0xFF4F46E5)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Activities in this category are automatically tracked via attendance.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...activities.map((activity) {
                          final currentIndex = globalActivityCounter++;
                          return _buildActivityCard(
                            context: context,
                            indexNumber: currentIndex,
                            activity: activity,
                            isActive: isActive,
                            isCompleted: isCompleted,
                          );
                        }),
                      const SizedBox(height: 12),
                    ],
                  );
                }),

              const SizedBox(height: 10),

              // Bottom Motivation Card ("Complete all tasks")
              _buildCompleteTasksCard(context, percentage.clamp(0.0, 1.0)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ──────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, int streakCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Mountain with winding path graphic on top-right background
        Positioned(
          right: -10,
          top: -10,
          child: Opacity(
            opacity: 0.95,
            child: Image.asset(
              'assets/images/stage_mountain_path.png',
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Content Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Back Button and Streak Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                ),
                // Streak badge
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
            const SizedBox(height: 14),
            // Title & Subtitle
            const Text(
              'Stage Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Complete tasks and earn XP\nto unlock the next stage.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. Stage Summary Hero Card ─────────────────────────────────────────────
  Widget _buildStageSummaryCard({
    required int currentXp,
    required int expectedXp,
    required double percentage,
    required int categoriesCount,
    required String stageStatus,
  }) {
    final int percentInt = (percentage * 100).toInt();

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
          // Top Row: Title, Status Pill, Percent Complete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Stage Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$stageStatus •',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '$percentInt% Complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Columns: Current XP, Expected XP, Categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeroStatColumn('Current XP', '$currentXp'),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
              _buildHeroStatColumn('Expected XP', '$expectedXp'),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
              _buildHeroStatColumn('Categories', '$categoriesCount'),
            ],
          ),
          const SizedBox(height: 16),

          // White Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),

          // Center Progress Text below bar
          Center(
            child: Text(
              '$currentXp / $expectedXp XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ── 3. Activity Card Item ──────────────────────────────────────────────────
  Widget _buildActivityCard({
    required BuildContext context,
    required int indexNumber,
    required Map<String, dynamic> activity,
    required bool isActive,
    required bool isCompleted,
  }) {
    final String name = activity['activityName'] ?? activity['name'] ?? 'Activity';
    final int rewardXp = (activity['rewardXp'] ?? activity['xp'] ?? 0) as int;
    final int awardedXp = (activity['awardedXp'] ?? 0) as int;
    final String status = (activity['status'] ?? 'PENDING').toString().toUpperCase();
    final bool isActCompleted = status == 'COMPLETED' || awardedXp > 0;

    final String numStr = indexNumber.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (isActive) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityDetailsScreen(activity: activity),
                ),
              );
            } else if (isCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This stage is already completed. Activities are read-only.'),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This stage is currently locked.'),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Number Index Pill Badge (e.g. 01, 02)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      numStr,
                      style: TextStyle(
                        color: isActCompleted ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Middle Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reward: $rewardXp XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Percentage / Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActCompleted ? '100%' : '0%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isActCompleted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Right Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 4. Bottom Complete Tasks Card ──────────────────────────────────────────
  Widget _buildCompleteTasksCard(BuildContext context, double percentage) {
    final int percentInt = (percentage * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
      ),
      child: Row(
        children: [
          // Circular progress gauge
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: percentage > 0 ? percentage : 0.0,
                  strokeWidth: 4.5,
                  backgroundColor: const Color(0xFFEDE9FE),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                ),
              ),
              Text(
                '$percentInt%',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Info Column
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete all tasks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Finish all tasks to complete this stage\nand unlock exciting rewards!',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // View Rewards Button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Complete all category XP requirements to claim your stage badge!'),
                  backgroundColor: Color(0xFF4F46E5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Rewards',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Fallback Demo Activities when subgroups empty ───────────────────────
  Widget _buildFallbackEmptyOrSampleActivities(
    BuildContext context,
    bool isActive,
    bool isCompleted,
  ) {
    final sampleSubgroups = [
      {
        'name': 'Must',
        'threshold': 80,
        'activities': [
          {'activityName': 'Presentable attire', 'rewardXp': 40, 'awardedXp': 0},
        ],
      },
      {
        'name': 'Individual',
        'threshold': 150,
        'activities': [
          {'activityName': 'Assignment Physics', 'rewardXp': 10, 'awardedXp': 0},
          {'activityName': 'MS Word Document', 'rewardXp': 50, 'awardedXp': 0},
          {'activityName': 'MS Excel', 'rewardXp': 50, 'awardedXp': 0},
          {'activityName': 'MS Power Point', 'rewardXp': 50, 'awardedXp': 0},
          {'activityName': 'Oral presentation JAM', 'rewardXp': 50, 'awardedXp': 0},
        ],
      },
    ];

    int counter = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sampleSubgroups.map((subgroup) {
        final String subName = subgroup['name'] as String;
        final int threshold = subgroup['threshold'] as int;
        final List activities = subgroup['activities'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '0 / $threshold XP',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            ...activities.map((act) {
              return _buildActivityCard(
                context: context,
                indexNumber: counter++,
                activity: act,
                isActive: isActive,
                isCompleted: isCompleted,
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}
