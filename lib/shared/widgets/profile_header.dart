import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';

class SharedProfileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final double radius;
  final bool isCaptain;
  final bool isViceCaptain;

  const SharedProfileHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.person,
    this.radius = 50,
    this.isCaptain = false,
    this.isViceCaptain = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use the calling context's theme primaryColor if available,
    // otherwise fall back to AppColors.darkSlate.
    final color = Theme.of(context).primaryColor;
    return Column(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, size: radius, color: color),
        ),
        const SizedBox(height: 16),
        Text(
          isCaptain ? '👑 $title' : title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        if (isCaptain || isViceCaptain) ...[
          const SizedBox(height: 4),
          Text(
            isCaptain ? '[Captain]' : '[Vice Captain]',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
