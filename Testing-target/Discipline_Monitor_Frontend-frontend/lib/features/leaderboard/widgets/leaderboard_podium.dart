import 'package:flutter/material.dart';

class LeaderboardPodium extends StatelessWidget {
  final List<Map<String, dynamic>> topStudents;
  final String? currentUserId;

  const LeaderboardPodium({
    super.key,
    required this.topStudents,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (topStudents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topStudents.length > 1)
            _buildPodiumItem(
              context,
              student: topStudents[1],
              rank: 2,
              height: 120,
              color: const Color(0xFFC0C0C0),
              label: '🥈',
            ),
          if (topStudents.isNotEmpty)
            _buildPodiumItem(
              context,
              student: topStudents[0],
              rank: 1,
              height: 160,
              color: const Color(0xFFFFD700),
              label: '🥇',
            ),
          if (topStudents.length > 2)
            _buildPodiumItem(
              context,
              student: topStudents[2],
              rank: 3,
              height: 90,
              color: const Color(0xFFCD7F32),
              label: '🥉',
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    BuildContext context, {
    required Map<String, dynamic> student,
    required int rank,
    required double height,
    required Color color,
    required String label,
  }) {
    final bool isCurrentUser = student['regNo'] == currentUserId;
    final String name = student['fullName'] ?? 'Unknown';
    final int score = student['score'] ?? 0;

    // Extract initials for avatar placeholder
    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: rank == 1 ? 32 : 24,
            backgroundColor: isCurrentUser
                ? Colors.blue.shade100
                : color.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: TextStyle(
                color: isCurrentUser
                    ? Colors.blue.shade900
                    : color.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 22 : 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.bold,
              fontSize: rank == 1 ? 16 : 14,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            '$score XP',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: rank == 1 ? 14 : 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: height,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(top: BorderSide(color: color, width: 4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: rank == 1 ? 28 : 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
