import 'package:flutter/material.dart';

class SharedProfileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imageAsset;
  final String? imageUrl;
  final double radius;
  final bool isCaptain;
  final bool isViceCaptain;
  final String? bio;

  const SharedProfileHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.person,
    this.imageAsset,
    this.imageUrl,
    this.radius = 52,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.bio,
  });

  @override
  Widget build(BuildContext context) {
    String? roleBadgeLabel;
    IconData? roleBadgeIcon;
    Color roleBadgeColor = const Color(0xFF4F46E5);
    if (isCaptain) {
      roleBadgeLabel = 'Captain';
      roleBadgeIcon = Icons.workspace_premium_rounded;
      roleBadgeColor = const Color(0xFF8B5CF6);
    } else if (isViceCaptain) {
      roleBadgeLabel = 'Vice Captain';
      roleBadgeIcon = Icons.star_rounded;
      roleBadgeColor = const Color(0xFF7C3AED);
    }

    return Column(
      children: [
        // Avatar Container
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? Image.network(
                    imageUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => (imageAsset != null)
                        ? Image.asset(
                            imageAsset!,
                            width: radius * 2,
                            height: radius * 2,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Icon(
                              icon,
                              size: radius,
                              color: const Color(0xFF4F46E5),
                            ),
                          )
                        : Icon(
                            icon,
                            size: radius,
                            color: const Color(0xFF4F46E5),
                          ),
                  )
                : (imageAsset != null)
                    ? Image.asset(
                        imageAsset!,
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          icon,
                          size: radius,
                          color: const Color(0xFF4F46E5),
                        ),
                      )
                    : Icon(
                        icon,
                        size: radius,
                        color: const Color(0xFF4F46E5),
                      ),
          ),
        ),
        const SizedBox(height: 14),

        // Full Name
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),

        // Role Badge Pill (if Captain or Vice Captain)
        if (roleBadgeLabel != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: roleBadgeColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: roleBadgeColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (roleBadgeIcon != null) ...[
                  Icon(roleBadgeIcon, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  roleBadgeLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (bio != null && bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            bio!.trim(),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 4),

        // Subtitle (Role / RegNo / Dept)
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
