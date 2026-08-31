import 'package:flutter/material.dart';
import 'package:pragatix/features/leaderboard/pages/shared_leaderboard_page.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/captain/repository/captain_repository.dart';

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedLeaderboardPage(
      title: 'Class Leaderboard',
      showFilters: true,
      showYearFilter: false, // Year is locked to the captain's year
      showDepartmentFilter: true, // Department filter is visible
      showSectionFilter: true, // Section filter is visible
      showCurrentUserRank: true,
      fetchCurrentUser: () async {
        return getIt<CaptainRepository>().getCurrentUser();
      },
    );
  }
}
