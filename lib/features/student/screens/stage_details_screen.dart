import 'package:flutter/material.dart';
import 'package:pragatix/features/student/widgets/student_activity_card.dart';
import 'package:pragatix/features/student/screens/activity_details_screen.dart';
import 'package:pragatix/core/utils/string_utils.dart';

class StageDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> stage;

  const StageDetailsScreen({Key? key, required this.stage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = stage['name'] ?? 'Stage Details';
    final String description = stage['description'] ?? '';
    final int expectedXp = stage['expectedXp'] ?? 0;
    final int currentXp =
        (stage['studentMustXp'] ?? 0) +
        (stage['studentIndividualXp'] ?? 0) +
        (stage['studentGroupXp'] ?? 0);
    final double percentage = (stage['overallPercentage'] ?? 0.0) / 100.0;

    final List subgroups = stage['subgroups'] ?? [];

    // Filter out subgroups with no activities
    final String stageStatus = stage['stageStatus'] ?? 'LOCKED';
    final bool isCompleted = stageStatus == 'COMPLETED';
    final bool isLocked = stageStatus == 'LOCKED';
    final bool isActive = stageStatus == 'ACTIVE';

    final validSubgroups = subgroups.where((sub) {
      final List acts = sub['activities'] ?? [];
      return acts.isNotEmpty;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stage Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stageStatus,
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.greenAccent
                                  : (isActive
                                        ? Colors.amberAccent
                                        : Colors.grey.shade300),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(percentage * 100).toInt()}% Complete',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn('Current XP', '$currentXp'),
                      _StatColumn('Expected XP', '$expectedXp'),
                      _StatColumn('Categories', '${validSubgroups.length}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (validSubgroups.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activities available for this stage yet.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...validSubgroups.map((subgroup) {
                final String rawSubName = subgroup['name'] ?? 'Category';
                final String subName = StringUtils.toTitleCase(rawSubName);
                final List activities = subgroup['activities'] ?? [];

                int completedCount = 0;
                int categoryXp = 0;

                for (var act in activities) {
                  if (act['status'] == 'COMPLETED') {
                    completedCount++;
                  }
                  categoryXp += (act['awardedXp'] as num?)?.toInt() ?? 0;
                }

                final int threshold = subgroup['threshold'] ?? 0;
                final bool isPassed = categoryXp >= threshold && threshold > 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPassed
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$categoryXp / $threshold XP',
                            style: TextStyle(
                              color: isPassed
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Activities
                    ...activities.map((activity) {
                      return StudentActivityCard(
                        activity: activity,
                        onTap: () {
                          if (isActive) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ActivityDetailsScreen(activity: activity),
                              ),
                            );
                          } else if (isCompleted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This stage is already completed. Activities are read-only.',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This stage is currently locked.',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
