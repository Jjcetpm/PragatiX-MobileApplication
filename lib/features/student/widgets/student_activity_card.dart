import 'package:flutter/material.dart';

class StudentActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;

  const StudentActivityCard({
    Key? key,
    required this.activity,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = activity['activityName'] ?? 'Activity';
    final int rewardXp = activity['rewardXp'] ?? 0;
    final int awardedXp = activity['awardedXp'] ?? 0;
    final String status = activity['status'] ?? 'PENDING';
    final bool isCompleted = status == 'COMPLETED';

    final darkColor = const Color(0xFF1E293B);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted ? Colors.green.shade50.withOpacity(0.3) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.star_border,
                  color: isCompleted ? Colors.green : Colors.blue,
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
                        color: darkColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? 'Completed • Earned $awardedXp XP'
                          : 'Reward: $rewardXp XP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
