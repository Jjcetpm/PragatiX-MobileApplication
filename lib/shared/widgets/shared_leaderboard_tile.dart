import 'package:flutter/material.dart';

class SharedLeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final String subtitle;
  final int score;
  final String? gender;
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
    this.gender,
    this.isCurrentUser = false,
    this.themeColor = const Color(0xFF4F46E5),
    this.isCaptain = false,
    this.isViceCaptain = false,
  });

  Color _getAccentColor(int rank) {
    const colors = [
      Color(0xFF6366F1), // Indigo/Purple
      Color(0xFF10B981), // Mint Emerald
      Color(0xFFF97316), // Orange
      Color(0xFF0EA5E9), // Sky Blue
      Color(0xFF8B5CF6), // Violet
      Color(0xFFEC4899), // Pink
      Color(0xFFF59E0B), // Amber
    ];
    return colors[(rank - 1) % colors.length];
  }

  Widget _buildAvatar() {
    final String g = (gender ?? '').trim().toLowerCase();
    final bool isFemale = g.startsWith('f') || g == 'female' || g == 'girl';
    final String avatarAsset = isFemale
        ? 'assets/images/avatar_female.png'
        : 'assets/images/avatar_male.png';

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          avatarAsset,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            backgroundColor: const Color(0xFFEDE9FE),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? themeColor : const Color(0xFFF1F5F9),
          width: isCurrentUser ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Colored Accent Strip
              Container(
                width: 4,
                color: accentColor,
              ),
              const SizedBox(width: 10),

              // Rank Circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Gender Avatar
              _buildAvatar(),
              const SizedBox(width: 12),

              // Name and Department Subtitle
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          if (isCaptain)
                            const Text('👑 ', style: TextStyle(fontSize: 13)),
                          if (isViceCaptain)
                            const Text('🥈 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Trailing Points and Star Icon
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score pts',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.star_outline_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
