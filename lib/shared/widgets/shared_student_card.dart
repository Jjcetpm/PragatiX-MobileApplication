import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';

class SharedStudentCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color themeColor;
  final VoidCallback? onTap;
  final Widget? trailingContent;
  final int? score;

  const SharedStudentCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.themeColor,
    this.onTap,
    this.trailingContent,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeColor.withValues(alpha: 0.1),
          child: Icon(Icons.person, color: themeColor),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (score != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
            ?trailingContent,
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
