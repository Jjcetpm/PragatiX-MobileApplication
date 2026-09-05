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
    final int penaltyXp = activity['penaltyXp'] ?? 0;
    final int awardedXp = activity['awardedXp'] ?? 0;
    final String status = activity['status'] ?? 'PENDING';
    final bool isCompleted = status == 'COMPLETED';
    final String xpType = (activity['xpType'] ?? '').toString().toUpperCase();
    final bool isPenalty = xpType == 'PENALTY' || (penaltyXp > 0 && rewardXp == 0);
    final bool isBoth = xpType == 'BOTH' || (rewardXp > 0 && penaltyXp > 0);

    final darkColor = const Color(0xFF1E293B);

    String xpSubtitle;
    Color xpColor;
    if (isCompleted) {
      xpSubtitle = 'Completed • Earned $awardedXp XP';
      xpColor = Colors.green.shade700;
    } else if (isPenalty) {
      final val = penaltyXp > 0 ? penaltyXp : rewardXp;
      xpSubtitle = 'Penalty: -$val XP';
      xpColor = Colors.red.shade600;
    } else if (isBoth) {
      xpSubtitle = 'Reward: $rewardXp • Penalty: -$penaltyXp XP';
      xpColor = Colors.grey.shade600;
    } else {
      xpSubtitle = 'Reward: $rewardXp XP';
      xpColor = Colors.grey.shade600;
    }

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
                      : (isPenalty ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : (isPenalty ? Icons.warning_amber_rounded : Icons.star_border),
                  color: isCompleted
                      ? Colors.green
                      : (isPenalty ? Colors.red : Colors.blue),
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
                      xpSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: xpColor,
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
