import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';

class SharedStudentCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color themeColor;
  final VoidCallback? onTap;
  final Widget? trailingContent;
  final int? score;
  final String? gender;

  const SharedStudentCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.themeColor,
    this.onTap,
    this.trailingContent,
    this.score,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final String g = (gender ?? '').trim().toLowerCase();
    final bool isFemale = g.startsWith('f') || g == 'girl';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
            border: Border.all(
              color: isFemale ? const Color(0xFFFBCFE8) : const Color(0xFFBFDBFE),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isFemale ? const Color(0xFFDB2777) : const Color(0xFF2563EB),
              ),
            ),
          ),
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
