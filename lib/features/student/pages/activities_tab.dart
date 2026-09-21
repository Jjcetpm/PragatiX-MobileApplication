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
  final VoidCallback? onBack;

  const ActivitiesTab({super.key, this.onBack});

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
    if (mounted) setState(() => isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isEmpty || token == 'debug_token') {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/stages'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

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

          if (mounted) {
            setState(() {
              stages = mapped;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _initializeData: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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

                // Hero Progress Card ("Your Progress")
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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ──────────────────────────────────────────────────────────
  Widget _buildTopHeader(int streakCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activities & Stages',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
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
        const SizedBox(width: 8),
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
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
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
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11.5,
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

  // ── 3. Stage Roadmap Item ──────────────────────────────────────────────────
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFFBAE6FD)
                : const Color(0xFFF1F5F9),
            width: isActive ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFF0284C7).withValues(alpha: 0.06)
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
                  // Circular leading icon with Stage Number (No lock symbol)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFFDCFCE7)
                          : (isActive
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFF1F5F9)),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF16A34A),
                              size: 24,
                            )
                          : Text(
                              '$stageNumber',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isActive
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
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
                              color: Color(0xFF0284C7),
                            ),
                          )
                        else if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Upcoming',
                              style: TextStyle(
                                color: Color(0xFF64748B),
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
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFCBD5E1),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
