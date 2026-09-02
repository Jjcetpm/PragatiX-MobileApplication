import 'package:flutter/material.dart';

class LeaderboardPodium extends StatelessWidget {
  final List<Map<String, dynamic>> topStudents;
  final String? currentUserId;
  final VoidCallback? onViewAll;

  const LeaderboardPodium({
    super.key,
    required this.topStudents,
    this.currentUserId,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (topStudents.isEmpty) return const SizedBox.shrink();

    final Map<String, dynamic>? first = topStudents.isNotEmpty ? topStudents[0] : null;
    final Map<String, dynamic>? second = topStudents.length > 1 ? topStudents[1] : null;
    final Map<String, dynamic>? third = topStudents.length > 2 ? topStudents[2] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Performers (Sorted by Total XP)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3-Pillar Podium
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2: Silver (Left)
              Expanded(
                child: second != null
                    ? _buildPodiumColumn(
                        student: second,
                        rank: 2,
                        pedestalHeight: 65,
                        avatarRadius: 26,
                        pedestalColor: const Color(0xFFEEF2FF),
                        pedestalBorderColor: const Color(0xFFE0E7FF),
                        avatarBg: const Color(0xFFE2E8F0),
                        avatarTextColor: const Color(0xFF475569),
                        ribbonColor: const Color(0xFF94A3B8),
                        medalIcon: Icons.military_tech_rounded,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // Rank 1: Gold (Center - Tallest)
              Expanded(
                child: first != null
                    ? _buildCenterGoldColumn(student: first)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // Rank 3: Bronze (Right)
              Expanded(
                child: third != null
                    ? _buildPodiumColumn(
                        student: third,
                        rank: 3,
                        pedestalHeight: 52,
                        avatarRadius: 26,
                        pedestalColor: const Color(0xFFFFEDD5),
                        pedestalBorderColor: const Color(0xFFFED7AA),
                        avatarBg: const Color(0xFFFFEDD5),
                        avatarTextColor: const Color(0xFF9A3412),
                        ribbonColor: const Color(0xFFCD7F32),
                        medalIcon: Icons.military_tech_rounded,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Rank 1 Center Gold Column ──────────────────────────────────────────────
  Widget _buildCenterGoldColumn({required Map<String, dynamic> student}) {
    final String name = student['fullName'] ?? 'Unknown';
    final int score = (student['totalXp'] is num)
        ? (student['totalXp'] as num).toInt()
        : (int.tryParse(student['totalXp']?.toString() ?? '0') ?? 0);
    final String g = (student['gender'] ?? '').toString().trim().toLowerCase();
    final bool isFemale = g.startsWith('f') || g == 'female' || g == 'girl';
    final String avatarAsset = isFemale
        ? 'assets/images/avatar_female.png'
        : 'assets/images/avatar_male.png';

    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Golden Crown on top
          const Text('👑', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 2),

          // Avatar with overlapping Gold #1 Pill
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    avatarAsset,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                      backgroundColor: const Color(0xFF4F46E5),
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF59E0B),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Score
          Text(
            '$score XP',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 10),

          // Tall Purple Gradient Pedestal Stand
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rank 2 & 3 Standard Column ─────────────────────────────────────────────
  Widget _buildPodiumColumn({
    required Map<String, dynamic> student,
    required int rank,
    required double pedestalHeight,
    required double avatarRadius,
    required Color pedestalColor,
    required Color pedestalBorderColor,
    required Color avatarBg,
    required Color avatarTextColor,
    required Color ribbonColor,
    required IconData medalIcon,
  }) {
    final String name = student['fullName'] ?? 'Unknown';
    final int score = (student['totalXp'] is num)
        ? (student['totalXp'] as num).toInt()
        : (int.tryParse(student['totalXp']?.toString() ?? '0') ?? 0);
    final String g = (student['gender'] ?? '').toString().trim().toLowerCase();
    final bool isFemale = g.startsWith('f') || g == 'female' || g == 'girl';
    final String avatarAsset = isFemale
        ? 'assets/images/avatar_female.png'
        : 'assets/images/avatar_male.png';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Ribbon Medal Badge
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ribbonColor.withValues(alpha: 0.15),
          ),
          child: Icon(medalIcon, size: 20, color: ribbonColor),
        ),
        const SizedBox(height: 6),

        // Gender Avatar with Rank Badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ribbonColor.withValues(alpha: 0.7), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  avatarAsset,
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: avatarBg,
                    child: Text(
                      _getInitials(name),
                      style: TextStyle(
                        color: avatarTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ribbonColor,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 2),

        // Score
        Text(
          '$score XP',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(height: 8),

        // Pedestal Box
        Container(
          height: pedestalHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pedestalColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: pedestalBorderColor, width: 1.2),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
