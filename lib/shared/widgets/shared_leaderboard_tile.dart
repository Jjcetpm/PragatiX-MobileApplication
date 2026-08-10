import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';

class SharedLeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final String subtitle;
  final int score;
  final bool isCurrentUser;
  final Color themeColor;
  final bool isCaptain;
  final bool isViceCaptain;

  const SharedLeaderboardTile({
    super.key,
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.score,
    this.isCurrentUser = false,
    this.themeColor = AppColors.studentPrimary,
    this.isCaptain = false,
    this.isViceCaptain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? BorderSide(color: themeColor, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentUser ? themeColor.withValues(alpha: 0.05) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.rankGold.withValues(alpha: 0.15)
                : (rank == 2
                      ? AppColors.rankSilver.withValues(alpha: 0.15)
                      : (rank == 3
                            ? AppColors.rankBronze.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1))),
            shape: BoxShape.circle,
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: rank == 1
                  ? AppColors.rankGold
                  : (rank == 2
                        ? AppColors.rankSilver
                        : (rank == 3
                              ? AppColors.rankBronze
                              : Colors.grey.shade700)),
              fontSize: 13,
            ),
          ),
        ),
        title: Row(
          children: [
            if (isCaptain) const Text('👑 ', style: TextStyle(fontSize: 14)),
            if (isViceCaptain)
              const Text('🥈 ', style: TextStyle(fontSize: 14)),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? themeColor : AppColors.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          '$score pts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: themeColor,
          ),
        ),
      ),
    );
  }
}
