import 'package:flutter/material.dart';

class FireStreakIcon extends StatelessWidget {
  final int streakCount;

  const FireStreakIcon({Key? key, required this.streakCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasStreak = streakCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasStreak
            ? Colors.orange.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasStreak
              ? Colors.orange.withOpacity(0.5)
              : Colors.grey.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: hasStreak
                  ? [Colors.orange, Colors.red]
                  : [Colors.grey, Colors.grey.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$streakCount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: hasStreak ? Colors.orange.shade800 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
