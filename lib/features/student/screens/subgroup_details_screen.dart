import 'package:flutter/material.dart';
import 'package:pragatix/features/student/widgets/student_activity_card.dart';
import 'package:pragatix/features/student/screens/activity_details_screen.dart';
import 'package:pragatix/features/student/widgets/progress_card.dart';

import 'package:pragatix/core/utils/string_utils.dart';

class SubgroupDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> subgroup;

  const SubgroupDetailsScreen({Key? key, required this.subgroup})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String rawName = subgroup['name'] ?? 'Subgroup Details';
    final String name = StringUtils.toTitleCase(rawName);
    final List activities = subgroup['activities'] ?? [];

    int completedCount = 0;
    int currentXp = 0;

    for (var act in activities) {
      if (act['status'] == 'COMPLETED') {
        completedCount++;
      }
      currentXp += (act['awardedXp'] as num?)?.toInt() ?? 0;
    }

    final int threshold = subgroup['threshold'] ?? 0;
    final double progress = threshold > 0
        ? (currentXp / threshold).clamp(0.0, 1.0)
        : 0.0;
    final bool isPassed = currentXp >= threshold && threshold > 0;

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
            // Subgroup Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${isPassed ? "Threshold Met!" : "Keep Going!"}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isPassed
                                ? Colors.green.shade700
                                : Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You have completed $completedCount out of ${activities.length} activities in this category.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ProgressCard(
                    percentage: progress,
                    centerText: '${(progress * 100).toInt()}%',
                    label: '$currentXp / $threshold XP',
                    color: isPassed ? Colors.green : const Color(0xFF4F46E5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activities',
                  style: TextStyle(
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activities.length} total',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (activities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No activities found.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ...activities.map((activity) {
                return StudentActivityCard(
                  activity: activity,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailsScreen(activity: activity),
                      ),
                    );
                  },
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
