import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';

class ActivityStreaksPage extends StatelessWidget {
  const ActivityStreaksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);
    final attendanceStreaks = xpProvider.streaks;
    final activityStreaks = xpProvider.activityStreaks;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Streaks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Streaks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            if (activityStreaks.isEmpty)
              const Text('No activity streaks recorded. Enable streaks in activities.', style: TextStyle(color: Colors.grey)),
            ...activityStreaks.map((s) => _buildStreakCard(s, isActivity: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(dynamic streak, {bool isActivity = true}) {
    final String name = streak['activityName']?.toString() ?? 'Activity';
    final int count = streak['currentStreak'] ?? 0;
    
    // Check broken logic
    final bool isBroken = count == 0;
    final int longest = streak['longestStreak'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBroken ? Colors.red.shade200 : Colors.orange.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isBroken ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isBroken ? '💤' : '⚡',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBroken ? 'Broken' : '$count Active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBroken ? Colors.red.shade700 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (longest > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Longest Streak: $longest',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
