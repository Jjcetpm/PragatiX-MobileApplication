import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/analytics/pages/student_attendance_analytics_page.dart';
import 'package:pragatix/features/analytics/providers/attendance_analytics_provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart' as pragatix_auth;
import 'package:pragatix/features/analytics/pages/xp_analytics_dashboard_page.dart';
class StudentAnalyticsPage extends StatelessWidget {
  const StudentAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Analytics'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAttendanceCard(context),
          const SizedBox(height: 12),
          _buildXpCard(context),
          const SizedBox(height: 12),
          _buildPlaceholderCard('Activity Analytics'),
          const SizedBox(height: 12),
          _buildPlaceholderCard('Promotion Analytics'),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // For the ripple effect to not overflow
      child: InkWell(
        onTap: () {
          final token = context.read<pragatix_auth.AuthProvider>().token ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => AttendanceAnalyticsProvider(token),
                child: StudentAttendanceAnalyticsPage(
                  isSuperAdmin: context.read<pragatix_auth.AuthProvider>().isSuperAdmin,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => XpAnalyticsDashboardPage(
                isSuperAdmin: context.read<pragatix_auth.AuthProvider>().isSuperAdmin,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'XP Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
