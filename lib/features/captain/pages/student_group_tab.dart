import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pragatix/features/captain/services/captain_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/team/pages/student_team_details_page.dart';

class StudentGroupTab extends StatefulWidget {
  const StudentGroupTab({super.key});

  @override
  State<StudentGroupTab> createState() => _StudentGroupTabState();
}

class _StudentGroupTabState extends State<StudentGroupTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMyGroup();
  }

  Future<void> _fetchMyGroup() async {
    setState(() => _isLoading = true);
    try {
      final response = await getIt<CaptainProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/my-team'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _groupData = data['data'];
            _members = _groupData?['teamMembers'] ?? [];
          });
        } else {
          setState(() {
            _groupData = null;
            _members = [];
          });
        }
      } else {
        setState(() {
          _groupData = null;
          _members = [];
        });
      }
    } catch (e) {
      ErrorHandler.showSnackBar(context, e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasGroup = _groupData != null;

    if (!hasGroup) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Group'),
          backgroundColor: Colors.amber,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.group_off_rounded,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No Team Assigned",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are not assigned to any group yet. Please contact your Class Coordinator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchMyGroup,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Return StudentTeamDetailsPage configured for read-only leaderboard view
    return const StudentTeamDetailsPage();
  }
}
