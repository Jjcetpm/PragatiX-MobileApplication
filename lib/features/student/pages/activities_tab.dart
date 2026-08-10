import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/attendance/widgets/fire_streak_icon.dart';
import 'package:pragatix/features/student/widgets/stage_card.dart';
import 'package:pragatix/features/student/screens/stage_details_screen.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  final darkColor = const Color(0xFF1E293B);

  List<Map<String, dynamic>> stages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    try {
      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/stages'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> fetchedStages = data['data'] ?? [];

          final List<Map<String, dynamic>> mapped = fetchedStages
              .map((st) {
                return st as Map<String, dynamic>;
              })
              .where((st) {
                final bool isLocked = st['isLocked'] == true;
                final bool isCompleted = st['isCompleted'] == true;
                // Hide future stages entirely, show only past (completed) and current stages
                return !(isLocked && !isCompleted);
              })
              .toList();

          mapped.sort(
            (a, b) => ((a['displayOrder'] ?? a['id']) as num).compareTo(
              (b['displayOrder'] ?? b['id']) as num,
            ),
          );

          setState(() {
            stages = mapped;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _initializeData: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: PragatiXLoader(fullScreen: false, message: 'Loading Activities...'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Activities & Stages',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: darkColor,
        elevation: 0,
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: FireStreakIcon(streakCount: provider.currentStreak),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete subgroups to unlock the next stages.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: stages.isEmpty
                    ? const Center(child: Text('No stages found.'))
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: stages.length,
                        itemBuilder: (context, index) {
                          final stage = stages[index];
                          return StageCard(
                            stage: stage,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StageDetailsScreen(stage: stage),
                                ),
                              ).then((_) {
                                // Refresh when coming back just in case
                                _initializeData();
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
