import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'captain_reward_settings_page.dart';

class CaptainRewardYearSelectionPage extends StatelessWidget {
  const CaptainRewardYearSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Captain & Vice Captain Rewards'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Academic Year',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an academic year to configure Captain & Vice Captain automated rewards.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  _buildYearCard(
                    context,
                    '🎓 First Year',
                    'FIRST_YEAR',
                    Icons.looks_one,
                  ),
                  const SizedBox(height: 16),
                  _buildYearCard(
                    context,
                    '🎓 Second Year',
                    'SECOND_YEAR',
                    Icons.looks_two,
                  ),
                  const SizedBox(height: 16),
                  _buildYearCard(
                    context,
                    '🎓 Third Year',
                    'THIRD_YEAR',
                    Icons.looks_3,
                  ),
                  const SizedBox(height: 16),
                  _buildYearCard(
                    context,
                    '🎓 Fourth Year',
                    'FOURTH_YEAR',
                    Icons.looks_4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearCard(
    BuildContext context,
    String title,
    String yearValue,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CaptainRewardSettingsPage(academicYear: yearValue),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: AppColors.adminPrimary),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
