import 'package:flutter/material.dart';
import 'package:pragatix/features/leaderboard/pages/shared_leaderboard_page.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/student/repository/student_repository.dart';

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedLeaderboardPage(
      title: 'Leaderboard',
      showFilters: true,
      showCurrentUserRank: true,
      fetchCurrentUser: () async {
        return getIt<StudentRepository>().getCurrentUser();
      },
    );
  }
}
