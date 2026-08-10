import 'package:flutter/material.dart';
import 'package:pragatix/features/student/widgets/progress_card.dart';

import 'package:pragatix/core/utils/string_utils.dart';

class SubgroupCard extends StatelessWidget {
  final Map<String, dynamic> subgroup;
  final VoidCallback onTap;

  const SubgroupCard({Key? key, required this.subgroup, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String rawName = subgroup['name'] ?? 'Subgroup';
    final String name = StringUtils.toTitleCase(rawName);
    final List activities = subgroup['activities'] ?? [];

    // For progress, we calculate based on the activities completed
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

    final darkColor = const Color(0xFF1E293B);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.0),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed: $completedCount / ${activities.length} Activities',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
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
                color: isPassed ? Colors.green : Colors.amber.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
