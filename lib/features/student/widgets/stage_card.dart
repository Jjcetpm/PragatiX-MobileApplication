import 'package:flutter/material.dart';

class StageCard extends StatelessWidget {
  final Map<String, dynamic> stage;
  final VoidCallback onTap;

  const StageCard({Key? key, required this.stage, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = stage['isCompleted'] == true;
    final bool isLocked = stage['isLocked'] == true && !isCompleted;
    final String name = stage['name'] ?? 'Stage';
    final int completedCount = stage['overallCompletedSubgroups'] ?? 0;
    final int totalCount = stage['overallTotalSubgroups'] ?? 0;
    final double percentage = (stage['overallPercentage'] ?? 0.0) / 100.0;

    final primaryColor = const Color(0xFF4F46E5);
    final darkColor = const Color(0xFF1E293B);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLocked
              ? Colors.grey.shade200.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: isLocked ? 0.8 : 1.0,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      color: isLocked
          ? Colors.grey.shade50.withValues(alpha: 0.8)
          : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLocked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.shade200
                      : (isCompleted
                            ? Colors.green.withValues(alpha: 0.1)
                            : primaryColor.withValues(alpha: 0.1)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLocked
                      ? Icons.lock_rounded
                      : (isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.lock_open_rounded),
                  color: isLocked
                      ? Colors.grey.shade500
                      : (isCompleted ? Colors.green : primaryColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.grey.shade500 : darkColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked
                          ? 'Stage Locked'
                          : (isCompleted
                                ? 'Stage Completed'
                                : 'Progress: ${(percentage * 100).toInt()}% • $completedCount/$totalCount Subgroups'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? Colors.grey.shade500
                            : (isCompleted
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLocked)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
