import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/shared/widgets/profile_header.dart';
import 'package:pragatix/shared/widgets/shared_profile_card.dart';
import 'package:pragatix/shared/widgets/shared_logout_button.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/badge/pages/cc_badge_requests_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;
  String _name = 'Teacher';
  String _email = '';
  String _role = 'TEACHER';
  String _department = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final d = data['data'];
          setState(() {
            _name = d['fullName'] ?? d['username'] ?? 'Teacher';
            _email = d['email'] ?? '';
            _role = d['role'] ?? 'TEACHER';
            _department = d['department'] ?? '';
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // fallback
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Profile Summary',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFF1F5F9),
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  SharedProfileHeader(
                    title: _name,
                    subtitle: _email,
                    icon: Icons.person,
                    radius: 60,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Access Scope: Student Discipline Monitoring',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SharedProfileCard(
                      children: [
                        SharedProfileRow(
                          label: 'Role',
                          value: _role.replaceAll('ROLE_', ''),
                        ),
                        const Divider(height: 24),
                        const SharedProfileRow(
                          label: 'Active System Session',
                          value: 'Yes',
                        ),
                        if (_department.isNotEmpty) ...[
                          const Divider(height: 24),
                          SharedProfileRow(
                            label: 'Department',
                            value: _department,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_role.contains('CC'))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CCBadgeRequestsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.badge, color: Colors.white),
                          label: const Text(
                            'Manage Class Badge Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: SharedLogoutButton(
                      backgroundColor: Color(0xFF11998e),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
